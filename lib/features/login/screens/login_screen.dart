// lib/features/login/screens/login_screen.dart
// ───────────────────────────────────────────────
// User picker screen — fetches seeded users from GET /users and lets
// the user tap a name to "log in". No password required.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cleandesk_ai/core/theme/app_theme.dart';
import 'package:cleandesk_ai/data/models/user.dart';
import 'package:cleandesk_ai/data/repositories/user_repository.dart';
import 'package:cleandesk_ai/features/login/providers/session_provider.dart';
import 'package:cleandesk_ai/features/employee/providers/checkin_provider.dart';
import 'package:cleandesk_ai/features/employee/providers/history_provider.dart';
import 'package:cleandesk_ai/features/manager/providers/team_provider.dart';
import 'package:cleandesk_ai/features/employee/screens/employee_home_screen.dart';
import 'package:cleandesk_ai/features/manager/screens/team_dashboard_screen.dart';

// ── Provider: fetch users list ────────────────────────────────────────────────

final usersListProvider = FutureProvider<List<UserModel>>((ref) {
  return ref.watch(userRepositoryProvider).getUsers();
});

// ── Screen ────────────────────────────────────────────────────────────────────

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersListProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 64),

              // ── Logo / heading ─────────────────────────────────────────────
              const Text(
                'Attendance',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: AppTheme.black,
                ),
              ),
              const Text(
                'GPS Check-In Module',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.grey600,
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: 48),

              const Text(
                'Select your profile to continue',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.grey600,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 12),

              // ── User list ──────────────────────────────────────────────────
              Expanded(
                child: usersAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppTheme.black),
                  ),
                  error: (err, _) => _ErrorState(
                    message: err.toString(),
                    onRetry: () => ref.invalidate(usersListProvider),
                  ),
                  data: (users) => ListView.separated(
                    itemCount: users.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => _UserTile(user: users[index]),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ── User tile ─────────────────────────────────────────────────────────────────

class _UserTile extends ConsumerWidget {
  final UserModel user;
  const _UserTile({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isManager = user.isManager;

    return GestureDetector(
      onTap: () => _selectUser(context, ref),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.grey200, width: 1.5),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isManager ? AppTheme.black : AppTheme.grey100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isManager ? Icons.shield_outlined : Icons.person_outline,
                color: isManager ? AppTheme.white : AppTheme.black,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),

            // Name + role
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.email,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.grey600,
                    ),
                  ),
                ],
              ),
            ),

            // Role badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isManager ? AppTheme.black : AppTheme.grey100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isManager ? 'Manager' : 'Employee',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isManager ? AppTheme.white : AppTheme.grey800,
                  letterSpacing: 0.3,
                ),
              ),
            ),

            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppTheme.grey400, size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _selectUser(BuildContext context, WidgetRef ref) async {
    await ref.read(sessionProvider.notifier).login(
      userId:   user.id,
      userName: user.name,
      userRole: user.role,
    );

    // ── Purge stale attendance state from the previous user ───────────────────
    // Both providers are global singletons. Without invalidating them here,
    // the new home screen would briefly (or permanently) display the old user's
    // check-in record until the async loadToday() overwrites it.
    ref.invalidate(checkInProvider);
    ref.invalidate(historyProvider);
    ref.invalidate(teamProvider);

    if (!context.mounted) return;

    // Navigate to the appropriate home screen based on role
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => user.isManager
            ? const TeamDashboardScreen()
            : const EmployeeHomeScreen(),
      ),
    );
  }
}

// ── Error state ───────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_outlined, size: 56, color: AppTheme.grey400),
            const SizedBox(height: 16),
            const Text(
              'Could not load users',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppTheme.grey600),
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
