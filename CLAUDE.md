# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Install dependencies
flutter pub get

# Generate code (Freezed models, Retrofit clients, Riverpod providers)
dart run build_runner build --delete-conflicting-outputs

# Watch and regenerate on change
dart run build_runner watch --delete-conflicting-outputs

# Run the app
flutter run

# Lint / static analysis
flutter analyze

# Run tests
flutter test

# Run a single test file
flutter test test/widget_test.dart

# Full setup from scratch
./scripts/setup.sh
```

## Environment Configuration

Copy `.env.example` to `.env` and fill in:
- `SUPABASE_URL` — Supabase project URL
- `SUPABASE_ANON_KEY` — Supabase anon key
- `API_BASE_URL` — REST backend base URL (default: `http://10.0.2.2:8000/api/v1` for Android emulator)

The app detects placeholder credentials and runs in **demo mode** (no auth required, no backend calls) when real credentials are absent.

## Architecture

Clean Architecture with feature-based modules. Each feature under `lib/features/<name>/` follows:

```
data/
  datasources/   # Retrofit REST clients (generated .g.dart files)
  models/        # JSON models (if separate from entities)
  repositories/  # Repository implementations
domain/
  entities/      # Freezed immutable value objects
  repositories/  # Abstract repository interfaces
  usecases/      # Business logic
presentation/
  pages/         # Screens
  widgets/       # Feature-scoped widgets
  providers/     # Riverpod providers (generated .g.dart files)
```

**Implemented features:** `auth`, `bills`, `dashboard`
**Stub/coming soon:** `transactions`, `wallets`, `budgets`, `reports`, `ai_chat`

### Key Patterns

**State management:** Riverpod with code generation (`@riverpod` annotation). Providers live in `presentation/providers/`. After editing a provider, run build_runner to regenerate `.g.dart` files.

**HTTP client:** Retrofit over Dio (`lib/core/network/dio_client.dart`). `createDio()` attaches an `_AuthInterceptor` that injects the Supabase JWT and auto-refreshes on 401, and a `_LoggingInterceptor`.

**Entities:** Freezed (`@freezed` + `@JsonSerializable(fieldRename: FieldRename.snake)`). The backend returns numeric fields (e.g. `amount`) as strings — use the `_parseDouble` / `_parseDoubleNullable` helpers defined in entity files.

**Navigation:** GoRouter with a `ShellRoute` wrapping a bottom nav bar (`MainShell`). Auth redirect is skipped in demo mode.

**Config:** `lib/core/config/app_config.dart` — reads from `flutter_dotenv`. The `.env` file is bundled as a Flutter asset.

### Code Generation

The following files are auto-generated and **must not be edited manually**:
- `*.freezed.dart` — Freezed immutable classes
- `*.g.dart` — JSON serialization, Retrofit clients, Riverpod providers

Always run `dart run build_runner build --delete-conflicting-outputs` after modifying any file annotated with `@freezed`, `@riverpod`, `@RestApi`, or `@JsonSerializable`.
