// lib/features/employee/screens/attendance_history_screen.dart
// ──────────────────────────────────────────────────────────────
// Paginated list of past attendance records for the employee.

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:cleandesk_ai/core/theme/app_theme.dart';
import 'package:cleandesk_ai/data/models/attendance.dart';
import 'package:cleandesk_ai/features/employee/providers/history_provider.dart';
import 'package:cleandesk_ai/widgets/status_chip.dart';

class AttendanceHistoryScreen extends ConsumerStatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  ConsumerState<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState
    extends ConsumerState<AttendanceHistoryScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(historyProvider.notifier).loadInitial());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Load more when within 200px of the bottom
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(historyProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(historyProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Attendance History')),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(HistoryState state) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.black),
      );
    }

    if (state.errorMessage != null && state.records.isEmpty) {
      return _ErrorState(
        message: state.errorMessage!,
        onRetry: () => ref.read(historyProvider.notifier).loadInitial(),
      );
    }

    if (state.records.isEmpty) {
      return const _EmptyState();
    }

    return RefreshIndicator(
      color: AppTheme.black,
      onRefresh: () => ref.read(historyProvider.notifier).loadInitial(),
      child: ListView.builder(
        controller:  _scrollController,
        padding:     const EdgeInsets.symmetric(vertical: 12),
        itemCount:   state.records.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.records.length) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.black),
              ),
            );
          }
          return _HistoryCard(record: state.records[index]);
        },
      ),
    );
  }
}

// ── History Card ─────────────────────────────────────────────────────────────

class _HistoryCard extends StatelessWidget {
  final AttendanceModel record;
  const _HistoryCard({required this.record});

  String _formatTime(String? timeStr) {
    if (timeStr == null) return '--';
    try {
      // Ensure the time is parsed as UTC if no offset is provided, then convert to local.
      final normalized = timeStr.contains('Z') || timeStr.contains('+') ? timeStr : '${timeStr}Z';
      final dt = DateTime.parse(normalized).toLocal();
      return DateFormat('hh:mm a').format(dt);
    } catch (_) {
      return '--';
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('EEE, d MMM yyyy').format(DateTime.parse(record.date));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.black,
                  ),
                ),
                StatusChip(status: record.status, small: true),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                _TimeInfo(label: 'Check In',  time: _formatTime(record.checkinTime)),
                const SizedBox(width: 32),
                _TimeInfo(label: 'Check Out', time: _formatTime(record.checkoutTime)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeInfo extends StatelessWidget {
  final String label;
  final String time;
  const _TimeInfo({required this.label, required this.time});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.grey600,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          time,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.black,
            fontFeatures: [ui.FontFeature.tabularFigures()],
          ),
        ),
      ],
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
                Icons.calendar_today_outlined,
                size: 36,
                color: AppTheme.grey400,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No attendance records yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.black,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your attendance history will appear here\nonce you start checking in.',
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
            const Icon(Icons.error_outline, size: 48, color: AppTheme.grey400),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
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
