# Project Audit — Quản lý Tài liệu

> **Trạng thái cập nhật 2026-10-13:** Phần audit ban đầu bên dưới là lịch sử
> trước khi triển khai. Quyết định kiến trúc mới của người dùng thay Firebase
> Storage bằng Supabase Storage. Tình trạng mã nguồn và cloud hiện tại được ghi
> ở mục “Cập nhật kiến trúc” cuối tài liệu.

**Ngày audit:** 2026-10-13  
**Phạm vi:** mã nguồn hiện có trong `mm/`, cấu hình nền tảng, dependency lockfile, tests và nội dung skill `skills/SKILL.md`.  
**Giai đoạn:** chỉ audit; chưa sửa mã ứng dụng, cấu hình Firebase/Supabase hoặc dữ liệu. Hai tài liệu audit/kế hoạch này là đầu ra được yêu cầu.

## 1. Kết luận điều hành (audit ban đầu)

Đây hiện là ứng dụng Flutter quản lý **metadata tài liệu cục bộ** bằng Drift/SQLite. Có bằng chứng trong mã cho thao tác thêm, xem, sửa, xóa, tìm kiếm theo tên/mô tả/môn học và lọc theo loại. Bộ test hiện tại chạy đạt 18 tests; `flutter analyze` không sạch: 7 vấn đề (1 info, 6 warning).

Không tìm thấy bằng chứng về Firebase Authentication, Google Sign-In, Firebase Storage, Supabase, các bảng/chính sách RLS, luồng chia sẻ, file picker, upload/download thực tế hoặc kiểm thử với nhiều tài khoản. Do đó các yêu cầu cloud và bảo mật tương ứng được đánh dấu **chưa có trong mã nguồn**, không phải đã hoạt động.

Android, iOS, Web, Linux, macOS và Windows có cấu trúc nền tảng Flutter. Tuy nhiên, phần database hiện dùng `dart:io`, `drift/native.dart` và SQLite FFI. Điều này phù hợp với cách chạy native hiện tại nhưng không phải triển khai Web có thể dùng trực tiếp. Nền tảng nộp bài/chạy chính chưa được chỉ định. Lỗi `sqlite3-3.5.2` về `external` đã được đề cập trước đó; nếu lỗi xảy ra khi target Chrome/Web, cấu hình SQLite native là một điểm không tương thích đáng chú ý. Chưa có kết quả build Android/iOS/Web trong phiên audit để kết luận nền tảng nào build thành công.

**Hướng bảo toàn kiến trúc đề xuất:** giữ Flutter UI, các màn hình hiện có, `DocumentService`, dependency composition và Drift ở phạm vi cần thiết; bổ sung tích hợp cloud qua services/repositories có trách nhiệm rõ ràng thay vì viết lại ứng dụng. Cần xác nhận trước nền tảng đích và cách cấp quyền truy cập tệp được chia sẻ.

## 2. Cấu trúc và kiến trúc quan sát được

- Flutter package nằm trong `mm/`; README gốc mô tả đây là repository môn Phát triển ứng dụng di động, README của app vẫn là nội dung template.
- Entry point: `mm/lib/main.dart`. `main()` khởi tạo bindings, tạo `AppDependencies`, rồi chạy `StudyCashewApp`.
- Dependency composition: `mm/lib/config/app_dependencies.dart` tạo `AppDatabase` và `DocumentService`, truyền service vào màn hình. Không thấy package/provider/state-management bên ngoài.
- Điều hướng dùng `MaterialApp.home` và `Navigator.push`/`MaterialPageRoute` giữa list, form và detail; không thấy router riêng.
- UI/state: `StatefulWidget` và `setState` trong `DocumentListPage`, `DocumentDetailPage`, `DocumentFormPage`.
- Data access: Drift, `Documents` table, `DocumentDao` và `DocumentService`; chỉ một bảng tài liệu cục bộ, không có repository riêng.
- Model/type: Drift-generated `Document` cùng enum `DocumentType`.
- Cấu hình lint: `mm/analysis_options.yaml` kế thừa Flutter lints và loại trừ thư mục build/platform.
- Tests: `database_test.dart`, `document_dao_test.dart`, `document_service_test.dart`. Không thấy integration/E2E test.

### Bằng chứng chức năng cục bộ

| Chức năng | Bằng chứng trong mã | Kết luận audit |
|---|---|---|
| Thêm metadata | `DocumentFormPage`, `DocumentService.addDocument`, `DocumentDao.insertDocument` | Đã có thao tác lưu metadata vào SQLite; chưa phải upload tệp. |
| Liệt kê và xem chi tiết | `DocumentListPage`, `DocumentDao.getAllDocuments/searchDocuments`, `DocumentDetailPage` | Đã có UI và truy vấn cục bộ. |
| Sửa metadata | `DocumentFormPage`, `DocumentService.updateDocument` | Đã có cập nhật SQLite. |
| Xóa metadata | List/detail page, `DocumentService.deleteDocument` | Đã có xóa bản ghi cục bộ; chưa có xóa tệp cloud. |
| Tìm kiếm/lọc | `DocumentDao.searchDocuments`, `DocumentFilter`, `DocumentSearch` | Tìm title/description/subject và lọc `DocumentType` trên SQLite. |
| Tệp | Form chỉ nhận chuỗi `filePath`; detail chỉ hiển thị đường dẫn | Không thấy chọn, đọc, upload, download, mở hay xóa tệp thực. |
| Đăng nhập/định danh | Không tìm thấy auth flow/service/package | Chưa có. |
| Chia sẻ/quyền | Không thấy model/table/service hoặc UI sharing | Chưa có. |

