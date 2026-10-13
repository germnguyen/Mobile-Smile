---
name: flutter-cloud-document-management
description: Upgrade an existing Flutter document management application with Firebase Google Authentication, Supabase PostgreSQL and Storage, document sharing, RLS, and multi-account testing. Always inspect the existing project before modifying code.
---

# Skill: Flutter Cloud Document Management

> Project-specific decision (2026-10-13): the user selected private Supabase
> Storage instead of Firebase Storage. Apply this decision throughout this
> project; Firebase Storage, Firebase Storage Rules, Firebase Callable
> Functions for file URLs, and Firebase Blaze billing are out of scope.

## 1. Mission

Upgrade the user's existing Flutter document management application to meet these requirements:

1. Google sign-in through Firebase Authentication.
2. Physical file storage through private Supabase Storage.
3. Supabase PostgreSQL tables for users, documents, and sharing permissions.
4. Document search, metadata updates, and secure sharing.
5. Supabase Row Level Security (RLS) and Supabase Storage Policies.
6. Functional and security testing with at least three independent user accounts.
7. Evidence and documentation suitable for academic submission.

This is an upgrade task, NOT a greenfield project.

## 2. Non-negotiable rules

- Never recreate the project from scratch unless the user explicitly authorizes it.
- Never modify code before inspecting the relevant existing files and architecture.
- Preserve working functionality and existing UI unless a change is necessary.
- Reuse existing models, services, providers, repositories, routes, and widgets where appropriate.
- Follow the project's existing state-management solution and coding conventions.
- Do not introduce unnecessary dependencies, architectural layers, or unrelated features.
- Use small, reviewable changes instead of replacing large files without justification.
- Never invent existing file paths, APIs, environment variables, configuration, or test results.
- Never claim a command or test passed unless it was actually executed and its result was inspected.
- Explain important changes and provide exact commands for the user to run when execution is unavailable.
- Never expose credentials, OAuth secrets, service-role keys, or private tokens.
- Never put Supabase service_role credentials in Flutter or any client-side bundle.
- Never rely on frontend visibility or disabled buttons as an authorization mechanism.
- Never treat Firebase authentication as automatically establishing a trusted Supabase identity.
- Never assume database RLS alone protects Supabase Storage objects; configure
  `storage.objects` policies separately.
- Never report completion while a required security or testing item remains unverified.

## 3. Phase 0: Inspect the existing project

Before coding:

1. Inspect the root directory and project documentation.
2. Read pubspec.yaml, lockfile, main.dart, Firebase initialization, and platform configuration.
3. Inspect the current lib/ directory, including models, services, repositories, providers, screens, routes, and reusable widgets.
4. Inspect existing Firebase Authentication, Firestore, or other database integrations.
5. Inspect current upload/download behavior and any existing document model.
6. Inspect automated tests, analysis configuration, and supported Flutter platforms.
7. Identify existing features that must be preserved.
8. Determine whether the app targets Android, iOS, Web, desktop, or multiple platforms.

Do not assume that every platform supports the same Google sign-in or storage workflow.

Create:

- docs/PROJECT_AUDIT.md
- docs/IMPLEMENTATION_PLAN.md

The audit must include:

- Current architecture and entry points.
- Existing working features.
- Missing requirements.
- Relevant files to modify or add.
- Dependencies that need to be added, removed, or upgraded.
- Platform-specific configuration.
- Risks, unresolved questions, and prerequisites.

At this stage, do not perform broad refactoring.

## 4. Phase 1: Define the architecture

Use the existing architecture as the starting point.

A preferred separation of responsibilities is:

- Presentation: existing screens and reusable widgets.
- State management: existing Provider, Riverpod, Bloc, or equivalent.
- Domain/models: user, document, and permission models.
- Services/repositories: authentication, storage, and document data access.
- Security/configuration: Firebase initialization, Supabase client, and environment configuration.

Do not introduce a new state-management library solely for this assignment.

Define the responsibilities of:

- Firebase Authentication: identity verification and session management.
- Supabase Storage: private physical file objects.
- Supabase PostgreSQL: document metadata, users, and permissions.
- Supabase RLS: database authorization.
- Supabase Storage policies: file-level authorization.
- A trusted authentication bridge: establishing a verified Firebase identity for Supabase requests.

Choose the authentication bridge only after inspecting the current project and checking compatibility with the selected Supabase configuration.

