# Implementation plan — Document Management

## Current decision and status

The user selected this architecture on 2026-10-13:

- Flutter Android UI.
- Firebase Authentication for Google sign-in and verified Firebase UID/ID token.
- Supabase PostgreSQL for profile, document metadata, and sharing permissions.
- Private Supabase Storage for file bytes, governed by Storage RLS policies.
- No Firebase Storage, Firebase Storage Rules, Firebase Callable Function,
  Firebase Blaze upgrade, or service-role key in the mobile app.

Implementation continues in the existing Flutter app and keeps its Material
UI, `setState`, `AppDependencies`, local Drift code, and existing tests. Cloud
data remains gated behind a successful profile upsert constrained by RLS.

## Implemented locally

1. Firebase Google Auth, session restore, logout, and sign-in cancellation/error
   handling remain in the existing Auth flow.
2. Existing Supabase metadata/RPC/RLS schema remains in place; its initial
   applied migration is not edited or replayed.
3. `SupabaseStorageService` targets a private `documents` bucket, validates
   supported MIME types and the 20 MiB limit, uses UID/document-scoped stable
   paths, creates 60-second signed download links, and deletes objects.
4. Document creation uploads to Supabase Storage and writes the object path
   into Supabase metadata. Replacement uploads the new object before switching
   metadata, then removes the old object. Document deletion reports any
   post-metadata object cleanup failure explicitly.
5. A new migration configures the private bucket and owner/viewer/editor
   Storage policies. It has been applied to the linked dev/test project and
   verified with read-only SQL.
6. Firebase Storage and Firebase Functions are removed from app dependencies
   and Firebase-only backend/rules files are removed.

## Identity and authorization gate

Supabase Third-Party Auth configuration and real-token claims are not verifiable
from source alone. The app passes Firebase ID tokens via Supabase Flutter's
`accessToken` callback. The existing users-table RLS requires the server-
verified `sub` to equal the Firebase UID. Firebase tokens do not normally
contain Supabase's required `role: authenticated` claim; without a trusted
server-side claim issuer, Supabase maps them to `anon` and the current table
grants/policies reject profile sync. No claim issuer is implemented in this
repository. A successful profile upsert must precede document search. If the
upsert is rejected, the app must show an error and must not load protected
data. No identity is inferred from a client-provided email or UID.

## Dependencies and execution order

1. Enable and verify Firebase Google provider and Android OAuth config.
2. Choose and provision a trusted issuer for `role: authenticated` on Firebase
   ID tokens. If billing/Identity Platform constraints prevent this, cloud CRUD
   remains blocked; do not broaden `anon` grants or weaken RLS.
3. Enable/configure Firebase Third-Party Auth in Supabase; validate a real
   Firebase ID token and confirm issuer, audience, subject, expiry, and role
   before cloud operations.
4. Review
   `mm/supabase/migrations/20261013233500_supabase_private_document_storage.sql`
   and confirm the private 20 MiB bucket and Storage policies in the Dashboard.
   The linked project is dev/test and the migration has been applied; do not
   apply this migration to production without explicit approval.
5. Validate CRUD/search/share using RLS with A (owner), B (viewer/editor), and
   C (unrelated). Validate Storage policies directly as well.
6. Run local tests/analyze/Android build, then record three-account results.

## Integrity limitations to verify

Supabase Storage and PostgreSQL do not share a transaction. The client
compensates by removing newly uploaded objects when metadata updates fail, and
by reporting exact object paths when cleanup fails. A process termination or
ambiguous network failure can still leave a private orphan object; reconcile
by comparing `storage.objects` against `documents.storage_path`. Do not report
cross-service operations as atomic.

## Acceptance gates

- Google Auth restores sessions and sign-out works on Android.
- Supabase rejects protected requests unless the Firebase token is verified
  and the token subject is the Firebase UID.
- Owner/viewer/editor/outsider database and file operations match the
  authorization matrix in `docs/SECURITY_MODEL.md`.
- Search, metadata editing, upload, replacement, download, sharing, revocation,
  and deletion handle errors without success-shaped fallbacks.
- Existing tests pass; cloud-only checks are marked blocked until performed
  against the real projects and three accounts.