**Lưu ý UI cần sửa trong phạm vi liên quan:** `mm/lib/widgets/document_form.dart` dựng hai trường nhập cùng dùng `titleController`; không có trường nhập mô tả dù service/database có `description`. Trường thứ hai có vẻ là lỗi UI hiện hữu cần xử lý khi điều chỉnh form metadata. Đây là nhận xét từ mã, chưa phải kết quả kiểm thử UI.

## 3. Dependency và tương thích nền tảng

`mm/pubspec.yaml` khai báo Dart SDK `^3.13.2`; môi trường audit báo Flutter 3.47.2 và Dart 3.13.2. Các dependency hiện có gồm `drift ^2.35.1`, `sqlite3_flutter_libs ^0.6.0+eol`, `path_provider ^2.1.6`, `path ^1.9.1`; lockfile resolve `drift`/`drift_dev` 2.35.1 và `sqlite3` 3.5.2.

- Hiện chưa khai báo package Firebase, Google Sign-In, Supabase hoặc chọn tệp.
- `mm/lib/database/app_database.dart` nhập `dart:io` và `package:drift/native.dart`, dùng `NativeDatabase.createInBackground`. Cách này không cung cấp backend database Web.
- `sqlite3_flutter_libs` đang resolve ở bản có suffix `+eol`; cần xác minh tình trạng hỗ trợ và hướng dẫn tương thích chính thức khi chốt dependency. Không nên nâng/hạ phiên bản theo phỏng đoán.
- Chỉ chạy Android/iOS desktop native: có thể tiếp tục đánh giá Drift native; cần build đúng target sau khi cấu hình cloud.
- Nếu Web là target: phải quyết định hỗ trợ Web bằng backend Drift phù hợp Web/SQLite WASM và cấu hình asset/worker tương ứng, hoặc tuyên bố app chỉ hỗ trợ mobile. Không thể giải quyết tính tương thích Web chỉ bằng cách sửa từ `external` trong package cache.
- Android module dùng Java/Kotlin 17; application ID còn là `com.example.mm`. Có Android SDK trong `local.properties`. iOS/Android/Web/Desktop có scaffolding, nhưng sự tồn tại của thư mục hoặc APK build cũ không chứng minh cấu hình hiện hành build thành công.
- Không tìm thấy `google-services.json`, `GoogleService-Info.plist`, `firebase_options.dart`, cấu hình Firebase, migration `.sql`, Supabase config hoặc `.env` trong phạm vi đã khảo sát. Cấu hình Google OAuth (SHA fingerprints/client IDs/URL scheme tùy nền tảng) vì vậy chưa được kiểm chứng.

## 4. Kết quả xác minh hiện trạng

- `flutter test`: **18 passed, 0 failed** trong bộ test hiện có. Các tests dùng SQLite memory/local DAO/service; không kiểm thử Firebase, Supabase, RLS, Storage Rules hay quyền đa tài khoản.
- `flutter analyze`: exit code 1; **7 issues**: 1 info (`use_super_parameters`) và 6 warning về import không dùng (4 trong UI, 2 trong tests). Đây là baseline hiện tại, chưa được sửa trong audit.
- Không chạy build nền tảng hoặc test cloud integration; không có cấu hình backend/credentials để kiểm tra luồng Firebase/Supabase thực tế.

## 5. Đối chiếu yêu cầu của giảng viên/skill