## 5. Phase 2: Firebase Google Authentication

Implement:

1. Google sign-in using Firebase Authentication.
2. Authentication state restoration and logout.
3. Loading, cancellation, and error handling.
4. A stable user identifier based on Firebase UID.
5. Synchronization of the authenticated user's profile with Supabase.
6. A safe and verified mechanism for authenticating Supabase requests.

Requirements:

- Handle users who cancel Google sign-in.
- Handle network failures and expired sessions.
- Avoid creating duplicate user records.
- Do not trust an email address or a user-supplied UID as proof of identity.
- Keep platform-specific OAuth configuration outside business logic.
- Do not expose private credentials in source control.

Do not continue to protected data operations until the authentication bridge is implemented and verified.

## 6. Phase 3: Supabase schema and migrations

Create version-controlled SQL migrations for the following tables.

### users

Suggested fields:

- id: primary key matching the verified Firebase UID.
- email.
- display_name.
- created_at.
- updated_at, if needed.

### documents

Suggested fields:

- id: UUID primary key.
- owner_id: foreign key referencing users.id.
- name.
- description, nullable.
- storage_path.
- mime_type.
- file_size, when available.
- created_at.
- updated_at.

### document_permissions

Suggested fields:

- id: UUID primary key.
- document_id: foreign key referencing documents.id.
- user_id: foreign key referencing users.id.
- permission: viewer or editor.
- created_at.

Required constraints:

- Foreign keys must reference valid records.
- A user cannot receive duplicate permission records for the same document.
- Permission values must be constrained.
- Ownership must be represented explicitly.
- Indexes must support owner lookups, permission checks, and practical search queries.

Define how user creation, document creation, permission updates, and deletion remain consistent.

Use migrations rather than relying only on manual dashboard changes.

## 7. Phase 4: Supabase Storage integration

Implement the existing project's equivalent of a storage service.

Required operations:

- Upload a file.
- Download or open a file through an authorized flow.
- Delete a file.
- Obtain file metadata where needed.
- Handle upload/download failures and cancellation where supported.

Storage policies:

- Use predictable object paths that include an ownership identifier.
- Do not use a predictable path as a substitute for authorization.
- Store a storage object path in Supabase, not the file's binary content.
- Prefer private storage objects over permanently public URLs.
- Avoid persisting expiring download URLs as the only source of truth.
- Verify the caller's identity and authorization before permitting access.
- Do not assume PostgreSQL RLS automatically applies to Supabase Storage;
  configure and test `storage.objects` policies.

For shared-file reads, use Supabase Storage policies to check the current
verified identity and document permission. Use a trusted backend only if the
Firebase token cannot be verified by the Supabase Third-Party Auth integration.

Handle failures between storage and database operations. For example, if upload succeeds but metadata insertion fails, define a cleanup or retry strategy so orphaned files can be detected and recovered.

## 8. Phase 5: Document management

Implement only the functionality needed for the assignment and preserve equivalent existing features.

Required capabilities:

- List accessible documents.
- Search by document name and, where appropriate, description.
- Display document metadata.
- Update permitted metadata.
- Upload new documents.
- Download or open authorized files.
- Delete documents only when the current user is authorized.
- Handle empty states, loading states, and errors.

Ensure that:

- Database operations use the authenticated client.
- User input is validated.
- Search is implemented efficiently.
- Unauthorized requests fail at the data/security layer.
- UI components do not directly contain database authorization logic.
- Existing screens and navigation are preserved when possible.

## 9. Phase 6: Document sharing and authorization

Implement a sharing workflow that allows a document owner to:

1. Identify another registered user.
2. Grant viewer or editor access.
3. View current sharing permissions.
4. Change or revoke a permission.
5. Prevent unauthorized users from managing sharing settings.

Recommended authorization policy:

| Action | Owner | Viewer | Editor | Unshared user |
|---|---|---|---|---|
| Read metadata | Allow | Allow | Allow | Deny |
| Read file | Allow | Allow | Allow | Deny |
| Update metadata | Allow | Deny | Allow | Deny |
| Delete document | Allow | Deny | Deny | Deny |
| Manage permissions | Allow | Deny | Deny | Deny |

Do not permit users to grant themselves access or change document ownership by directly manipulating database requests.

Prevent unauthorized permission escalation and duplicate permission records.

## 10. Phase 7: Supabase RLS and Storage policies

