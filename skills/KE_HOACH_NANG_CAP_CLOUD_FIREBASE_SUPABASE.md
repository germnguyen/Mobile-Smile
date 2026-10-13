# Kế hoạch nâng cấp ứng dụng Quản lý Tài liệu lên Cloud

> **Quyết định hiện hành (2026-10-13):** kế hoạch này mô tả phương án Firebase
> Storage cũ và đã bị thay thế. Dự án hiện giữ Firebase Authentication nhưng
> dùng private Supabase Storage; không tạo Firebase Storage/rules, Firebase
> Functions cho tệp hoặc yêu cầu Blaze billing. Xem
> [`../docs/IMPLEMENTATION_PLAN.md`](../docs/IMPLEMENTATION_PLAN.md).

**Phạm vi tài liệu:** kế hoạch được điều chỉnh theo mã nguồn thật trong `mm/`; đây không phải checklist thiết lập cho một dự án Flutter mới.  
**Ngày cập nhật:** 2026-10-13  
**Trạng thái tổng thể:** đang thực hiện nền tảng Firebase Auth/Supabase; chưa có cấu hình Firebase project chạy được, chưa có schema/RLS hoặc tích hợp Storage.  
**Nguyên tắc:** giữ kiến trúc và giao diện hiện có; không coi tính năng là hoàn tất khi chưa có bằng chứng từ mã chạy, cấu hình thật và kiểm thử tương ứng.

---

## 1. Mục tiêu và phạm vi

Nâng cấp ứng dụng Flutter Quản lý Tài liệu hiện tại để đáp ứng:

1. Đăng nhập Google qua Firebase Authentication.
2. Lưu file vật lý riêng tư trên Firebase Storage.
3. Lưu hồ sơ người dùng, metadata tài liệu và quyền chia sẻ trên Supabase PostgreSQL.
4. Tìm kiếm/cập nhật tài liệu và chia sẻ với vai trò viewer/editor.
5. Bảo vệ truy vấn bằng Supabase RLS và bảo vệ file bằng Firebase Storage Rules.
6. Kiểm thử quyền bằng ít nhất ba tài khoản Google độc lập.

Phần cần giữ lại từ ứng dụng hiện tại: Flutter Material UI, các màn hình list/detail/form, enum loại tài liệu, validation metadata và dependency composition hiện có. Không thay app thành ví dụ Todos, không tạo lại project, không thêm state-management library nếu chưa có lý do cụ thể.

### Trạng thái checklist

| # | Yêu cầu | Trạng thái thật hiện tại |
|---|---|---|
| 1 | Firebase Google Authentication | **Một phần, chưa chạy được:** đã thêm dependency và mã đăng nhập; emulator báo thiếu Firebase Android options nên app dừng ở `Firebase.initializeApp()`. |
| 2 | Firebase Storage + metadata Supabase | **Chưa triển khai.** Không có Storage SDK/rules/upload/download; Supabase chưa có bảng tài liệu. |
| 3 | Users/documents/permissions trong Supabase | **Chưa triển khai.** Chưa có migrations hoặc bảng cloud. Subject trong app hiện là text, không có bảng môn học. |
| 4 | Search/update/share | **Một phần cục bộ:** tìm kiếm/filter/CRUD metadata có trên Drift; chưa có cloud search, upload, sharing UI hoặc permission enforcement. |
| 5 | Supabase RLS | **Chưa triển khai.** |
| 6 | Kiểm thử với tối thiểu 3 tài khoản | **Chưa triển khai.** Bộ test hiện có là local-only. |

### Bằng chứng và baseline

