// lib/features/manager/providers/team_provider.dart
// ────────────────────────────────────────────────────
// State management for the manager team dashboard.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cleandesk_ai/data/models/attendance.dart';
import 'package:cleandesk_ai/data/repositories/attendance_repository.dart';
import 'package:cleandesk_ai/features/login/providers/session_provider.dart';

class TeamState {
  final List<TeamAttendanceModel> records;
  final bool isLoading;
  final String? errorMessage;

  const TeamState({
    this.records     = const [],
    this.isLoading   = false,
    this.errorMessage,
  });

  TeamState copyWith({
    List<TeamAttendanceModel>? records,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TeamState(
      records:      records       ?? this.records,
      isLoading:    isLoading     ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class TeamNotifier extends Notifier<TeamState> {
  @override
  TeamState build() => const TeamState();

  AttendanceRepository get _repo => ref.read(attendanceRepositoryProvider);
  String get _managerId => ref.read(sessionProvider).userId!;

  Future<void> loadTeam() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final records = await _repo.getTeamAttendance(_managerId);
      state = TeamState(records: records, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading:    false,
        errorMessage: e.toString(),
      );
    }
  }
}

final teamProvider = NotifierProvider<TeamNotifier, TeamState>(
  TeamNotifier.new,
);