RLS is mandatory.

For every relevant table:

1. Enable RLS.
2. Identify the trusted authenticated identity available to policies.
3. Write separate policies for SELECT, INSERT, UPDATE, and DELETE as applicable.
4. Verify ownership and sharing permissions.
5. Restrict permission management to document owners.
6. Prevent clients from assigning arbitrary owner IDs or trusted identity claims.
7. Test access through the actual client authentication mechanism.

Do not copy policies that assume auth.uid() automatically returns the Firebase UID unless the selected authentication bridge actually guarantees that mapping.

If Firebase JWT verification is performed by a backend, ensure that the backend verifies the signature, issuer, audience, expiration, and required identity claims.

Configure Supabase Storage policies independently from metadata-table RLS:

- Owners can access their own files.
- Authorized viewers and editors can read shared files.
- Only owners can upload, replace, or delete files.
- File paths, document ownership, and sharing permissions cannot be forged by a client.
- Enforce reasonable file-size and content-type restrictions where appropriate.

Use least privilege.

Do not claim the security model is complete until cross-account tests have verified it.

## 11. Phase 8: Testing with at least three accounts

Use three independent accounts, identified in the report as:

- Account A: document owner.
- Account B: authorized recipient.
- Account C: unrelated user without permission.

Required test scenarios:

1. Each account can sign in independently.
2. Each account has the correct profile record.
3. A can upload a document.
4. A can find and update its own document.
5. A can share a document with B as viewer.
6. B can see and read the shared document.
7. B cannot update or delete the document as viewer.
8. C cannot see or read A's private document.
9. Direct unauthorized metadata queries are denied or return no unauthorized records.
10. Direct unauthorized file access is denied.
11. A can revoke B's permission.
12. B loses access after revocation.
13. An editor can update permitted metadata but cannot delete the document or manage sharing.
14. Invalid users and duplicate permission requests are handled safely.
15. Storage failures and database failures do not silently corrupt document metadata.

Add further tests for owner access, editor access, missing files, expired sessions, and invalid inputs.

Use the actual configured authentication flow for security tests. Do not
substitute mocked authorization tests for end-to-end database RLS and Storage
policy verification.

Record each test's:

- Test ID.
- Preconditions.
- Steps.
- Expected result.
- Actual result.
- Pass/fail status.
- Evidence or logs.

Never fabricate test results or screenshots.

## 12. Phase 9: Verification and submission readiness

After implementation:

- Run dependency resolution.
- Run formatting and static analysis.
- Run existing and new automated tests.
- Build for the required target platform where possible.
- Test the actual authentication, database, and storage integration.
- Verify the three-account authorization matrix.
- Review database migrations and security policies.
- Check for committed secrets.
- Update documentation.

Create or update:

- docs/PROJECT_AUDIT.md
- docs/IMPLEMENTATION_PLAN.md
- docs/DATABASE_SCHEMA.md
- docs/SECURITY_MODEL.md
- docs/TEST_PLAN.md
- docs/TEST_RESULTS.md
- docs/SUBMISSION_CHECKLIST.md

Provide a final requirement-by-requirement report:

- Requirement.
- Implementation location.
- Verification method.
- Actual result.
- Remaining issues.

Separate completed, partially completed, and unverified items.

## 13. Execution protocol

Work in small phases.

For each phase:

1. Inspect the relevant existing code.
2. Explain the intended changes.
3. Identify files to add or modify.
4. Implement the smallest coherent change.
5. Run appropriate checks.
6. Report modified files and results.
7. Record unresolved issues.
8. Continue only when prerequisites are satisfied.

If credentials, dashboard access, OAuth configuration, or user input are missing, identify the exact blocker and provide the required manual steps. Do not invent configuration values.

If a test fails, investigate the cause before moving on. Do not hide failures by weakening security policies or deleting tests.

## 14. Definition of done

The project is ready for submission only when:

- Google authentication works on the required platform.
- Supabase contains the required relational tables and constraints.
- File objects are stored in private Supabase Storage.
- Metadata and file references remain consistent.
- Search and metadata updates work.
- Sharing and revocation work.
- RLS is enabled and verified.
- Supabase Storage policies are configured and verified.
- Three independent accounts have been tested.
- Unauthorized access attempts are denied.
- Required tests and documentation are available.
- Remaining limitations are explicitly reported.

Passing a build alone is not sufficient evidence of completion.
