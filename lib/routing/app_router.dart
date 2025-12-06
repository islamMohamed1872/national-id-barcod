import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nationalidbarcode/views/admin/home/admin_home_screen.dart';
import 'package:nationalidbarcode/views/login/login_screen.dart';
import 'package:nationalidbarcode/views/user/home/user_home_screen.dart';


class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => _buildPage(
          state,
          LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/admin-home',
        pageBuilder: (context, state) => _buildPage(
          state,
          AdminHomeScreen(),
        ),
      ),
      GoRoute(
        path: '/user-home',
        pageBuilder: (context, state) => _buildPage(
          state,
          UserHomeScreen(),
        ),
      ),
    ],
  );

  static CustomTransitionPage _buildPage(
      GoRouterState state,
      Widget child,
      ) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // 🌟 YOUR ANIMATION HERE
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset(1, 0), // from right → left
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
    );
  }
}
