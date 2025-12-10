import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nationalidbarcode/views/widgets/custom_scaffold.dart';

import '../../constants/app_colors.dart';
import '../../controllers/login/login_cubit.dart';
import '../../controllers/login/login_states.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: CustomScaffold(
        backgroundColor: const Color(AppColors.whiteSmoke),

        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Card(
              elevation: 10,
              shadowColor: Colors.black26,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              color: Colors.white,

              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 35),

                child: BlocConsumer<LoginCubit, LoginStates>(
                  listener: (context, state) {
                    if (state is LoginSuccessState) {
                      if (state.uid == "admin") {
                        context.go("/admin-home");
                      } else if(state.uid == "searcher"){
                        context.go("/searcher-home");
                      }
                      else if(state.uid == "user") {
                        context.go("/user-home");
                      }
                    }

                    if (state is LoginErrorState) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            state.error,
                            textDirection: TextDirection.rtl,
                          ),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  },

                  builder: (context, state) {
                    final cubit = LoginCubit.get(context);

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ------------------------------------------------
                        // TITLE + HEADER
                        // ------------------------------------------------
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
                          child: const Center(
                            child: Text(
                              "تسجيل الدخول",
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 35),

                        // ------------------------------------------------
                        // EMAIL FIELD
                        // ------------------------------------------------
                        TextField(
                          controller: emailController,
                          onSubmitted: state is LoginLoadingState
                          ? null
                        : (value) {
                    cubit.userLogin(
                    email: emailController.text.trim(),
                    password:
                    passwordController.text.trim(),
                    );
                    },
                          decoration: InputDecoration(
                            labelText: "البريد الإلكتروني",
                            labelStyle: const TextStyle(
                              color: Color(AppColors.primaryNavy),
                              fontWeight: FontWeight.w600,
                            ),
                            prefixIcon: const Icon(Icons.email_outlined,
                                color: Color(AppColors.deepBlue)),
                            filled: true,
                            fillColor: const Color(AppColors.whiteSmoke),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ------------------------------------------------
                        // PASSWORD FIELD
                        // ------------------------------------------------
                        TextField(
                          controller: passwordController,
                          obscureText: cubit.hidePassword,
                          onSubmitted: state is LoginLoadingState
                              ? null
                              : (value) {
                            cubit.userLogin(
                              email: emailController.text.trim(),
                              password:
                              passwordController.text.trim(),
                            );
                          },
                          decoration: InputDecoration(
                            labelText: "كلمة المرور",
                            labelStyle: const TextStyle(
                              color: Color(AppColors.primaryNavy),
                              fontWeight: FontWeight.w600,
                            ),
                            prefixIcon: const Icon(Icons.lock_outline,
                                color: Color(AppColors.deepBlue)),
                            suffixIcon: IconButton(
                              icon: Icon(
                                cubit.hidePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: const Color(AppColors.deepBlue),
                              ),
                              onPressed: cubit.togglePasswordVisibility,
                            ),
                            filled: true,
                            fillColor: const Color(AppColors.whiteSmoke),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),

                        // ------------------------------------------------
                        // LOGIN BUTTON
                        // ------------------------------------------------
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(AppColors.warmGold),
                              elevation: 3,
                              shadowColor: Colors.black38,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: state is LoginLoadingState
                                ? null
                                : () {
                              cubit.userLogin(
                                email: emailController.text.trim(),
                                password:
                                passwordController.text.trim(),
                              );
                            },
                            child: Text(
                              state is LoginLoadingState
                                  ? "جارٍ تسجيل الدخول..."
                                  : "تسجيل الدخول",
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
