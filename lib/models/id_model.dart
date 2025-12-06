import 'package:cloud_firestore/cloud_firestore.dart';

class IdModel {
  final String id;
  final String ownerName;
  final String state;
  final int time;
  final String barcodeNumber;   // ⭐ NEW

  IdModel({
    required this.id,
    required this.ownerName,
    required this.state,
    required this.time,
    required this.barcodeNumber,
  });

  factory IdModel.fromJson(Map<String, dynamic> json) {
    return IdModel(
      id: json["nationalId"],
      ownerName: json["ownerName"] ?? "",
      state: json["state"] ?? "new",
      time: json["timestamp"],
      barcodeNumber: json["barcodeNumber"] ?? "",  // ⭐ NEW
    );
  }

  factory IdModel.fromDoc(DocumentSnapshot doc) {
    final json = doc.data() as Map<String, dynamic>;
    return IdModel.fromJson(json);
  }
}
