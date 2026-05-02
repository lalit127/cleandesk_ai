// lib/features/employee/screens/employee_home_screen.dart
// ─────────────────────────────────────────────────────────
// Employee home: today's status badge + check-in / check-out buttons.

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:cleandesk_ai/core/theme/app_theme.dart';
import 'package:cleandesk_ai/features/employee/providers/checkin_provider.dart';
import 'package:cleandesk_ai/features/employee/screens/attendance_history_screen.dart';
import 'package:cleandesk_ai/features/login/providers/session_provider.dart';
import 'package:cleandesk_ai/features/login/screens/login_screen.dart';
import 'package:cleandesk_ai/widgets/status_chip.dart';

class EmployeeHomeScreen extends ConsumerStatefulWidget {
  const EmployeeHomeScreen({super.key});

  @override
  ConsumerState<EmployeeHomeScreen> createState() => _EmployeeHomeScreenState();
}

class _EmployeeHomeScreenState extends ConsumerState<EmployeeHomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(checkInProvider.notifier).loadToday());
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final checkIn = ref.watch(checkInProvider);

    ref.listen<CheckInState>(checkInProvider, (prev, next) {
      if (next.successMessage != null &&
          next.successMessage != prev?.successMessage) {
        _showSnack(next.successMessage!, isError: false);
        ref.read(checkInProvider.notifier).clearMessages();
      }
      if (next.errorMessage != null &&
          next.errorMessage != prev?.errorMessage &&
          next.status == CheckInStatus.error) {
        _showSnack(next.errorMessage!, isError: true);
        ref.read(checkInProvider.notifier).clearMessages();
      }
    });

    final isLoading   = checkIn.status == CheckInStatus.loading || checkIn.isGpsLoading;
    final todayRecord = checkIn.todayRecord;
    final hasCheckedIn  = todayRecord != null;
    final hasCheckedOut = todayRecord?.isCheckedOut ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text('Hello, ${session.userName?.split(' ').first ?? 'Employee'}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_outlined),
            tooltip: 'Attendance History',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AttendanceHistoryScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Logout',
            onPressed: () => _logout(context),
          ),
        ],
      ),

      body: RefreshIndicator(
        color: AppTheme.black,
        onRefresh: () => ref.read(checkInProvider.notifier).loadToday(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.grey600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),

              _StatusCard(
                record:       todayRecord,
                isLoading:    checkIn.status == CheckInStatus.loading,
              ),
              const SizedBox(height: 32),

              if (checkIn.isGpsPermissionDenied) ...[
                _GpsPermissionBanner(
                  onOpenSettings: () =>
                      ref.read(checkInProvider.notifier).openLocationSettings(),
                ),
                const SizedBox(height: 20),
              ],

              if (checkIn.isGpsLoading) ...[
                const _GpsLoadingBanner(),
                const SizedBox(height: 20),
              ],

              if (!hasCheckedIn)
                _ActionButton(
                  label:    'Check In',
                  icon:     Icons.login_outlined,
                  disabled: isLoading || checkIn.isGpsPermissionDenied,
                  onTap:    () => ref.read(checkInProvider.notifier).checkIn(),
                ),

              if (hasCheckedIn && !hasCheckedOut)
                _ActionButton(
                  label:    'Check Out',
                  icon:     Icons.logout_outlined,
                  disabled: isLoading || checkIn.isGpsPermissionDenied,
                  onTap:    () => ref.read(checkInProvider.notifier).checkOut(),
                  outlined: true,
                ),

              if (hasCheckedOut)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.grey100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: AppTheme.successGreen, size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your day is complete. See you tomorrow!',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.grey800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnack(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.errorRed : AppTheme.black,
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    await ref.read(sessionProvider.notifier).logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }
}

class _StatusCard extends StatelessWidget {
  final dynamic record; 
  final bool isLoading;
  const _StatusCard({required this.record, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.grey100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.black),
          ),
        ),
      );
    }

    final hasRecord     = record != null;
    final isCheckedOut  = record?.isCheckedOut ?? false;
    final checkinTime   = record?.checkinTime;
    final checkoutTime  = record?.checkoutTime;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.black,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Today's Status",
                style: TextStyle(color: AppTheme.grey400, fontSize: 13, fontWeight: FontWeight.w500),
              ),
              StatusChip(
                status: hasRecord ? (isCheckedOut ? 'checked_out' : 'present') : 'absent',
                small:  true,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _TimeRow(label: 'Check In', time:  checkinTime),
          if (hasRecord) ...[
            const SizedBox(height: 12),
            _TimeRow(label: 'Check Out', time:  checkoutTime),
          ],
        ],
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  final String label;
  final String? time;
  const _TimeRow({required this.label, this.time});

  @override
  Widget build(BuildContext context) {
    String displayTime = '--:--';
    if (time != null) {
      try {
        // Ensure UTC interpretation then convert to local
        final normalized = time!.contains('Z') || time!.contains('+') ? time! : '${time!}Z';
        final dt = DateTime.parse(normalized).toLocal();
        displayTime = DateFormat('hh:mm a').format(dt);
      } catch (_) {}
    }
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(label, style: const TextStyle(color: AppTheme.grey400, fontSize: 13)),
        ),
        const SizedBox(width: 12),
        Text(
          displayTime,
          style: const TextStyle(
            color: AppTheme.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            fontFeatures: [ui.FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool disabled;
  final VoidCallback onTap;
  final bool outlined;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.disabled,
    required this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Text(label),
      ],
    );

    return SizedBox(
      width: double.infinity,
      child: outlined
          ? OutlinedButton(onPressed: disabled ? null : onTap, child: child)
          : ElevatedButton(onPressed: disabled ? null : onTap, child: child),
    );
  }
}

class _GpsPermissionBanner extends StatelessWidget {
  final VoidCallback onOpenSettings;
  const _GpsPermissionBanner({required this.onOpenSettings});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.chipAbsent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.errorRed.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.location_off, color: AppTheme.errorRed, size: 18),
              SizedBox(width: 8),
              Text(
                'Location permission denied',
                style: TextStyle(color: AppTheme.errorRed, fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Location access is required to check in. Please enable it in your settings.',
            style: TextStyle(fontSize: 13, color: AppTheme.grey800),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(onPressed: onOpenSettings, child: const Text('Open Settings')),
          ),
        ],
      ),
    );
  }
}

class _GpsLoadingBanner extends StatelessWidget {
  const _GpsLoadingBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: AppTheme.grey100, borderRadius: BorderRadius.circular(12)),
      child: const Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.black),
          ),
          SizedBox(width: 12),
          Text('Resolving your location…', style: TextStyle(fontSize: 14, color: AppTheme.grey800)),
        ],
      ),
    );
  }
}
