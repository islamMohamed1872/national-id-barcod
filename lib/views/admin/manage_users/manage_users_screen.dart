import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nationalidbarcode/views/admin/manage_users/searcher_scan_history_screen.dart';

import 'package:nationalidbarcode/views/admin/manage_users/user_ids_screen.dart';
import 'package:nationalidbarcode/views/widgets/custom_scaffold.dart';

import '../../../constants/app_colors.dart';
import '../../../controllers/admin/manage_users/manage_users_cubit.dart';
import '../../../controllers/admin/manage_users/manage_users_states.dart';


class ManageUsersScreen extends StatelessWidget {
  const ManageUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: BlocProvider(
        create: (_) => ManageUsersCubit()..loadUsers(),
        child: BlocBuilder<ManageUsersCubit, ManageUsersStates>(
          builder: (context, state) {
            final cubit = ManageUsersCubit.get(context);

            return CustomScaffold(
              backgroundColor: const Color(AppColors.whiteSmoke),

              floatingActionButton: FloatingActionButton(
                backgroundColor: const Color(AppColors.warmGold),
                onPressed: () => cubit.showAddUserDialog(context),
                child: const Icon(Icons.add, color: Colors.white),
              ),

              body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      "إدارة المستخدمين",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(AppColors.primaryNavy),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Expanded(
                      child: state is UsersLoadingState
                          ? const Center(child: CircularProgressIndicator())
                          : ListView.separated(
                        itemCount: cubit.users.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final user = cubit.users[index];

                          // 🔥 Choose badge & color according to user type
                          final isSearcher = user.type == "searcher";

                          return Card(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 3,
                            child: ListTile(
                              onTap: () {
                                if(user.type=="searcher"){
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => BlocProvider(
                                        create: (_) => ManageUsersCubit(),
                                        child: SearcherScanHistoryScreen(
                                          userId: user.uid,
                                          userName: user.name,
                                        ),
                                      ),
                                    ),
                                  );

                                }
                                else{
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => BlocProvider(
                                        create: (_) => ManageUsersCubit(),
                                        child: UserIdsScreen(
                                          userId: user.uid,
                                          userName: user.name,
                                        ),
                                      ),
                                    ),
                                  );
                                }

                              },

                              // 🔥 Avatar color based on type
                              leading: CircleAvatar(
                                backgroundColor: isSearcher
                                    ? Colors.deepPurple
                                    : const Color(AppColors.deepBlue),
                                child: Text(
                                  user.name[0],
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),

                              title: Text(
                                user.name,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),

                              subtitle: Text(
                                "النوع: ${isSearcher ? "باحث" : "مستخدم"}\n"
                                    "البريد: ${user.email}\n"
                                    "${!isSearcher?"عدد الأرقام القومية: ":"عدد عمليات البحث: "}${user.count}",
                              ),

                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _confirmDelete(context, cubit, user.uid),
                              ),
                            ),
                          );
                        },
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

  // ================================================================
  // 🔥 CONFIRM DELETE DIALOG
  // ================================================================
  void _confirmDelete(BuildContext context, ManageUsersCubit cubit, String uid) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("تأكيد الحذف"),
        content: const Text("هل أنت متأكد أنك تريد حذف هذا المستخدم؟"),
        actions: [
          TextButton(
            child: const Text("إلغاء"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text("حذف", style: TextStyle(color: Colors.white)),
            onPressed: () {
              Navigator.pop(context);
              cubit.deleteUser(uid);
            },
          ),
        ],
      ),
    );
  }
}
