# Database and Storage schema

## Existing Supabase relational schema

The dev/test project has the initial migration
`mm/supabase/migrations/20261013223000_initial_document_schema.sql` applied.
Read-only inspection on 2026-10-13 confirmed these tables and their RLS
policies:

- `users`: text `id` matching Firebase UID, email/profile fields and timestamps.
- `documents`: UUID, owner FK, title/description/subject/type, nullable
  `storage_path`, MIME type, size, and timestamps.
- `document_permissions`: document/user FKs, `viewer|editor` check, unique
  `(document_id,user_id)`, and the account granting access.

The initial migration also contains RPCs for search, share, list shares, and
revoke. Its remote history is present; do not edit or rerun it.

## New private storage migration

`mm/supabase/migrations/20261013233500_supabase_private_document_storage.sql`
is a new migration applied to the linked dev/test project on 2026-10-13. It
creates a private bucket named `documents`,
caps objects at 20 MiB, and allows PDF, Word, PowerPoint, PNG, and JPEG MIME
types. Object names are `<firebase-uid>/<document-uuid>/<timestamp>_<filename>`;
`documents.storage_path` stores that name, not a URL or binary.

The migration adds four RLS policies on `storage.objects`: authorized read,
owner upload, owner update, and owner delete. Shared reads require a current
document row and current permission. Editor has read access only. Owner
namespace writes are scoped to the UID derived from the verified JWT.

## Current remote verification

- Initial migration: remotely recorded as applied.
- Tables / existing database policies: found by read-only SQL query.
- `documents` bucket: `public=false`, `file_size_limit=20971520`, expected MIME
  allowlist.
- `storage.objects` policies: four policies for authenticated SELECT/INSERT/
  UPDATE/DELETE were found.
- New private-storage migration: applied and listed in the remote migration
  table (`20261013233500`).
- A restored Firebase session on the Android emulator attempted profile upsert
  and received PostgreSQL `42501` (RLS denial); the UI did not continue to
  document search. No real token claims were inspected.

Firebase ID tokens normally lack Supabase's `role: authenticated` claim. The
current RLS grants and policies target `authenticated`; a trusted server-side
claim issuer is therefore a prerequisite not represented by the schema
migrations. Do not change grants to `anon` to work around this. Review
`docs/SECURITY_MODEL.md` and `docs/CLOUD_SETUP.md` before enabling cloud use.

The only remote write in this task was the additive, non-destructive private
Storage migration to the previously confirmed dev/test project. No data or
existing migration was changed.
