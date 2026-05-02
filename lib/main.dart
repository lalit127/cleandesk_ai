// lib/main.dart
// ──────────────
// Application entry point.
//
// Wraps the entire app in ProviderScope (required by Riverpod), loads
// the persisted session from SharedPreferences, and routes the user to
// the correct screen (login, employee home, or manager dashboard).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/employee/screens/employee_home_screen.dart';
import 'features/login/providers/session_provider.dart';
import 'features/login/screens/login_screen.dart';
import 'features/manager/screens/team_dashboard_screen.dart';

void main() {
  runApp(
    // ProviderScope is required — it holds all Riverpod provider state
    const ProviderScope(
      child: AttendanceApp(),
    ),
  );
}

class AttendanceApp extends ConsumerWidget {
  const AttendanceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title:        'Attendance',
      debugShowCheckedModeBanner: false,
      theme:        AppTheme.light,
      home:         const _SplashRouter(),
    );
  }
}

// ── Splash / router ───────────────────────────────────────────────────────────
// Loads the persisted session on startup then navigates to the right screen.

class _SplashRouter extends ConsumerStatefulWidget {
  const _SplashRouter();

  @override
  ConsumerState<_SplashRouter> createState() => _SplashRouterState();
}

class _SplashRouterState extends ConsumerState<_SplashRouter> {
  @override
  void initState() {
    super.initState();
    // Load persisted session after the first frame renders
    Future.microtask(() => ref.read(sessionProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);

    // While loading (waiting for SharedPreferences to be read),
    // show a minimal splash screen
    if (!session.isInitialized) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Attendance',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.black,
                ),
              ),
              SizedBox(height: 24),
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.black,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // No saved session → show login
    if (!session.isLoggedIn) {
      return const LoginScreen();
    }

    // Saved session exists → route by role
    if (session.isManager) {
      return const TeamDashboardScreen();
    }

    return const EmployeeHomeScreen();
  }
}
