// lib/features/manager/screens/team_dashboard_screen.dart
// ──────────────────────────────────────────────────────────
// Manager view: today's attendance for all employees.
// Pull-to-refresh supported.

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:cleandesk_ai/core/theme/app_theme.dart';
import 'package:cleandesk_ai/data/models/attendance.dart';
import 'package:cleandesk_ai/features/login/providers/session_provider.dart';
import 'package:cleandesk_ai/features/login/screens/login_screen.dart';
import 'package:cleandesk_ai/features/manager/providers/team_provider.dart';
import 'package:cleandesk_ai/widgets/status_chip.dart';

class TeamDashboardScreen extends ConsumerStatefulWidget {
  const TeamDashboardScreen({super.key});

  @override
  ConsumerState<TeamDashboardScreen> createState() =>
      _TeamDashboardScreenState();
}

class _TeamDashboardScreenState extends ConsumerState<TeamDashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(teamProvider.notifier).loadTeam());
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final teamState = ref.watch(teamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Team — ${session.userName?.split(' ').first ?? 'Manager'}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Logout',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Summary header ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.grey600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Team Attendance",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.black,
                  ),
                ),
                if (!teamState.isLoading && teamState.records.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _SummaryRow(records: teamState.records),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),

          const Divider(height: 1),

          // ── Body ────────────────────────────────────────────────────────
          Expanded(
            child: teamState.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.black),
                  )
                : teamState.errorMessage != null
                    ? _ErrorState(
                        message: teamState.errorMessage!,
                        onRetry: () =>
                            ref.read(teamProvider.notifier).loadTeam(),
                      )
                    : teamState.records.isEmpty
                        ? const _EmptyState()
                        : RefreshIndicator(
                            color: AppTheme.black,
                            onRefresh: () =>
                                ref.read(teamProvider.notifier).loadTeam(),
                            child: ListView.separated(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              itemCount: teamState.records.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1, indent: 72),
                              itemBuilder: (_, i) =>
                                  _EmployeeTile(record: teamState.records[i]),
                            ),
                          ),
          ),
        ],
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

// ── Summary row ───────────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final List<TeamAttendanceModel> records;
  const _SummaryRow({required this.records});

  @override
  Widget build(BuildContext context) {
    final present    = records.where((r) => r.isPresent).length;
    final checkedOut = records.where((r) => r.isCheckedOut).length;
    final total      = records.length;

    return Row(
      children: [
        Expanded(child: _SummaryChip(label: 'Total',       value: '$total',      color: AppTheme.grey100)),
        const SizedBox(width: 8),
        Expanded(child: _SummaryChip(label: 'Present',     value: '$present',    color: AppTheme.chipPresent)),
        const SizedBox(width: 8),
        Expanded(child: _SummaryChip(label: 'Checked Out', value: '$checkedOut', color: AppTheme.chipCheckedOut)),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color:        color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.black,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.grey600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Employee tile ─────────────────────────────────────────────────────────────

class _EmployeeTile extends StatelessWidget {
  final TeamAttendanceModel record;
  const _EmployeeTile({required this.record});

  String _format(String? t) {
    if (t == null) return '--:--';
    try {
      final normalized = t.contains('Z') || t.contains('+') ? t : '${t}Z';
      return DateFormat('hh:mm a').format(DateTime.parse(normalized).toLocal());
    } catch (_) {
      return '--:--';
    }
  }

  @override
  Widget build(BuildContext context) {
    String timeDisplay = 'Not checked in';
    if (record.checkinTime != null) {
      if (record.isCheckedOut && record.checkoutTime != null) {
        timeDisplay = 'In: ${_format(record.checkinTime)} • Out: ${_format(record.checkoutTime)}';
      } else {
        timeDisplay = 'Checked in at ${_format(record.checkinTime)}';
      }
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppTheme.grey100,
        child: Text(
          record.userName.isNotEmpty
              ? record.userName[0].toUpperCase()
              : '?',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppTheme.black,
          ),
        ),
      ),
      title: Text(
        record.userName,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: AppTheme.black,
        ),
      ),
      subtitle: Text(
        timeDisplay,
        style: const TextStyle(
          fontSize: 12, 
          color: AppTheme.grey600,
          fontFeatures: [ui.FontFeature.tabularFigures()],
        ),
      ),
      trailing: StatusChip(status: record.status, small: true),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.grey100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.group_outlined,
                size: 36,
                color: AppTheme.grey400,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No check-ins yet today',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.black,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Employee check-ins will appear\nhere as they arrive.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppTheme.grey600, height: 1.5),
            ),
          ],
        ),
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
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_outlined, size: 48, color: AppTheme.grey400),
            const SizedBox(height: 16),
            const Text(
              'Could not load team data',
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
