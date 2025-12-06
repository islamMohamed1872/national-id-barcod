import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import 'package:nationalidbarcode/controllers/admin/home/admin_home_cubit.dart';
import 'package:nationalidbarcode/controllers/admin/home/admin_home_states.dart';
import 'package:nationalidbarcode/views/widgets/custom_scaffold.dart';
import '../../../constants/app_colors.dart';
import '../manage_users/manage_users_screen.dart';
import '../search_ids/search_ids_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: BlocProvider(
        create: (_) => AdminHomeCubit(),
        child: BlocBuilder<AdminHomeCubit, AdminHomeStates>(
          builder: (context, state) {
            return DefaultTabController(
              length: 2,
              child: CustomScaffold(
                backgroundColor: const Color(AppColors.whiteSmoke),

                appBar: AppBar(
                  backgroundColor: const Color(AppColors.primaryNavy),
                  centerTitle: true,

                  title: const Text(
                    "لوحة التحكم",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),

                  // ✅ ADD LOGOUT BUTTON HERE
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.logout, color: Color(AppColors.softGold)),
                      tooltip: "تسجيل الخروج",
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        context.go("/"); // Clear stack and go to login
                      },
                    ),
                  ],

                  bottom: const TabBar(
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    indicatorColor: Color(AppColors.softGold),
                    tabs: [
                      Tab(
                        icon: Icon(Icons.people_alt),
                        text: "إدارة المستخدمين",
                      ),
                      Tab(
                        icon: Icon(Icons.search),
                        text: "البحث عن رقم قومي",
                      ),
                    ],
                  ),
                ),

                body: const TabBarView(
                  children: [
                    ManageUsersScreen(),
                    SearchIDsScreen(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
