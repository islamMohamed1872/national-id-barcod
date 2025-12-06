import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:nationalidbarcode/models/id_model.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'user_home_states.dart';

class UserHomeCubit extends Cubit<UserHomeStates> {
  UserHomeCubit() : super(UserHomeInitialState());
  static UserHomeCubit get(context) => BlocProvider.of(context);

  final _fire = FirebaseFirestore.instance;
  final GlobalKey barcodeKey = GlobalKey();

  Future<Uint8List> captureBarcode() async {
    print("📸 [captureBarcode] محاولة تصوير الباركود...");

    final boundary =
    barcodeKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

    if (boundary == null) {
      print("❌ [captureBarcode] boundary = NULL !!!");
      throw Exception("لم يتم العثور على عنصر الباركود بعد!");
    }

    print("📸 [captureBarcode] boundary OK. جارٍ تحويله لصورة...");

    // Increased pixelRatio for high-quality image suitable for printing
    final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    print("📸 [captureBarcode] الصورة تم التقاطها (${byteData!.lengthInBytes} بايت).");

    return Uint8List.fromList(byteData.buffer.asUint8List());
  }

  Uint8List? barcodeBytes;
  String? barcodeNumber;
  Future<void> submitNationalId(String id) async {
    print("➡️ [submitNationalId] الإدخال = $id");

    if (id.length != 14) {
      emit(UserHomeErrorState("الرقم القومي يجب أن يكون 14 رقمًا"));
      return;
    }
    // 🔍 Validate age from national ID
    try {
      final age = calculateAgeFromNationalId(id);

      if (age < 18) {
        emit(UserHomeErrorState("يجب أن يكون عمر المستخدم 18 عامًا على الأقل"));
        return;
      }
    } catch (_) {
      emit(UserHomeErrorState("الرقم القومي غير صالح"));
      return;
    }


    emit(UserHomeLoadingState());

    try {
      // Check duplicates
      final exists = await _fire
          .collection("national_ids")
          .where("nationalId", isEqualTo: id)
          .get();

      if (exists.docs.isNotEmpty) {
        emit(UserHomeErrorState("هذا الرقم مسجل بالفعل"));
        return;
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not authenticated");
      final uid = user.uid;

      // ⭐ Generate random barcode number
      barcodeNumber = generateRandomBarcode();

      print("🔢 NEW BARCODE = $barcodeNumber");

      // Save to Firestore
      await _fire.collection("national_ids").doc("$id""$barcodeNumber").set({
        "nationalId": id,
        "ownerId": uid,
        "barcodeNumber": barcodeNumber,   // ⭐ STORE IT
        "state": "new",
        "timestamp": DateTime.now().millisecondsSinceEpoch,
        "checked":false
      });

      // Add to local list
      addedIds.insert(
        0,
        IdModel.fromJson({
          "nationalId": id,
          "ownerId": uid,
          "barcodeNumber": barcodeNumber,
          "state": "new",
          "timestamp": DateTime.now().millisecondsSinceEpoch,
        }),
      );

      // Show barcode
      emit(UserHomeBarcodeReadyState(barcodeNumber!));  // ⭐ DISPLAY RANDOM BARCODE

      await Future.delayed(const Duration(milliseconds: 200));

      barcodeBytes = await captureBarcode();

      emit(UserHomeSuccessState());

    } catch (e) {
      emit(UserHomeErrorState("حدث خطأ: ${e.toString()}"));
    }
  }

  Future<Uint8List> generatePdf(PdfPageFormat format, String title) async {
    final pdf = pw.Document(version: PdfVersion.pdf_1_5, compress: true);
    final font = await PdfGoogleFonts.nunitoExtraLight();

    pdf.addPage(
      pw.Page(
        pageFormat: format,
        build: (context) {
          return pw.Column(
            children: [
              pw.SizedBox(
                width: double.infinity,
                child: pw.FittedBox(
                  child: pw.Text(title, style: pw.TextStyle(font: font)),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Flexible(child: pw.FlutterLogo()),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // =====================================================
  // 🖨 Print Barcode (FIXED - Capture BEFORE state change)
  // =====================================================
  Future<void> printBarcode(String id) async {
    try {
      print("🖨 Checking Firestore…");

      final doc = await _fire.collection("national_ids").doc("$id""$barcodeNumber").get();
      if (!doc.exists) {
        emit(PrintErrorState(error: "هذا الرقم غير موجود"));
        return;
      }

      // ⭐ DON'T emit PrintPreparingState yet - keep barcode visible!

      // Wait for frame to complete
      await Future.delayed(const Duration(milliseconds: 150));

      print("📸 Capturing barcode BEFORE changing state...");

      // ⭐ Capture barcode BEFORE emitting state change
      final boundary = barcodeKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) {
        print("❌ Boundary is NULL - barcode not rendered");
        emit(PrintErrorState(error: "حدث خطأ — لا يمكن تصوير الباركود"));
        return;
      }

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      barcodeBytes = Uint8List.fromList(byteData!.buffer.asUint8List());

      print("📸 Captured ${barcodeBytes!.lengthInBytes} bytes! Opening printer…");

      // ⭐ NOW emit state changes AFTER capture
      emit(PrintPreparingState(id: id));

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
                    child: pw.Image(pw.MemoryImage(barcodeBytes!), width: 300),
                  ),
                  pw.Center(child:  pw.Text(barcodeNumber!,
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
        emit(UserHomeErrorState("تم الغاء الطباعة"));
        emit(UserHomeBarcodeReadyState(id));
        return;
      }

      print("🖨️ Updating Firestore state…");
      await _fire.collection("national_ids").doc("$id""$barcodeNumber").update({"state": "printed"});

      barcodeBytes = null;
      barcodeNumber = null;
      emit(PrintSuccessState());
    } catch (e) {
      print("❌ ERROR: $e");
      emit(PrintErrorState(error: "فشل في الطباعة: ${e.toString()}"));
    }
  }

  List<IdModel> addedIds = [];

  Future<void> loadUserIds() async {
    try {
      emit(UserHomeIdsLoadingState());

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        throw Exception("User not logged in");
      }

      final snapshot = await _fire
          .collection("national_ids")
          .where("ownerId", isEqualTo: uid)
          .orderBy("timestamp", descending: true)
          .get();

      final ids = snapshot.docs.map((doc) => doc).toList();
      addedIds = ids.map((doc) => IdModel.fromDoc(doc)).toList();

      emit(UserHomeIdsLoadedState());
    } catch (e) {
      print(e);
      emit(UserHomeErrorState("Failed loading IDs: $e"));
    }
  }

  Future<void> showBarcodeAgain(String id) async {
    try {
      print("🔁 [showBarcodeAgain] Loading ID = $id…");

      final doc = await _fire.collection("national_ids").doc(id).get();

      if (!doc.exists) {
        emit(UserHomeErrorState("هذا الرقم غير موجود"));
        return;
      }

      // 1️⃣ Reset UI so barcode widget rebuilds
      emit(UserHomeInitialState());
      await Future.delayed(const Duration(milliseconds: 80));

      // 2️⃣ Show barcode widget
      emit(UserHomeBarcodeReadyState(id));
      await Future.delayed(const Duration(milliseconds: 200));

      // 3️⃣ Print (which will capture internally)
      await printBarcode(id);

    } catch (e) {
      print("❌ [showBarcodeAgain] ERROR: $e");
      emit(UserHomeErrorState("Error reloading barcode: ${e.toString()}"));
    }
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
  }
  String generateRandomBarcode() {
    final random = DateTime.now().microsecondsSinceEpoch;
    final number = random % 90000 + 10000; // ensures 5 digits (10000–99999)
    return number.toString();
  }
  int calculateAgeFromNationalId(String id) {
    // Extract digits
    final centuryDigit = id[0];
    final year = int.parse(id.substring(1, 3));
    final month = int.parse(id.substring(3, 5));
    final day = int.parse(id.substring(5, 7));

    // Determine full year
    int fullYear;
    if (centuryDigit == '2') {
      fullYear = 1900 + year;
    } else if (centuryDigit == '3') {
      fullYear = 2000 + year;
    } else {
      throw Exception("Invalid national ID format");
    }

    final birthDate = DateTime(fullYear, month, day);
    final today = DateTime.now();
    int age = today.year - birthDate.year;

    // Adjust if birthday didn't occur yet this year
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }

    return age;
  }

  void listenToForcedLogout(String uid, BuildContext context) async {
    final deviceId = await getDeviceId();

    FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .snapshots()
        .listen((doc) async {
      if (!doc.exists) return;

      final activeDevice = doc.data()?["activeDevice"];

      // If device ID does not match → forced logout
      if (activeDevice != deviceId) {

        // ⭐ Show logout reason
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("تم تسجيل دخول هذا الحساب من جهاز آخر"),
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 3),
          ),
        );

        // Wait for SnackBar to show
        await Future.delayed(const Duration(milliseconds: 700));

        await FirebaseAuth.instance.signOut();
        if (context.mounted) {
          context.go("/");
        }
      }
    });
  }
  Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();

    // If device ID already exists → return it
    if (prefs.getString("device_id") != null) {
      return prefs.getString("device_id")!;
    }

    // Otherwise generate a new one
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    await prefs.setString("device_id", newId);

    return newId;
  }

}