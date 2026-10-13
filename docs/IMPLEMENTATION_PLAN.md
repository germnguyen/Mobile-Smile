# Implementation Plan — Quản lý Tài liệu Cloud

**Trạng thái:** Đang triển khai theo từng bước sau khi người dùng chọn hướng Firebase Third-Party Auth; chưa hoàn tất xác thực hoặc cloud data access.  
**Cơ sở:** kết quả trong `docs/PROJECT_AUDIT.md` và các ràng buộc của `skills/SKILL.md`.

## Mục tiêu

Nâng cấp ứng dụng Flutter hiện có (không dựng lại) thành ứng dụng quản lý tài liệu với Firebase Google Authentication, Firebase Storage, Supabase PostgreSQL, chia sẻ viewer/editor, Supabase RLS và Firebase Storage Rules. Bảo toàn UI/luồng local đang dùng khi khả thi; không đưa cloud data qua UI như thể đã xác thực nếu bridge chưa được xác minh.

## Nguyên tắc kỹ thuật

- Giữ `MaterialApp`, màn hình, `setState`, `AppDependencies` và validation hiện tại làm điểm xuất phát. Không thêm Provider/Riverpod/Bloc/router nếu không phát sinh yêu cầu cụ thể.
- Xác định một nguồn dữ liệu chính. Với yêu cầu cloud, Supabase là nguồn metadata/quyền; Drift chỉ tiếp tục nếu offline/cache hoặc migration legacy có yêu cầu rõ. Không cho SQLite local quyết định quyền truy cập cloud.
- Firebase Auth xác minh danh tính; Supabase client phải dùng token Firebase được xác minh qua cấu hình third-party Auth hoặc qua trusted backend. Không dùng email/UID do client tự khai báo.
- RLS phải bảo vệ trực tiếp các truy vấn database. Firebase Storage Rules là lớp riêng; RLS không cấp quyền trên bucket.
- Client chỉ chứa cấu hình public cần thiết. Không bao giờ nhúng Supabase service-role key hoặc Firebase Admin credentials.
- Chọn và khóa versions sau khi nền tảng đích đã chốt; giữ các test cũ có giá trị.

## Thứ tự giai đoạn và phụ thuộc