| Yêu cầu | Trạng thái trong dự án hiện tại | Bằng chứng / phần còn thiếu |
|---|---|---|
| Google Sign-In qua Firebase Authentication | Chưa có | Không có package, Firebase init, auth service hoặc màn hình đăng nhập. |
| Khôi phục phiên, đăng xuất, hủy đăng nhập và lỗi mạng | Chưa có | Không có trạng thái auth/session. |
| UID Firebase ổn định và profile người dùng trên Supabase | Chưa có | Không có user model/table/profile sync. |
| Xác thực Supabase bằng danh tính Firebase đã xác minh | Chưa có; quyết định kiến trúc cần chốt | Không có token bridge/client config. `auth.uid()` không được mặc định là Firebase UID nếu chưa xác minh token/claims và cách tích hợp Supabase. |
| Firebase Storage cho binary | Chưa có | `filePath` chỉ là text; không có Storage service hay rules. |
| PostgreSQL/Supabase tables `users`, `documents`, `document_permissions` | Chưa có | Metadata hiện lưu trong một bảng SQLite local; không thấy migration SQL. |
| Ràng buộc FK, uniqueness, role viewer/editor và indexes | Chưa có | Không có schema hoặc constraint cloud. |
| Liệt kê tài liệu truy cập được | Một phần | Có list local; chưa truy vấn cloud theo owner/share/RLS. |
| Tìm kiếm tài liệu | Một phần | Tìm cục bộ; chưa search cloud theo quyền và chỉ mục Postgres. |
| Hiển thị/cập nhật metadata | Một phần | Có metadata local; chưa quyền editor/owner phía server. Form hiện thiếu ô mô tả và có trường tiêu đề trùng. |
| Upload, download/mở và xóa file có ủy quyền | Chưa có | Không có file picker/storage operation; detail chỉ hiển thị chuỗi đường dẫn. |
| Chia sẻ, liệt kê/cập nhật/thu hồi quyền | Chưa có | Không có recipient lookup, permission UI hoặc backend policy. |
| Supabase RLS cho mọi bảng liên quan | Chưa có | Không có SQL migration hoặc policy. |
| Firebase Storage Rules độc lập | Chưa có | Không thấy rules hoặc Firebase config. |
| Ngăn leo thang quyền/giả mạo owner/UID | Chưa xác minh; hiện app local không có khái niệm account | Cần enforcement trong PostgreSQL policy/backend/Storage Rules, không dựa vào trạng thái UI. |
| Ba tài khoản độc lập A/B/C và kiểm thử ma trận quyền | Chưa có | 18 tests hiện tại không sử dụng tài khoản cloud; chưa có integration test/evidence. |
| Xử lý lỗi upload thành công nhưng insert metadata thất bại và ngược lại | Chưa có | Chưa tồn tại hai hệ thống cần phối hợp. |
| Báo cáo/schema/security/test evidence | Chưa có ngoài audit này | Cần tạo các tài liệu submission trong giai đoạn triển khai sau khi xác nhận yêu cầu. |

## 6. Đánh giá Firebase ↔ Supabase identity và quyền truy cập

### Supabase PostgreSQL

Phương án ưu tiên để đánh giá trước khi viết code là dùng tích hợp Firebase Authentication làm third-party auth của Supabase nếu project/plan hiện có hỗ trợ và có thể cấu hình/kiểm tra được. Firebase ID token phải được Supabase xác minh; client không tự gửi một UID/email do người dùng nhập làm bằng chứng xác thực. Mọi truy vấn database phải dùng client/token đã đăng nhập và chịu RLS.

Trước khi dựa vào policy cần kiểm chứng token thực tế (`iss`, `aud`, `sub`, thời hạn, role/claims) trên môi trường thử nghiệm. Cần xác nhận cách policy lấy Firebase UID từ claim `sub` và kiểu dữ liệu return của helper như `auth.uid()` với tích hợp đang chọn; không giả định `auth.uid()` tự khớp Firebase UID. Có thể lưu Firebase UID dạng `text` trong `public.users.id`/owner/permission nếu policy so sánh claim đã xác minh dưới dạng chuỗi. Nếu tích hợp native không đáp ứng, phương án thay thế là backend tin cậy xác minh Firebase ID token rồi cấp/ủy quyền request Supabase; không đặt service-role key trong ứng dụng.

Schema dự kiến cần owner rõ ràng: `users` có ID Firebase UID; `documents.owner_id` FK tới users và metadata/path; `document_permissions` có document, user, role có ràng buộc `viewer|editor`, unique `(document_id,user_id)`. Policy phải phân biệt owner/viewer/editor và giới hạn thao tác permission cho owner. RLS là lớp bắt buộc, không thay bằng lọc dữ liệu phía client.

### Firebase Storage

RLS của Supabase không kiểm soát Firebase Storage. Firebase Storage Rules cũng không truy vấn trực tiếp các bảng permission trong Supabase. Quy tắc chỉ cho owner truy cập theo UID/path chưa đủ để cấp quyền đọc an toàn cho user được chia sẻ.

**Phương án an toàn đề xuất cho luồng chia sẻ file:** tệp private, path không chứa thông tin nhạy cảm và có owner UID; upload/delete của owner có thể được giới hạn trực tiếp bằng Firebase Rules. Trước khi cấp quyền đọc tệp chia sẻ, gọi backend tin cậy (ví dụ HTTPS/Callable Function) để backend xác minh Firebase ID token, truy vấn quyền hiện hành trong Supabase và chỉ trả URL ký có thời hạn ngắn hoặc proxy stream. Không chứa Firebase Admin credential/Supabase service-role key trong Flutter. URL ký là bearer credential nên phải ngắn hạn, không lưu như nguồn dữ liệu lâu dài và không ghi vào log. Cần xác nhận backend có được phép triển khai hay không.

Custom claims đồng bộ quyền chia sẻ lên Firebase là phương án khác nhưng cập nhật/thu hồi có độ trễ cho tới khi token refresh; không nên coi là cơ chế thu hồi tức thời nếu không bổ sung kiểm soát khác.

### Tính toàn vẹn metadata và file

