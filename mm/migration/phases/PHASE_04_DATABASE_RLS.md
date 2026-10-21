# PHASE 04 — Migration danh tính, dữ liệu và RLS

## Cảnh báo
Đây là phase có nguy cơ làm mất quyền truy cập tài liệu hoặc làm sai quyền chia sẻ. **Không thay đổi production trước khi có kế hoạch được người dùng duyệt.**

## Điều kiện tiên quyết
- Phase 03 được kiểm thử và duyệt.
- Đã thu thập schema hiện tại của `users`, `documents`, `document_permissions`.
- Đã thu thập definitions của RLS policies/functions liên quan.
- Đã xác định Firebase UID cũ, Supabase Auth UID mới và chiến lược mapping.
- Có backup/khả năng khôi phục và môi trường test.

## Mục tiêu
Chuyển mô hình xác định người dùng và kiểm soát truy cập từ Firebase UID/JWT sang Supabase Auth UID/JWT mà vẫn bảo toàn dữ liệu và quyền.

## Trước khi thay đổi
1. Tạo báo cáo hiện trạng schema, indexes, constraints, triggers, functions, grants, RLS policies.
2. Xác định tất cả bảng/cột đang lưu Firebase UID, gồm cả bảng quyền chia sẻ và bảng phụ.
3. Lập kế hoạch mapping cũ → mới. Không giả định UID/email giống nhau.
4. Phân tích tài khoản trùng email, tài khoản không còn đăng nhập, chủ sở hữu đã mất quyền truy cập và người được chia sẻ.
5. Lập backup và rollback cụ thể.
6. Chuẩn bị migration SQL có thể review, ưu tiên transaction/idempotency khi phù hợp.
7. Chạy thử trên bản sao hoặc dữ liệu test và xác minh số lượng bản ghi trước/sau.
8. Trình bày kế hoạch và chờ **chấp thuận rõ ràng** trước khi áp dụng vào production.

## Thiết kế RLS
- Dùng identity claim do Supabase Auth phát hành theo đúng cơ chế được tài liệu Supabase xác nhận, thường là `auth.uid()` cho UUID Auth ID.
- Vì `public.users.id`/`documents.owner_id` từng được mô tả là `text`, phải kiểm tra schema thực tế và quyết định kiểu dữ liệu có chủ đích; không ép cast hoặc đổi kiểu hàng loạt tuỳ tiện.
- Giữ nguyên nguyên tắc least privilege.
- Kiểm tra riêng SELECT/INSERT/UPDATE/DELETE cho chủ sở hữu, viewer, editor và người không được chia sẻ.
- Kiểm tra function `SECURITY DEFINER`, `search_path`, grants và quyền thực thi.
- Không tắt RLS, không cấp quyền rộng cho `anon`, không tạo policy cho phép tất cả.
- Không chỉ sửa policy documents mà bỏ quên `document_permissions`, `users`, storage objects hoặc các truy vấn liên quan.

## Việc cần làm sau khi được duyệt
1. Thực hiện theo đúng migration plan đã duyệt.
2. Kiểm tra constraints và dữ liệu orphan.
3. Xác minh số lượng/quan hệ bản ghi trước-sau.
4. Chạy test quyền bằng các user test riêng.
5. Ghi lại lệnh/script đã chạy, thời điểm, kết quả và phương án rollback.

## Đầu ra
- `migration/reports/PHASE_04_IDENTITY_RLS_PLAN.md`
- SQL migration chỉ sau khi được duyệt.
- `migration/reports/PHASE_04_IDENTITY_RLS_REPORT.md`
- Cập nhật context/progress.

## Điều kiện hoàn thành
- Mapping UID được kiểm chứng.
- Chủ sở hữu và quyền chia sẻ được bảo toàn.
- RLS tests đạt.
- Backup/rollback được ghi lại.
- Người dùng duyệt kết quả trước Phase 05.

## Dừng ngay nếu
- Không có backup hoặc rollback khả thi.
- Không thể xác định UID chủ sở hữu.
- Số lượng bản ghi/quan hệ thay đổi ngoài dự kiến.
- Có nguy cơ tài liệu bị lộ hoặc mất quyền.