| Giai đoạn | Nội dung | File chính dự kiến | Điều kiện hoàn tất / phụ thuộc |
|---|---|---|---|
| 0. Chốt yêu cầu và môi trường | Xác nhận target platform, Firebase/Supabase project, third-party auth hay backend bridge, local data migration, sharing lookup, MIME/size và test accounts. Kiểm tra SDK/dependency/API hiện hành theo đúng target. | Không sửa mã app; cập nhật quyết định vào docs khi được duyệt. | Bắt buộc trước cấu hình cloud/dependency. Không tiếp tục tới protected data nếu bridge chưa chọn. |
| 1. Firebase project setup | Thiết lập Firebase app theo target (Android/iOS/Web nếu áp dụng), Google provider, app identifiers, OAuth callback/SHA/client config; kiểm tra không đưa secret vào repo. | `main.dart`, Gradle/Android config, iOS/Web config, Firebase options/config. | Firebase init và Google Sign-In chạy trên target đã chọn; xử lý cancel/error/logout/session restore. Phụ thuộc giai đoạn 0. |
| 2. Xác minh identity bridge | Cấu hình Firebase third-party Auth trên Supabase nếu tương thích; hoặc tạo backend xác minh ID token. Kiểm chứng chữ ký/issuer/audience/expiry/subject/role và UID mapping thực tế. | auth service/client config, backend nếu lựa chọn; chưa thao tác protected data trước gate này. | Thử token thật từ Firebase và xác nhận truy vấn Supabase nhận đúng user/claims. Phụ thuộc giai đoạn 1. |
| 3. Schema, migrations và RLS | Viết migration cho `users`, `documents`, `document_permissions`, FK/check/unique/index; bật RLS, policy SELECT/INSERT/UPDATE/DELETE theo owner/viewer/editor; giới hạn quản lý chia sẻ cho owner. | `supabase/migrations/*.sql`, model/DTO, seed test không chứa secret. | Kiểm tra migration trên project/dev database và chạy policy bằng token thật A/B/C. Phụ thuộc giai đoạn 2; không coi kiểm thử mock là xác minh RLS. |
| 4. Cloud data layer và đồng bộ profile | Tạo user profile/upsert idempotent bằng UID token đã xác minh; thay CRUD/search trong `DocumentService` bằng Supabase API; quyết định xử lý/migrate SQLite legacy. | `AppDependencies`, `DocumentService`, có thể thêm `DocumentRepository`, model/DTO, migration data nếu được duyệt. | CRUD/search dùng authenticated client; người không quyền bị RLS chặn; local data không mất âm thầm. Phụ thuộc giai đoạn 3. |
| 5. File picker và Firebase Storage | Chọn tệp trên target; path có owner ID và document ID; private upload; validate size/type; lưu `storage_path` vào Supabase. Thiết kế cleanup/retry cho upload/insert lỗi lệch pha. | `StorageService`, document form/detail, Storage Rules, `pubspec.yaml/lock`. | Upload/download/delete owner chạy thật; lỗi giữa Storage/DB có trạng thái/reconciliation xác định. Phụ thuộc giai đoạn 1 và 3. |
| 6. Quy trình đọc file được chia sẻ | Dùng backend xác minh Firebase token và permission Supabase trước khi cấp short-lived signed URL/proxy; hoặc giải pháp claims khác chỉ khi đã phân tích độ trễ revoke và được duyệt. | HTTPS/Callable Function/API, UI detail/share, Storage Rules. | B có thể đọc sau share; C bị từ chối truy cập object trực tiếp; revoke làm mất quyền theo SLA đã xác định. Phụ thuộc giai đoạn 2, 3 và 5. |
| 7. UI quản lý document và chia sẻ | Hoàn thiện list/search/filter/empty/loading/error, form upload/metadata, share recipient, viewer/editor, danh sách quyền, đổi/revoke; UI phản ánh quyền nhưng không thay authorization. | List/detail/form pages và widgets hiện có; navigation chỉ mở rộng cần thiết. | Không có hành động client vượt quyền; profile/error/auth states rõ ràng. Phụ thuộc giai đoạn 4–6. |
| 8. Kiểm thử, hardening và tài liệu nộp | Unit/service tests; migration/RLS/Storage integration; test A/B/C thực; build target thật; review secrets/rules; ghi kết quả và evidence. | `test/**`, SQL/rules/backend tests, `docs/DATABASE_SCHEMA.md`, `SECURITY_MODEL.md`, `TEST_PLAN.md`, `TEST_RESULTS.md`, `SUBMISSION_CHECKLIST.md`. | Mọi test có actual result/evidence; không tuyên bố pass khi chưa chạy. Phụ thuộc các giai đoạn trước. |

### Các cổng an toàn bắt buộc

1. **Gate identity:** không query/ghi dữ liệu Supabase được bảo vệ trước khi Firebase token được Supabase/backend xác minh và map tới một định danh ổn định.
2. **Gate RLS:** không coi ứng dụng multi-user hoàn tất trước khi test bằng token độc lập của owner, recipient và user không được chia sẻ.
3. **Gate file-sharing:** không bật chia sẻ file trước khi có cơ chế trusted xác nhận permission ngoài UI; test direct access không được cấp quyền.
4. **Gate data migration:** không xóa hoặc ghi đè SQLite legacy trước khi user quyết định cách giữ/migrate dữ liệu và có backup phù hợp.

## Kiến trúc tích hợp đề xuất để duyệt

```text
Flutter UI (giữ màn hình hiện có)
  ├── Firebase Auth / Google Sign-In → Firebase UID + ID token
  ├── DocumentService → Supabase PostgreSQL (token Firebase đã xác minh, RLS)
  └── StorageService → Firebase Storage private objects
                           └── file share read → trusted backend kiểm tra Supabase permission
```

- `public.users.id` đề xuất kiểu `text` khớp Firebase UID; `documents.owner_id` và `document_permissions.user_id` tham chiếu đến users. Không dựa vào email làm ID.
- `documents`: UUID, owner, name/title, description, storage path, MIME, size, timestamps (và các metadata cần giữ như subject/type).
- `document_permissions`: UUID, document/user FK, role giới hạn `viewer|editor`, unique `(document_id,user_id)`, created timestamp.
- Kiểm chứng claim `sub` và cách dùng `auth.uid()` trước khi viết policy: không mặc định Firebase UID được trả về/cast giống Supabase native UUID.
- Upload chỉ dùng đường dẫn object làm khóa ổn định. Không lưu public/permanent URL. Đường dẫn dự đoán được không phải cơ chế authorization.
- Cloud/local consistency cần retry/reconciliation hoặc trạng thái pending; thao tác Firebase Storage và Postgres không được mô tả như một transaction duy nhất.

