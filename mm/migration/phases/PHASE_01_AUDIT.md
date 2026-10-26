# PHASE 01 — Audit hiện trạng và tạo bản đồ migration

## Mục tiêu
Hiểu đúng cấu trúc auth, database, RLS, storage và chia sẻ tài liệu trước khi sửa code. Tạo tài liệu đủ ngắn để các phase sau không phải đọc toàn bộ repository.

## Phạm vi được phép
- Đọc mã nguồn và cấu hình.
- Chạy lệnh kiểm tra không phá huỷ nếu cần.
- Tạo/cập nhật tài liệu trong `migration/`.
- Không sửa logic ứng dụng, không chạy SQL thay đổi dữ liệu/schema/policy, không thay đổi dashboard.

## Việc cần làm
1. Xác nhận workspace root và framework/package manager.
2. Tìm các file liên quan đến:
   - Khởi tạo Supabase client.
   - Firebase initialization và Firebase Auth.
   - Google Sign-In/OAuth.
   - Auth repository/service/provider/state management.
   - Profile/user creation và mapping UID.
   - Document repository/DAO/service.
   - Document permission/sharing.
   - Upload/download/delete file và storage bucket/path.
   - SQL migrations, schema, RLS policies, functions nếu có trong repo.
   - Tests và cấu hình deep links Android.
3. Vẽ luồng hiện tại bằng sơ đồ văn bản: Google sign-in → Firebase/Supabase session → tạo profile → query/insert document → upload file → chia sẻ.
4. Ghi rõ package và phiên bản liên quan; không đưa secret vào báo cáo.
5. Liệt kê nơi đang dùng Firebase ngoài Auth để tránh xoá nhầm.
6. Xác định các khoảng trống cần người dùng cung cấp, ví dụ schema thật của `document_permissions`, bucket và redirect URL.
7. Đưa ra đề xuất theo từng phase nhưng không triển khai phase 02 trở đi.

## Đầu ra bắt buộc
- `AGENTS.md`
- `migration/MIGRATION_CONTEXT.md`
- `migration/MIGRATION_PROGRESS.md`
- `migration/reports/PHASE_01_AUDIT_REPORT.md`

Nếu các file context đã tồn tại, cập nhật thay vì tạo bản sao khác.

## Điều kiện hoàn thành
- Có danh sách file quan trọng và trách nhiệm của từng file.
- Có sơ đồ luồng Auth/data hiện tại.
- Có danh sách dependencies Firebase còn dùng.
- Có danh sách RLS/functions/policies đã xác minh và những gì chưa thể xác minh.
- Có risk register và câu hỏi cần người dùng trả lời.
- Không có source code nghiệp vụ bị sửa.

## Báo cáo cuối phase
Nêu rõ các lệnh kiểm tra đã chạy, kết quả thực tế, file nào đã đọc/sửa, và xác nhận không thay đổi source/DB. Đánh dấu `READY_FOR_REVIEW`, không tự đánh dấu `DONE`.