- Upload thành công nhưng insert metadata lỗi có thể tạo object mồ côi: dùng staging/idempotency, cleanup có retry và có quy trình phát hiện object mồ côi.
- Xóa metadata và xóa object không thể giả định cùng transaction phân tán: định nghĩa thứ tự, trạng thái pending-delete/outbox/retry hoặc reconciliation; không báo thành công giả nếu một phía thất bại.
- Lưu `storage_path` ổn định trong DB; không lưu binary vào PostgreSQL hoặc dùng URL tải hết hạn làm nguồn dữ liệu chính.
- Validate tên, MIME, dung lượng và phần mở rộng ở cả client lẫn trusted backend/Storage Rules; MIME từ client không phải bằng chứng tin cậy tuyệt đối.
- Chỉ owner được xóa document/quản lý chia sẻ; editor chỉ được cập nhật metadata được phép; viewer chỉ đọc; người ngoài không thấy metadata hoặc tải file.
- Tìm user để chia sẻ cần tránh lộ danh sách/email không cần thiết; xác định chính sách user lookup và xử lý người nhận chưa đăng ký.
- Không có dữ liệu đủ để biết SQLite hiện có tài liệu/tệp người dùng cần chuyển lên cloud. Cần quyết định chiến lược import/giữ local/khởi đầu cloud trống; chuỗi `filePath` hiện tại không chứng minh file còn tồn tại.

## 7. Danh mục file: tái sử dụng, sửa, thêm

Phân loại này là đề xuất cho các giai đoạn sau, không có file ứng dụng nào trong các danh mục sửa/thêm được tạo trong audit này.

### Có thể tái sử dụng

| File/thư mục hiện có | Cách tái sử dụng |
|---|---|
| `mm/lib/pages/document_list_page.dart` | Giữ màn hình và bố cục list/search/filter; thay nguồn dữ liệu qua service để chỉ hiện dữ liệu được phép. |
| `mm/lib/pages/document_detail_page.dart` | Giữ khung chi tiết; thay hiển thị đường dẫn thành metadata và hành động mở/tải có ủy quyền. |
| `mm/lib/pages/document_form_page.dart`, `mm/lib/widgets/document_form.dart` | Giữ form/state và validation hiện có; bổ sung chọn tệp, mô tả đúng field, trạng thái upload và quyền. |
| `mm/lib/widgets/document_card.dart`, `document_filter.dart`, `document_search.dart`, `empty_state.dart` | Tái sử dụng presentation sau khi kiểm tra quyền và states cloud. |
| `mm/lib/struct/document_type.dart`, `mm/lib/config/app_theme.dart` | Tái sử dụng enum và theme; enum có thể cần mapping ổn định với Postgres. |
| `mm/lib/config/app_dependencies.dart` | Mở rộng composition cho auth/storage/document services; giữ pattern truyền dependencies hiện tại, không thêm state library nếu chưa cần. |
| `mm/lib/services/document_service.dart` | Tái sử dụng trách nhiệm/use-case và validation; chuyển persistence sang API cloud hoặc abstraction nhỏ, không giữ local DAO làm nguồn dữ liệu cloud. |
| `mm/test/document_service_test.dart`, `document_dao_test.dart`, `database_test.dart` | Bảo toàn các test local cần thiết; bổ sung unit/integration tests thay vì xóa hoặc làm yếu chúng. |

### Cần sửa (khi triển khai)

| File/thư mục | Lý do |
|---|---|
| `mm/pubspec.yaml`, `mm/pubspec.lock` | Thêm dependency cloud/file cần thiết với phiên bản tương thích target và SDK; cân nhắc giữ/bỏ `sqlite3_flutter_libs` chỉ sau khi quyết định vai trò Drift/platform. |
| `mm/lib/main.dart` | Khởi tạo Firebase/Supabase đúng thứ tự, phục hồi auth và chọn login/protected screen mà không phá home flow; hiện khởi động thẳng vào list. |
| `mm/lib/config/app_dependencies.dart` | Tạo/cấp auth, document, storage services; đảm bảo lifecycle/close đúng. |
| `mm/lib/database/app_database.dart`, `tables.dart`, `daos/*` | Nếu Drift chỉ là cache/local legacy, xác định schema/migration/import; nếu Web target phải có database implementation phù hợp. Không tự xóa dữ liệu local. |
| `mm/lib/struct/document.dart` và DTO/model liên quan | Chuyển ID số local sang ID cloud phù hợp, bổ sung owner/storage/mime/size/timestamps và role/permission một cách tương thích. |
| `mm/lib/services/document_service.dart` | Tích hợp Supabase, RLS, search, metadata update, sharing; quy định rõ lỗi/retry và không tin input UID. |
| `mm/lib/pages/document_list_page.dart`, `document_detail_page.dart`, `document_form_page.dart`, `home_page.dart` | Auth states, cloud states, sharing UI, file actions và quyền theo role; chỉ mở rộng navigation cần thiết. |
| `mm/lib/widgets/document_form.dart`, `document_card.dart` | Khắc phục title field trùng/description thiếu; chọn file và hiển thị metadata/quyền/trạng thái. |
| `mm/android/settings.gradle.kts`, `android/app/build.gradle.kts`, manifest và cấu hình iOS/Web tùy target | Áp dụng cấu hình Firebase/Google thực tế (plugin, OAuth callbacks/client config, SHA hoặc URL scheme khi yêu cầu). Chưa cấu hình hiện tại. |
| `mm/analysis_options.yaml` hoặc Dart files có cảnh báo | Chỉ xử lý lint có liên quan; không che lint rộng để làm sạch báo cáo. |

