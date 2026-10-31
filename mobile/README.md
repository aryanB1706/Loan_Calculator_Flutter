# Loan App (Flutter)

Flutter client for the Loan Application project. It uses GetX for state
management, dependency injection and named routes, with a feature-first layout.

## Requirements

- Flutter 3.47.9 / Dart 3.13.7
- Backend running on port `5000`

The SDK used in this environment is installed at `~/development/flutter`. Add it
to the shell for future sessions:

```bash
export PATH="$HOME/development/flutter/bin:$PATH"
```

## Run

```bash
cd mobile
flutter pub get
flutter run
```

For a quick browser check (no Android emulator required):

```bash
flutter run -d chrome
# or
flutter run -d web-server --web-port=8088
```

The web platform exists for development verification only; Android and iOS are
the production targets. The app currently opens the `Auth` placeholder route.
The global theme is built from the Figma design tokens; real screens will be
implemented step by step.

## Backend URL

`BASE_URL` is configured in `lib/core/config/app_config.dart`. The API prefix
`/api` is appended automatically.

| Target                     | URL                                  |
| -------------------------- | ------------------------------------ |
| Android emulator           | `http://10.0.2.2:5000`               |
| iOS simulator / web/desktop | `http://localhost:5000`             |
| Physical device (same LAN) | `http://<your-computer-LAN-IP>:5000` |

For a physical device, pass the computer's LAN IP at build/run time. The phone
and computer must be on the same network, the backend must listen on
`0.0.0.0:5000`, and the firewall must allow port `5000`.

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.25:5000
```

The value is the server origin only; do not include `/api`. Cleartext HTTP is
enabled for Android debug builds and local networking is enabled for iOS. Use
HTTPS before a production release.

## Packages

| Package                 | Why                                                     |
| ----------------------- | ------------------------------------------------------- |
| `get`                   | State management, DI, bindings and named routes         |
| `dio`                   | HTTP client with interceptors for auth and error handling |
| `flutter_secure_storage`| Encrypted storage for access and refresh tokens         |
| `intl`                  | Indian currency and date formatting                     |

Only `flutter_test` and `flutter_lints` are used for development.

## Design

The Figma frames are saved in `../design/screens/` with their node mapping in
`../design/README.md`. Colors, typography and component sizes come from those
frames. Montserrat 400/500/600 is bundled under `assets/fonts/`, so the app does
not need a fonts package or a network request.

Shared widgets:

- `PrimaryButton` — primary CTA with loading state
- `AppTextField` — labelled input, password visibility and validation
- `AppLoader` — inline or full-screen progress indicator

## Structure

```
lib/
  core/
    config/       app config and backend URL
    constants/    shared storage/API constants
    network/      Dio client and API exception mapping
    storage/      secure token storage
    theme/        AppColors, AppTextStyles, AppTheme
    utils/        currency/date formatters
    widgets/      PrimaryButton, AppTextField, AppLoader
  data/
    models/       API response/request models
    providers/    feature API providers
    repositories/ feature repositories
  modules/
    auth/ profile/ home/ loan_calculator/ loan_apply/ loan_status/ notifications/
                  each with controller + binding + view
  routes/         app_routes.dart, app_pages.dart
  app.dart        GetMaterialApp and global theme
  main.dart       dependency bootstrap
```

Layering: `data -> controller -> view`. Widgets never call the API directly.

## Test

```bash
flutter analyze
flutter test
```
