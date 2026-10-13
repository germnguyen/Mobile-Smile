# Test results

## Current run — 2026-10-13

Executed in `mm/`:

| Command | Result | Notes |
|---|---|---|
| `flutter pub get` | Pass | Firebase Storage/Functions no longer resolve as dependencies |
| `flutter test` | Pass | All 21 tests passed, including 3 new storage-path/validation unit tests |
| `flutter analyze` | Warning/fail exit code 1 | 4 existing issues remain: 1 info in `document_dao.dart`, 1 unused import in `document_card.dart`, 2 unused imports in existing tests. No findings in newly changed Dart files. |
| `flutter build apk --debug` | Pass | APK produced; Firebase Auth plugins emit a Kotlin Gradle Plugin migration warning |
| Functions/backend tests | N/A | The Firebase Callable Function was removed; no backend service remains in this architecture |

| Check | Result | Notes |
|---|---|---|
| Supabase migration history | Pass (read-only) | Initial migration `20261013223000` recorded remotely |
| Existing table RLS policies | Pass (read-only inspection) | Policies exist for `users`, `documents`, and `document_permissions` |
| Supabase Storage migration | Pass | `20261013233500` applied to linked dev/test; migration record confirmed via read-only SQL |
| Supabase Storage bucket | Pass (configuration only) | `documents` exists, `public=false`, 20 MiB, expected MIME allowlist |
| Supabase Storage policies | Pass (definition only) | Four `authenticated` policies exist; enforcement not yet tested with users |
| Firebase Third-Party Auth claims | Blocked/unverified | Requires Dashboard configuration and a real Firebase login |
| Three-account cloud tests | Blocked/not run | Requires configured auth bridge, bucket/policies, and A/B/C credentials |

Do not replace pending/blocked entries with pass without capturing actual
command output or cloud test evidence.

## Follow-up local validation — 2026-10-14

| Command/check | Result | Notes |
|---|---|---|
| Package versions | Verified | `google_sign_in 7.2.0`, `firebase_auth 6.7.0`, `firebase_core 4.15.0`, `supabase_flutter 2.18.3`. |
| Format changed Dart files | Pass | Auth service, token bridge, cloud service, sign-in page and added tests formatted. |
| `flutter test` | Pass | 36/36 pass. The new auth, token-claim, profile UID, and mocked RLS denial checks are included. Mock claims/RLS do not verify real provider signatures or hosted policies. |
| Focused auth/profile test run | Pass | 11/11 pass: Google-token-to-Firebase flow, cancellation/failures, token claim checks, UID mismatch and mocked `42501`. |
| `flutter analyze` | Warning / exit code 1 | Four pre-existing findings remain outside changed Dart files: `use_super_parameters` at `lib/database/daos/document_dao.dart:12`; unused imports at `lib/widgets/document_card.dart`, `test/database_test.dart`, and `test/document_dao_test.dart`. No new finding in changed files. |
| `flutter build apk --debug` | Pass | APK built at `build/app/outputs/flutter-apk/app-debug.apk`. Flutter reports the existing Firebase Auth/Core plugins' Kotlin Gradle Plugin migration warning. |
| `git diff --check` | Pass | No whitespace errors. |
| `flutter emulators --launch Pixel_8_2` | Launched | Flutter listed `emulator-5554` as Android 17/API 37. |
| `flutter run -d emulator-5554` (earlier build) | Pass with cloud access blocked | App installed and started. Firebase restored an existing signed-in session (this was not a fresh Google OAuth test). The app attempted `users` profile upsert; Supabase returned PostgreSQL `42501` / row-level security violation. The app displayed its fail-closed state and did not issue document search. |
| `flutter run -d emulator-5554` (updated build) | Pass: app launched | Updated APK assembled, installed and launched. Widget inspection confirmed the Google sign-in screen. No fresh OAuth interaction was performed, so no cloud request/token acceptance was established. |
| Flutter runtime errors | Pass | No runtime errors found after the updated app launch. |

The current security gate has an unverified prerequisite: Firebase ID tokens
normally lack `role: authenticated`. No trusted claim issuer is implemented
in this repository. New code preflights `sub`, `aud`, `iss`, expiration and
role from Firebase's local `getIdTokenResult()` result and passes the original
token unchanged only when these checks pass. Firebase's client-decoded claims
are not trusted and do not replace Supabase server verification. No real token
claims were inspected/logged, no fresh Google OAuth flow was run, and no A/B/C
cloud authorization test was performed in this local validation.

An attempted widget-level test for account switching did not complete
reliably and was not kept in the suite. The account-change generation guard is
implemented, but this race currently lacks automated widget-test coverage.
Likewise, the hosted provider, JWT signature validation, and actual server-side
RLS enforcement remain unverified.
