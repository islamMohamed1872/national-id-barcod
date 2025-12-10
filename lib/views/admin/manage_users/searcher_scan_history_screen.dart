import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nationalidbarcode/controllers/admin/manage_users/manage_users_states.dart';
import '../../../constants/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../controllers/admin/manage_users/manage_users_cubit.dart';

class SearcherScanHistoryScreen extends StatelessWidget {

  final String userId;
  final String userName;

  const SearcherScanHistoryScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = ManageUsersCubit.get(context);

    return BlocBuilder<ManageUsersCubit,ManageUsersStates>(
      builder: (context,state) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: const Color(AppColors.primaryNavy),
              title: Text(
                "سجلات مسح: $userName",
                style: const TextStyle(
                  color: Color(AppColors.warmGold),
                  fontWeight: FontWeight.bold,
                ),
              ),
              leading: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new),
                color: Color(AppColors.warmGold),
              ),
            ),

            body: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("scans")
                  .snapshots(),
              builder: (_, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final scanDocs = snap.data!.docs;

                final filteredDocs = scanDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final scans = (data["scans"] ?? []) as List;
                  return scans.any((s) => s["scannedBy"] == userId);
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(
                    child: Text(
                      "لا يوجد عمليات مسح لهذا الباحث",
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredDocs.length,
                  itemBuilder: (_, i) {

                    final scanDoc = filteredDocs[i];
                    final barcode = scanDoc.id;

                    return FutureBuilder<QuerySnapshot>(
                      future: FirebaseFirestore.instance
                          .collection("national_ids")
                          .where("nationalId", isEqualTo: barcode)
                          .get(),
                      builder: (_, idSnap) {
                        if (!idSnap.hasData) return const SizedBox();

                        if (idSnap.data!.docs.isEmpty) {
                          return _noNationalIdCard(barcode);
                        }

                        final docRef = idSnap.data!.docs.first.reference;
                        final idData =
                        idSnap.data!.docs.first.data() as Map<String, dynamic>;

                        return _barcodeCard(context, cubit, docRef, idData);
                      },
                    );
                  },
                );
              },
            ),
          ),
        );
      }
    );
  }

  // ==========================================================
  // FULL TOGGLE CHECKBOX (USING CUBIT)
  // ==========================================================
  Widget _barcodeCard(
      BuildContext context,
      ManageUsersCubit cubit,
      DocumentReference docRef,
      Map<String, dynamic> data,
      ) {

    final nationalId = data["nationalId"] ?? "";
    final barcodeNumber = data["barcodeNumber"] ?? "";
    final state = data["state"] ?? "غير محدد";
    final isChecked = data["checked"] ?? false;

    final timestamp = data["timestamp"] ?? 0;
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);

    final formattedDate =
        "${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}";

    final formattedTime =
        "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        title: Text(
          "الرقم القومي: $nationalId",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(AppColors.charcoal),
          ),
        ),
        subtitle: Text(
          "الحالة: $state\n"
              "التاريخ: $formattedDate\n"
              "الوقت: $formattedTime\n"
              "رقم الباركود: $barcodeNumber",
        ),

        // ⭐⭐⭐ USE CUBIT FOR TOGGLE
        trailing: InkWell(
          onTap: () async {
            await cubit.toggleCheck(docRef, isChecked);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isChecked ? "تم إلغاء التمييز" : "تم التمييز ✓",
                ),
                backgroundColor: isChecked ? Colors.red : Colors.green,
                duration: const Duration(seconds: 1),
              ),
            );
          },
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: isChecked
                  ? null
                  : Border.all(color: Colors.black, width: 2),
              color: isChecked ? Colors.green : Colors.white,
            ),
            child: isChecked
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : null,
          ),
        ),
      ),
    );
  }

  Widget _noNationalIdCard(String barcode) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        title: Text("باركود: $barcode"),
        subtitle: const Text("لا يوجد بيانات رقم قومي"),
        trailing: const Icon(Icons.error, color: Colors.red),
      ),
    );
  }
}