## Kiểm thử bắt buộc theo skill

Tài khoản thử nghiệm phải là ba tài khoản độc lập và dữ liệu thật trên project thử nghiệm đã cấu hình:

| Nhóm | Kiểm tra tối thiểu |
|---|---|
| Auth/profile | A, B, C đăng nhập độc lập, hủy Google sign-in được xử lý, profile đúng UID, restore/logout/expired token. |
| Owner | A upload, list/search/update metadata, download, share, đổi/revoke, delete; invalid input và lỗi mạng/storage/database. |
| Viewer | B thấy/đọc sau share; không sửa/xóa/quản lý permission; sau revoke thì mất metadata và file access. |
| Người ngoài | C không thấy metadata hoặc tải file; thử direct Supabase query và direct Firebase object URL/path. |
| Editor | Editor cập nhật đúng metadata được phép nhưng không xóa document/quản lý quyền. |
| Integrity | Duplicate permission, người nhận không tồn tại, missing object, upload thành công/DB thất bại, DB record thành công/storage lỗi và retry/reconciliation. |
| Build/security | Format/analyze/tests/build cho platform đã chốt; rà migrations/RLS/Storage Rules, xác nhận không có service-role/Admin secrets trong bundle hoặc repo. |

Mỗi test phải lưu ID, preconditions, steps, expected/actual, pass/fail và evidence/log. Bộ test hiện tại chỉ là baseline local: `flutter test` đạt 18 tests; không được tính chúng thay cho kiểm thử cloud.

## Tài liệu sẽ bổ sung sau khi được duyệt triển khai

- `docs/DATABASE_SCHEMA.md`: ERD/fields/constraints/indexes và cách chạy migration.
- `docs/SECURITY_MODEL.md`: token bridge, claims, RLS, Storage Rules, backend file-share flow, threat/limitations.
- `docs/TEST_PLAN.md` và `docs/TEST_RESULTS.md`: test matrix, actual outcome/evidence cho A/B/C.
- `docs/SUBMISSION_CHECKLIST.md`: build, cấu hình, rules, secrets, test evidence, các mục còn tồn tại.
- Cập nhật `docs/PROJECT_AUDIT.md` và `docs/IMPLEMENTATION_PLAN.md` khi các quyết định được xác nhận/thay đổi.

## Baseline trước triển khai

- Flutter 3.47.2 / Dart 3.13.2; SDK constraint hiện tại `^3.13.2`.
- `flutter test`: 18 passed, 0 failed.
- `flutter analyze`: 7 vấn đề (1 info, 6 warning), exit code 1.
- Chưa chạy build Android/iOS/Web; chưa có Firebase/Supabase config hoặc credentials kiểm thử trong workspace.

## Tiến độ sau khi người dùng chọn hướng identity

- Người dùng xác nhận dùng Google qua Firebase Authentication để định danh/lấy Firebase UID, và chọn khảo sát tích hợp Firebase Third-Party Auth với Supabase trước khi quyết định phương án cuối.
- `supabase_flutter ^2.18.3` hiện có trong `pubspec.yaml` và lockfile; `main.dart` khởi tạo Supabase bằng project URL/publishable key do người dùng cung cấp, đồng thời giữ nguyên màn hình tài liệu hiện tại.
- Chưa có Firebase SDK/config hoặc Google Sign-In; chưa có Firebase ID token callback cho Supabase; chưa xác minh third-party auth trên dashboard, claims hay RLS. Không thực hiện truy vấn dữ liệu cloud được bảo vệ ở bước này.
- Xác minh cục bộ sau cập nhật: `flutter test` 18 passed; `flutter analyze` vẫn có 7 issue (1 info, 6 warning), không tăng so với baseline audit. Chưa chạy platform build hoặc integration tests.
- Việc cần làm tiếp theo: kiểm tra cấu hình Supabase Third-Party Auth khả dụng cho project, xác nhận mapping claim `sub`/UID trong JWT thực tế, sau đó mới tích hợp Firebase Google Sign-In và token bridge. Nếu không thể kiểm chứng, dừng ở bước chuẩn bị và quay lại xin xác nhận phương án backend tin cậy.
