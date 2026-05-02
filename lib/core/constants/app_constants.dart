// lib/core/constants/app_constants.dart
// ─────────────────────────────────────
// All app-wide constants.
//
// Environment-specific values (URLs, geofence settings) are read from
// AppEnv — see lib/core/config/app_env.dart.
// Switch the environment in main.dart via AppEnv.init(Flavor.xxx).

import 'package:cleandesk_ai/core/config/app_env.dart';

class AppConstants {
  AppConstants._(); // prevent instantiation

  // -------------------------------------------------------------------------
  // Backend base URL — resolved from the current environment
  // -------------------------------------------------------------------------

  static String get baseUrl => AppEnv.baseUrl;

  // -------------------------------------------------------------------------
  // SharedPreferences keys
  // -------------------------------------------------------------------------
  static const String prefUserId   = 'user_id';
  static const String prefUserName = 'user_name';
  static const String prefUserRole = 'user_role';

  // -------------------------------------------------------------------------
  // GPS / location
  // -------------------------------------------------------------------------
  static const int gpsTimeoutSeconds = 15;

  // -------------------------------------------------------------------------
  // Pagination
  // -------------------------------------------------------------------------
  static const int historyPageSize = 10;
}