### Cần thêm (khi triển khai)

| File/thư mục đề xuất | Lý do |
|---|---|
| `mm/lib/services/auth_service.dart` (hoặc tương đương) | Bọc Firebase Auth/Google Sign-In, restore, cancel, logout, token và lỗi. |
| `mm/lib/services/storage_service.dart` | Chọn/upload/download/delete và kiểm soát lỗi tệp; không đặt policy chỉ ở UI. |
| `mm/lib/repositories/document_repository.dart` (chỉ nếu cần tách cloud data access) | Bao bọc Supabase queries; hiện không có repository. Có thể giữ service trực tiếp dùng client nếu đó là thay đổi nhỏ hơn, không bắt buộc tạo layer chỉ vì sở thích. |
| Model permission/user/document cloud cần thiết | Biểu diễn người dùng, document UUID/owner/storage path và role rõ kiểu. |
| `mm/supabase/migrations/*.sql` | Version hóa schema, constraints, indexes, grants và RLS policies. |
| `mm/supabase/config.toml` / seed test an toàn (nếu được dùng) | Quản lý cấu hình migration cục bộ, không chứa secret. |
| Firebase Storage Rules và rules test/config cho Functions/backend | Bảo vệ object độc lập với RLS; hỗ trợ đọc file share qua trusted authorization flow. |
| Backend Function/API (nếu chọn mô hình ký URL/proxy) | Xác minh token Firebase và permission Supabase trước khi trả file. |
| Firebase platform configuration files | Sinh/thiết lập qua Firebase project đúng; không tạo file giả/placeholder rồi coi như cấu hình hoàn tất. |
| Integration/security tests và các `docs/*` submission | Kiểm tra 3 tài khoản, RLS, Storage, migration consistency và lưu evidence thật. |

## 8. Quyết định/prerequisite cần xác nhận

1. Nền tảng bắt buộc khi demo/nộp bài là Android, iOS, Web hay nhiều nền tảng? Android/iOS là hướng mobile tự nhiên từ cấu trúc dự án; Web hiện không tương thích database native. Lỗi `sqlite3` ban đầu xảy ra với target nào?
2. Supabase project/plan có thể bật third-party Firebase Auth và cấu hình provider để Supabase xác thực Firebase ID token không? Nếu không, có backend tin cậy (Firebase Function/API) để kiểm tra token và quyền không?
3. Có cần migrate dữ liệu SQLite/tệp hiện tại hay bắt đầu cloud trống? Nếu cần migrate, file gốc còn tồn tại ở vị trí nào?
4. Có cho phép thêm backend Function/API để chia sẻ tệp private không? Nếu không, cần thống nhất giới hạn bảo mật/UX của phương án thay thế trước khi mở quyền file share.
5. Quy định chia sẻ: tìm người nhận theo email/UID nào, viewer/editor được thay đổi những metadata gì, giới hạn MIME/dung lượng nào?
6. Firebase/Supabase project, OAuth configuration, app IDs và tài khoản test 3 người đã sẵn sàng chưa? Không cung cấp secret trong chat/mã client.

## 9. Giới hạn audit

Đây là đánh giá tĩnh các file đã được đọc và kết quả chạy `flutter test`/`flutter analyze`. Chưa truy cập Firebase Console/Supabase Dashboard, chưa xác minh cloud credentials/rules, chưa build các target, chưa thử UI trên thiết bị và chưa thực hiện test tài khoản. Các mục không tìm thấy trong workspace được báo là “không thấy/chưa có bằng chứng”, không suy diễn về cấu hình ngoài workspace.

## 10. Cập nhật sau audit — khởi tạo Supabase

Sau khi người dùng chọn hướng Firebase Authentication (Google) kết hợp Firebase Third-Party Auth của Supabase để khảo sát tiếp, `mm/pubspec.yaml` đã có dependency `supabase_flutter ^2.18.3` (lockfile: 2.18.3), và `mm/lib/main.dart` đã được cập nhật để gọi `Supabase.initialize` với URL và publishable key do người dùng cung cấp. Luồng màn hình hiện hữu vẫn được giữ nguyên.

Đây chỉ là khởi tạo SDK/client. **Chưa** có Firebase Authentication/Google Sign-In, chưa truyền Firebase ID token vào Supabase, chưa xác minh cấu hình Third-Party Auth/claims trên Supabase project và chưa gọi bảng Todos hay dữ liệu cloud nào. Vì vậy Supabase chưa được xem là đã xác thực người dùng và không được dùng để truy cập dữ liệu cần bảo vệ trước khi hoàn thành gate identity.

