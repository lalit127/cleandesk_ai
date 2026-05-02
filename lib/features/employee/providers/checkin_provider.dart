// lib/features/employee/providers/checkin_provider.dart
// ────────────────────────────────────────────────────────
// Manages the state for the employee check-in / check-out flow.
//
// Handles:
//   - Fetching today's attendance record on load
//   - Requesting GPS permission
//   - Resolving current GPS coordinates
//   - Calling the check-in / check-out API endpoints
//   - All error states (permission denied, GPS timeout, network error, etc.)

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import 'package:cleandesk_ai/core/constants/app_constants.dart';
import 'package:cleandesk_ai/data/models/attendance.dart';
import 'package:cleandesk_ai/data/repositories/attendance_repository.dart';
import 'package:cleandesk_ai/features/login/providers/session_provider.dart';

// ── State ─────────────────────────────────────────────────────────────────────

enum CheckInStatus {
  idle,         // Nothing happening
  loading,      // Fetching today's record or resolving GPS
  success,      // Operation completed successfully
  error,        // An error occurred — see errorMessage
}

class CheckInState {
  final CheckInStatus status;
  final AttendanceModel? todayRecord; // null = not checked in today
  final bool isGpsLoading;           // GPS resolution in progress
  final bool isGpsPermissionDenied;  // User denied location permission
  final String? errorMessage;
  final String? successMessage;

  const CheckInState({
    this.status              = CheckInStatus.idle,
    this.todayRecord,
    this.isGpsLoading        = false,
    this.isGpsPermissionDenied = false,
    this.errorMessage,
    this.successMessage,
  });

  CheckInState copyWith({
    CheckInStatus? status,
    AttendanceModel? todayRecord,
    bool? isGpsLoading,
    bool? isGpsPermissionDenied,
    String? errorMessage,
    String? successMessage,
    bool clearTodayRecord = false,
    bool clearMessages    = false,
  }) {
    return CheckInState(
      status:               status              ?? this.status,
      todayRecord:          clearTodayRecord ? null : (todayRecord ?? this.todayRecord),
      isGpsLoading:         isGpsLoading        ?? this.isGpsLoading,
      isGpsPermissionDenied: isGpsPermissionDenied ?? this.isGpsPermissionDenied,
      errorMessage:         clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage:       clearMessages ? null : (successMessage ?? this.successMessage),
    );
  }
}

// ── Notifier ─────────────────────────────────────────────────────────────────

class CheckInNotifier extends Notifier<CheckInState> {
  @override
  CheckInState build() => const CheckInState();

  AttendanceRepository get _repo => ref.read(attendanceRepositoryProvider);
  String get _userId => ref.read(sessionProvider).userId!;

  // ── Load today's attendance ───────────────────────────────────────────────

  Future<void> loadToday() async {
    state = state.copyWith(status: CheckInStatus.loading, clearMessages: true);
    try {
      final record = await _repo.getTodayAttendance(_userId);
      state = state.copyWith(
        status:      CheckInStatus.idle,
        todayRecord: record,
      );
    } catch (e) {
      // A missing record is represented as null, not an error
      state = state.copyWith(
        status:          CheckInStatus.idle,
        clearTodayRecord: true,
      );
    }
  }

  // ── Check in ─────────────────────────────────────────────────────────────

  Future<void> checkIn() async {
    final position = await _resolvePosition();
    if (position == null) return; // resolvePosition already updated state

    state = state.copyWith(status: CheckInStatus.loading, clearMessages: true);
    try {
      final record = await _repo.checkIn(
        userId: _userId,
        lat:    position.latitude,
        lng:    position.longitude,
      );
      state = state.copyWith(
        status:         CheckInStatus.success,
        todayRecord:    record,
        successMessage: 'Checked in successfully!',
      );
    } catch (e) {
      state = state.copyWith(
        status:       CheckInStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  // ── Check out ────────────────────────────────────────────────────────────

  Future<void> checkOut() async {
    final position = await _resolvePosition();
    if (position == null) return;

    state = state.copyWith(status: CheckInStatus.loading, clearMessages: true);
    try {
      final record = await _repo.checkOut(
        userId: _userId,
        lat:    position.latitude,
        lng:    position.longitude,
      );
      state = state.copyWith(
        status:         CheckInStatus.success,
        todayRecord:    record,
        successMessage: 'Checked out successfully!',
      );
    } catch (e) {
      state = state.copyWith(
        status:       CheckInStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  // ── GPS resolution ───────────────────────────────────────────────────────

  Future<Position?> _resolvePosition() async {
    // Check / request location permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      state = state.copyWith(
        isGpsPermissionDenied: true,
        errorMessage: 'Location permission is required to check in.',
      );
      return null;
    }

    // Permission granted — resolve position with timeout
    state = state.copyWith(isGpsLoading: true, clearMessages: true);
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      ).timeout(
        Duration(seconds: AppConstants.gpsTimeoutSeconds),
        onTimeout: () => throw TimeoutException(
          'GPS is taking too long. Please try again.',
        ),
      );
      state = state.copyWith(isGpsLoading: false);
      return position;
    } on TimeoutException catch (e) {
      state = state.copyWith(
        isGpsLoading: false,
        status:       CheckInStatus.error,
        errorMessage: e.message,
      );
      return null;
    } catch (e) {
      state = state.copyWith(
        isGpsLoading: false,
        status:       CheckInStatus.error,
        errorMessage: 'Could not determine your location. Please try again.',
      );
      return null;
    }
  }

  void openLocationSettings() {
    Geolocator.openLocationSettings();
  }

  void clearMessages() {
    state = state.copyWith(clearMessages: true);
  }
}

class TimeoutException implements Exception {
  final String? message;
  const TimeoutException(this.message);
}

final checkInProvider = NotifierProvider<CheckInNotifier, CheckInState>(
  CheckInNotifier.new,
);
