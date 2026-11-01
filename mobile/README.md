# Credit Sea — Mobile App (Flutter)

Flutter client for the loan application. It uses **GetX** for state management,
dependency injection and routing, and talks to the Node.js backend in
[`../backend`](../backend). All data comes from the real API; nothing is mocked.

Screens: splash, mobile number, OTP, 4-step profile setup, home, loan
calculator, eligibility and offer, review and apply, success, application
status with timeline and repayments, my applications, my profile.

## Requirements

- Flutter 3.47.9 (Dart 3.13.7)
- The backend running on port `5000` (see [`../backend/README.md`](../backend/README.md))
- Android Studio / Xcode only if you run on an emulator or simulator

## Run

```bash
cd mobile
flutter pub get
flutter run
```

With the backend in `OTP_MODE=demo`, every OTP is `123456`. The OTP screen then
shows a small "Demo mode: use OTP 123456" hint; it appears only when the backend
sends `demoOtp`, so it never shows against a real SMS setup.

To try it in the browser:

```bash
flutter run -d chrome
```

To publish it as a website, `flutter build web --release` and host the
`build/web` folder; see [`../docs/deploy-web.md`](../docs/deploy-web.md). On a
wide screen the app stays in a centred phone-width column (`PhoneFrame`).

## Backend URL

The app talks to the deployed backend by default:

```
https://credit-sea-api.onrender.com
```

So `flutter run` and release builds work on an emulator, a real phone and Chrome
with no extra flags. The address is one constant in
`lib/core/config/app_config.dart` (the app adds `/api` itself).

To use a different backend, such as one running on your laptop, pass the server
origin (no `/api`) with `--dart-define=API_BASE_URL=...`:

| Where the app runs   | Local backend (`npm run dev` on port 5000)                         |
| -------------------- | ------------------------------------------------------------------ |
| Android emulator     | `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000`      |
| iOS simulator / web  | `flutter run --dart-define=API_BASE_URL=http://localhost:5000`     |
| Physical phone       | `flutter run --dart-define=API_BASE_URL=http://<laptop-ip>:5000`   |

Checklist for a phone talking to your laptop: same Wi-Fi, the laptop's LAN IP
(not `localhost`), and port `5000` allowed in the firewall. Android debug builds
allow plain `http`; iOS only allows it to `localhost`, so a real iPhone needs an
`https` URL.

**First request after a pause.** The deployed backend is on Render's free plan,
which sleeps when idle and takes up to a minute to wake. The app waits up to 30
seconds to connect and 60 to receive for that reason, and shows "Try again" if
it still cannot reach the server. Opening
`https://credit-sea-api.onrender.com/api/health` in a browser wakes it up.

Release build:

```bash
flutter build apk --release
```

Deploying your own copy of the backend is covered in
[`../docs/deploy-render.md`](../docs/deploy-render.md).

## Firebase / push notifications

**Not part of this build.** The app has no Firebase dependency, no
`google-services.json` / `GoogleService-Info.plist`, and nothing sends or
receives push messages. Today the status screen refreshes when it opens and on
pull-to-refresh.

What is already in place for adding it later:

- the backend emits a `loan.status.changed` event on every status change, and
  the `User` model reserves an `fcmTokens` field;
- `LoanStatusController.reload()` is public so a notification tap can call it;
- a placeholder `/notifications` route exists (`modules/notifications`).

Adding it would mean creating a Firebase project, adding the platform config
files, `firebase_core` and `firebase_messaging`, registering the device token
with the backend, and subscribing a sender to the backend event.

## Packages

| Package                  | Why                                                       |
| ------------------------ | --------------------------------------------------------- |
| `get`                    | State management, dependency injection, named routes      |
| `dio`                    | HTTP client; interceptors add the token and refresh it    |
| `flutter_secure_storage` | Encrypted storage for the access and refresh tokens       |
| `intl`                   | Indian rupee grouping and date formats                    |

Dev only: `flutter_test`, `flutter_lints`. Montserrat is bundled in
`assets/fonts/`, so no font package or network request is needed.

## Folder structure

