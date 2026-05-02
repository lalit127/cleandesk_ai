import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cleandesk_ai/core/constants/app_constants.dart';
import 'package:cleandesk_ai/core/config/app_env.dart';

enum ApiErrorType {
  network,          // No internet or server unreachable
  notFound,         // 404 — resource does not exist
  conflict,         // 409 — business rule conflict (e.g. already checked in)
  unprocessable,    // 422 — validation error (e.g. outside geofence)
  forbidden,        // 403 — not allowed
  server,           // 5xx — backend error
  unknown,          // Anything else
}

class ApiException implements Exception {
  final ApiErrorType type;
  final String message;

  const ApiException({required this.type, required this.message});

  @override
  String toString() => message;
}

/// Creates and configures the shared Dio instance.
Dio _buildDio() {
  final dio = Dio(
    BaseOptions(
      baseUrl:         AppConstants.baseUrl,
      connectTimeout:  const Duration(seconds: 10),
      receiveTimeout:  const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept':       'application/json',
      },
    ),
  );

  // Request / response logger — only enabled in development
  if (AppEnv.enableApiLogs) {
    dio.interceptors.add(
      LogInterceptor(
        requestBody:  true,
        responseBody: true,
        logPrint: (obj) => debugPrint(obj.toString()),
      ),
    );
  }

  return dio;
}

// ignore_for_file: avoid_print
void debugPrint(String message) {
  // ignore: avoid_print
  print('[API] $message');
}


/// Riverpod provider — inject this wherever you need to make API calls.
final dioProvider = Provider<Dio>((ref) => _buildDio());

/// Converts a DioException into a user-friendly ApiException.
ApiException handleDioError(DioException e) {
  // 1. Handle Timeouts
  if (e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.receiveTimeout ||
      e.type == DioExceptionType.sendTimeout) {
    return const ApiException(
      type: ApiErrorType.network,
      message: 'Connection timed out. Please check your internet stability.',
    );
  }

  // 2. Handle Connection Errors (No internet vs Server Down)
  if (e.type == DioExceptionType.connectionError) {
    final errorStr = e.error?.toString() ?? e.message ?? '';
    if (errorStr.contains('Failed host lookup') || errorStr.contains('SocketException')) {
      return const ApiException(
        type: ApiErrorType.network,
        message: 'Cannot reach the server. Please check your internet connection or verify if the backend is running.',
      );
    }
    return const ApiException(
      type: ApiErrorType.network,
      message: 'A network connection error occurred.',
    );
  }

  final statusCode = e.response?.statusCode;
  final detail = _extractDetail(e.response?.data);

  switch (statusCode) {
    case 404:
      return ApiException(type: ApiErrorType.notFound, message: detail ?? 'Not found.');
    case 409:
      return ApiException(type: ApiErrorType.conflict, message: detail ?? 'Conflict.');
    case 422:
      return ApiException(type: ApiErrorType.unprocessable, message: detail ?? 'Validation error.');
    case 403:
      return ApiException(type: ApiErrorType.forbidden, message: detail ?? 'Forbidden.');
    default:
      if (statusCode != null && statusCode >= 500) {
        return const ApiException(
          type: ApiErrorType.server,
          message: 'Server error. The backend might be down. Please try again later.',
        );
      }
      return ApiException(
        type: ApiErrorType.unknown,
        message: detail ?? 'An unexpected error occurred.',
      );
  }
}

/// Extracts the `detail` field from a FastAPI error response body.
String? _extractDetail(dynamic data) {
  if (data is Map<String, dynamic>) {
    final detail = data['detail'];
    if (detail is String) return detail;
    if (detail is List && detail.isNotEmpty) {
      // Pydantic validation errors return a list
      return detail.map((e) => e['msg']?.toString() ?? '').join(', ');
    }
  }
  return null;
}
