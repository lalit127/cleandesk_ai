// lib/data/repositories/attendance_repository.dart
// ──────────────────────────────────────────────────
// Repository for all attendance-related API calls.

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cleandesk_ai/core/constants/app_constants.dart';
import 'package:cleandesk_ai/data/models/attendance.dart';
import 'package:cleandesk_ai/data/services/api_service.dart';

class AttendanceRepository {
  final Dio _dio;
  const AttendanceRepository(this._dio);

  // ── Check in ─────────────────────────────────────────────────────────────

  Future<AttendanceModel> checkIn({
    required String userId,
    required double lat,
    required double lng,
  }) async {
    try {
      final response = await _dio.post('/attendance/checkin', data: {
        'user_id': userId,
        'lat':     lat,
        'lng':     lng,
      });
      return AttendanceModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  // ── Check out ────────────────────────────────────────────────────────────

  Future<AttendanceModel> checkOut({
    required String userId,
    required double lat,
    required double lng,
  }) async {
    try {
      final response = await _dio.post('/attendance/checkout', data: {
        'user_id': userId,
        'lat':     lat,
        'lng':     lng,
      });
      return AttendanceModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  // ── Today's attendance ───────────────────────────────────────────────────

  /// Returns null if no record exists for today (user hasn't checked in).
  Future<AttendanceModel?> getTodayAttendance(String userId) async {
    try {
      final response = await _dio.get('/attendance/today/$userId');
      return AttendanceModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      // 404 is expected when the user hasn't checked in yet — return null
      final err = handleDioError(e);
      if (err.type == ApiErrorType.notFound) return null;
      throw err;
    }
  }

  // ── History (paginated) ──────────────────────────────────────────────────

  Future<PaginatedAttendance> getHistory({
    required String userId,
    int page = 1,
    int pageSize = AppConstants.historyPageSize,
  }) async {
    try {
      final response = await _dio.get(
        '/attendance/history/$userId',
        queryParameters: {'page': page, 'page_size': pageSize},
      );
      return PaginatedAttendance.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  // ── Team attendance (manager view) ───────────────────────────────────────

  Future<List<TeamAttendanceModel>> getTeamAttendance(String managerId) async {
    try {
      final response = await _dio.get(
        '/attendance/team',
        queryParameters: {'manager_id': managerId},
      );
      final list = response.data as List<dynamic>;
      return list
          .map((json) =>
              TeamAttendanceModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }
}

/// Riverpod provider for the attendance repository.
final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository(ref.watch(dioProvider));
});
