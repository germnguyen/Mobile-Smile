# Migration Context — Flutter + Supabase Auth

## 1. Mục tiêu sản phẩm
Ứng dụng Flutter quản lý tài liệu đa nền tảng, hiện ưu tiên Android. Người dùng đăng nhập Google, quản lý tài liệu và chia sẻ quyền xem/chỉnh sửa với người dùng khác.

## 2. Quyết định kiến trúc hiện tại
- Hướng di chuyển đã chọn: **Supabase Auth + Google OAuth**.
- Không tiếp tục dùng Firebase Authentication làm nhà cung cấp danh tính cho luồng đăng nhập chính.
- Tiếp tục dùng Supabase Postgres, RLS, các bảng tài liệu/quyền chia sẻ và Supabase Storage hiện có nếu kiểm tra xác nhận chúng đang được sử dụng.
- Mục tiêu là bảo toàn dữ liệu hiện có; không xoá bảng hoặc dữ liệu để “làm sạch” migration.
- Firebase có thể còn được dùng ở nơi khác trong dự án; chỉ loại bỏ dependency/cấu hình Firebase sau khi tìm toàn bộ nơi sử dụng và được người dùng duyệt.

## 3. Đường dẫn dự án
Thư mục dự án Flutter được người dùng cung cấp:
`D:\TLU\Mobile\Repo\Mobile-Smile\mm`

Đường dẫn có thể thay đổi; hãy xác nhận workspace đang mở trước khi thao tác.

## 4. Backend hiện có — thông tin lịch sử cần xác minh
Supabase project URL từng được cung cấp:
`https://fzzsffkeajsqjjaljojk.supabase.co`

Firebase project ID cũ:
`document-management-ecf5c`

Không cần dùng Firebase project ID cho luồng Auth mới, trừ khi đang kiểm tra code cũ hoặc lập kế hoạch rollback.

Các bảng Supabase từng được xác nhận:
- `public.users`: `id text NOT NULL`, `email`, `display_name`, `avatar_url`, `created_at`, `updated_at`.
- `public.documents`: `id uuid`, `owner_id text NOT NULL`, `title`, `description`, `subject`, `document_type`, `storage_path`, `mime_type`, `file_size_bytes`, `created_at`, `updated_at`.
- `public.document_permissions`: tồn tại; schema chi tiết cần kiểm tra trước khi viết migration.

Các chi tiết trên là thông tin lịch sử, **không thay thế việc xác minh schema hiện tại**.

## 5. RLS và danh tính cũ — phải xác minh trước khi thay đổi
Các policy/function trước đây từng dựa trên Firebase UID/JWT:
- `app_private.current_firebase_uid()`
- `app_private.is_document_owner(uuid)`
- `app_private.can_read_document(uuid)`
- `app_private.can_edit_document(uuid)`

Một policy insert trên `public.documents` từng kiểm tra `owner_id = app_private.current_firebase_uid()` và yêu cầu tồn tại bản ghi tương ứng trong `public.users`.

Không được giả định các function/policy trên vẫn còn nguyên. Hãy lấy schema/policy thực tế trước khi thiết kế migration.

## 6. Rủi ro danh tính quan trọng
Firebase UID và Supabase Auth UID **không mặc định giống nhau**. Khi chuyển Auth:
- Không thay `owner_id` hàng loạt chỉ vì UID mới khác UID cũ.
- Lập bảng ánh xạ danh tính hoặc kế hoạch chuyển quyền sở hữu có thể kiểm toán.
- Xác định cách xử lý tài khoản cũ, email trùng, tài khoản chưa đăng nhập lại và tài liệu được chia sẻ.
- Bảo đảm quyền của chủ sở hữu/người được chia sẻ không bị mở rộng hoặc mất.
- Có backup, kiểm thử trên dữ liệu thử nghiệm và kế hoạch rollback trước khi áp dụng production.

## 7. Quy tắc bảo mật
- Không đặt Supabase `service_role` key trong Flutter.
- Không ghi token OAuth, access token, refresh token hoặc secret vào log.
- Không tắt RLS để “sửa nhanh”.
- Không tạo policy `USING (true)`/`WITH CHECK (true)` cho dữ liệu riêng tư.
- Không gửi secret trong prompt, commit hoặc báo cáo.
- Dùng đúng redirect URL đã cấu hình và kiểm tra deep link/callback trên Android.

## 8. Phạm vi giai đoạn
1. Audit và tài liệu hoá hiện trạng; chưa sửa hành vi ứng dụng.
2. Cấu hình Google OAuth cho Supabase; xác định dashboard steps và redirect URLs.
3. Chuyển Flutter Auth sang Supabase Auth.
4. Thiết kế và thực hiện migration UID/RLS sau khi được duyệt.
5. Kiểm thử Storage, quyền chia sẻ và luồng tích hợp; chỉ sau đó mới đề xuất dọn Firebase.

## 9. Thông tin cần ghi nhận khi phát hiện
- File và dòng liên quan.
- Hiện trạng đã xác minh và nguồn xác minh.
- Mức độ ảnh hưởng.
- Đề xuất, rủi ro và cách rollback.
- Câu hỏi cần người dùng trả lời.

## 10. Kết quả audit source — 2026-10-21
- Luồng trong source hiện tại đã xác minh vẫn là Google Sign-In lấy Google ID token → Firebase Auth credential/session → Firebase ID token được đưa vào Supabase qua `Supabase.initialize(accessToken: ...)`. Supabase Auth chưa được dùng để đăng nhập ứng dụng.
- `public.users.id`, `documents.owner_id`, `document_permissions.user_id/shared_by` và đoạn đầu `storage_path` hiện được gắn với Firebase UID (`sub` trong token theo các migration có trong repo). Không có mapping Firebase UID ↔ Supabase Auth UID trong source/migration đã kiểm tra; không được giả định hai UID giống nhau.
- Source migration hiện có định nghĩa các bảng profile/document/sharing, `app_private.current_firebase_uid()` và RLS/policies; migration Storage định nghĩa bucket `documents` private và policies dựa trên UID trong path. Đây chỉ là trạng thái migration được commit trong repo, chưa xác minh trạng thái triển khai trên Supabase.
- `firebase_auth`, `firebase_core` và `google_sign_in` còn là dependency trực tiếp và được dùng trong luồng đang chạy. Android cũng áp dụng Google Services Gradle plugin và chứa `google-services.json`. Chưa thấy Firebase Storage/Firestore được dùng trong vùng source/config đã khảo sát; Storage tài liệu dùng Supabase Storage.
- Token provider hiện kiểm tra `sub`, `aud`, `iss` và thời hạn; test provider lại kỳ vọng kiểm tra role `authenticated`, nhưng phần implementation được đọc không thấy kiểm tra role đó. Provider còn gọi RPC `debug_auth_context`; function này không có trong các migration đã khảo sát. Cần xác minh/test riêng trước khi dựa vào các hành vi này.
- Chi tiết file, rủi ro và câu hỏi chưa được xác minh nằm trong [báo cáo Phase 01](reports/PHASE_01_AUDIT_REPORT.md).
- Không có xác minh live schema, policies, bucket, OAuth provider/dashboard, hoặc dữ liệu production trong phiên audit; các nội dung tương ứng vẫn là việc cần xác minh, không phải kết luận về môi trường đang chạy.