- Package Flutter nằm tại `mm/`; Android `applicationId` và `namespace` hiện là `com.example.mm`.
- `mm/lib/main.dart` đã khởi tạo Firebase, Google Sign-In và Supabase. Supabase dùng project URL/publishable key hiện được khai báo trong file và callback `accessToken` lấy Firebase ID token.
- Đã có `mm/lib/services/auth_service.dart`, `mm/lib/pages/sign_in_page.dart`, `mm/lib/pages/auth_gate.dart`, `mm/lib/pages/signed_in_page.dart`.
- Emulator `Pixel_8_2`: APK debug build/cài đặt thành công; runtime dừng vì `Failed to load FirebaseOptions from resource`. Không có `google-services.json`, `GoogleService-Info.plist` hoặc `firebase_options.dart` trong project tại lần kiểm tra gần nhất.
- Dependencies hiện có: Flutter 3.47.2/Dart 3.13.2; `firebase_core 4.15.0`, `firebase_auth 6.7.0`, `google_sign_in 7.2.0`, `supabase_flutter 2.18.3`.
- `flutter test`: 18 passed ở bộ test local hiện có. `flutter analyze`: 6 issues (1 info, 5 warning) ở lần chạy sau thay đổi Auth; chưa phải analyzer sạch.
- Chưa xác nhận cấu hình Firebase Console, Supabase Third-Party Auth, token claims, database/RLS, Firebase Storage Rules hoặc bất kỳ luồng cloud nào.

---

## 2. Kiến trúc dự án hiện tại và cách mở rộng

```text
mm/lib/
├── main.dart
├── config/
│   ├── app_dependencies.dart
│   └── app_theme.dart
├── database/
│   ├── app_database.dart
│   ├── tables.dart
│   └── daos/
├── pages/
│   ├── auth_gate.dart
│   ├── sign_in_page.dart
│   ├── signed_in_page.dart
│   ├── document_list_page.dart
│   ├── document_detail_page.dart
│   ├── document_form_page.dart
│   └── home_page.dart
├── services/
│   ├── auth_service.dart
│   └── document_service.dart
├── struct/
│   └── document_type.dart
└── widgets/
    ├── document_card.dart
    ├── document_filter.dart
    ├── document_form.dart
    ├── document_search.dart
    └── empty_state.dart
```

Đây là danh sách từ workspace; không tự giả định các file nêu trong kế hoạch cũ như `lib/models/document_item.dart`, `lib/state/auth_notifier.dart`, `login_page.dart`, `search_bar_widget.dart` đang tồn tại.

### Trách nhiệm dự kiến

```text
Màn hình Flutter hiện có
  ├── AuthService → Google Sign-In → Firebase Authentication
  ├── DocumentService → Supabase PostgreSQL (Firebase ID token + RLS)
  ├── StorageService → Firebase Storage private objects
  └── Quyền đọc file được chia sẻ → trusted backend kiểm tra quyền hiện hành
```

- Giữ `setState`, `Navigator`, `AppDependencies` và `DocumentService` làm nền.
- Chỉ thêm repository nếu cần tách query Supabase ra khỏi service; không tạo layer chỉ vì mẫu kiến trúc.
- Supabase lưu metadata/quyền; Firebase Storage giữ binary. Drift hiện lưu local và **chưa có owner UID**, vì vậy không được dùng như nguồn dữ liệu đa tài khoản nếu chưa có thiết kế phân vùng/migration rõ ràng.
- Hiện tại `AuthGate` chỉ mở trang tạm sau login, không hiển thị dữ liệu SQLite cục bộ. Điều này có chủ ý nhằm không làm lộ tài liệu local giữa các tài khoản.
- Model dữ liệu hiện có gồm title, description, filePath, documentType, subject, createdAt, updatedAt; bảng local dùng ID số tự tăng. Mô hình cloud sẽ cần UUID và UID Firebase.
- `subject` hiện là text nullable, không có bảng Subjects. Chỉ tạo bảng `subjects` nếu giảng viên yêu cầu quan hệ môn học hoặc cần chia sẻ/tái sử dụng môn học; nếu không thì giữ chuỗi subject trong document để tránh đổi schema không cần thiết.

---

## 3. Quyết định kiến trúc và bảo mật bắt buộc

### 3.1 Firebase Authentication → Supabase

Người dùng đã chọn:

- Đăng nhập bằng Google thông qua Firebase Authentication; Firebase UID là định danh người dùng.
- Ưu tiên kiểm tra Firebase Third-Party Auth của Supabase để xác minh Firebase ID token.

