// lib/core/constants/app_constants.dart
// ─────────────────────────────────────
// All hard-coded values live here so they can be changed in one place.
// Change BASE_URL to point to your backend before running the app.

class AppConstants {
  AppConstants._(); // prevent instantiation

  // -------------------------------------------------------------------------
  // Backend base URL
  // -------------------------------------------------------------------------

  static const String baseUrl = 'https://trouble-subtitle-pager.ngrok-free.dev';

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
