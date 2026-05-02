// lib/core/config/app_env.dart
// ─────────────────────────────────────────────────────────────────────────────
// Environment configuration for the Attendance app.
//
// ┌─────────────────────────────────────────────────────────────────────────┐
// │  HOW ENVIRONMENTS WORK — READ THIS FIRST                                │
// ├─────────────────────────────────────────────────────────────────────────┤
// │  THE URL NEVER CHANGES once deployed.                                   │
// │                                                                         │
// │  The backend URL (Railway / Render / etc.) is always the same.          │
// │  What changes is the backend's APP_ENV variable, which toggles          │
// │  the geofence check on or off.                                          │
// │                                                                         │
// │  To toggle geofence: only update the backend's environment variable.    │
// │    Railway dashboard → your service → Variables → APP_ENV              │
// └─────────────────────────────────────────────────────────────────────────┘
//
// ┌──────────────────────┬──────────────────────────┬──────────────────────┐
// │ Setting              │ DEVELOPMENT               │ PRODUCTION           │
// ├──────────────────────┼──────────────────────────┼──────────────────────┤
// │ Flutter flavor       │ Flavor.development        │ Flavor.production    │
// │ Backend URL          │ Same URL — never changes  │ Same URL always ✅   │
// │ Backend APP_ENV      │ APP_ENV=development       │ APP_ENV=production   │
// │ Geofence             │ SKIPPED — check in from   │ ENFORCED — must be   │
// │                      │ anywhere (home, cafe, etc)│ within office radius │
// │ Geofence radius      │ Not checked               │ 200 m (set in .env)  │
// │ Office coordinates   │ Not checked               │ Real office lat/lng  │
// │ API logs in Flutter  │ Printed to console        │ Silent               │
// │ Mock GPS             │ Can enable (emulator use) │ Always real GPS      │
// └──────────────────────┴──────────────────────────┴──────────────────────┘
//
// HOW TO SWITCH TO PRODUCTION (geofence ON):
//   Step 1 — Flutter (main.dart) — controls logs, mock GPS, display banner:
//     AppEnv.init(Flavor.production);
//
//   Step 2 — Backend env variable (Railway dashboard or .env):
//     APP_ENV=production
//     OFFICE_LAT=<your_real_office_latitude>
//     OFFICE_LNG=<your_real_office_longitude>
//     GEOFENCE_RADIUS_METRES=200
//
//   Step 3 — Flutter (this file) — set matching office coords for UI display:
//     Update officeLatitude and officeLongitude below.
//
// NOTE: The baseUrl stays the same in both flavors — it's always the
//       deployed Railway URL. Only change baseUrl if you're switching
//       from local ngrok testing to the deployed server.
// ─────────────────────────────────────────────────────────────────────────────

/// The available environment flavors.
enum Flavor {
  /// Local testing — geofence is OFF, any location can check in.
  development,

  /// Real deployment — geofence is ON, only office location allowed.
  production,
}

/// All environment-specific values, resolved once at app startup.
class AppEnv {
  AppEnv._(); // prevent instantiation

  static Flavor _flavor = Flavor.development;

  /// Call this once in main() before runApp().
  /// Must match the APP_ENV set in the backend .env file.
  static void init(Flavor flavor) {
    _flavor = flavor;
  }

  /// Current flavor — useful for conditional UI (e.g. showing a "DEV" badge).
  static Flavor get flavor => _flavor;
  static bool get isDev  => _flavor == Flavor.development;
  static bool get isProd => _flavor == Flavor.production;

  // ── Backend URL ────────────────────────────────────────────────────────────

  /// The base URL of the FastAPI backend.
  ///
  /// ✅ This URL is the SAME for both development and production flavors
  ///    once the backend is deployed (Railway, Render, etc.).
  ///
  /// The geofence behavior is NOT controlled by this URL — it is controlled
  /// entirely by the APP_ENV variable set on the backend server.
  ///
  /// Only change this if you are switching between:
  ///   - Local testing with ngrok  →  'https://xxxx.ngrok-free.dev'
  ///   - Deployed Railway server   →  'https://xxxx.railway.app'
  // TODO: Replace with your Railway URL after deployment.
  static const String _deployedUrl = 'https://your-app.railway.app';

