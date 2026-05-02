// lib/data/services/api_service.dart
// ────────────────────────────────────
// Configured Dio HTTP client.

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cleandesk_ai/core/constants/app_constants.dart';
import 'package:cleandesk_ai/core/config/app_env.dart';

enum ApiErrorType {
  network,          // No internet
  notFound,         // 404 — resource does not exist (legit 404)
  conflict,         // 409 — business rule conflict (e.g. already checked in)
  unprocessable,    // 422 — validation error (e.g. outside geofence)
  forbidden,        // 403 — not allowed
  server,           // 5xx — backend error or connection refused
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
  print('[API] $message');
}

final dioProvider = Provider<Dio>((ref) => _buildDio());

/// Converts a DioException into a user-friendly ApiException.
ApiException handleDioError(DioException e) {
  if (e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.receiveTimeout ||
      e.type == DioExceptionType.sendTimeout) {
    return const ApiException(
      type: ApiErrorType.network,
      message: 'Connection timed out. Please check your internet stability.',
    );
  }

  if (e.type == DioExceptionType.connectionError) {
    final errorStr = e.error?.toString() ?? e.message ?? '';
    
    if (errorStr.contains('Connection refused') || errorStr.contains('Connection closed')) {
      return const ApiException(
        type: ApiErrorType.server,
        message: 'The server is not running. Please verify your backend is active.',
      );
    }

    if (errorStr.contains('Failed host lookup') || errorStr.contains('SocketException')) {
      return const ApiException(
        type: ApiErrorType.network,
        message: 'Cannot reach the server. Please check your internet connection.',
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
      // Check for ngrok offline error specifically (ERR_NGROK_3200)
      final ngrokHeader = e.response?.headers.value('ngrok-error-code');
      if (ngrokHeader == 'ERR_NGROK_3200') {
        return const ApiException(
          type: ApiErrorType.server,
          message: 'The backend server is offline. Please start your backend application.',
        );
      }

      return const ApiException(
        type: ApiErrorType.server, 
        message: 'Server endpoint not found. The backend might not be running correctly.',
      );
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

String? _extractDetail(dynamic data) {
  if (data is Map<String, dynamic>) {
    final detail = data['detail'];
    if (detail is String) return detail;
    if (detail is List && detail.isNotEmpty) {
      return detail.map((e) => e['msg']?.toString() ?? '').join(', ');
    }
  }
  return null;
}
