# Flutter App — Attendance & GPS Check-In

Flutter frontend for the Mini Attendance & GPS Check-In module.

---

## Prerequisites

- Flutter 3.19+ (run `flutter --version`)
- Android Studio / Xcode for emulator / simulator
- Backend running at `http://localhost:8000` (or your device LAN IP)

---

## Configure the backend URL

Open `lib/core/constants/app_constants.dart` and change `baseUrl`:

```dart
// Android emulator (default)
static const String baseUrl = 'http://10.0.2.2:8000';

// iOS simulator
static const String baseUrl = 'http://localhost:8000';

// Physical device — use your machine's LAN IP
static const String baseUrl = 'http://192.168.x.x:8000';
```

---

## Run the app

```bash
cd flutter_app
flutter pub get
flutter run
```

---

## App structure

```
lib/
├── main.dart                    ← Entry point + session router
├── core/
│   ├── constants/
│   │   └── app_constants.dart   ← Base URL, prefs keys, timeouts
│   └── theme/
│       └── app_theme.dart       ← Black/white design system
├── data/
│   ├── models/                  ← UserModel, AttendanceModel, etc.
│   ├── repositories/            ← API call abstractions
│   └── services/
│       └── api_service.dart     ← Dio setup + error handling
└── features/
    ├── login/
    │   ├── providers/           ← Session (SharedPreferences)
    │   └── screens/             ← User picker screen
    ├── employee/
    │   ├── providers/           ← Check-in state, history pagination
    │   └── screens/             ← Home + attendance history screens
    └── manager/
        ├── providers/           ← Team data state
        └── screens/             ← Team dashboard screen
```

---

## Key packages

| Package | Purpose |
|---------|---------|
| `flutter_riverpod` | State management |
| `dio` | HTTP client |
| `geolocator` | GPS coordinates |
| `shared_preferences` | Persist session locally |
| `permission_handler` | Location permission |
| `intl` | Date/time formatting |

---

## Screens

| Screen | Role |
|--------|------|
| User Picker | All — select who you are |
| Employee Home | Employee — check in/out with GPS |
| Attendance History | Employee — paginated past records |
| Team Dashboard | Manager — today's team attendance |