Sau thay đổi, `flutter test` vẫn đạt 18/18; `flutter analyze` vẫn có 7 issue (1 info, 6 warning), bằng số lượng baseline lúc audit. Build nền tảng và xác minh kết nối dashboard chưa chạy.

## 11. Tiến độ tích hợp Firebase Auth (đang triển khai)

Người dùng cung cấp phạm vi yêu cầu: Google Sign-In qua Firebase Authentication để xác thực và lấy Firebase UID; Firebase Storage chứa tệp; Supabase giữ users/documents/permissions; tìm kiếm/cập nhật/chia sẻ; RLS; kiểm thử tối thiểu ba tài khoản. Cũng đã chọn khảo sát Firebase Third-Party Auth của Supabase làm identity bridge.

Đã thêm `firebase_core ^4.15.0`, `firebase_auth ^6.7.0`, `google_sign_in ^7.2.0`; lockfile resolve lần lượt 4.15.0, 6.7.0, 7.2.0. Mã mới:

- `mm/lib/services/auth_service.dart`: Google Sign-In → Google ID token → Firebase credential; hỗ trợ hủy và Firebase Auth stream/logout.
- `mm/lib/pages/sign_in_page.dart`: giao diện đăng nhập, loading và hiển thị lỗi.
- `mm/lib/pages/auth_gate.dart`: chờ/khôi phục Firebase auth state và định tuyến trạng thái đăng nhập.
- `mm/lib/pages/signed_in_page.dart`: trang tạm cho user đã đăng nhập, hiển thị trạng thái chưa kết nối cloud và logout.
- `mm/lib/main.dart`: khởi tạo Firebase và Google Sign-In trước Supabase; Supabase `accessToken` callback lấy Firebase ID token hiện hành.
- `mm/lib/config/app_dependencies.dart`: đăng ký AuthService theo pattern dependency composition hiện hữu.

**Giới hạn/bảo vệ dữ liệu:** do Supabase chưa có schema/RLS và Drift hiện không gắn owner UID, AuthGate chủ động không hiển thị danh sách SQLite cục bộ cho user đăng nhập. Đây là trạng thái tạm thời để tránh tài liệu của một tài khoản bị thấy bởi tài khoản khác; không có fallback dữ liệu không xác thực.

**Chặn cấu hình runtime:** không tìm thấy `google-services.json`, `GoogleService-Info.plist` hoặc `firebase_options.dart`. `Firebase.initializeApp()` Android chưa thể chạy thành công cho tới khi Firebase project thật được cấu hình. Google Sign-In còn cần OAuth client/provider tương ứng. Không tạo file cấu hình giả và chưa chỉnh Gradle/plugin native vì thiếu Firebase project config thật.

**Tích hợp Supabase:** SDK `supabase_flutter 2.18.3` có callback `accessToken` dùng cho third-party auth; app hiện trả Firebase `getIdToken()` ở đó. Cấu hình provider trong Supabase Dashboard, claims/token thật, JWT verification và policy UID mapping chưa được xác minh. Không có truy vấn Postgres nào được triển khai ở bước này.

**Kiểm tra tại thời điểm Auth:** sau khi thêm Auth, Problems tool báo không có compile errors trong các file Auth được kiểm tra và `flutter test` đạt 18/18. `flutter analyze` còn 6 issue (1 info, 5 warning; giảm một warning do bỏ import thừa trong file đã sửa). Android APK debug build thành công và được cài lên Pixel_8_2, nhưng app dừng ngay khi khởi tạo Firebase: `Failed to load FirebaseOptions from resource. Check that you have defined values.xml correctly.` Thiết bị/emulator hoạt động, nhưng runtime Firebase chưa cấu hình. `flutter run` vì vậy không đạt trạng thái sẵn sàng sử dụng. Chưa chạy đăng nhập trên thiết bị, cloud calls, RLS/Storage test hoặc test ba tài khoản.

## 12. Tiến độ triển khai cloud — 2026-10-13

Người dùng yêu cầu tiếp tục checklist và chọn phương án **Firebase Storage riêng tư + Firebase Callable Function xác minh quyền Supabase trước khi cấp signed URL ngắn hạn**. Hướng này giữ Firebase Storage cho binary, Supabase làm metadata/ACL; signed URL là bearer credential, hết hạn sau 5 phút và không được lưu làm metadata lâu dài.

### Đã thêm trong workspace

