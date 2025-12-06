import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nationalidbarcode/views/widgets/custom_scaffold.dart';
import '../../../constants/app_colors.dart';
import '../../../controllers/admin/search_ids/search_ids_cubit.dart';
import '../../../controllers/admin/search_ids/search_ids_states.dart';
import 'package:barcode_widget/barcode_widget.dart';

class SearchIDsScreen extends StatelessWidget {
  const SearchIDsScreen({super.key});

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
              print(state);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state.isChecked ? "تم التمييز بنجاح" : "تم إلغاء التمييز",
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

                    TextField(
                      controller: searchController,
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        cubit.searchNationalId(value.trim());
                      },
                      decoration: InputDecoration(
                        labelText: "ادخل الرقم القومي",
                        filled: true,
                        fillColor: const Color(AppColors.lightGrey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: () {
                            cubit.searchNationalId(searchController.text.trim());
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    if (state is SearchLoadingState)
                      const CircularProgressIndicator(),

                    if (state is SearchEmptyState)
                      const Text(
                        "لا يوجد بيانات لهذا الرقم.",
                        style: TextStyle(fontSize: 18),
                      ),

                    // ⭐ Keep barcode visible during both SearchSuccess AND PrintPreparing states
                    if (state is SearchSuccessState || state is PrintPreparingState)
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              // Info Card
                              if (state is SearchSuccessState)
                                Card(
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
                                    subtitle: Builder(builder: (context) {
                                      final dt = DateTime.fromMillisecondsSinceEpoch(state.model.time);
                                      final barcodeNumber = state.model.barcodeNumber;

                                      final formattedDate =
                                          "${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}";

                                      final formattedTime =
                                          "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";

                                      return Text(
                                        "أُضيف بواسطة: ${state.model.userName}\n"
                                            "الحالة: ${state.model.state}\n"
                                            "التاريخ: $formattedDate\n"
                                            "الوقت: $formattedTime\n"
                                            "رقم الباركود: $barcodeNumber",
                                      );
                                    }),
                                    trailing: InkWell(
                                      onTap: () {
                                        _showCheckToggleDialog(
                                          context,
                                          state.model.nationalId,
                                          state.model.isChecked,
                                            state.model.barcodeNumber
                                        );
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
                                            ? const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 20,
                                        )
                                            : null,
                                      ),
                                    ),
                                  ),
                                ),

                              const SizedBox(height: 20),

                              // ⭐ Barcode Display - Stays visible during printing
                              RepaintBoundary(
                                key: cubit.barcodeKey,
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  color: Colors.white,
                                  child: BarcodeWidget(
                                    barcode: Barcode.code128(),
                                    data: state is SearchSuccessState
                                        ? state.model.nationalId
                                        : (state as PrintPreparingState).nationalId,
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

                              // ⭐ Show loading indicator during printing
                              if (state is PrintPreparingState)
                                Column(
                                  children: const [
                                    CircularProgressIndicator(),
                                    SizedBox(height: 10),
                                    Text(
                                      "جاري الطباعة...",
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Color(AppColors.deepBlue),
                                      ),
                                    ),
                                  ],
                                ),

                              // ⭐ Print button - only show when in SearchSuccessState
                              if (state is SearchSuccessState)
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(AppColors.deepBlue),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
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
                                    _showPrintConfirmation(
                                      context,
                                      cubit,
                                      state.model.nationalId,
                                      state.model.barcodeNumber,
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),

                    // ⭐ Error messages
                    if (state is AdminIdErrorState)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
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

                    // ⭐ Success message after printing
                    if (state is PrintSuccessState)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: const [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 48,
                            ),
                            SizedBox(height: 10),
                            Text(
                              "تمت الطباعة بنجاح!",
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
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

  // -------------------------------------------------------------
  // CHECKBOX TOGGLE CONFIRMATION DIALOG
  // -------------------------------------------------------------
  void _showCheckToggleDialog(
      BuildContext context,
      String nationalId,
      bool currentCheckedState,
      String barcodeNumber
      ) {
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
            currentCheckedState
                ? "هل تريد إلغاء تمييز الرقم $nationalId؟"
                : "هل تريد تمييز الرقم $nationalId كمستلم؟",
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
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
                Navigator.pop(context);

                final cubit = SearchIdsCubit.get(context);
                await cubit.toggleCheckedStatus(nationalId, !currentCheckedState,barcodeNumber);
              },
              child: const Text(
                "تأكيد",
                style: TextStyle(color: Color(AppColors.warmGold)),
              ),
            ),
          ],
        );
      },
    );
  }

  // -------------------------------------------------------------
  // PRINT CONFIRMATION DIALOG
  // -------------------------------------------------------------
  void _showPrintConfirmation(
      BuildContext context,
      SearchIdsCubit cubit,
      String nationalId,
      String barcodeNumber,
      ) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            "تأكيد الطباعة",
            textDirection: TextDirection.rtl,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            "هل تريد طباعة الباركود للرقم القومي:\n$nationalId؟",
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
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
                await cubit.printBarcode(nationalId, barcodeNumber);
              },
              child: const Text(
                "طباعة",
                style: TextStyle(color: Color(AppColors.warmGold)),
              ),
            ),
          ],
        );
      },
    );
  }
}