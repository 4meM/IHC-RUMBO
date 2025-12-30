import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/constants/app_colors.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/verify_code_page.dart';
import 'features/trip_planner/presentation/pages/search_page.dart';
import 'features/live_tracking/presentation/pages/live_tracking_page.dart';
class RumboApp extends StatelessWidget {
  const RumboApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'RUMBO - Transporte Arequipa',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      routerConfig: _router,
    );
  }
}

// GoRouter Configuration
final GoRouter _router = GoRouter(
  initialLocation: '/tracking',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/verify-code',
      builder: (context, state) {
        final phoneNumber = state.extra as String? ?? '';
        return VerifyCodePage(phoneNumber: phoneNumber);
      },
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const SearchPage(),
    ),
    GoRoute(
      path: '/tracking',
      builder: (context, state) {
        final extra = state.extra as Map<String, String>? ?? {};
        return LiveTrackingPage(
          busNumber: extra['busNumber'] ?? '12',
          routeName: extra['routeName'] ?? 'Centro - Cercado',
        );
      },
    ),
  ],
);