SDK Supabase trong project có callback `accessToken`; code hiện cung cấp Firebase `getIdToken()` cho callback đó. Việc có callback trong SDK **không chứng minh** project Supabase đã cấu hình provider hoặc rằng RLS helper trả về Firebase UID đúng dạng.

Trước khi bất kỳ thao tác dữ liệu được bảo vệ nào được bật:

1. Cấu hình Firebase project thật và đăng nhập thành công trên Android.
2. Bật/cấu hình Firebase provider theo khả năng hiện hành trong Supabase project.
3. Lấy token qua flow thực (không in/lưu token đầy đủ trong log).
4. Xác nhận việc xác minh signature, issuer, audience, expiry và claim `sub`.
5. Kiểm chứng UID mapping trong policy. Không mặc định `auth.uid()` trả Firebase UID hoặc có cùng kiểu UUID; có thể cần đọc claim đã xác minh trong JWT và lưu Firebase UID ở cột `text`.
6. Kiểm tra request không đăng nhập/token sai bị từ chối ở RLS.

Nếu project Supabase không hỗ trợ hoặc không thể kiểm chứng tích hợp này, dừng và duyệt phương án backend tin cậy xác minh Firebase ID token. Không gửi một UID/email do client tự khai báo làm bằng chứng danh tính. Không để service-role key hoặc Firebase Admin credentials trong app.

### 3.2 Firebase Storage và chia sẻ

RLS Supabase không áp dụng cho Firebase Storage; Storage Rules không tự query bảng permission của Supabase.

- Bucket phải private; không dùng test mode trong triển khai cuối.
- Path gợi ý: `documents/{ownerUid}/{documentUuid}/{generatedObjectName}`. Đường dẫn chỉ là định vị object, không phải authorization.
- Chỉ owner được upload/ghi/xóa object của mình bằng Firebase Rules; kiểm tra `request.auth.uid`, dung lượng, MIME allowlist và thao tác phù hợp.
- Mặc định chỉ owner đọc trực tiếp object. Không dùng rule `allow read: if request.auth != null`: rule đó cho **mọi user đã đăng nhập** đọc tất cả file của mọi người.
- Để viewer/editor đọc file chia sẻ cần trusted authorization flow: backend xác minh Firebase ID token, kiểm tra permission hiện tại trong Supabase và chỉ sau đó stream file hoặc cấp URL ký ngắn hạn. URL ký là bearer secret có thời hạn; không lưu thay cho `storage_path`, không log.
- Không mở direct read cho toàn bộ user chỉ để làm sharing dễ hơn. RLS database không thể bù cho Storage Rules quá rộng.
- Định nghĩa xử lý orphan object và metadata sai lệch (upload thành công/insert lỗi; metadata thành công/object lỗi) bằng retry/cleanup/reconciliation. Không mô tả hai dịch vụ là cùng một transaction.

### 3.3 Quyền dự kiến

| Thao tác | Owner | Viewer | Editor | Không được chia sẻ |
|---|---:|---:|---:|---:|
| Đọc metadata | Có | Có | Có | Không |
| Đọc/tải file qua luồng được ủy quyền | Có | Có | Có | Không |
| Sửa metadata được phép | Có | Không | Có | Không |
| Xóa document/file | Có | Không | Không | Không |
| Cấp/đổi/thu hồi quyền | Có | Không | Không | Không |

Quyền phải được kiểm tra tại RLS/backend và Firebase Storage flow, không chỉ ẩn/nút disable trong giao diện. Owner không được thay đổi bởi client sau khi tạo document. Không cho người nhận tự cấp quyền cho mình hoặc sửa quyền của người khác.

---

## 4. Thiết lập dịch vụ bên ngoài

### 4.1 Firebase Android app

1. Tạo hoặc chọn Firebase project hiện có.
2. Android app phải đăng ký với application ID đúng như project hiện tại: **`com.example.mm`**. Không dùng package name giả định từ hướng dẫn cũ.
3. Từ `mm/android`, lấy fingerprint debug:

   ```powershell
   .\gradlew signingReport
   ```

   Đăng ký SHA-1 và SHA-256 tương ứng trong Firebase Console. Nếu phát hành release, bổ sung fingerprint của signing key phát hành.