- `mm/lib/models/cloud_document.dart`: DTO cloud với owner, metadata, Storage path và role.
- `mm/lib/services/cloud_document_service.dart`: upsert profile, tìm kiếm qua RPC, CRUD metadata, upload/replace/delete file, chia sẻ/thu hồi quyền và gọi Function lấy URL tải có ủy quyền.
- `mm/lib/pages/signed_in_page.dart`: thay trang placeholder sau đăng nhập bằng danh sách cloud, tìm kiếm/lọc và khởi tạo profile.
- `mm/lib/pages/cloud_document_form_page.dart`, `cloud_document_detail_page.dart`: form metadata/file, tải tệp, chia sẻ và quản lý/revoke quyền.
- `mm/lib/config/app_dependencies.dart`, `auth_gate.dart`, `main.dart`: nối cloud service vào luồng auth hiện tại.
- `mm/supabase/migrations/20261013223000_initial_document_schema.sql`: schema/RLS và RPC tìm kiếm, liệt kê quyền, chia sẻ/thu hồi; đã áp dụng vào project dev/test sau xác nhận của người dùng.
- `mm/storage.rules`: chỉ chủ sở hữu được truy cập trực tiếp object; người được chia sẻ phải qua backend.
- `mm/functions/src/index.ts`: Callable Function xác minh Firebase caller, đọc permission theo UID trong Supabase bằng secret server-side và cấp signed URL 5 phút.
- `mm/firebase.json`, `mm/functions/package.json`, `mm/functions/tsconfig.json`, lockfile: cấu hình nguồn Functions/Storage Rules và dependency backend.
- `mm/pubspec.yaml`, `mm/pubspec.lock`: thêm Firebase Storage, Cloud Functions, file picker và URL launcher.

### Trạng thái xác minh, giới hạn còn lại

- `npx supabase link --project-ref fzzsffkeajsqjjaljojk` thành công. Sau xác nhận project dev/test và migration chưa chạy, `supabase db push --linked` đã áp dụng migration `20261013223000`; `supabase migration list --linked` xác nhận lịch sử local/remote khớp. Read-only query xác nhận ba bảng, bốn RPC và 11 RLS policies tồn tại. Chưa xác minh provider Firebase Third-Party Auth/claim `sub` trong Supabase.
- Firebase Android app `1:644994258114:android:b237d407e2e7596ecbd75b` đã được đăng ký trong project `document-management-ecf5c` cho `com.example.mm`; CLI tải `android/app/google-services.json`, và debug SHA-1/SHA-256 đã đăng ký. Google provider vẫn chưa được bật; iOS/Web không được cấu hình. App có thể khởi động Android nhưng sign-in thật chưa xác minh.
- Firebase CLI xác nhận Storage service chưa được setup trên project; chưa có bucket khả dụng để deploy Rules. Người dùng đã chọn `asia-southeast1` (Singapore), nhưng việc khởi tạo bucket trong Firebase Console vẫn đang chờ. Storage Rules/Callable Function chưa được deploy.
- Storage deploy dry-run dừng với `Firebase Storage has not been set up`; CLI đã bật Storage API nhưng không tạo bucket hay thay Storage Rules. Firebase Console hiện báo Storage cần Blaze billing và nút Upgrade project; chưa thực hiện upgrade.
- `flutter test`: 18 passed. `flutter analyze`: không còn error; còn 4 issue có sẵn ngoài phần cloud (1 info trong `document_dao.dart`, 3 unused-import warnings ở widgets/tests).
- Android debug APK build thành công sau khi thêm packages; Gradle đưa ra cảnh báo plugin Firebase đang dùng Kotlin Gradle Plugin theo cơ chế cũ, không phải lỗi build. Chưa khởi chạy APK do thiếu Firebase app config.
- TypeScript Cloud Function đã qua `npx tsc --noEmit`; không có test runtime/backend hoặc deploy.
- Không có test bằng ba tài khoản độc lập. RLS, Firebase Storage Rules, direct-object denial, share/revoke, signed URL, migration và token bridge đều **chưa xác minh runtime**.
- Migration initial hiện đã được ghi nhận trên remote; không chạy lại thủ công. Các thay đổi schema về sau phải được tạo thành migration mới.
- Upload dùng memory buffer và giới hạn 20 MB; file MIME do client khai báo không thay thế kiểm tra virus/nội dung. Khi xóa metadata thành công nhưng Firebase Storage delete thất bại, lỗi được báo và có thể còn object cần dọn.
- Tải file mở bằng signed URL trong ứng dụng ngoài; người nhận có thể chuyển tiếp URL trong thời hạn 5 phút. Muốn ngăn chia sẻ lại tuyệt đối cần proxy stream thay cho signed URL.

### Kết luận checklist hiện tại

Mã ứng dụng, schema/RLS draft, Storage Rules và backend authorization flow đã được bổ sung, nhưng checklist **chưa hoàn tất ở mức cloud vận hành** cho tới khi cấu hình Firebase thật, bật và xác minh Supabase Firebase provider, áp dụng migration phù hợp với lịch sử remote, deploy Rules/Function và chạy ma trận ba tài khoản có bằng chứng.

## 13. Cập nhật kiến trúc theo quyết định người dùng — 2026-10-13

Người dùng quyết định loại Firebase Storage khỏi giải pháp do yêu cầu billing.
Kiến trúc mục tiêu hiện tại là Firebase Authentication + Supabase PostgreSQL +
Supabase Storage private. Mục này thay thế các đề xuất Firebase Storage ở
phần lịch sử phía trên.

### Trạng thái mã nguồn mới nhất

