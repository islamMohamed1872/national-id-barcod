import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  bool isScanning = true;
  bool torchOn = false;

  late final MobileScannerController controller;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
  }

  /// =====================================================
  /// 🔥 STORE SCAN (single doc per barcode)
  /// =====================================================
  Future<void> _storeScan(String code) async {
    try {
      final current = FirebaseAuth.instance.currentUser;
      if (current == null) return;

      // get user name
      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(current.uid)
          .get();

      final userName = userDoc.data()?["name"] ?? "غير معروف";
      print("code");

      // push scan to array
      await FirebaseFirestore.instance
          .collection("scans")
          .doc(code)
          .set(
        {
          "barcodeNumber": code,
          "scans": FieldValue.arrayUnion([
            {
              "scannedBy": current.uid,
              "scannedByName": userName,
              "time": Timestamp.now()
            }
          ]),
        },
        SetOptions(merge: true), // 👈 keeps old scans and only adds new one
      );
      print("done");

    } catch (e) {
      debugPrint("🔥 Error saving scan: $e");
    }
  }

  /// =====================================================
  /// UI
  /// =====================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("سكان الباركود"),
        actions: [
          IconButton(
            icon: Icon(
              torchOn ? Icons.flash_on : Icons.flash_off,
            ),
            onPressed: () {
              controller.toggleTorch();
              setState(() => torchOn = !torchOn);
            },
          ),
        ],
      ),
      body: MobileScanner(
        controller: controller,
        onDetect: (capture) async {
          if (!isScanning) return;
          final barcode = capture.barcodes.first;
          final code = barcode.rawValue;
          if (code == null) return;

          isScanning = false;

          /// 👉 SAVE SCAN
          await _storeScan(code.trim());

          /// 👉 RETURN TO PREVIOUS SCREEN
          if (mounted) {
            Navigator.pop(context, code.trim());
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
