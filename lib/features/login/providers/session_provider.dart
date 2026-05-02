// lib/features/login/providers/session_provider.dart
// ─────────────────────────────────────────────────────
// Manages the currently logged-in user stored in SharedPreferences.
//
// After the user taps a name in the user picker, their id and role are
// persisted here. All screens read from this provider to know who is
// logged in and which role they have.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cleandesk_ai/core/constants/app_constants.dart';

// ── Session state ────────────────────────────────────────────────────────────

class SessionState {
  final String? userId;
  final String? userName;
  final String? userRole;
  final bool isInitialized;

  const SessionState({
    this.userId,
    this.userName,
    this.userRole,
    this.isInitialized = false,
  });

  bool get isLoggedIn => userId != null && userRole != null;
  bool get isManager  => userRole == 'manager';
  bool get isEmployee => userRole == 'employee';

  SessionState copyWith({
    String? userId,
    String? userName,
    String? userRole,
    bool? isInitialized,
  }) {
    return SessionState(
      userId:        userId        ?? this.userId,
      userName:      userName      ?? this.userName,
      userRole:      userRole      ?? this.userRole,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

// ── Notifier ─────────────────────────────────────────────────────────────────

class SessionNotifier extends Notifier<SessionState> {
  @override
  SessionState build() => const SessionState(); // Start empty; load() fills it

  /// Load persisted session from SharedPreferences on app startup.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final userId   = prefs.getString(AppConstants.prefUserId);
    final userName = prefs.getString(AppConstants.prefUserName);
    final userRole = prefs.getString(AppConstants.prefUserRole);
    state = SessionState(
      userId: userId,
      userName: userName,
      userRole: userRole,
      isInitialized: true,
    );
  }

  /// Save the selected user to SharedPreferences and update state.
  Future<void> login({
    required String userId,
    required String userName,
    required String userRole,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefUserId,   userId);
    await prefs.setString(AppConstants.prefUserName, userName);
    await prefs.setString(AppConstants.prefUserRole, userRole);
    state = SessionState(
      userId: userId,
      userName: userName,
      userRole: userRole,
      isInitialized: true,
    );
  }

  /// Clear the session (logout).
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.prefUserId);
    await prefs.remove(AppConstants.prefUserName);
    await prefs.remove(AppConstants.prefUserRole);
    state = const SessionState(isInitialized: true);
  }
}

/// Global provider — read anywhere in the app with ref.watch / ref.read.
final sessionProvider = NotifierProvider<SessionNotifier, SessionState>(
  SessionNotifier.new,
);