- `mm/lib/services/supabase_storage_service.dart` là lớp lưu trữ file mới:
  bucket private `documents`, giới hạn 20 MiB, MIME allowlist, object path
  `<uid>/<document-uuid>/<timestamp>_<filename>`, URL tải ký hạn 60 giây.
- `mm/lib/services/cloud_document_service.dart` đã được chuyển từ Firebase
  Storage/Callable Function sang Supabase Storage. Upload/replace dùng object
  mới trước khi đổi metadata; lỗi dọn file được báo rõ, không trả về success.
- `mm/supabase/migrations/20261013233500_supabase_private_document_storage.sql`
  thêm bucket và policies owner/viewer/editor; đã apply vào linked dev/test.
- Đã xóa Firebase Storage/Functions SDK usages, `mm/storage.rules`,
  `mm/firebase.json` và source/manifest/lockfile của Functions.
- Firebase Auth, Google Sign-In, Android `google-services.json`, `.firebaserc`,
  Supabase project URL/publishable key vẫn được giữ.
- `mm/test/supabase_storage_service_test.dart` bổ sung unit tests cho path,
  MIME, giới hạn kích thước và path segments; cả 3 tests mới đã chạy pass.

### Kiểm chứng cloud chỉ đọc trong lượt này

- `npx supabase migration list --linked`: initial migration `20261013223000`
  vẫn áp dụng ở remote.
- Read-only SQL: policies hiện có cho ba bảng `users`, `documents`,
  `document_permissions`. Trước khi chạy migration mới, bucket `documents` và
  policies `storage.objects` chưa tồn tại; migration additive đã tạo chúng.
- Migration Storage được apply vào dev/test; không xóa dữ liệu hay sửa migration
  ban đầu.
- Read-only SQL sau migration xác nhận bucket private `documents`, limit 20 MiB,
  MIME allowlist, bốn Storage policies và migration version
  `20261013233500`.
- Supabase Firebase Third-Party Auth/JWT mapping, Google provider runtime,
  Android sign-in, Storage operations và test A/B/C vẫn chưa xác minh.
- `flutter pub get`: pass sau khi xóa dependency Firebase Storage/Functions.
- `flutter test`: 21 tests passed (18 existing + 3 new storage helper tests).
- `flutter analyze`: exit code 1 do 4 issue ngoài file mới/sửa (1 info trong
  `document_dao.dart`, unused imports trong `document_card.dart`,
  `database_test.dart` và `document_dao_test.dart`).
- `flutter build apk --debug`: pass; còn warning KGP từ plugin Firebase Auth.
- Functions/backend test không áp dụng vì toàn bộ Callable Function đã bỏ.

### Rủi ro còn lại

Firebase ID token callback có trong `main.dart`, nhưng cấu hình Supabase
Third-Party Auth và claim `sub` cần Dashboard + token thật. `ensureProfile`
được dùng làm cổng trước truy vấn tài liệu; nếu server không chấp nhận token,
UI chỉ nên báo lỗi và không tải dữ liệu. Supabase Storage object và PostgreSQL
metadata không transactional; process termination có thể để lại private orphan
object cần đối soát. Signed URL là bearer credential tới khi hết hạn 60 giây.

### Bổ sung audit identity/runtime

- Firebase ID token mặc định không có `role: authenticated`. Tài liệu Supabase
  Third-Party Auth yêu cầu claim này để dùng PostgreSQL role `authenticated`;
  hiện schema chỉ grant protected operations cho role đó. Vì vậy Google
  sign-in/token callback trong mã không đủ chứng minh profile upsert có thể
  chạy. Cần một trusted Firebase-side claim issuer; chưa có issuer trong repo.
- `mm/android/app/google-services.json` hiện có Android OAuth client và web
  client entries, nhưng file này không chứng minh Firebase Google provider
  đã bật hay sign-in đã chạy thành công. `mm/google-services.json` là bản
  cấu hình bổ sung ngoài vị trí Android Gradle chuẩn và không được runtime
  Android tự đọc.
- Đã phát hiện và sửa rủi ro reuse `SignedInPage` khi Firebase UID đổi: danh
  sách cũ/profile-ready được reset, và kết quả async cũ bị bỏ qua theo
  generation/UID. Unit tests cho capability owner/editor/viewer không phải
  kiểm thử enforcement của RLS.
- OAuth thật, role claim, token claims, thao tác cloud và phân quyền A/B/C
  vẫn chưa xác minh được nếu không có tài khoản và môi trường Firebase/Supabase
  thực tế. Không được đánh dấu hoàn tất dựa trên cấu hình source hoặc dashboard
  một mình.
- Khi chạy emulator Android, Firebase khôi phục một phiên đăng nhập hiện có;
  upsert hồ sơ vào `users` bị PostgreSQL trả `42501` (RLS violation). App
  hiển thị trạng thái fail-closed và không tiếp tục gọi tìm kiếm tài liệu.
  Đây chưa phải kiểm chứng Google OAuth mới hoặc bằng chứng xác định claim
  nào sai; xem `docs/TEST_RESULTS.md`.
