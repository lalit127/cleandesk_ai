// lib/data/repositories/user_repository.dart
// ─────────────────────────────────────────────
// Repository for user-related API calls.
//
// All HTTP calls are isolated here — providers and widgets only
// interact with this repository, never with Dio directly.

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cleandesk_ai/data/models/user.dart';
import 'package:cleandesk_ai/data/services/api_service.dart';

class UserRepository {
  final Dio _dio;
  const UserRepository(this._dio);

  /// Fetch all seeded users from GET /users.
  /// Used by the login screen to display the user picker.
  Future<List<UserModel>> getUsers() async {
    try {
      final response = await _dio.get('/users');
      final list = response.data as List<dynamic>;
      return list
          .map((json) => UserModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }
}

/// Riverpod provider for the user repository.
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(ref.watch(dioProvider));
});
