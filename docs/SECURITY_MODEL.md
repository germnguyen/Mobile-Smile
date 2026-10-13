# Security model

## Identity

Firebase Authentication verifies Google sign-in and provides the current
Firebase ID token. The Flutter Supabase client supplies that token through its
`accessToken` callback. This code-level bridge is **not proof** that the
Supabase project is configured to verify the Firebase issuer/audience.

The database policies read `sub` from the provider-verified JWT and expect it
to match the Firebase UID. The app must successfully upsert its own `users`
profile under RLS before it loads documents. A failed upsert locks the cloud
list behind an error/retry state. Do not remove RLS, trust client-supplied UID,
or expose data anonymously to bypass a bridge failure.

**Role claim blocker:** Firebase ID tokens do not normally include a
`role` claim. Supabase therefore assigns the Postgres `anon` role by default,
but the current schema grants protected operations only to `authenticated`.
The Firebase Third-Party Auth integration verifies the provider; it does not
by itself add `role: authenticated` to the Firebase token. This repository has
no trusted claim issuer. A server-side Firebase Authentication blocking
function (Identity Platform) or Firebase Authentication function/Admin SDK
process is needed for existing/new users. Until configured, the expected
profile upsert is denied and cloud access must remain closed.

Required manual verification: configure Firebase Third-Party Auth and a
trusted role-claim issuer, then sign in and prove a real token is accepted,
`iss`/`aud` identify the configured Firebase project, `sub` is the Firebase UID,
`exp` is valid, and `role` is `authenticated`. Do not log the token. If this
cannot be provisioned without billing, stop cloud authorization work rather
than weakening the RLS role boundary.
If this provider cannot be enabled or verified, protected operations must
remain blocked until a trusted backend/Edge Function verifies the Firebase
signature, issuer, audience, expiration, and subject.

## Authorization matrix

| Operation | Owner | Viewer | Editor | Unshared/anonymous |
|---|---:|---:|---:|---:|
| Read metadata | Allow | Allow | Allow | Deny |
| Read file | Allow | Allow | Allow | Deny |
| Upload/replace file | Allow | Deny | Deny | Deny |
| Update permitted metadata | Allow | Deny | Allow | Deny |
| Delete document/file | Allow | Deny | Deny | Deny |
| Share/change/revoke permissions | Allow | Deny | Deny | Deny |

Supabase PostgreSQL policies enforce metadata access. Supabase Storage has a
separate RLS layer on `storage.objects`; database RLS alone does not protect
object bytes. The new storage policies allow shared reads only when the
document path still matches an accessible row. Upload/update/delete policies
require the UID folder to match the verified token; upload also requires
ownership of the referenced document.

The bucket is private. Signed download URLs expire after 60 seconds and are
bearer credentials during that window; revocation is not instantaneous for a
URL already issued.

## Integrity and secrets

- Only a Supabase publishable key is present in Flutter. Never put a Supabase
  secret/service-role key or Firebase Admin credential in the client/repo.
- Supabase Storage/PostgreSQL are not a cross-service transaction. Upload
  replacement before swapping metadata, compensate on metadata failure, and
  report cleanup failures with the affected object path.
- If an app process is terminated or a request times out ambiguously, a private
  unreferenced object may remain. Reconcile object names with
  `documents.storage_path`; do not expose or delete unrelated objects.
- Storage MIME and size restrictions are configured in the bucket and checked
  in the client, but MIME supplied by a client is not content inspection.

## Verification status

RLS definitions exist in both applied migrations, and read-only queries confirm
the bucket is private and the four storage policies exist. Real Firebase-token
and cross-account enforcement remains unverified. On the Android emulator an
existing Firebase session was restored, but the `users` profile upsert received
a PostgreSQL `42501` RLS denial; the app correctly did not continue to
document search. This confirms the fail-closed UI path, not the token's
claims/provider configuration. Do not mark security complete until a trusted
role issuer is configured and A/B/C tests pass.
