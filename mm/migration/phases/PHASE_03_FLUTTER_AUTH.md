# PHASE 03 — Chuyển luồng Auth trong Flutter sang Supabase Auth

## Điều kiện tiên quyết
- Phase 01 được duyệt.
- Phase 02 đã cấu hình và người dùng xác nhận Google OAuth hoạt động hoặc sẵn sàng kiểm thử.
- Có thể giữ lại code cũ để rollback.

## Mục tiêu
Chuyển đăng nhập/đăng xuất/session và lấy thông tin người dùng từ Supabase Auth. Không thay đổi schema, RLS hay quyền sở hữu dữ liệu trong phase này.

## Phạm vi được phép
- Sửa code Flutter liên quan trực tiếp đến Auth, session, profile UI/state và dependency injection.
- Thêm/cập nhật tests cho Auth.
- Không thực hiện migration UID trong database.
- Không xoá Firebase packages/config cho đến khi kiểm tra toàn bộ nơi sử dụng và có duyệt riêng.

## Việc cần làm
1. Lần theo Auth flow hiện tại và các interface được sử dụng bởi UI.
2. Thiết kế thay đổi nhỏ nhất để thay Firebase Auth bằng Supabase Auth, giữ interface ổn định khi có thể.
3. Dùng API OAuth phù hợp với phiên bản package đang cài; không sao chép API từ phiên bản khác mà chưa kiểm chứng.
4. Đảm bảo trạng thái loading/success/cancel/error rõ ràng.
5. Xử lý session khôi phục sau khi mở lại app và logout.
6. Lấy user ID/email/avatar từ Supabase Auth session/user, nhưng không tự đổi `public.users.id` hoặc `documents.owner_id` trong phase này.
7. Xử lý trường hợp người dùng OAuth thành công nhưng profile row chưa tồn tại; nếu việc tạo row bị RLS chặn, ghi nhận và dừng ở lỗi có kiểm soát thay vì mở RLS.
8. Cập nhật UI/state management theo pattern hiện có trong dự án.
9. Viết/chỉnh tests phù hợp; chạy formatter, analyzer và test liên quan.
10. Cập nhật context/progress và báo cáo.

## Kiểm thử tối thiểu
- Đăng nhập Google thành công.
- Người dùng huỷ OAuth.
- OAuth callback lỗi.
- Khởi động lại app và khôi phục session.
- Logout và xác minh session bị xoá.
- Mất mạng/timeout.
- Auth thành công nhưng profile/database bị từ chối.
- Không có token hoặc user null.

## Giới hạn an toàn
- Không thay đổi database/RLS.
- Không xoá code Firebase cũ trừ khi được người dùng duyệt rõ ràng sau khi audit dependency.
- Không log token/secret.
- Không coi việc Google OAuth thành công là bằng chứng quyền đọc/ghi documents đã đúng.

## Đầu ra
- Code Auth đã chuyển trong phạm vi.
- Tests liên quan.
- `migration/reports/PHASE_03_FLUTTER_AUTH_REPORT.md`
- Cập nhật `migration/MIGRATION_CONTEXT.md` và `migration/MIGRATION_PROGRESS.md`.

## Điều kiện hoàn thành
Các kiểm thử Auth trong phạm vi đạt; báo cáo nêu rõ kiểm thử nào chạy thực tế, kiểm thử nào chưa chạy. Chờ người dùng duyệt trước Phase 04.
