# Flutter Starter Template

Production-grade Flutter scaffold. Clone this to start any new project. Authentication, routing, secure storage, network layer, and design system are pre-wired. Replace placeholders with project-specific code and ship.

---

## What this gives you

Every project needs the same infrastructure. This template builds it once so you never build it again.

| Layer | What's included |
|---|---|
| **Network** | `DioClient` with JWT bearer auth, automatic token refresh on 401, request coalescing, structured `ApiResult<T>` error handling |
| **Auth** | Full auth flow: `AuthState` sealed class, `AuthNotifier`, login screen, secure token storage |
| **Router** | `GoRouter` with auth guard — unauthenticated users are redirected to `/login` automatically |
| **Storage** | `SecureTokenStorage` for JWTs (device keychain/keystore), `StorageService` via Hive for non-sensitive preferences |
| **Design system** | `AppColors`, `AppTypography`, `AppSpacing`, `AppRadii`, `AppColorScheme` (theme extension), light + dark themes |
| **State** | Riverpod throughout. `ProviderScope` at root |

---

## Starting a new project

### Step 1 — Clone and rename

```bash
git clone https://github.com/your-org/flutter-starter my_new_project
cd my_new_project
```

Find and replace `cut_above` with your project name across all Dart files and `pubspec.yaml`:

```bash
# macOS / Linux
grep -rl "cut_above" . --include="*.dart" --include="*.yaml" | xargs sed -i '' 's/cut_above/your_project_name/g'
```

### Step 2 — Set your API base URL

The base URL is never hardcoded. Pass it at run time:

```bash
flutter run --dart-define=API_BASE_URL=https://your-api.com
```

For VS Code, add to `.vscode/launch.json`:

```json
{
  "configurations": [
    {
      "name": "Dev",
      "request": "launch",
      "type": "dart",
      "args": ["--dart-define=API_BASE_URL=https://your-api.com"]
    }
  ]
}
```

### Step 3 — Update brand colors

Open `lib/core/design_system/app_colors.dart`. Replace the two brand values:

```dart
static const Color brandPrimary = Color(0xFF1B3A5C); // ← your primary color
static const Color brandAccent  = Color(0xFFC9A84C); // ← your accent color
```

Everything else (buttons, nav indicators, headers) inherits from these two values. Nothing else needs to change.

### Step 4 — Add your features

Create a folder under `lib/features/` for each feature. Each feature follows the same three-layer structure:

```
lib/features/your_feature/
  data/
    your_feature_repository.dart   # API calls, returns ApiResult<T>
    your_feature_model.dart        # data classes with fromJson
  domain/
    your_feature_state.dart        # sealed state class
  presentation/
    your_feature_providers.dart    # Riverpod providers
    your_feature_notifier.dart     # state machine (part of providers)
    your_feature_screen.dart       # Flutter UI, no business logic
```

### Step 5 — Add project-specific Hive boxes

Open `lib/core/storage/app_boxes.dart` and add your box names:

```dart
class AppBoxes {
  static const String settings = 'settings';
  // Add project-specific box names here
  static const String cart     = 'cart';
  static const String drafts   = 'drafts';
}
```

Then open each box in `main.dart`:

```dart
await Hive.openBox(AppBoxes.cart);
await Hive.openBox(AppBoxes.drafts);
```

---

## Architecture decisions

These decisions are locked. Do not change them without understanding the consequences.

### Tokens in SecureStorage, everything else in Hive

JWT access and refresh tokens are stored in `SecureTokenStorage` — backed by the Android Keystore and iOS Keychain. These are hardware-encrypted. Even if someone extracts the app's storage files from the device, they cannot read the tokens.

Non-sensitive data (theme preference, onboarding flags, cached responses) goes in Hive via `StorageService`. Fast, simple, no encryption overhead.

**Rule: tokens never touch Hive. Non-sensitive data never needs SecureStorage.**

### ApiResult instead of exceptions

Every API call returns `ApiResult<T>` — either `ApiSuccess<T>` or `ApiError`. The compiler forces every caller to handle both cases. Nothing is silently swallowed.

```dart
final result = await ref.read(authRepositoryProvider).login(phone, password);
switch (result) {
  case ApiSuccess(:final data):
    // handle success
  case ApiError(:final message):
    // handle error — compiler won't let you skip this
}
```

### DioClient knows nothing about Riverpod

`DioClient` is pure infrastructure. It takes an `onLogout` callback at construction time. The callback is wired in `dio_providers.dart` using `ref.read` — a lazy lookup that only runs when refresh actually fails, not during construction. This prevents circular dependencies.

### Router guard is reactive

`GoRouterRefreshStream` listens to `authNotifierProvider` via `ChangeNotifier`. Any change to auth state immediately re-evaluates the router's `redirect` callback. There is no manual navigation. The state machine drives navigation.