```
lib/
├── main.dart               starts the app
├── app.dart                GetMaterialApp: theme, routes, initial binding
├── core/
│   ├── config/             AppConfig (base URL, timeouts)
│   ├── constants/          sizes, loan limits, status labels, option lists
│   ├── network/            ApiClient (Dio), ApiException, ApiResponse
│   ├── storage/            TokenStorage (secure), SessionService (login state)
│   ├── theme/              colors, text styles, ThemeData
│   ├── utils/              formatters, validators, navigation helper
│   └── widgets/            shared widgets (buttons, fields, StateMessage, ...)
├── data/
│   ├── models/             plain Dart classes with fromJson
│   └── repositories/       one call per endpoint, returns models
├── modules/                one folder per screen
│   └── <screen>/           <screen>_controller.dart, _binding.dart, _view.dart
└── routes/                 AppRoutes (names), AppPages (pages + bindings)
```

Dependencies only point down: **view -> controller -> repository -> ApiClient**.
Widgets never call the API, and repositories know nothing about screens.

## How GetX is used here

GetX does three jobs, kept deliberately simple.

**1. Dependency injection (`InitialBinding`).** At startup three permanent
objects are created once: `TokenStorage`, `SessionService` and `ApiClient`.
Every other class receives what it needs through its constructor, which is
what makes controllers easy to test with fakes.

**2. One controller per screen, built by a binding.** A binding creates the
screen's controller only when the route opens and disposes it when the route
closes:

```dart
class HomeBinding extends Bindings {
  @override
  void dependencies() {
    final api = Get.find<ApiClient>();
    Get.lazyPut<HomeController>(
      () => HomeController(UserRepository(api), LoanRepository(api)),
    );
  }
}
```

**3. Reactive state with `Rx` + `Obx`.** The controller holds state in
observables (`isLoading`, `errorMessage`, `quote`, ...). The view wraps only the
parts that change in `Obx`, so it rebuilds just those. Views read state and call
controller methods; they contain no business logic.

```dart
Obx(() => PrimaryButton(
      label: 'Request OTP',
      isLoading: controller.isLoading.value,
      onPressed: controller.requestOtp,
    ))
```

Routing uses named routes (`Get.toNamed(AppRoutes.loanStatus, arguments: loan)`).
Pages that need data passed in are wrapped with `guardedPage`, which sends the
user back to the splash screen if the page is reopened without its arguments
(for example after a browser refresh) instead of crashing.

## Session and login flow

1. **Splash** (about 1.5 s) restores the saved tokens from secure storage.
2. `SessionService.landingRoute` decides where to go: no session -> login,
   session without a finished profile -> profile setup, otherwise -> home.
3. After OTP verification the tokens are stored, so the user stays signed in
   until they log out.
4. `ApiClient` adds the access token to every request. On a `401` it refreshes
   once (a single refresh is shared between parallel requests), replays the
   request, and if the refresh fails it clears the session and returns to login.

## Loading, empty, error and offline states

Every data screen follows the same pattern:

- **Loading:** `AppLoader` while the first load runs.
- **Error:** `StateMessage.error(...)` with a "Try again" button. It shows a
  "No internet connection" variant when `ApiException.isNetworkError` is true
  (timeout or unreachable server).
- **Empty:** `StateMessage` with a call to action (for example "No applications
  yet").
- **Submitting:** buttons take an `isLoading` flag and are disabled while a
  request is running, and controllers also ignore a second call, so a double tap
  can't submit twice.

## Test

```bash
flutter analyze    # must report "No issues found"
flutter test
```

Tests cover the API error mapping, formatters, model parsing, validators,
session storage and routing, and controllers for auth, profile setup, loan
apply, loan tracking and home (using fake repositories, no network).

Regenerate the README screenshots (real screens, sample data, no device needed):

```bash
flutter test tool/screenshots_test.dart --update-goldens
```

It lives in `tool/`, so a normal `flutter test` never runs it.

## Design

Figma exports are in [`../design/screens`](../design/screens) and the node
mapping is in [`../design/README.md`](../design/README.md). Colors, typography
and spacing come from those frames.
