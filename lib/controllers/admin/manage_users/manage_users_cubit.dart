import 'dart:typed_data';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nationalidbarcode/constants/app_colors.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../models/app_user_model.dart';
import 'manage_users_states.dart';

class ManageUsersCubit extends Cubit<ManageUsersStates> {
  ManageUsersCubit() : super(ManageUsersInitialState());
  static ManageUsersCubit get(context) => BlocProvider.of(context);

  List<AppUserModel> users = [];

  final _fire = FirebaseFirestore.instance;

  // =====================================================
  // Load users + national ID count
  // (skips admins - only manage normal users & searchers)
  // =====================================================
  Future<void> loadUsers() async {
    emit(UsersLoadingState());

    users = [];

    /// 1️⃣ Load all users
    final userSnap = await _fire.collection("users").get();

    /// 2️⃣ Load all national IDs once
    final idsSnap = await _fire.collection("national_ids").get();

    /// 3️⃣ Load all scan documents once
    final scansSnap = await _fire.collection("scans").get();

    for (var doc in userSnap.docs) {
      final uid = doc.id;
      final name = doc["name"] ?? "مستخدم";
      final email = doc["email"] ?? "";
      final type = doc["type"] ?? "user";

      if (type == "admin") continue; // skipping admins

      // count national IDs belonging to this user
      final idCount = idsSnap.docs
          .where((d) => d["ownerId"] == uid)
          .length;

      // count scans performed by this user
      int scanCount = 0;

      for (var scanDoc in scansSnap.docs) {
        final scans = scanDoc["scans"] as List? ?? [];

        if (scans.any((s) => s["scannedBy"] == uid)) {
          scanCount++;
        }
      }

      users.add(
        AppUserModel(
          uid: uid,
          name: name,
          email: email,
          count: idCount + scanCount,
          type: type,
        ),
      );
    }

    emit(UsersLoadedState());
  }

  // =====================================================
  // Delete a user
  // =====================================================
  Future<void> deleteUser(String uid) async {
    await _fire.collection("users").doc(uid).delete();
    await loadUsers();
  }

  // =====================================================
  // Add user dialog
  //  - Admin can create:
  //      * type "user"  (existing behavior)
  //      * type "searcher" (new role: search-only)
  // =====================================================
  void showAddUserDialog(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passController = TextEditingController();

    String selectedType = "user"; // default: normal user

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("إضافة مستخدم جديد"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "اسم المستخدم"),
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "البريد الإلكتروني"),
              ),
              TextField(
                controller: passController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "كلمة المرور"),
              ),
              const SizedBox(height: 12),
              // نوع المستخدم
              DropdownButtonFormField<String>(
                dropdownColor: Colors.white,
                value: selectedType,
                decoration: const InputDecoration(
                  labelText: "نوع المستخدم",
                ),
                items: const [
                  DropdownMenuItem(
                    value: "user",
                    child: Text("مستخدم عادي"),
                  ),
                  DropdownMenuItem(
                    value: "searcher",
                    child: Text("باحث (شاشة البحث فقط)"),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    selectedType = val;
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text(
              "إلغاء",
              style: TextStyle(color: Colors.red),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(AppColors.warmGold),
            ),
            onPressed: () async {
              final name = nameController.text.trim();
              final email = emailController.text.trim();
              final password = passController.text.trim();

              // Basic validation
              if (name.isEmpty || email.isEmpty || password.isEmpty) {
                _showErrorDialog(context, "من فضلك املأ جميع الحقول.");
                return;
              }

              try {
                // إنشاء المستخدم في Firebase Auth
                UserCredential cred = await FirebaseAuth.instance
                    .createUserWithEmailAndPassword(
                  email: email,
                  password: password,
                );

                // إنشاء مستند المستخدم في Firestore
                await addUser(
                  uid: cred.user!.uid,
                  name: name,
                  email: email,
                  type: selectedType,
                );

                Navigator.pop(context); // Close dialog on success
              } on FirebaseAuthException catch (e) {
                _showErrorDialog(context, _firebaseErrorToArabic(e.code));
              } catch (e) {
                _showErrorDialog(context, "حدث خطأ غير متوقع.");
              }
            },
            child: const Text(
              "إضافة",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  String _firebaseErrorToArabic(String code) {
    switch (code) {
      case "email-already-in-use":
        return "هذا البريد مستخدم بالفعل.";
      case "invalid-email":
        return "البريد الإلكتروني غير صالح.";
      case "weak-password":
        return "كلمة المرور ضعيفة جداً.";
      case "operation-not-allowed":
        return "إنشاء الحسابات معطّل حالياً.";
      case "network-request-failed":
        return "خطأ في الاتصال. تأكد من وجود إنترنت.";
      default:
        return "فشل إنشاء المستخدم. حاول مرة أخرى.";
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("خطأ"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("حسناً"),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // Add user to Firestore
  //  - Uses the newly created Auth UID
  //  - Saves "type": "user" or "searcher"
  // =====================================================
  Future<void> addUser({
    required String uid,
    required String name,
    required String email,
    required String type,
  }) async {
    await _fire.collection("users").doc(uid).set({
      "name": name,
      "email": email,
      "type": type, // "user" | "searcher"
    });

    await loadUsers();
  }

  // =====================================================
  // Printing logic for user barcodes (unchanged)
  // =====================================================
  final GlobalKey barcodeKey = GlobalKey();

  Future<Uint8List> captureBarcode(GlobalKey key) async {
    final boundary =
    key.currentContext?.findRenderObject() as RenderRepaintBoundary?;

    if (boundary == null) {
      throw Exception("Barcode not rendered yet!");
    }

    final image = await boundary.toImage(pixelRatio: 2.0);
    final byteData = await image.toByteData(format: ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }

  Future<void> printBarcodeForUser(
      BuildContext context,
      String id,
      GlobalKey key,
      String barcodeNumber,
      ) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("جار تجهيز الباركود للطباعة...")),
      );

      final bytes = await captureBarcode(key);

      final result = await Printing.layoutPdf(
        onLayout: (format) async {
          final cairoFont =
          await rootBundle.load("assets/fonts/Cairo-Regular.ttf");
          final ttf = pw.Font.ttf(cairoFont);
          final pdf = pw.Document();
          pdf.addPage(
            pw.Page(
              pageFormat: PdfPageFormat.a4,
              build: (_) => pw.Column(
                children: [
                  pw.Center(
                    child: pw.Image(pw.MemoryImage(bytes), width: 300),
                  ),
                  pw.Center(
                    child: pw.Text(
                      barcodeNumber,
                      style: pw.TextStyle(
                        font: ttf,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
          return pdf.save();
        },
      );

      if (result == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("تم الغاء الطباعة"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      await FirebaseFirestore.instance
          .collection("national_ids")
          .doc("$id$barcodeNumber")
          .update({
        "state": "printed",
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("تمت الطباعة وتحديث الحالة ✓"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("فشل في الطباعة: $e")),
      );
    }
  }

  Future<void> toggleCheck(DocumentReference docRef, bool currentValue) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (currentValue == true) {
      // 🔴 UNCHECK
      await docRef.update({
        "checked": false,
        "checkedBy": FieldValue.delete(),
        "checkedAt": FieldValue.delete(),
      });
    } else {
      // 🟢 CHECK
      await docRef.update({
        "checked": true,
        "checkedBy": user.uid,
        "checkedAt": FieldValue.serverTimestamp(),
      });
    }
    emit(ToggleCheckBox());
  }

}