```
AuthInitial  → redirect to /login
AuthLoading  → no redirect (stays on current screen, button shows spinner)
AuthError    → redirect to /login
AuthAuthenticated → redirect away from /login to /home
```

### Feature-first folder structure

Features are self-contained. The `auth` feature does not reach into the `transactions` feature. `transactions` does not reach into `booking`. Each feature has its own data, domain, and presentation layers.

The `core` folder contains infrastructure with no business logic. Core serves features. Features never import from other features directly — they communicate through shared providers in `core` if needed.

---

## Optional: add Firebase

Firebase is not included. If a project needs it:

1. Run `flutter pub add firebase_core` and `flutterfire configure`
2. Add to `main.dart` before `runApp`:

```dart
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
```

---

## File structure

```
lib/
├── main.dart                              Boot sequence. Hive init. ProviderScope.
│
├── core/
│   ├── auth/
│   │   └── token_storage_provider.dart    Riverpod provider for SecureTokenStorage
│   ├── components/
│   │   ├── app_shell.dart                 Shell scaffold with bottom nav
│   │   └── app_bottom_nav.dart            Bottom navigation bar
│   ├── design_system/
│   │   ├── app_colors.dart                Raw color constants
│   │   ├── app_color_scheme.dart          ThemeExtension mapping colors to roles
│   │   ├── app_typography.dart            Text style constants
│   │   ├── app_spacing.dart               8pt grid spacing constants
│   │   ├── app_radii.dart                 Corner radius constants
│   │   ├── app_theme.dart                 Light + dark ThemeData
│   │   ├── theme_mode_provider.dart       Riverpod provider for ThemeMode
│   │   └── design_system.dart             Barrel export
│   ├── network/
│   │   ├── dio_client.dart                HTTP client with auth interceptor
│   │   ├── api_result.dart                Sealed ApiSuccess / ApiError
│   │   ├── token_storage.dart             Abstract TokenStorage interface
│   │   └── dio_providers.dart             dioClientProvider
│   ├── router/
│   │   ├── app_router.dart                routerProvider + GoRouterRefreshStream
│   │   ├── app_routes.dart                Route path constants
│   │   └── placeholder_route_screen.dart  Dev placeholder for unbuilt screens
│   ├── storage/
│   │   ├── secure_token_storage.dart      FlutterSecureStorage TokenStorage impl
│   │   ├── storage_service.dart           Hive wrapper for non-sensitive data
│   │   └── app_boxes.dart                 Hive box name constants
│   └── utils/                             Add project utilities here
│
└── features/
    └── auth/
        ├── data/
        │   ├── auth_repository.dart       POST /api/v1/auth/login
        │   └── auth_tokens.dart           Response model
        ├── domain/
        │   └── auth_state.dart            Sealed: Initial/Loading/Authenticated/Error
        └── presentation/
            ├── auth_providers.dart        authNotifierProvider, authRepositoryProvider
            ├── auth_notifier.dart         login() / logout() state machine
            └── login_screen.dart          Phone + password UI
```

---

## Local setup after clone

1. Copy `.env.example` to `.env` and fill in your Supabase URL, anon key, and any Dart-side secrets.
2. **Android:** Add your Maps API key to `android/local.properties` (this file is not committed):
   `GOOGLE_MAPS_KEY=your_key`
3. **iOS:** The committed `ios/Runner/Info.plist` keeps `GMSApiKey` as `GOOGLE_MAPS_KEY_PLACEHOLDER`. To use a real key locally without committing it:
   ```bash
   git update-index --skip-worktree ios/Runner/Info.plist
   ```
   Then edit `ios/Runner/Info.plist` and set `GMSApiKey` to your real key. To resume tracking: `git update-index --no-skip-worktree ios/Runner/Info.plist`.
4. **iOS (optional):** `ios/Runner/GoogleMaps.xcconfig` is gitignored — you can store `GOOGLE_MAPS_KEY=...` there if you wire it into Xcode; the default flow uses `Info.plist` as above.
5. **Web:** The Maps script in `web/index.html` includes the app key; restrict that key in Google Cloud Console (HTTP referrers / domains). For a local-only HTML override, use `web/index.local.html` (gitignored) if you add a workflow that swaps it in.

---

## Dependencies

| Package | Purpose |
|---|---|
| `flutter_riverpod` | State management |
| `go_router` | Navigation + auth guard |
| `dio` | HTTP client |
| `flutter_secure_storage` | Encrypted token storage |
| `hive_flutter` | Local key-value storage |

---

*This template is maintained by the CutAbove engineering team. Tag releases as `vX.Y.Z` when making breaking changes to the architecture.*