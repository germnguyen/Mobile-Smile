# Test plan

## Automated local tests

- Preserve existing Drift/document service and database tests.
- Unit-test Supabase Storage path construction, MIME mapping, unsafe path
  rejection, empty file handling, supported format validation, and the 20 MiB
  bound.
- Unit-test the UI model's owner/editor/viewer edit capability decisions. These
  tests do not replace database/Storage RLS enforcement tests.
- Verify that changing Firebase accounts clears the previous account's
  document list and ignores results from stale in-flight searches.
- After implementation, run Flutter tests, analysis, and Android debug build.

## Cloud matrix (not yet executed)

Use three independent Firebase/Google accounts. Record actual UIDs privately
in the test evidence, not in a public document.

| Case | Account | Action | Expected |
|---|---|---|---|
| AUTH-A/B/C | A, B, C | Google login, restore, logout | Each maps to its own verified Firebase UID |
| AUTH-ROLE | A, B, C | Inspect verified token claims without logging token | Correct `iss`, `aud`, `sub`, valid `exp`, and trusted `role: authenticated`; absent role must remain denied by current grants |
| OWN-01 | A | Create/upload/search/update/replace/download/delete | Own metadata and file operations succeed |
| SHARE-01 | A | Share to B as viewer | Only owner manages the grant |
| VIEW-01 | B | Read metadata and create short-lived file URL | Allowed while grant exists |
| VIEW-02 | B | Update metadata, upload, replace, delete, share | Denied as viewer |
| EDIT-01 | A | Change B to editor | Grant updates to editor |
| EDIT-02 | B | Update metadata; try file write/delete/share | Metadata allowed; file write/delete/share denied |
| OUT-01 | C | Query A's metadata or file directly | No rows/file access and URL creation denied |
| REVOKE-01 | A then B | Revoke B and retry metadata/file access | Denied after revoke; already-issued URL may work only until its 60s expiry |
| TOKEN-01 | Any | Invalid/expired Firebase token | Protected operations fail closed |
| INTEGRITY-01 | A | Force upload/database failure, replace failure, delete cleanup failure | Explicit error; old file retained for failed replace; cleanup path surfaced |

For each cloud case record preconditions, steps, expected/actual output,
pass/fail, timestamp, and sanitized evidence. Never save ID tokens or signed
URLs in the evidence.
