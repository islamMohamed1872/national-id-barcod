import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:barcode_widget/barcode_widget.dart';

import '../../../constants/app_colors.dart';
import '../../../controllers/admin/search_ids/search_ids_cubit.dart';
import '../../../controllers/admin/search_ids/search_ids_states.dart';
import 'package:nationalidbarcode/views/widgets/custom_scaffold.dart';

import 'barcode_scanner_screen.dart';

class SearchIDsScreen extends StatelessWidget {
  final bool isSearcher;
  const SearchIDsScreen({super.key, this.isSearcher = false});

  /// ============================
  /// BARCODE SCAN
  /// ============================
  Future<void> _scanBarcode(
      BuildContext context,
      TextEditingController controller,
      ) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const BarcodeScannerScreen(),
      ),
    );

    if (result == null) return;

    final clean = result.toString().trim();
    controller.text = clean;

    final cubit = SearchIdsCubit.get(context);
    cubit.searchNationalId(clean);
  }

  @override
  Widget build(BuildContext context) {
    final searchController = TextEditingController();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: BlocProvider(
        create: (_) => SearchIdsCubit(),
        child: BlocConsumer<SearchIdsCubit, SearchIdsStates>(
          listener: (context, state) {
            if (state is CheckToggleSuccessState) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state.isChecked
                        ? "تم التمييز بنجاح"
                        : "تم إلغاء التمييز",
                  ),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
          builder: (context, state) {
            final cubit = SearchIdsCubit.get(context);

            return CustomScaffold(
              backgroundColor: const Color(AppColors.whiteSmoke),
              body: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Text(
                      "البحث عن رقم قومي",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(AppColors.primaryNavy),
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// ============================
                    /// SEARCH + SCAN BUTTON
                    /// ============================
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: searchController,
                            keyboardType: TextInputType.number,
                            onChanged: (value) =>
                                cubit.searchNationalId(value.trim()),
                            decoration: InputDecoration(
                              labelText: "ادخل الرقم القومي أو الباركود",
                              filled: true,
                              fillColor: const Color(AppColors.lightGrey),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.search),
                                onPressed: () => cubit.searchNationalId(
                                  searchController.text.trim(),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          onPressed: () =>
                              _scanBarcode(context, searchController),
                          icon: const Icon(
                            Icons.qr_code_scanner,
                            size: 34,
                            color: Color(AppColors.deepBlue),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    /// ============================
                    /// CUBIT STATES
                    /// ============================
                    if (state is SearchLoadingState)
                      const CircularProgressIndicator(),

                    if (state is SearchEmptyState)
                      const Text(
                        "لا يوجد بيانات لهذا الرقم.",
                        style: TextStyle(fontSize: 18),
                      ),

                    if (state is SearchSuccessState ||
                        state is PrintPreparingState)
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              if (state is SearchSuccessState)
                                _resultCard(context, state, isSearcher),

                              const SizedBox(height: 20),

                              /// BARCODE WIDGET
                              RepaintBoundary(
                                key: cubit.barcodeKey,
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  color: Colors.white,
                                  child: BarcodeWidget(
                                    barcode: Barcode.code128(),
                                    data: state is SearchSuccessState
                                        ? state.model.nationalId
                                        : (state as PrintPreparingState)
                                        .nationalId,
                                    width: 300,
                                    height: 120,
                                    drawText: false,
                                  ),
                                ),
                              ),

                              Text(
                                state is SearchSuccessState
                                    ? state.model.barcodeNumber
                                    : "",
                                style: const TextStyle(fontSize: 20),
                              ),

                              const SizedBox(height: 20),

                              /// ============================
                              /// ADMIN ONLY SECTION
                              /// ============================
                              if (!isSearcher && state is SearchSuccessState) ...[
                                _checkedInfo(state),
                                const SizedBox(height: 16),
                                _scanHistory(state),
                                const SizedBox(height: 20),

                                /// PRINT BUTTON (admin only)
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                    const Color(AppColors.deepBlue),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.print,
                                    color: Color(AppColors.warmGold),
                                  ),
                                  label: const Text(
                                    "طباعة الباركود",
                                    style: TextStyle(
                                      color: Color(AppColors.warmGold),
                                      fontSize: 16,
                                    ),
                                  ),
                                  onPressed: () {
                                    final m =
                                        (state).model;
                                    _showPrintConfirmation(
                                      context,
                                      cubit,
                                      m.nationalId,
                                      m.barcodeNumber,
                                    );
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                    if (state is AdminIdErrorState)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          state.message,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // =====================================================
  // RESULT CARD (WITH STATUS, OWNER, DATE, TIME, BARCODE)
  // =====================================================
  Widget _resultCard(
      BuildContext context,
      SearchSuccessState state,
      bool isSearcher,
      ) {
    final dt = DateTime.fromMillisecondsSinceEpoch(state.model.time);
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
          "الرقم القومي: ${state.model.nationalId}",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(AppColors.charcoal),
          ),
        ),
        subtitle: Text(
          "أُضيف بواسطة: ${state.model.userName}\n"
              "الحالة: ${state.model.state}\n"
              "التاريخ: $formattedDate\n"
              "الوقت: $formattedTime\n"
              "رقم الباركود: ${state.model.barcodeNumber}",
        ),
        trailing: InkWell(
          onTap: () {
            if (!isSearcher || !state.model.isChecked) {
              _showCheckToggleDialog(
                context,
                state.model.nationalId,
                state.model.isChecked,
                state.model.barcodeNumber,
              );
            }
          },
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: state.model.isChecked
                  ? null
                  : Border.all(color: Colors.black, width: 2),
              color: state.model.isChecked ? Colors.green : Colors.white,
            ),
            child: state.model.isChecked
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : null,
          ),
        ),
      ),
    );
  }

  // =====================================================
  // CHECKED INFO (ADMIN ONLY)
  // =====================================================
  Widget _checkedInfo(SearchSuccessState state) {
    if (state.model.checkedById == null) return const SizedBox();

    return FutureBuilder(
      future: FirebaseFirestore.instance
          .collection("users")
          .doc(state.model.checkedById)
          .get(),
      builder: (_, snap) {
        if (!snap.hasData) return const SizedBox();
        final user = snap.data!.data();
        final name = user?["name"] ?? "غير معروف";
        final dt = state.model.checkedAt != null
            ? DateTime.fromMillisecondsSinceEpoch(state.model.checkedAt!)
            : null;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("تم التمييز بواسطة: $name"),
              if (dt != null)
                Text(
                  "وقت التمييز: $dt",
                  style: const TextStyle(fontSize: 12),
                ),
            ],
          ),
        );
      },
    );
  }

  // =====================================================
  // SCAN HISTORY (ADMIN ONLY)
  // =====================================================
  Widget _scanHistory(SearchSuccessState state) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection("scans")
          .doc(state.model.nationalId)
          .snapshots(),
      builder: (_, snap) {
        print(snap.hasData);
        if (!snap.hasData || !snap.data!.exists) {
          return const SizedBox();
        }

        final data = snap.data!.data() as Map<String, dynamic>;
        final scans = (data["scans"] ?? []) as List;

        if (scans.isEmpty) {
          return const Text(
            "لا يوجد سجل عمليات مسح",
            style: TextStyle(fontSize: 16),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "سجل عمليات المسح:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            ...scans.reversed.map((scan) {
              final ts = scan["time"];
              final dt = ts is Timestamp ? ts.toDate() : DateTime.now();
              final name = scan["scannedByName"] ?? "غير معروف";

              return ListTile(
                leading: const Icon(
                  Icons.qr_code_scanner,
                  color: Colors.deepPurple,
                ),
                title: Text(name),
                subtitle: Text(
                  "${dt.year}/${dt.month}/${dt.day} ${dt.hour}:${dt.minute}",
                  style: const TextStyle(fontSize: 12),
                ),
              );
            })
          ],
        );
      },
    );
  }

  // =====================================================
  // DIALOGS
  // =====================================================
  void _showCheckToggleDialog(
      BuildContext context,
      String nationalId,
      bool currentCheckedState,
      String barcodeNumber,
      ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("تأكيد التحديث"),
        content: Text(
          currentCheckedState
              ? "هل تريد إلغاء تمييز الرقم؟"
              : "هل تريد تمييز الرقم كمستلم؟",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("إلغاء"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final cubit = SearchIdsCubit.get(context);
              await cubit.toggleCheckedStatus(
                nationalId,
                !currentCheckedState,
                barcodeNumber,
              );
            },
            child: const Text("تأكيد"),
          ),
        ],
      ),
    );
  }

  void _showPrintConfirmation(
      BuildContext context,
      SearchIdsCubit cubit,
      String nationalId,
      String barcodeNumber,
      ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("تأكيد الطباعة"),
        content: const Text("هل تريد طباعة الباركود؟"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("إلغاء"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await cubit.printBarcode(nationalId, barcodeNumber);
            },
            child: const Text("طباعة"),
          ),
        ],
      ),
    );
  }
}