  static String get baseUrl {
    switch (_flavor) {
      case Flavor.development:
        // While testing locally before Railway deployment, use ngrok URL.
        // Once deployed on Railway, set this to _deployedUrl too.
        return 'https://trouble-subtitle-pager.ngrok-free.dev';
      case Flavor.production:
        // Same Railway URL — geofence is controlled by backend APP_ENV, not the URL.
        return _deployedUrl;
    }
  }

  // ── Geofence settings ──────────────────────────────────────────────────────
  //
  // ⚠️  IMPORTANT: The actual geofence enforcement is done on the BACKEND.
  //
  //  • Development  (APP_ENV=development in backend .env):
  //      The backend's validate_within_geofence() is completely skipped.
  //      Any GPS coordinates are accepted — no distance check is done.
  //      This means employees can check in from home, office, or anywhere.
  //
  //  • Production   (APP_ENV=production in backend .env):
  //      The backend calculates the distance between the employee's GPS
  //      and the configured OFFICE_LAT/OFFICE_LNG using the Haversine formula.
  //      If the distance > GEOFENCE_RADIUS_METRES, check-in is rejected (HTTP 422).
  //      The employee MUST physically be within the office radius to check in.
  //
  //  The values below mirror the backend config for UI display/info purposes.
  //  They do NOT enforce the geofence — only the backend does.

  /// Office GPS latitude.
  /// Must match OFFICE_LAT in the backend .env for consistency.
  static double get officeLatitude {
    switch (_flavor) {
      case Flavor.development:
        return 28.6139; // Placeholder — not used in dev (geofence is skipped)
      case Flavor.production:
        // TODO: Set your real office latitude before going live.
        // Example: Ahmedabad = 23.0225, Mumbai = 19.0760
        return 28.6139;
    }
  }

  /// Office GPS longitude.
  /// Must match OFFICE_LNG in the backend .env for consistency.
  static double get officeLongitude {
    switch (_flavor) {
      case Flavor.development:
        return 77.2090; // Placeholder — not used in dev (geofence is skipped)
      case Flavor.production:
        // TODO: Set your real office longitude before going live.
        return 77.2090;
    }
  }

  /// Geofence radius in metres.
  /// Must match GEOFENCE_RADIUS_METRES in the backend .env.
  ///
  /// Development : 10,000 m — but irrelevant since check is skipped entirely.
  /// Production  : 200 m — employee must be within 200 m of the office.
  static double get geofenceRadiusMetres {
    switch (_flavor) {
      case Flavor.development:
        return 10000; // Not enforced — for display/info only in dev
      case Flavor.production:
        return 200;   // Enforced strictly by the backend
    }
  }

  // ── GPS mock (dev only) ────────────────────────────────────────────────────

  /// If true, skip real GPS and use [mockLat] / [mockLng] for check-in.
  ///
  /// Useful when:
  ///   - Testing on an Android emulator (no real GPS).
  ///   - Testing check-in flow quickly without waiting for GPS fix.
  ///
  /// How to enable: set _useMockGps = true below.
  /// Always false in production — real GPS is always used.
  static bool get useMockGps => _flavor == Flavor.development && _useMockGps;
  static const bool _useMockGps = false; // ← flip to true to use mock GPS

  /// Mock GPS coordinates used when [useMockGps] is true.
  static const double mockLat = 28.6139;
  static const double mockLng = 77.2090;

  // ── API logging ────────────────────────────────────────────────────────────

  /// Whether verbose API request/response logs are printed to the console.
  /// Automatically off in production for cleaner output.
  static bool get enableApiLogs => _flavor == Flavor.development;

  // ── Display name ───────────────────────────────────────────────────────────

  static String get displayName {
    switch (_flavor) {
      case Flavor.development:
        return 'DEV';
      case Flavor.production:
        return 'PROD';
    }
  }
}