4. Bật Google trong Firebase Authentication và chọn support email.
5. Tải Firebase Android config từ Firebase Console vào:

   ```text
   mm/android/app/google-services.json
   ```

6. Kiểm tra Gradle Google Services plugin theo hướng dẫn Firebase/FlutterFire hiện hành. Chỉ sửa `mm/android/settings.gradle.kts`, `mm/android/app/build.gradle.kts` hoặc config native khi cần và có config project thật.
7. Xác nhận config không bị bỏ qua bởi gitignore nếu cần build trên máy khác; không commit service account hoặc private keys.
8. Khởi động lại ứng dụng. Thành công tối thiểu là app khởi tạo Firebase và hiển thị Sign-In page; tiếp đó kiểm tra Google Sign-In thật.

> Đã thử chạy `flutter run -d emulator-5554` trên Pixel_8_2. APK build/cài đặt được nhưng app dừng ở Firebase initialization do chưa có Android config. Không lặp lại build/run như thể lỗi đã khắc phục trước khi config được thêm.

### 4.2 Firebase Storage

1. Bật Firebase Storage trong đúng project, chọn region sau khi cân nhắc độ trễ, vị trí người dùng và khả năng đồng bộ với Supabase.
2. Không chọn “test mode” làm cấu hình cuối.
3. Viết rules trong file version-controlled `mm/storage.rules`; deploy/publish rules sau khi test.
4. Rules phải owner-only cho thao tác ghi/xóa và direct read theo quyết định security ở mục 3.2.
5. Tạo Emulator/rules tests nếu khả thi; xác minh user A không thể thao tác vào path của user B và user không đăng nhập bị từ chối.

### 4.3 Supabase project

1. Dùng project Supabase hiện có trong `mm/lib/main.dart` (URL/publishable key đã được người dùng cung cấp) nếu đó là project mục tiêu; xác minh quyền truy cập Dashboard trước khi tạo project mới.
2. Publishable/anon key được dùng trong client không phải service-role key. Không chia sẻ database password hoặc secret key trong mã/chat.
3. Trong Supabase Dashboard, kiểm tra khả năng cấu hình Firebase Third-Party Auth và hướng dẫn JWT hiện hành cho plan/project.
4. Chưa tạo schema/policy trên production trước khi kiểm tra migration tại local/dev project.
5. Version hóa schema bằng SQL migration trong `mm/supabase/migrations/` thay vì chỉ giữ SQL đã dán thủ công vào Dashboard.

---

## 5. Mô hình dữ liệu dự kiến

Tên bảng chuẩn theo yêu cầu: `users`, `documents`, `document_permissions`. Có thể dùng tên `profiles` cho user profile nếu thống nhất trước; không tạo song song `profiles` và `users` cho cùng mục đích.

### `users`

- `id TEXT PRIMARY KEY`: Firebase UID đã xác minh.
- `email`, `display_name`, `avatar_url` (nullable khi identity không cung cấp).
- `created_at`, `updated_at`.
- Email không dùng làm principal/permission key; cần normalize/unique chỉ khi nghiệp vụ yêu cầu.

### `documents`

- `id UUID PRIMARY KEY`.
- `owner_id TEXT NOT NULL REFERENCES users(id)`.
- `title TEXT NOT NULL`, `description TEXT NULL`.
- `subject TEXT NULL` và `document_type TEXT`/enum tương ứng với enum hiện có (`lecture`, `assignment`, `reference`, `other`), trừ khi quyết định rõ tạo Subjects.
- `storage_path TEXT NOT NULL`: object path, không phải permanent/public download URL.
- `mime_type TEXT NULL`, `file_size_bytes BIGINT NULL`.
- `created_at`, `updated_at`.
- Cần quyết định khi document metadata không có file nếu vẫn hỗ trợ record không đính kèm như SQLite hiện tại.

### `document_permissions`

