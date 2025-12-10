import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:nationalidbarcode/controllers/admin/manage_users/manage_users_cubit.dart';
import 'package:nationalidbarcode/views/widgets/custom_scaffold.dart';
import '../../../constants/app_colors.dart';

class UserIdsScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const UserIdsScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<UserIdsScreen> createState() => _UserIdsScreenState();
}

class _UserIdsScreenState extends State<UserIdsScreen> {
  final TextEditingController searchController = TextEditingController();
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: CustomScaffold(
        backgroundColor: const Color(AppColors.whiteSmoke),

        appBar: AppBar(
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios, color: Color(AppColors.warmGold)),
          ),
          backgroundColor: const Color(AppColors.primaryNavy),
          title: Text(
            "الأرقام القومية لـ ${widget.userName}",
            style: const TextStyle(
              color: Color(AppColors.warmGold),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        body: Column(
          children: [
            // 🔍 SEARCH BAR
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: searchController,
                onChanged: (value) {
                  setState(() {
                    searchQuery = value.trim();
                  });
                },
                decoration: InputDecoration(
                  labelText: "بحث برقم قومي",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: const Color(AppColors.lightGrey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("national_ids")
                    .where("ownerId", isEqualTo: widget.userId)
                    .orderBy("timestamp", descending: true)
                    .snapshots(),

                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // ⭐ Get all docs from stream
                  final allDocs = snapshot.data!.docs;

                  // ⭐ Filter based on search query EVERY TIME stream updates
                  final filteredDocs = searchQuery.isEmpty
                      ? allDocs
                      : allDocs.where((doc) {
                    final id = doc['nationalId'].toString();
                    final barcode = doc['barcodeNumber'].toString();

                    return id.contains(searchQuery) || barcode == searchQuery;
                  }).toList();

                  if (filteredDocs.isEmpty) {
                    return const Center(
                      child: Text(
                        "لا يوجد نتائج مطابقة.",
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredDocs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),

                    itemBuilder: (_, i) {
                      final doc = filteredDocs[i];
                      final data = doc.data() as Map<String, dynamic>;

                      final nationalId = data["nationalId"] ?? "";
                      final barcodeNumber = data["barcodeNumber"] ?? "";

                      // ⭐ FIX: Handle null by defaulting to false
                      final isChecked = data["checked"] ?? false;

                      final state = data["state"] ?? "new";
                      final timestamp = data["timestamp"];

                      if (timestamp == null) {
                        return const SizedBox.shrink();
                      }

                      final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);

                      final formattedDate =
                          "${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}";

                      final formattedTime =
                          "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";

                      return Card(
                        elevation: 6,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),

                        child: ListTile(
                          title: Text(
                            nationalId,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(AppColors.primaryNavy),
                            ),
                          ),

                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "الحالة: $state",
                                style: const TextStyle(fontSize: 14, color: Colors.black87),
                              ),

                              Text(
                                "التاريخ: $formattedDate\n"
                                    "الوقت: $formattedTime\n"
                                    "رقم الباركود: ${barcodeNumber.isEmpty ? 'لا يوجد' : barcodeNumber}",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                ),
                              )
                            ],
                          ),

                          trailing: SizedBox(
                            width: 150,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                // ⭐ Checkbox
                                InkWell(
                                  onTap: () {
                                    _confirmCheckToggle(context, doc.id, nationalId, !isChecked);
                                  },

                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5),
                                      border: isChecked ? null : Border.all(color: Colors.black, width: 2),
                                      color: isChecked ? Colors.green : Colors.white,
                                    ),
                                    child: isChecked
                                        ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 18,
                                    )
                                        : null,
                                  ),
                                ),

                                const SizedBox(width: 10),

                                // ⭐ Print button
                                IconButton(
                                  icon: const Icon(Icons.print, color: Color(AppColors.deepBlue)),
                                  onPressed: () {
                                    _showBarcodePopup(context, nationalId, state, barcodeNumber);
                                  },
                                ),

                                // ⭐ Delete button
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    _confirmDelete(context, nationalId, doc.id);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------------------
  // POPUP PRINT WINDOW
  // ----------------------------------------------------------------------
  void _showBarcodePopup(BuildContext parentContext, String id, String state, String barcodeNumber) {
    final printKey = GlobalKey();

    showModalBottomSheet(
      context: parentContext,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (bottomSheetContext) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "باركود الرقم: $id",
                style: const TextStyle(
                  color: Color(AppColors.primaryNavy),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              RepaintBoundary(
                key: printKey,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.black12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: BarcodeWidget(
                    barcode: Barcode.code128(),
                    data: id,
                    width: 280,
                    height: 120,
                    drawText: false,
                  ),
                ),
              ),

              if (barcodeNumber.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    barcodeNumber,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),

              const SizedBox(height: 25),

              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(bottomSheetContext);

                  await ManageUsersCubit.get(parentContext)
                      .printBarcodeForUser(parentContext, id, printKey, barcodeNumber);
                },

                icon: const Icon(Icons.print, color: Color(AppColors.warmGold)),
                label: const Text(
                  "طباعة الباركود",
                  style: TextStyle(
                    color: Color(AppColors.warmGold),
                    fontWeight: FontWeight.bold,
                  ),
                ),

                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(AppColors.primaryNavy),
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 26),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------
  // CHECKBOX CONFIRMATION DIALOG
  // -------------------------------------------------------------
  void _confirmCheckToggle(BuildContext context, String docId, String nationalId, bool newValue) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            "تأكيد التحديث",
            textDirection: TextDirection.rtl,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            newValue
                ? "هل تريد تمييز الرقم $nationalId كمستلم؟"
                : "هل تريد إلغاء تمييز الرقم $nationalId؟",
            textDirection: TextDirection.rtl,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("إلغاء"),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(AppColors.deepBlue),
              ),
              onPressed: () async {
                Navigator.pop(context); // close dialog

                try {
                  print(docId);
                 final docRef =   FirebaseFirestore.instance
                      .collection("national_ids")
                      .doc(docId);
                  if (newValue == false) {
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
                      "checkedBy": FirebaseAuth.instance.currentUser?.uid,
                      "checkedAt": FieldValue.serverTimestamp(),
                    });
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        newValue ? "تم التمييز بنجاح" : "تم إلغاء التمييز",
                      ),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                } catch (e) {
                  print("Error updating checked: $e");
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("حدث خطأ في التحديث"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text("تأكيد", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // -------------------------------------------------------------
  // DELETE FUNCTION
  // -------------------------------------------------------------
  void _confirmDelete(BuildContext context, String nationalId, String docId) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            "تأكيد الحذف",
            textDirection: TextDirection.rtl,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            "هل تريد حذف الرقم القومي $nationalId ؟",
            textDirection: TextDirection.rtl,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("إلغاء"),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () async {
                Navigator.pop(context); // close dialog

                try {
                  await FirebaseFirestore.instance
                      .collection("national_ids")
                      .doc(docId)
                      .delete();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("تم حذف الرقم $nationalId بنجاح"),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                } catch (e) {
                  print("Error deleting: $e");
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("حدث خطأ عند الحذف"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text("حذف", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}