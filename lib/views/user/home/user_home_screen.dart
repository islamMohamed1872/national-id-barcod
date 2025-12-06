import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:go_router/go_router.dart';
import 'package:nationalidbarcode/views/widgets/custom_scaffold.dart';

import '../../../constants/app_colors.dart';
import '../../../controllers/user/home/user_home_cubit.dart';
import '../../../controllers/user/home/user_home_states.dart';

class UserHomeScreen extends StatelessWidget {
  UserHomeScreen({super.key});

  final idController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: BlocProvider(
        create: (_) => UserHomeCubit()..loadUserIds()..listenToForcedLogout(FirebaseAuth.instance.currentUser!.uid,context),
        child: BlocConsumer<UserHomeCubit, UserHomeStates>(
          listener: (context, state) {
            print(state);
            if (state is UserHomeErrorState) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.redAccent,
                ),
              );
            }

            if (state is UserHomeSuccessState) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("تم إضافة الرقم بنجاح"),
                  backgroundColor: Color(AppColors.successGreen),
                ),
              );
            }

            if (state is PrintSuccessState) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("تمت الطباعة بنجاح"),
                  backgroundColor: Color(AppColors.successGreen),
                ),
              );
            }
          },
          builder: (context, state) {
            final cubit = UserHomeCubit.get(context);
            final isPrinting = state is UserHomePrintingState || state is PrintPreparingState;
            final isLoading = state is UserHomeLoadingState;

            return CustomScaffold(
              backgroundColor: const Color(AppColors.whiteSmoke),
              body: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // TOP BAR WITH LOGOUT
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "لوحة المستخدم",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(AppColors.primaryNavy),
                              ),
                            ),

                            // Logout button
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(AppColors.deepBlue),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.logout, color: Color(AppColors.warmGold)),
                              label: const Text(
                                "تسجيل الخروج",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              onPressed: () async {
                                final cubit = UserHomeCubit.get(context);
                                await cubit.logout();
                                context.go("/");
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 25),

                        // ---------------------------------------------------------
                        // HEADER
                        // ---------------------------------------------------------
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerRight,
                              end: Alignment.centerLeft,
                              colors: [
                                Color(AppColors.primaryNavy),
                                Color(AppColors.deepBlue),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text(
                            "إضافة رقم قومي جديد",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                        ),

                        const SizedBox(height: 25),

                        // ---------------------------------------------------------
                        // CARD: ADD NEW NATIONAL ID
                        // ---------------------------------------------------------
                        Card(
                          elevation: 12,
                          shadowColor: Colors.black12,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(25),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "ادخل الرقم القومي",
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Color(AppColors.primaryNavy),
                                  ),
                                ),

                                const SizedBox(height: 20),

                                TextField(
                                  controller: idController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: "الرقم القومي (14 رقم)",
                                    filled: true,
                                    fillColor: const Color(AppColors.whiteSmoke),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  maxLength: 14,
                                ),

                                const SizedBox(height: 12),

                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(AppColors.warmGold),
                                      shadowColor: Colors.black45,
                                      elevation: 3,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    onPressed: isLoading
                                        ? null
                                        : () {
                                      cubit.submitNationalId(
                                          idController.text.trim());
                                    },
                                    child: Text(
                                      isLoading ? "جاري الإضافة..." : "إضافة",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 20),

                                /// ⭐ BARCODE - Visible during BarcodeReady, Success, AND PrintPreparing states
                                if (state is UserHomeBarcodeReadyState ||
                                    state is UserHomeSuccessState ||
                                    state is PrintPreparingState)
                                  Center(
                                    child: RepaintBoundary(
                                      key: cubit.barcodeKey,
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Color(AppColors.deepBlue).withOpacity(.2),
                                          ),
                                        ),
                                        child: BarcodeWidget(
                                          barcode: Barcode.code128(),
                                          data: state is UserHomeBarcodeReadyState
                                              ? state.id
                                              : state is PrintPreparingState
                                              ? state.id
                                              : idController.text.trim(),
                                          width: 300,
                                          height: 120,
                                          drawText: false,
                                        ),
                                      ),
                                    ),
                                  ),
                                if(cubit.barcodeNumber!=null&&(state is UserHomeBarcodeReadyState ||
                                    state is UserHomeSuccessState ||
                                    state is PrintPreparingState))
                                Center(child: Text(cubit.barcodeNumber!,
                                style: TextStyle(
                                  fontSize: 20
                                ),
                                )),

                                // ⭐ Show loading during print preparation
                                if (state is PrintPreparingState)
                                  Column(
                                    children: const [
                                      SizedBox(height: 20),
                                      CircularProgressIndicator(),
                                      SizedBox(height: 10),
                                      Text(
                                        "جاري التحضير للطباعة...",
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Color(AppColors.deepBlue),
                                        ),
                                      ),
                                    ],
                                  ),

                                // ⭐ Print button - only show when barcode bytes are ready
                                if (cubit.barcodeBytes != null && state is! PrintPreparingState)
                                  Column(
                                    children: [
                                      const SizedBox(height: 20),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 48,
                                        child: ElevatedButton.icon(
                                          icon: const Icon(
                                            Icons.print,
                                            color: Colors.white,
                                          ),
                                          label: const Text(
                                            "طباعة",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(AppColors.deepBlue),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                          onPressed: isPrinting
                                              ? null
                                              : () {
                                            cubit.printBarcode(idController.text);
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),


                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}