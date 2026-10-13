# Submission checklist

## Implemented in source

- [x] Firebase Google Authentication flow retained.
- [x] Supabase metadata, search, and sharing service retained.
- [x] Supabase Storage client service added for private file operations.
- [x] File size/MIME allowlist and owner/document-scoped object naming added.
- [x] New migration authored for private bucket and owner/viewer/editor policies.
- [x] Firebase Storage dependency, rules, and Firebase Callable Function removed.
- [x] Cloud operations remain behind the Firebase-token/RLS profile gate.
- [x] Cloud list state is reset and stale requests are ignored when Firebase UID changes.
- [x] Client-side permission capability tests cover owner/editor/viewer behavior.
- [x] Run Flutter tests, analyzer, and Android debug build; see `TEST_RESULTS.md`.

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

The project is not submission-ready until the manual items and blocked security
tests are complete. No Firebase Storage/Blaze setup is required.