- `id UUID PRIMARY KEY`.
- `document_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE`.
- `user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE`.
- `permission TEXT NOT NULL CHECK (permission IN ('viewer','editor'))`.
- `created_at TIMESTAMPTZ`.
- `UNIQUE(document_id,user_id)` ngăn quyền trùng.
- `shared_by` có thể lưu nếu cần audit, nhưng phải có constraint/policy bảo đảm chỉ owner có thể cấp quyền.

### RLS design — yêu cầu, chưa phải SQL đã triển khai

- Bật RLS trên mọi bảng được client truy cập và giới hạn quyền SQL grants.
- `users`: user chỉ tạo/cập nhật profile của chính mình; người dùng khác chỉ được tra cứu thông tin tối thiểu cần để chia sẻ theo chính sách privacy.
- `documents SELECT`: owner hoặc user có permission hợp lệ.
- `documents INSERT`: `owner_id` bắt buộc bằng principal đã xác minh.
- `documents UPDATE`: owner hoặc editor; `WITH CHECK` ngăn đổi owner/đường dẫn tùy tiện.
- `documents DELETE`: chỉ owner.
- `document_permissions SELECT`: owner hoặc recipient theo nhu cầu UI.
- `document_permissions INSERT/UPDATE/DELETE`: chỉ owner của document; chống tự cấp quyền, sửa `shared_by`, quyền trùng và permission escalation.
- Không dùng điều kiện “claim `sub` null thì allow” hay `USING (true)` trên bảng nhạy cảm. Các điều kiện như vậy vô hiệu hóa bảo mật.
- Không copy policy SQL cũ trong tài liệu này. Policy phải viết sau khi xác minh token bridge, claim name, subject format và test trên Supabase thực.

### Tìm recipient

Không cung cấp quyền đọc toàn bộ bảng users/profiles chỉ để tìm email. Cần chọn:

- Chỉ cho chia sẻ tới tài khoản đã đăng ký và tìm chính xác email đã normalize; hoặc
- Backend tin cậy thực hiện lookup hạn chế và trả tối thiểu thông tin.

Không lưu email là định danh quyền chính vì email có thể đổi; lưu Firebase UID recipient đã xác minh.

---

## 6. Kế hoạch thay đổi theo file thực tế

### Đã có/đang dùng

| File | Hiện trạng và hướng xử lý |
|---|---|
| `mm/lib/main.dart` | Đã khởi tạo Firebase, Google Sign-In, Supabase; Firebase config runtime còn thiếu. Supabase client có token callback nhưng provider chưa xác minh. |
| `mm/lib/config/app_dependencies.dart` | Tạo AppDatabase, AuthService, DocumentService; mở rộng để thêm storage/document cloud dependency theo pattern đang có. |
| `mm/lib/services/auth_service.dart` | Google ID token được trao đổi lấy Firebase credential; có auth stream/sign-out/cancel. Cần test device thật và kiểm tra web support riêng nếu Web là target. |
| `mm/lib/pages/auth_gate.dart`, `sign_in_page.dart` | Auth restore và UI đăng nhập; giữ và hoàn thiện error/loading theo config thật. |
| `mm/lib/pages/signed_in_page.dart` | Trang tạm sau đăng nhập; chỉ thay bằng danh sách cloud sau khi schema/RLS đã có. Hiện cố ý không hiện local docs. |
| `mm/lib/services/document_service.dart` | Có CRUD/search/validation local qua DocumentDao; chuyển hoặc mở rộng sau khi định rõ local migration/source-of-truth. |
| `mm/lib/database/app_database.dart`, `tables.dart`, `daos/*` | Drift/SQLite native, schemaVersion 1, ID số; giữ tạm cho legacy/tests, không dùng làm nơi lưu quyền cloud. Không xóa hoặc migrate dữ liệu tự động. |
| `mm/lib/pages/document_list_page.dart`, `document_detail_page.dart`, `document_form_page.dart` | UI list/search/filter/detail/form hiện hữu có thể tái sử dụng; thay service/data flow incrementally. |
| `mm/lib/widgets/document_form.dart` | Hiện có lỗi liên quan: hai text fields dùng `titleController`, thiếu input description. Sửa khi chạm form. |
| `mm/lib/widgets/document_card.dart`, `document_filter.dart`, `document_search.dart`, `empty_state.dart` | Tái sử dụng UI; bổ sung role/status khi có data cloud. |
| `mm/lib/struct/document_type.dart` | Enum đang là lecture/assignment/reference/other; mapping DB cần ổn định, không dùng index enum làm wire format lâu dài. |
| `mm/test/database_test.dart`, `document_dao_test.dart`, `document_service_test.dart` | Giữ các test local, mở rộng test phù hợp; không xem là bằng chứng cloud/security. |
| `mm/pubspec.yaml`, `mm/pubspec.lock` | Firebase Auth/Core, Google Sign-In và Supabase đã có. Cần thêm Firebase Storage và file picker khi bước storage được duyệt; chọn versions tương thích SDK target thay vì dùng các versions cũ giả định trong kế hoạch ban đầu. |

