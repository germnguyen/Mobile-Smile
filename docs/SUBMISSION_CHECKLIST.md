# Submission checklist

## Implemented in source

- [x] Firebase Google Authentication flow retained.
- [x] Supabase metadata, search, and sharing service retained.
- [x] Supabase Storage client service added for private file operations.
- [x] File size/MIME allowlist and owner/document-scoped object naming added.
- [x] New migration authored for private bucket and owner/viewer/editor policies.
- [x] Firebase Storage dependency, rules, and Firebase Callable Function removed.
- [x] Cloud operations remain behind the Firebase-token/RLS profile gate.
- [x] Supabase `accessToken` callback supplies the unchanged Firebase ID token;
      local claim checks fail closed on missing/invalid `sub`, `aud`, `iss`,
      expiry, or `role`.
- [x] Unit tests cover Google-to-Firebase credential flow, cancellation and
      failures, token preflight, profile UID matching, and mocked RLS denial.
- [x] Cloud list state is reset and stale requests are ignored when Firebase UID changes.
- [x] Client-side permission capability tests cover owner/editor/viewer behavior.
- [x] Flutter tests and Android debug build pass; analyzer reports four existing
      findings. See `TEST_RESULTS.md`.

## Manual/cloud verification still required

- [ ] Enable Firebase Google provider and verify Android OAuth setup.
- [ ] Configure Firebase Third-Party Auth for the linked Supabase project.
- [ ] Provision a trusted server-side issuer for Firebase `role: authenticated`;
      Firebase Third-Party Auth alone does not add this claim.
- [ ] Verify real Firebase token acceptance and its `iss`, `aud`, `sub == Firebase UID`,
      valid `exp`, and `role == authenticated`.
- [x] Apply the migration to the linked development/test Supabase project.
- [x] Confirm bucket `documents` is private, 20 MiB-limited, and four policies are present.
- [ ] Verify Storage policy enforcement with actual Firebase-authenticated A/B/C users.
- [ ] Complete the A-owner / B-recipient / C-unshared cloud test matrix.
- [ ] Record real outcomes and sanitized evidence in `TEST_RESULTS.md`.
- [x] Launch the updated app on the booted Android emulator; the Google
      sign-in screen renders without runtime errors.
- [ ] Complete a fresh Google OAuth flow and verify cloud access on the emulator.

The project is not submission-ready until the manual items and blocked security
tests are complete. No Firebase Storage/Blaze setup is required.
