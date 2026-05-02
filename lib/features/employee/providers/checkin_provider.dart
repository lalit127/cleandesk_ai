// lib/features/employee/providers/checkin_provider.dart
// ────────────────────────────────────────────────────────
// Manages the state for the employee check-in / check-out flow.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import 'package:cleandesk_ai/core/config/app_env.dart';
import 'package:cleandesk_ai/core/constants/app_constants.dart';
import 'package:cleandesk_ai/data/models/attendance.dart';
import 'package:cleandesk_ai/data/repositories/attendance_repository.dart';
import 'package:cleandesk_ai/data/services/api_service.dart';
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
  final ApiErrorType? errorType;
  final String? successMessage;

  const CheckInState({
    this.status              = CheckInStatus.idle,
    this.todayRecord,
    this.isGpsLoading        = false,
    this.isGpsPermissionDenied = false,
    this.errorMessage,
    this.errorType,
    this.successMessage,
  });

  CheckInState copyWith({
    CheckInStatus? status,
    AttendanceModel? todayRecord,
    bool? isGpsLoading,
    bool? isGpsPermissionDenied,
    String? errorMessage,
    ApiErrorType? errorType,
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
      errorType:            clearMessages ? null : (errorType    ?? this.errorType),
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
    } on ApiException catch (e) {
      if (e.type == ApiErrorType.notFound) {
        state = state.copyWith(status: CheckInStatus.idle, clearTodayRecord: true);
      } else {
        state = state.copyWith(
          status:       CheckInStatus.error,
          errorMessage: e.message,
          errorType:    e.type,
        );
      }
    } catch (e) {
      state = state.copyWith(
        status:       CheckInStatus.error,
        errorMessage: 'An unexpected error occurred.',
        errorType:    ApiErrorType.unknown,
      );
    }
  }

  // ── Check in ─────────────────────────────────────────────────────────────

  Future<void> checkIn() async {
    final position = await _resolvePosition();
    if (position == null) return;

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
    } on ApiException catch (e) {
      state = state.copyWith(
        status:       CheckInStatus.error,
        errorMessage: e.message,
        errorType:    e.type,
      );
    } catch (e) {
      state = state.copyWith(
        status:       CheckInStatus.error,
        errorMessage: 'An unexpected error occurred.',
        errorType:    ApiErrorType.unknown,
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
    } on ApiException catch (e) {
      state = state.copyWith(
        status:       CheckInStatus.error,
        errorMessage: e.message,
        errorType:    e.type,
      );
    } catch (e) {
      state = state.copyWith(
        status:       CheckInStatus.error,
        errorMessage: 'An unexpected error occurred.',
        errorType:    ApiErrorType.unknown,
      );
    }
  }

  // ── GPS resolution ───────────────────────────────────────────────────────

  Future<Position?> _resolvePosition() async {
    // In development with mock GPS enabled, skip real GPS entirely.
    // Flip AppEnv._useMockGps = true in app_env.dart to activate.
    if (AppEnv.useMockGps) {
      return Future.value(
        Position(
          latitude:             AppEnv.mockLat,
          longitude:            AppEnv.mockLng,
          timestamp:            DateTime.now(),
          accuracy:             1.0,
          altitude:             0.0,
          altitudeAccuracy:     0.0,
          heading:              0.0,
          headingAccuracy:      0.0,
          speed:                0.0,
          speedAccuracy:        0.0,
        ),
      );
    }

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

    state = state.copyWith(isGpsLoading: true, clearMessages: true, isGpsPermissionDenied: false);
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


  Future<void> refreshPermissionStatus() async {
    final permission = await Geolocator.checkPermission();
    final isDenied = permission == LocationPermission.denied || 
                     permission == LocationPermission.deniedForever;
    
    state = state.copyWith(
      isGpsPermissionDenied: isDenied,
      clearMessages: !isDenied && state.errorMessage == 'Location permission is required to check in.',
    );
  }

  void openLocationSettings() {
    Geolocator.openAppSettings();
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
