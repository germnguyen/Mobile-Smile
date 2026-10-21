# Hướng dẫn Agent — Migration sang Supabase Auth

## Mục tiêu
Di chuyển ứng dụng Flutter quản lý tài liệu từ Firebase Authentication sang Supabase Auth sử dụng Google OAuth, đồng thời giữ Supabase làm backend dữ liệu, quyền chia sẻ và lưu trữ hiện có.

## Quy tắc bắt buộc
1. Chỉ thực hiện **một giai đoạn mỗi lần**.
2. Trước khi làm, chỉ đọc:
   - `AGENTS.md`
   - `migration/MIGRATION_CONTEXT.md`
   - `migration/MIGRATION_PROGRESS.md`
   - file của giai đoạn đang được yêu cầu trong `migration/phases/`
3. Chỉ đọc thêm các file mã nguồn thực sự liên quan đến giai đoạn hiện tại. Không quét lại toàn bộ repo nếu chưa có lý do cụ thể.
4. Không tự suy đoán schema, tên cột, API đang dùng hoặc trạng thái môi trường. Kiểm tra trong source code hoặc yêu cầu người dùng cung cấp thông tin còn thiếu.
5. Không thực hiện thay đổi dữ liệu production, SQL phá huỷ, migration dữ liệu hoặc thay đổi RLS diện rộng nếu chưa có kế hoạch, backup/rollback và sự chấp thuận rõ ràng của người dùng.
6. Không tắt RLS, không tạo policy mở rộng cho `anon`, không đưa service-role key hoặc secret vào mã Flutter, Git, log hay tài liệu.
7. Không xoá Firebase packages, `google-services.json`, cấu hình Firebase hoặc code cũ cho đến khi giai đoạn xác thực mới đã được kiểm thử thành công và có xác nhận của người dùng.
8. Không in giá trị secret/token/API key vào báo cáo. Nếu phát hiện secret bị hard-code, chỉ mô tả vị trí và đề xuất xử lý an toàn; không sao chép giá trị.
9. Không sửa ngoài phạm vi giai đoạn. Nếu phát hiện vấn đề thuộc giai đoạn sau, ghi vào báo cáo và dừng tại đó.
10. Sau khi hoàn thành, cập nhật `migration/MIGRATION_PROGRESS.md`, `migration/MIGRATION_CONTEXT.md` nếu có quyết định mới, và báo cáo của giai đoạn hiện tại.

## Quy trình làm việc
- Đọc các tài liệu điều phối nêu trên.
- Xác nhận đúng giai đoạn và điều kiện tiên quyết.
- Khảo sát đúng các file liên quan.
- Nêu kế hoạch ngắn trước khi sửa.
- Thực hiện thay đổi nhỏ, có thể kiểm tra được.
- Chạy các kiểm tra phù hợp; ghi rõ lệnh và kết quả thực tế.
- Cập nhật tài liệu tiến độ.
- Báo cáo: đã làm gì, file nào thay đổi, kiểm tra nào chạy, việc gì còn chờ người dùng, cách rollback.
- Nếu cần dashboard, Google Cloud Console, Supabase Dashboard hoặc thông tin bí mật mà Agent không thể truy cập, hãy hướng dẫn người dùng thao tác thủ công; không giả vờ đã thực hiện.

## Cách xử lý trạng thái
- `NOT_STARTED`: chưa bắt đầu.
- `IN_PROGRESS`: đang làm.
- `BLOCKED`: thiếu thông tin hoặc điều kiện tiên quyết.
- `READY_FOR_REVIEW`: đã làm xong phần của giai đoạn, chờ người dùng kiểm tra.
- `APPROVED`: người dùng đã chấp thuận kết quả.
- `DONE`: giai đoạn đã được xác nhận hoàn tất.

Không tự đánh dấu `APPROVED` hoặc `DONE` thay người dùng.
