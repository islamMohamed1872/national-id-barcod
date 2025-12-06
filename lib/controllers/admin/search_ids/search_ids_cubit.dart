import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../models/search_ids_model.dart';
import 'search_ids_states.dart';

class SearchIdsCubit extends Cubit<SearchIdsStates> {
  SearchIdsCubit() : super(SearchIdsInitialState());
  static SearchIdsCubit get(context) => BlocProvider.of(context);

  final _fire = FirebaseFirestore.instance;

  /// --- Needed for capturing the barcode widget ---
  final GlobalKey barcodeKey = GlobalKey();

  Uint8List? barcodeBytes;

  // =====================================================
  // 🔍 Search for National ID
  // =====================================================
  Future<void> searchNationalId(String id) async {
    if (id.isEmpty) {
      emit(SearchEmptyState());
      return;
    }

    emit(SearchLoadingState());

    try {
      // Load all documents (collection small = OK)
      final snap = await _fire.collection("national_ids").get();

      Map<String, dynamic>? match;

      // ============================================================
      // 🔍 Case 1: User entered 5 digits → match with LAST 5 digits
      // ============================================================
      if (id.length == 5) {
        for (var doc in snap.docs) {
          final nationalId = doc["barcodeNumber"].toString();
          if (nationalId.length >= 5 && nationalId==id) {
            match = doc.data();
            break;
          }
        }
      }

      // ============================================================
      // 🔍 Case 2: User entered 14 digits → match with FIRST 14 digits
      // ============================================================
      else if (id.length == 14) {
        for (var doc in snap.docs) {
          final nationalId = doc["nationalId"].toString();
          if (nationalId.length >= 14 && nationalId.substring(0, 14) == id) {
            match = doc.data();
            break;
          }
        }
      }

      // ============================================================
      // ❌ No match found
      // ============================================================
      if (match == null) {
        emit(SearchEmptyState());
        return;
      }

      // Fetch user info
      final ownerId = match["ownerId"];
      final userDoc = await _fire.collection("users").doc(ownerId).get();
      final userName = userDoc.exists ? userDoc["name"] : "غير معروف";

      // Emit success
      emit(
        SearchSuccessState(
          SearchResultModel(
            nationalId: match["nationalId"],
            userName: userName,
            state: match["state"] ?? "غير محدد",
            time: match["timestamp"] ??
                DateTime.now().millisecondsSinceEpoch,
            barcodeNumber: match["barcodeNumber"] ?? "",
            isChecked: match["checked"] ?? false,
          ),
        ),
      );
    } catch (e) {
      emit(SearchErrorState("حدث خطأ أثناء البحث"));
    }
  }
  // =====================================================
  // 📸 Capture Barcode Image
  // =====================================================
  Future<Uint8List> captureBarcode() async {
    print("📸 [captureBarcode] محاولة تصوير الباركود...");

    final boundary =
    barcodeKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

    if (boundary == null) {
      print("❌ Boundary = NULL");
      throw Exception("لم يتم العثور على عنصر الباركود!");
    }

    final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    print("📸 Captured ${byteData!.lengthInBytes} bytes");
    return Uint8List.fromList(byteData.buffer.asUint8List());
  }

  // =====================================================
  // 🖨 Print Barcode (Fixed - Capture BEFORE state change)
  // =====================================================
  Future<void> printBarcode(String id,String barcodeNumber) async {
    try {
      print("🖨️ Checking Firestore…");

      final doc = await _fire.collection("national_ids").doc("$id""$barcodeNumber").get();
      if (!doc.exists) {
        emit(AdminIdErrorState("تم العثور على خطأ — الرقم غير موجود"));
        return;
      }

      // Wait until widget is fully rendered
      await Future.delayed(const Duration(milliseconds: 100));

      final boundary = barcodeKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        print("❌ Boundary is NULL - barcode not rendered");
        emit(AdminIdErrorState("Unable to capture the barcode."));
        return;
      }

      print("📸 Capturing barcode…");
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      barcodeBytes = Uint8List.fromList(byteData!.buffer.asUint8List());

      print("📸 Barcode captured (${barcodeBytes!.lengthInBytes} bytes)");

      emit(PrintPreparingState(nationalId: id));

      // ⭐ THIS is the important part: check result
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

      // ⭐ result == null → user canceled the print dialog
      if (result == false) {
        print("⚠️ Print was canceled by the user.");
        emit(AdminIdErrorState("تم الغاء الطباعة"));
        return; // ❌ DO NOT UPDATE FIRESTORE
      }

      // If we reach here → printing was successful
      print("🖨️ Printing completed. Updating Firestore…");

      await _fire.collection("national_ids").doc("$id""$barcodeNumber").update({
        "state": "printed",
      });

      barcodeBytes = null;
      emit(PrintSuccessState());

    } catch (e) {
      print("❌ ERROR: $e");
      emit(AdminIdErrorState("Printing failed: ${e.toString()}"));
    }
  }

  Future<void> toggleCheckedStatus(String id, bool newValue,String barcodeNumber) async {
    try {
      await _fire.collection("national_ids").doc("$id""$barcodeNumber").update({
        "checked": newValue,
      });

      // Refresh the search to show updated state
      await searchNationalId(id);

      // Show success message via state
      emit(CheckToggleSuccessState(newValue));

      // Wait a moment then search again to show updated data
      await Future.delayed(Duration(milliseconds: 500));
      await searchNationalId(id);
    } catch (e) {
      emit(AdminIdErrorState("حدث خطأ في التحديث: ${e.toString()}"));
    }
  }
}