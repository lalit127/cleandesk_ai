// lib/features/employee/providers/history_provider.dart
// ────────────────────────────────────────────────────────
// Manages paginated attendance history for the employee.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cleandesk_ai/core/constants/app_constants.dart';
import 'package:cleandesk_ai/data/models/attendance.dart';
import 'package:cleandesk_ai/data/repositories/attendance_repository.dart';
import 'package:cleandesk_ai/data/services/api_service.dart';
import 'package:cleandesk_ai/features/login/providers/session_provider.dart';

class HistoryState {
  final List<AttendanceModel> records;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final String? errorMessage;
  final ApiErrorType? errorType;

  const HistoryState({
    this.records      = const [],
    this.isLoading    = false,
    this.isLoadingMore = false,
    this.hasMore      = true,
    this.currentPage  = 0,
    this.errorMessage,
    this.errorType,
  });

  HistoryState copyWith({
    List<AttendanceModel>? records,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    String? errorMessage,
    ApiErrorType? errorType,
    bool clearError = false,
  }) {
    return HistoryState(
      records:       records        ?? this.records,
      isLoading:     isLoading      ?? this.isLoading,
      isLoadingMore: isLoadingMore  ?? this.isLoadingMore,
      hasMore:       hasMore        ?? this.hasMore,
      currentPage:   currentPage    ?? this.currentPage,
      errorMessage:  clearError ? null : (errorMessage ?? this.errorMessage),
      errorType:     clearError ? null : (errorType    ?? this.errorType),
    );
  }
}

class HistoryNotifier extends Notifier<HistoryState> {
  @override
  HistoryState build() => const HistoryState();

  AttendanceRepository get _repo => ref.read(attendanceRepositoryProvider);
  String get _userId => ref.read(sessionProvider).userId!;

  /// Initial load (or refresh)
  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repo.getHistory(userId: _userId, page: 1);
      state = HistoryState(
        records:     result.records,
        isLoading:   false,
        hasMore:     result.hasMore,
        currentPage: 1,
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading:    false,
        errorMessage: e.message,
        errorType:    e.type,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading:    false,
        errorMessage: 'An unexpected error occurred.',
        errorType:    ApiErrorType.unknown,
      );
    }
  }

  /// Load the next page (called when user scrolls to the bottom)
  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore) return;

    state = state.copyWith(isLoadingMore: true);
    try {
      final nextPage = state.currentPage + 1;
      final result = await _repo.getHistory(
        userId:   _userId,
        page:     nextPage,
        pageSize: AppConstants.historyPageSize,
      );
      state = state.copyWith(
        records:       [...state.records, ...result.records],
        isLoadingMore: false,
        hasMore:       result.hasMore,
        currentPage:   nextPage,
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage:  e.message,
        errorType:     e.type,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage:  'An unexpected error occurred.',
        errorType:     ApiErrorType.unknown,
      );
    }
  }
}

final historyProvider = NotifierProvider<HistoryNotifier, HistoryState>(
  HistoryNotifier.new,
);
