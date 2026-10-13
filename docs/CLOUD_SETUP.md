# Cloud setup: Firebase Auth + Supabase

The current target architecture is Flutter Android, Firebase Authentication
(Google sign-in), Supabase PostgreSQL, and a **private Supabase Storage**
bucket. Firebase Storage, its rules, Firebase Functions, and Blaze billing are
not part of this design.

Do not place Supabase secret/service-role keys or Firebase Admin credentials in
the app, repository, or chat. The Android Firebase configuration and Supabase
publishable key are client configuration, not server secrets.

## Current cloud state

- Firebase Android app `com.example.mm` is registered in
  `document-management-ecf5c`; Google provider/runtime sign-in still needs
  verification in Firebase Console.
- Supabase project `fzzsffkeajsqjjaljojk` is linked in the CLI. The initial
  schema migration is recorded remotely.
- Read-only checks confirm the three existing database tables have their
  expected RLS policies, and the `documents` bucket is private with four
  `storage.objects` policies.
- Firebase Third-Party Auth/JWT configuration has not been confirmed. The app
  only enters cloud data after the profile upsert succeeds under RLS; until
  that succeeds, cloud CRUD is not verified or available.
- Emulator startup restored an existing Firebase session, but the profile
  upsert was rejected with PostgreSQL `42501` (row-level security violation).
  The UI stayed fail-closed and did not continue to document search. This does
  not identify the exact JWT claim/configuration cause and is not proof that
  Firebase Third-Party Auth accepts the token.
- The new Supabase Storage migration was applied to the linked dev/test project
  on 2026-10-13. A read-only query confirmed its migration record.
- No Firebase Storage bucket, Firebase Storage Rules, or Firebase Function is
  created or deployed.

## Supabase identity bridge

The client supplies the current Firebase ID token through Supabase Flutter's
`accessToken` callback. On the Supabase project, enable/configure Firebase as a
Third-Party Auth provider and confirm the provider project/audience matches the
Firebase project. The database policies expect the provider-verified JWT claim
`sub` to equal the Firebase UID; the client does not send a trusted UID claim.

**Important role prerequisite:** Firebase ID tokens do not normally contain a
`role` claim. Supabase maps a token without that claim to the PostgreSQL `anon`
role, while the current database grants and policies target `authenticated`.
Merely adding Firebase as a Supabase Third-Party Auth provider does not prove
that the custom `role: authenticated` claim is issued. Before profile sync or
cloud CRUD can pass, configure a trusted server-side claim issuer (for example
a Firebase blocking Authentication function, which requires Identity
Platform, or a Firebase Authentication function with the required billing
configuration), then sign in/refresh and verify the role on a real token
without logging it. Never add this claim in Flutter: client-controlled claims
are not trusted. No such claim issuer is present in this repository.

`ensureProfile()` performs an upsert constrained by RLS to the verified token
subject and token email. Its success is the runtime gate before document search
is requested. If it is rejected, keep cloud data closed and inspect the
Supabase Third-Party Auth settings/JWT claims, including `iss`, `aud`, `sub`,
`exp`, and `role`; do not disable RLS or substitute an unverified UID.

## Create the private Supabase Storage bucket

The migration
`mm/supabase/migrations/20261013233500_supabase_private_document_storage.sql`
was applied to the linked **development/test** project, not production:

The migration created/set the `documents` bucket to private, limits objects
to 20 MiB and the supported document/image MIME types, and installs the
following `storage.objects` authorization policies:

- Owner: read/upload/replace/delete within the UID/document path.
- Viewer/editor: read only when the current document metadata and permission
  row authorize the signed Firebase subject.
- Unshared users and anonymous users: no object read/write policy.
- Editors cannot write or delete objects.

Read-only verification confirmed the bucket is private, has a 20 MiB limit,
and has the declared MIME allowlist; four policies exist for `storage.objects`.
The applied migration records can be inspected from `mm/` with:

```powershell
npx supabase db query --linked "select version, name from supabase_migrations.schema_migrations where version in ('20261013223000', '20261013233500') order by version;"
```

Do not manually recreate or duplicate the bucket/policies. Do not rerun or edit
the already-applied initial migration.

Object names are stable paths stored in `documents.storage_path`, in the form
`<firebase-uid>/<document-uuid>/<timestamp>_<safe-filename>`. The bucket name
is not included in `storage_path`. File bytes are never stored in PostgreSQL.
Downloads use a 60-second Supabase signed URL created only after a document
query allowed by RLS; a signed URL is a bearer credential until expiry, so a
revoked share may retain access for at most that short lifetime.

## Three-account verification

Use three independent Firebase accounts and record actual results:

| Account | Expected verification |
|---|---|
| A — owner | Create/search/edit/upload/replace/download/share/revoke/delete own documents |
| B — recipient | Viewer can read but not write; editor can update metadata but cannot replace/delete/share; access ends after revoke and any existing 60-second URL expires |
| C — unrelated | Cannot query metadata or obtain/read/write an object |

Also test failed/expired Firebase tokens, failed uploads, metadata failures,
delete cleanup errors, and direct Storage API calls. Unit tests and local
mocks do not prove cloud RLS or Storage behavior. Do not log tokens or signed
URLs.

## Remaining manual actions

1. In Supabase Dashboard, verify/configure the Firebase Third-Party Auth
   provider and validate a real Firebase ID token's verified `sub` and
   `role: authenticated`.
2. Review the existing migration and confirm the private bucket/four policies
   in the Supabase Dashboard; no further database deployment is needed.
3. In Firebase Console, enable Google as an Authentication provider and verify
   the Android OAuth configuration.
4. Configure a trusted role-claim issuer for existing and newly created
   Firebase users. This is not implemented by the mobile app; cloud access
   remains blocked until this prerequisite is satisfied.
5. Run the app with accounts A, B, and C and record real pass/fail evidence.
