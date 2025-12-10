import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'search_ids_states.dart';
import '../../../models/search_ids_model.dart';

class SearchIdsCubit extends Cubit<SearchIdsStates> {
  SearchIdsCubit() : super(SearchIdsInitialState());
  static SearchIdsCubit get(context) => BlocProvider.of(context);

  final _fire = FirebaseFirestore.instance;

  final GlobalKey barcodeKey = GlobalKey();
  Uint8List? barcodeBytes;

  // =====================================================
  // 🔍 SEARCH LOGIC
  // =====================================================
  Future<void> searchNationalId(String rawId) async {
    final id = rawId.trim();

    if (id.isEmpty) {
      emit(SearchEmptyState());
      return;
    }

    emit(SearchLoadingState());

    try {
      final snap = await _fire.collection("national_ids").get();
      Map<String, dynamic>? match;

      // try by barcode (5 digits)
      if (id.length == 5) {
        for (var doc in snap.docs) {
          final data = doc.data();
          if ((data["barcodeNumber"] ?? "").toString().trim() == id) {
            match = data;
            break;
          }
        }
      }
      // try by nationalId prefix (14 digits)
      else if (id.length == 14) {
        for (var doc in snap.docs) {
          final data = doc.data();
          final nationalId = (data["nationalId"] ?? "").toString().trim();
          if (nationalId.length >= 14 &&
              nationalId.substring(0, 14) == id) {
            match = data;
            break;
          }
        }
      }

      // fallback
      if (match == null) {
        for (var doc in snap.docs) {
          final data = doc.data();
          if ((data["barcodeNumber"] ?? "").toString().trim() == id ||
              (data["nationalId"] ?? "").toString().trim() == id) {
            match = data;
            break;
          }
        }
      }

      if (match == null) {
        emit(SearchEmptyState());
        return;
      }

      // owner data
      final ownerId = match["ownerId"] ?? "";
      String ownerName = "غير معروف";

      if (ownerId.toString().isNotEmpty) {
        final ownerDoc = await _fire.collection("users").doc(ownerId).get();
        ownerName = (ownerDoc.data()?["name"] ?? "غير معروف").toString();
      }

      // checking metadata
      final rawCheckedAt = match["checkedAt"];
      int? checkedAtMillis;

      if (rawCheckedAt is Timestamp) {
        checkedAtMillis = rawCheckedAt.millisecondsSinceEpoch;
      } else if (rawCheckedAt is int) {
        checkedAtMillis = rawCheckedAt;
      }

      emit(
        SearchSuccessState(
          SearchResultModel(
            nationalId: match["nationalId"],
            userName: ownerName,
            state: match["state"] ?? "غير محدد",
            time: match["timestamp"] ?? DateTime.now().millisecondsSinceEpoch,
            barcodeNumber: match["barcodeNumber"] ?? "",
            isChecked: match["checked"] ?? false,
            checkedById: match["checkedBy"],
            checkedAt: checkedAtMillis,
          ),
        ),
      );
    } catch (e) {
      emit(SearchErrorState("حدث خطأ أثناء البحث"));
    }
  }

  // =====================================================
  // 🖨 PRINT
  // (unchanged - keeping exact logic per your request)
  // =====================================================
  Future<void> printBarcode(String id, String barcodeNumber) async {
    try {
      final doc =
      await _fire.collection("national_ids").doc("$id$barcodeNumber").get();

      if (!doc.exists) {
        emit(AdminIdErrorState("الرقم غير موجود"));
        return;
      }

      await Future.delayed(const Duration(milliseconds: 150));

      final boundary =
      barcodeKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        emit(AdminIdErrorState("لم يتم العثور على الباركود"));
        return;
      }

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
      await image.toByteData(format: ui.ImageByteFormat.png);
      barcodeBytes = byteData!.buffer.asUint8List();

      emit(PrintPreparingState(nationalId: id));

      final result = await Printing.layoutPdf(
        onLayout: (format) async {
          final font =
          await rootBundle.load("assets/fonts/Cairo-Regular.ttf");
          final ttf = pw.Font.ttf(font);
          final pdf = pw.Document();

          pdf.addPage(
            pw.Page(
              build: (_) => pw.Column(
                children: [
                  pw.Image(pw.MemoryImage(barcodeBytes!), width: 300),
                  pw.Text(
                    barcodeNumber,
                    style: pw.TextStyle(font: ttf, fontSize: 20),
                  ),
                ],
              ),
            ),
          );
          return pdf.save();
        },
      );

      if (result == false) {
        emit(AdminIdErrorState("تم إلغاء الطباعة"));
        return;
      }

      await _fire
          .collection("national_ids")
          .doc("$id$barcodeNumber")
          .update({"state": "printed"});

      barcodeBytes = null;
      emit(PrintSuccessState());
    } catch (e) {
      emit(AdminIdErrorState("فشل الطباعة"));
    }
  }

  // =====================================================
  // ✔️ Toggle Check Logic
  // =====================================================
  Future<void> toggleCheckedStatus(
      String id, bool newValue, String barcodeNumber) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc = await _fire.collection("users").doc(user.uid).get();
      final userType = userDoc.data()?["type"] ?? "user";

      // prevent searcher unchecking
      if (userType == "searcher" && newValue == false) {
        emit(AdminIdErrorState("لا يمكنك إلغاء التمييز"));
        return;
      }

      Map<Object, Object?> updateData = {
        "checked": newValue,
      };

      if (newValue == true) {
        updateData["checkedBy"] = user.uid;
        updateData["checkedAt"] = FieldValue.serverTimestamp();
      }
      else{
        updateData["checkedBy"] = null;
        updateData["checkedAt"] = null;
      }

      await _fire
          .collection("national_ids")
          .doc("$id$barcodeNumber")
          .update(updateData);

      emit(CheckToggleSuccessState(newValue));

      await Future.delayed(const Duration(milliseconds: 200));
      await searchNationalId(id);
    } catch (e) {
      emit(AdminIdErrorState("حدث خطأ في التحديث"));
    }
  }
}