### Dự kiến thêm

| File | Mục đích |
|---|---|
| `mm/lib/services/storage_service.dart` | Upload/download/delete Firebase Storage và lỗi/retry; không tự quyết định authorization share. |
| `mm/lib/services/document_service.dart` hoặc `mm/lib/repositories/document_repository.dart` | Cloud CRUD/search/share. Ưu tiên mở rộng service hiện tại; thêm repository khi thực sự giúp tách PostgREST. |
| Model cloud cần thiết trong `mm/lib/struct/` hoặc thư mục models được thống nhất | Document UUID, storage path, owner UID, permission/user DTO; chọn theo convention hiện tại, không tạo nhiều model trùng lặp. |
| `mm/supabase/migrations/*.sql` | Schema, constraints, indexes, RLS/grants theo version control. |
| `mm/storage.rules` và rules tests | Firebase object security độc lập với Supabase RLS. |
| Backend Function/API (nếu cần file share) | Xác minh Firebase token + permission hiện hành trước khi trả file/URL ký. |
| UI share dialog/page cần thiết | Tìm người nhận, chọn role, xem/thu hồi share; đặt cạnh màn hình hiện có thay vì thay toàn bộ navigation. |
| Tests tích hợp/rules và `docs/DATABASE_SCHEMA.md`, `SECURITY_MODEL.md`, `TEST_PLAN.md`, `TEST_RESULTS.md`, `SUBMISSION_CHECKLIST.md` | Bằng chứng schema/bảo mật và báo cáo nộp bài. Chỉ ghi kết quả sau khi chạy thật. |

Không tạo `AuthNotifier`, `DocumentManagerNotifier`, thư mục `models/`, `state/` hoặc bảng `subjects` trừ khi có nhu cầu đã xác nhận; project hiện không dùng Provider/Riverpod/Bloc và chưa có model tách riêng khỏi Drift.

---

## 7. Các giai đoạn thực hiện và điều kiện hoàn tất

| Giai đoạn | Công việc | Điều kiện qua giai đoạn |
|---|---|---|
| 0. Cấu hình Firebase thật | Đăng ký `com.example.mm`, SHA-1/SHA-256, Google provider, `google-services.json`, Gradle setup chính thức. | Firebase khởi tạo trên Pixel_8_2; đăng nhập/đăng xuất Google hoạt động; cancel/error không crash. |
| 1. Identity bridge | Bật Firebase third-party auth trên Supabase nếu project hỗ trợ; chuyển ID token qua callback đang có; xác minh claim/UID. | Token thật được Supabase xác minh đúng; auth UID policy mapping đã chứng minh; unauthenticated bị từ chối. Nếu không được thì dừng xin duyệt backend. |
| 2. Migrations và RLS | Tạo schema tối thiểu users/documents/permissions; indexes, FK, unique/check; bật RLS/grants/policies. | Migration chạy trên dev DB; truy vấn trực tiếp A/B/C có đúng allow/deny; không policy open. |
| 3. Profile và document data layer | Đồng bộ profile idempotent theo Firebase UID; nối list/search/CRUD metadata cloud; quyết định migration dữ liệu local. | CRUD/search chạy với token thật, không đọc dữ liệu ngoài quyền; local data không bị mất. |
| 4. Storage owner flow | Thêm file picker và Storage service; private upload/download/delete của owner; save `storage_path`; xử lý lỗi lệch pha. | Owner flow thực tế chạy; direct access của user lạ bị chặn; MIME/size limits được kiểm tra. |
| 5. Share flow | Tìm recipient đúng privacy policy; grant/change/revoke viewer/editor; server policies bảo đảm quyền. Thiết lập backend file access nếu chia sẻ file. | A cấp quyền cho B; B được đúng quyền; C không truy cập; revoke có hiệu lực theo yêu cầu. |
| 6. Hoàn thiện UI | Gắn data cloud vào UI cũ; auth, loading, empty, errors; role controls; sửa form field trùng/description. | Các luồng không tạo quyền bằng UI state; accessibility/error UX được kiểm tra. |
| 7. Kiểm thử và submission | Unit/integration, RLS, Storage Rules, 3 tài khoản, platform build, secret review, tài liệu/evidence. | Kết quả thật được ghi; mọi mục chưa test được đánh dấu chưa xác minh; không báo hoàn tất sớm. |

