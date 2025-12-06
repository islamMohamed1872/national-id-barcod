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

  // Load users + national ID count
  Future<void> loadUsers() async {
    emit(UsersLoadingState());

    final snap = await _fire.collection("users").get();

    users = [];

    for (var doc in snap.docs) {
      final uid = doc.id;
      final name = doc["name"] ?? "مستخدم";
      final email = doc["email"] ?? "";

      // count national IDs added by this user
      final ids = await _fire
          .collection("national_ids")
          .where("ownerId", isEqualTo: uid)
          .get();
      if(doc['type']=='admin') continue;
      users.add(
        AppUserModel(
          uid: uid,
          name: name,
          email: email,
          count: ids.size,
        ),
      );
    }

    emit(UsersLoadedState());
  }

  // Delete a user
  Future<void> deleteUser(String uid) async {
    await _fire.collection("users").doc(uid).delete();
    await loadUsers();
  }

  // Add user dialog
  void showAddUserDialog(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("إضافة مستخدم جديد"),
        content: Column(
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
          ],
        ),
        actions: [
          TextButton(
            child: const Text("إلغاء",style: TextStyle(
              color: Colors.red
            ),),
            onPressed: () => Navigator.pop(context),
          ),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(AppColors.warmGold),
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
                // Try creating Firebase Auth user
                UserCredential cred = await FirebaseAuth.instance
                    .createUserWithEmailAndPassword(
                  email: email,
                  password: password,
                );

                // Add user to Firestore
                await addUser(
                  name: name,
                  email: email,
                  password: password,
                );

                Navigator.pop(context); // Close dialog on success

              } on FirebaseAuthException catch (e) {
                // Show Arabic error
                _showErrorDialog(context, _firebaseErrorToArabic(e.code));
              } catch (e) {
                _showErrorDialog(context, "حدث خطأ غير متوقع.");
              }
            },
            child:  Text("إضافة",style: TextStyle(color: Colors.white),),
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
          )
        ],
      ),
    );
  }


  // Add user to Firestore
  Future<void> addUser({
    required String name,
    required String email,
    required String password,
  }) async {
    // ⚠ Must use cloud function for secure admin creation
    // For now, write basic firestore document

    await _fire.collection("users").doc(FirebaseAuth.instance.currentUser!.uid).set({
      "name": name,
      "email": email,
      "type" :"user"
    });

    await loadUsers();
  }
  final GlobalKey barcodeKey = GlobalKey();
// ======================================================================
// PRINT LOGIC SAME AS ADMIN
// ======================================================================

  Future<Uint8List> captureBarcode(GlobalKey key) async {
    final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;

    if (boundary == null) {
      throw Exception("Barcode not rendered yet!");
    }

    final image = await boundary.toImage(pixelRatio: 2.0);
    final byteData = await image.toByteData(format: ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }

  Future<void> printBarcodeForUser(BuildContext context, String id, GlobalKey key,String barcodeNumber) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("جار تجهيز الباركود للطباعة...")),
      );

      final bytes = await captureBarcode(key);

      // open OS printing window
      final result =  await Printing.layoutPdf(
        onLayout: (format) async {
          final cairoFont = await rootBundle.load("assets/fonts/Cairo-Regular.ttf");
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
                    pw.Center(child:  pw.Text(barcodeNumber,
                      style:  pw.TextStyle(
                        font: ttf,
                        fontSize: 20,
                      ),
                    )),
                  ]
              ),
            ),
          );
          return pdf.save();
        },
      );
      if(result == false){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("تم الغاء الطباعة"),
            backgroundColor: Colors.red,

          ),

        );
        return;
      }

      // update state in Firestore
      await FirebaseFirestore.instance.collection("national_ids").doc("$id""$barcodeNumber").update({
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

}
