# PHASE 01 — Audit hiện trạng dự án

**Ngày khảo sát:** 2026-10-21  
**Phạm vi:** Source/config liên quan Firebase Auth, Google Sign-In, Supabase, profile, documents, permissions, Storage và RLS.  
**Trạng thái:** Báo cáo chờ người dùng kiểm tra. Đây không phải xác nhận phê duyệt hay hoàn tất migration.

## 1. Tóm tắt

Source hiện dùng Google Sign-In để lấy Google ID token, sau đó đăng nhập Firebase Auth bằng credential Google. Supabase chưa cấp session Auth riêng cho ứng dụng: client Supabase được cấu hình lấy Firebase ID token làm access token. Vì vậy `auth.uid`/claim `sub` theo các migration hiện có, profile ID, document owner ID, permission user ID và UID đầu đường dẫn object đều theo Firebase UID.

Các migration có trong repository mô tả bảng `users`, `documents`, `document_permissions`, RLS và bucket private `documents`. Chúng **không chứng minh** schema, policies, functions hoặc bucket hiện đang deploy trên Supabase. Không truy cập dashboard/database trong audit này.

## 2. File đã kiểm tra

### Điều phối và migration

| File | Phạm vi đã kiểm tra |
|---|---|
| [`mm/AGENTS.md`](../../AGENTS.md) | Quy tắc scope, bảo mật, trạng thái phase |
| [`MIGRATION_CONTEXT.md`](../MIGRATION_CONTEXT.md) | Mục tiêu, quyết định, dữ kiện backend lịch sử và rủi ro UID |
| [`MIGRATION_PROGRESS.md`](../MIGRATION_PROGRESS.md) | Trạng thái phase trước audit |
| [`PHASE_01_AUDIT.md`](../phases/PHASE_01_AUDIT.md) | Checklist/phạm vi của Phase 01 |
| [`20261013223000_initial_document_schema.sql`](../../supabase/migrations/20261013223000_initial_document_schema.sql) | Bảng, functions, sharing RPC, RLS và policies theo Firebase UID |
| [`20261013233500_supabase_private_document_storage.sql`](../../supabase/migrations/20261013233500_supabase_private_document_storage.sql) | Bucket private và Storage policies |
| [`config.toml`](../../supabase/config.toml) | Cấu hình Supabase CLI/local có trong repo; network restrictions local đang tắt và các CIDR được đặt allow-all, không dùng để suy ra trạng thái project hosted |

### Source ứng dụng, cấu hình và tests liên quan