Không tiếp tục tới protected data operations nếu identity bridge chưa qua giai đoạn 1. Không bật file sharing trước khi backend/Storage authorization có cách kiểm tra permission thật.

---

## 8. Kiểm thử đa tài khoản

Chuẩn bị tối thiểu ba tài khoản Google riêng:

- **A — Owner:** tạo document.
- **B — Viewer:** A cấp quyền đọc.
- **C — Unshared user:** không được chia sẻ; dùng để xác minh deny.
- **Editor test:** thêm tài khoản D nếu có thể; nếu chỉ có ba tài khoản, chạy lại vòng test với B được cấp editor sau khi thu hồi quyền viewer. Không gộp “editor” và “unshared” trong cùng thời điểm nếu như vậy không kiểm tra được cả hai trường hợp.

| ID | Tài khoản | Bước thử | Kết quả kỳ vọng |
|---|---|---|---|
| AUTH-01 | A/B/C | Đăng nhập Google lần lượt; ghi UID đã che/mã hóa trong evidence, profile tạo đúng người. | UID Firebase khác nhau; không lưu token đầy đủ/log credentials. |
| AUTH-02 | A/B/C | Đăng xuất/đăng nhập lại, khởi động lại app, hủy sign-in, mô phỏng lỗi mạng/expired session. | Session state đúng; cancel không tạo session; lỗi hiển thị rõ. |
| DOC-01 | A | Tạo/upload tài liệu với metadata hợp lệ. | Object private có path owner A; DB record owner A và storage_path khớp. |
| DOC-02 | A | Search theo title/description/subject, sửa metadata. | Kết quả đúng; owner có thể sửa, timestamps cập nhật. |
| SHARE-01 | A | Chia sẻ document với B là viewer. | Permission có đúng user ID/role; user khác không thể tự thêm quyền. |
| VIEW-01 | B | List tài liệu được chia sẻ, đọc metadata và mở/tải qua luồng được ủy quyền. | B đọc được đúng tài liệu; không sửa/xóa/quản lý permission. |
| DENY-01 | C | Query trực tiếp document table và cố truy cập object/path đã biết của A. | Không có metadata; database RLS và Storage/backend đều từ chối. |
| EDIT-01 | D hoặc B ở vòng role riêng | Được cấp editor, sửa metadata, thử xóa document/quản lý permission. | Sửa trường cho phép được; xóa và permission management bị từ chối. |
| REVOKE-01 | A rồi B | A thu hồi B; B thử lại query và link/file cũ. | Metadata bị ẩn và yêu cầu file sau revoke bị từ chối theo SLA; signed URL cũ chỉ sống đến hạn ngắn đã quy định. |
| INTEG-01 | A | Giả lập upload thành công/DB fail và DB record/storage fail; duplicate share, người nhận không tồn tại, object missing. | Không báo thành công giả; cleanup/retry/reconciliation hoạt động, không tạo quyền trùng. |

Mỗi lần chạy ghi: Test ID, build/commit/version, precondition, steps, expected, actual, PASS/FAIL/BLOCKED, timestamp và evidence/log đã loại bỏ secrets. Không ghi “PASS” nếu chỉ xem code hoặc chạy unit test local.

---

## 9. Điều cần người dùng cung cấp/thực hiện

1. Tạo Firebase project hoặc quyết định dùng project hiện có.
2. Đăng ký Android app package `com.example.mm`, thêm SHA-1/SHA-256, bật Google provider và cung cấp file config qua workspace tại `mm/android/app/google-services.json`.
3. Xác nhận có thể truy cập Supabase project đã được khai báo trong app và bật Firebase Third-Party Auth. Không gửi database password, service-role key hoặc Firebase Admin key.
4. Xác nhận target là Android (emulator `Pixel_8_2` hiện có) hay cần iOS/Web. Web hiện chưa tương thích database local `dart:io`/`drift/native.dart`, và Google Sign-In cần setup riêng.
5. Quyết định giữ/chuyển metadata SQLite hiện hữu; không tự upload mọi đường dẫn `filePath` vì chưa biết binary còn tồn tại.
6. Xác nhận có thể triển khai trusted backend cho việc user được chia sẻ đọc file Firebase Storage private. Nếu không, cần thống nhất security/UX alternative trước khi mở bucket.
7. Cung cấp 3 tài khoản thử nghiệm qua quy trình phù hợp; không đưa mật khẩu vào mã hoặc tài liệu công khai.

---

## 10. Lệnh kiểm tra trong workspace hiện tại

Từ thư mục `mm` (PowerShell):

```powershell
flutter pub get
flutter analyze
flutter test
flutter emulators --launch Pixel_8_2
flutter run -d emulator-5554
```

Lệnh build/run chỉ được xác nhận thành công khi app khởi tạo Firebase và hiển thị UI; APK build được không đồng nghĩa Firebase login hoạt động. Nếu runtime vẫn báo thiếu Firebase options, kiểm tra file config và Gradle trước khi chạy lại.

Để lấy SHA fingerprints:

```powershell
Set-Location .\android
.\gradlew signingReport
```

Không dùng `npx skills add supabase/agent-skills` như một bước bắt buộc: đó là tùy chọn công cụ, không cấu hình Firebase/Supabase, không thay thế migrations và không xác nhận bảo mật.

---

## 11. Tài liệu bàn giao

Sau khi triển khai và xác minh, cập nhật/tạo:

- `docs/PROJECT_AUDIT.md`: đánh giá hiện trạng/tiến độ và các mục còn thiếu.
- `docs/IMPLEMENTATION_PLAN.md`: trạng thái thực tế và các quyết định đã duyệt.
- `docs/DATABASE_SCHEMA.md`: schema/migrations.
- `docs/SECURITY_MODEL.md`: token bridge, RLS, Storage Rules, file sharing.
- `docs/TEST_PLAN.md`, `docs/TEST_RESULTS.md`: kiểm thử đã chạy và evidence.
- `docs/SUBMISSION_CHECKLIST.md`: checklist nộp bài và limitations.

### Definition of Done

- Google Auth hoạt động trên target đã chốt; Firebase UID và Supabase claim mapping được xác minh.
- Migrations tạo schema/constraints; RLS bật và kiểm tra trực tiếp bằng A/B/C.
- Firebase Storage objects private; upload/download/delete được giới hạn; file share được xác minh bằng trusted path.
- Metadata/file reference nhất quán hoặc có quy trình phát hiện/sửa orphan.
- Search, update, sharing/revoke và role boundaries chạy thật.
- Ba tài khoản độc lập đã được kiểm tra; user ngoài không đọc được metadata hoặc binary.
- Tests/build/analyze đã chạy; warnings/errors còn lại được liệt kê, không che giấu.
- Không có service-role key/Firebase Admin credential trong app hoặc repo; tài liệu submission chứa evidence thật.

**Kết luận trạng thái hôm nay:** chưa đạt Definition of Done. Bước chặn kế tiếp là cấu hình Firebase Android cho `com.example.mm`; sau đó mới có thể kiểm thử đăng nhập và xác minh Firebase token bridge với Supabase.