| File | Phạm vi đã kiểm tra |
|---|---|
| [`main.dart`](../../lib/main.dart#L14) | Khởi tạo Firebase, Google Sign-In, Supabase và access-token provider |
| [`app_dependencies.dart`](../../lib/config/app_dependencies.dart) | Khởi tạo và wiring Auth/document services |
| [`auth_service.dart`](../../lib/services/auth_service.dart#L41) | Google authentication, Firebase credential, auth state và sign-out |
| [`auth_gate.dart`](../../lib/pages/auth_gate.dart) | Điều hướng theo Firebase auth state |
| [`sign_in_page.dart`](../../lib/pages/sign_in_page.dart) | UI đăng nhập và xử lý lỗi Firebase |
| [`signed_in_page.dart`](../../lib/pages/signed_in_page.dart#L54) | Đồng bộ profile trước khi tải tài liệu |
| [`firebase_supabase_token_provider.dart`](../../lib/services/firebase_supabase_token_provider.dart#L44) | Lấy/xác thực Firebase token và cấp cho Supabase |
| [`cloud_document_service.dart`](../../lib/services/cloud_document_service.dart#L14) | Profile, CRUD/search documents, sharing, download URI và user ID hiện tại |
| [`supabase_storage_service.dart`](../../lib/services/supabase_storage_service.dart#L10) | Bucket, object path, upload/download URL/delete |
| [`cloud_document.dart`](../../lib/models/cloud_document.dart) | Ánh xạ document/permission và quyền owner/editor phía UI |
| [`pubspec.yaml`](../../pubspec.yaml#L40) và [`pubspec.lock`](../../pubspec.lock#L340) | Dependency trực tiếp và phiên bản đã khóa |
| [`build.gradle.kts`](../../android/app/build.gradle.kts#L1) | Android Google Services plugin |
| [`settings.gradle.kts`](../../android/settings.gradle.kts#L20) | Phiên bản Google Services Gradle plugin |
| [`AndroidManifest.xml`](../../android/app/src/main/AndroidManifest.xml) | Activity và intent filters Android |
| [`auth_service_test.dart`](../../test/auth_service_test.dart) | Kỳ vọng luồng Google → Firebase |
| [`cloud_document_profile_test.dart`](../../test/cloud_document_profile_test.dart) | Kỳ vọng profile gắn Firebase UID |
| [`firebase_supabase_token_provider_test.dart`](../../test/firebase_supabase_token_provider_test.dart#L29) | Kỳ vọng claim token, gồm role `authenticated` |

`android/app/google-services.json` được xác nhận có mặt và được tìm thấy trong search cấu hình Firebase; không sao chép giá trị cấu hình nhạy cảm vào báo cáo. Không mở rộng khảo sát sang các chức năng nghiệp vụ không liên quan.

## 3. Luồng hiện tại đã xác minh từ source

```text
Ứng dụng khởi động
  → Firebase.initializeApp()
  → GoogleSignIn.initialize()
  → Supabase.initialize(accessToken: FirebaseSupabaseTokenProvider.call)
  → AuthGate nghe FirebaseAuth.authStateChanges()
  → Google Sign-In trả Google ID token
  → FirebaseAuth.signInWithCredential(GoogleAuthProvider credential)
  → Firebase User/UID trở thành danh tính ứng dụng
  → SignedInPage upsert public.users với id = Firebase UID
  → Supabase request mang Firebase ID token
  → RLS lấy auth.jwt()->>'sub' làm Firebase UID
  → documents.owner_id / document_permissions.user_id đối chiếu UID đó
  → Tệp tải lên Supabase Storage bucket `documents`
     với path `<owner UID>/<document UUID>/<timestamp>_<filename>`
  → Chia sẻ/gỡ chia sẻ/liệt kê chia sẻ qua RPC Supabase
```

Sign-out hiện gọi Firebase sign-out rồi Google Sign-In sign-out. Không thấy luồng đăng nhập Supabase Auth (`signInWithOAuth`, Supabase Auth session/state listener) trong các file liên quan đã tìm.

## 4. Auth, profile và UID

- [`auth_service.dart`](../../lib/services/auth_service.dart#L41) gọi Google Sign-In, lấy ID token và truyền token đó vào Firebase `signInWithCredential`; stream/current user cũng lấy từ Firebase Auth.
- [`firebase_supabase_token_provider.dart`](../../lib/services/firebase_supabase_token_provider.dart#L44) đọc Firebase user/token, kiểm tra `sub == uid`, issuer Firebase, audience project Firebase và expiration trước khi trả token cho Supabase.
- [`cloud_document_service.dart`](../../lib/services/cloud_document_service.dart#L28) upsert profile vào `users` với `id = user.uid`; email/display name/avatar đến từ Firebase user. Các truy vấn document tiếp tục dùng Firebase UID làm `owner_id`/`user_id`.
- Hai migration định nghĩa `public.users.id` là `text`, documents và permissions tham chiếu `public.users(id)`. Không có bảng/logic UID mapping Firebase ↔ Supabase Auth trong migrations đã khảo sát.
- **Rủi ro UID:** Khi đổi provider, Supabase Auth UID không mặc định bằng Firebase UID. Chuyển identity mà không có mapping được kiểm toán có thể làm mất quyền đọc/chỉnh sửa/chia sẻ, sai owner khi tạo document hoặc tạo profile trùng. Không được đổi owner/permission hàng loạt chỉ theo email hay giả định UID giống nhau.

## 5. Documents, permissions, Storage và RLS

### Source migration trong repository

- Migration [`20261013223000_initial_document_schema.sql`](../../supabase/migrations/20261013223000_initial_document_schema.sql#L9) khai báo `users`, `documents` và `document_permissions`. Permission chỉ nhận `viewer`/`editor`; unique theo cặp document/recipient; `owner_id`, `user_id`, `shared_by` tham chiếu `users.id`.
- Function `app_private.current_firebase_uid()` lấy JWT claim `sub`; các helper owner/read/edit và policies sử dụng giá trị đó. RLS được bật trên ba bảng. Policy document cho phép đọc theo owner hoặc permission, chỉnh sửa theo owner/editor, xóa theo owner. Quản lý sharing được giới hạn cho owner.
- `share_document_with_email`, `revoke_document_share`, `list_document_shares` xử lý chia sẻ qua RPC; recipients được tìm từ `users.email`.
- Migration [`20261013233500_supabase_private_document_storage.sql`](../../supabase/migrations/20261013233500_supabase_private_document_storage.sql#L5) khai báo bucket `documents` private, giới hạn 20 MiB và danh sách MIME types. Policies insert/update/delete dựa trên Firebase UID ở đoạn đầu object path; select cho phép owner hoặc người có quyền đọc document.

### Source ứng dụng

- [`cloud_document_service.dart`](../../lib/services/cloud_document_service.dart#L28): profile được upsert trước khi trang signed-in tải documents.
- Tìm kiếm gọi RPC `search_documents`, sau đó truy vấn `document_permissions` để gắn quyền cho UI. CRUD gọi trực tiếp bảng `documents`; share/revoke/list gọi các RPC có tên tương ứng.
- [`supabase_storage_service.dart`](../../lib/services/supabase_storage_service.dart#L10): bucket tên `documents`; object path mang owner UID và document ID; upload binary, tạo signed URL có thời hạn 60 giây, xóa object. Giới hạn client là 20 MiB và allowlist phần mở rộng/MIME type.
- Xóa document xóa metadata trước rồi xóa object; lỗi xóa object được báo lại, do đó có thể còn object orphan nếu bước Storage thất bại. Đây là behavior/rủi ro cần tính vào kiểm thử/rollback sau này, không được thay đổi trong Phase 01.

## 6. Dependencies Firebase còn dùng

| Dependency/cấu hình | Phiên bản đã khóa / vị trí | Công dụng hiện thấy |
|---|---|---|
| `firebase_core` | 4.15.0; khai báo trực tiếp trong `pubspec.yaml` | Khởi tạo Firebase app và lấy project config cho token provider |
| `firebase_auth` | 6.7.0; khai báo trực tiếp | Firebase sign-in/session/auth state, ID token và UID; còn được dùng trong Auth UI, profile/document service |
| `google_sign_in` | 7.2.0; khai báo trực tiếp | Chọn tài khoản Google và lấy Google ID token |
| Google Services Gradle plugin | `android/app/build.gradle.kts`; version plugin khai báo ở `android/settings.gradle.kts` | Tích hợp cấu hình Google/Firebase cho Android |
| `google-services.json` | `android/app/google-services.json` | Cấu hình Firebase Android; không đưa nội dung vào báo cáo |

Supabase Flutter là dependency trực tiếp (`^2.18.3` trong manifest); phiên bản khóa là `2.18.3`. Trong source/config có khảo sát, không tìm thấy Firebase Firestore hoặc Firebase Storage API/package; tài liệu dùng Supabase Postgres/Storage. Đây là kết quả search trong vùng app source và platform config, không phải khẳng định về dịch vụ ngoài repository.

## 7. Rủi ro / điểm cần xác minh

| Mức | Phát hiện | Ảnh hưởng / đề nghị |
|---|---|---|
| Cao | Firebase UID đang là khóa xuyên suốt profile, documents, sharing và Storage path; không có UID mapping | Trước Phase 04 cần inventory UID/profile/doc/permission thực tế, quyết định mapping và xử lý account chưa đăng nhập lại/email trùng; không sửa dữ liệu ở phase audit |
| Cao | Migration trong repo dựa trên `current_firebase_uid()`/Firebase JWT, nhưng không có bằng chứng chúng khớp với cấu hình live | Lấy schema/policy/function/bucket từ project đúng môi trường trước khi thiết kế thay đổi; không áp migration dựa trên tài liệu lịch sử |
| Cao | Token provider gọi RPC `debug_auth_context` trong callback cấp access token ([`firebase_supabase_token_provider.dart`](../../lib/services/firebase_supabase_token_provider.dart#L81)); không tìm thấy function này trong migrations/repo được khảo sát | Xác minh function có tồn tại trên server. Vì RPC được gọi từ callback cấp token của cùng Supabase client, cần kiểm thử rõ nguy cơ request lồng nhau/đệ quy, lỗi khi function không tồn tại và ảnh hưởng mọi request; chưa chạy runtime test trong audit |
| Trung bình | Test token provider kỳ vọng thiếu role `authenticated` sẽ bị từ chối, còn implementation đã đọc kiểm tra `sub`, `aud`, `iss`, expiry nhưng không thấy check role tương ứng | Test/source hiện có khả năng không đồng nhất; chạy test có kiểm soát và quyết định invariant token trước khi thay auth. Audit không chạy test nên đây là phát hiện tĩnh, chưa phải kết quả test |
| Trung bình | Source in Firebase UID và claims vào debug log; token provider cũng log phản hồi RPC debug | Tránh đưa claim/profile metadata hoặc nội dung auth context vào log phát hành; xác minh log chỉ ở debug builds và xóa/tắt theo chính sách trước production |
| Trung bình | AndroidManifest chỉ có launcher intent filter trong file đọc; chưa thấy callback/deep-link scheme OAuth trong manifest | Xác nhận callback/redirect architecture cần cho OAuth được chọn và kiểm thử trên thiết bị ở phase phù hợp; không suy ra cấu hình dashboard từ manifest |
| Trung bình | Luồng xóa tài liệu xóa row trước object; nếu Storage delete lỗi, file có thể còn lại trong bucket | Phase kiểm thử cần có tình huống lỗi dọn file/orphan và quy trình xử lý rõ; không sửa trong audit |

Không phát hiện hoặc kiểm chứng bất kỳ secret/token nào trong báo cáo. Giá trị cấu hình public client không được sao chép.

## 8. Thông tin còn thiếu cần người dùng/backend cung cấp

1. **Live Supabase schema:** cấu trúc hiện tại của `users`, `documents`, `document_permissions`; constraints/indexes; toàn bộ RLS policies; functions/triggers và quyền execute. Xác nhận đúng project/environment mà app đang dùng.
2. **Live Storage:** bucket `documents` có tồn tại, private/public, giới hạn dung lượng/MIME và policies `storage.objects` đang deploy; xác nhận path và dữ liệu object thật.
3. **RPC debug:** function `debug_auth_context` có tồn tại không, nội dung/return fields là gì và vì sao được gọi trong token callback. Không gửi giá trị token hoặc secret.
4. **Identity inventory:** số lượng/đặc tính profile Firebase UID, email trùng, tài liệu ownership, records chia sẻ và tài khoản chưa đăng nhập lại. Chỉ cung cấp dữ liệu đã ẩn danh; không cần gửi PII hoặc token.
5. **OAuth hiện tại/mục tiêu:** provider nào đang bật ở Supabase Auth, trạng thái cấu hình Google OAuth, các client/platform và redirect URLs đã đăng ký. Không gửi client secret.
6. **Platforms cần hỗ trợ và callback:** xác nhận Android-only hay cả iOS/web/desktop, redirect scheme/host dự định và cách người dùng quay lại app.
7. **Migration safety:** môi trường test/staging, cách tạo backup/restore và yêu cầu rollback trước bất kỳ thay đổi schema/dữ liệu production nào.

## 9. Định hướng phase sau — chỉ là đề xuất, chưa thực hiện

- Phase 02: xác nhận Google OAuth provider, client IDs và redirect URLs theo platform; kiểm chứng bằng cấu hình/test môi trường phù hợp.
- Phase 03: thiết kế chuyển UI/session/logout sang Supabase Auth; giữ Firebase packages/config cho đến khi parity và kiểm thử được người dùng duyệt.
- Phase 04: chỉ sau khi nhận schema live và duyệt kế hoạch, thiết kế UID mapping cùng thay đổi RLS theo nguyên tắc quyền tối thiểu; kiểm thử staging, backup và rollback trước production.
- Phase 05: kiểm tra ownership/sharing, Storage upload/download/delete và lỗi dọn file; chỉ đề xuất dọn Firebase sau khi luồng mới được xác nhận.

## 10. Thực hiện và giới hạn xác minh

- Đã đọc các file liệt kê ở mục 2 và tìm có giới hạn trong source/config/migrations liên quan.
- Đã chạy `git status --short` để ghi nhận trạng thái worktree trước sửa tài liệu.
- Không chạy test, build hoặc thay đổi cấu hình.
- Không kết nối Supabase/Firebase, không truy vấn database, không chạy SQL.
- Không sửa source code nghiệp vụ, không thay đổi dữ liệu/schema/policies/dashboard.
- Chỉ tạo báo cáo này và cập nhật `MIGRATION_CONTEXT.md`, `MIGRATION_PROGRESS.md`.
- **Điểm dừng:** chờ người dùng kiểm tra báo cáo. Không bắt đầu Phase 02 hoặc giai đoạn tiếp theo nếu chưa được yêu cầu.
