# PHASE 02 — Cấu hình Google OAuth cho Supabase

## Điều kiện tiên quyết
- Phase 01 có báo cáo và người dùng đã xem/duyệt.
- Đã xác định package Supabase Flutter và phiên bản hiện tại.
- Đã xác định Android application ID, scheme/deep link hiện dùng và URL môi trường.

## Mục tiêu
Chuẩn bị Supabase Auth Google provider và callback để Flutter có thể đăng nhập qua Google mà không cần Firebase Authentication.

## Phạm vi
- Kiểm tra hướng dẫn chính thức phù hợp với phiên bản Supabase/Flutter hiện có.
- Chuẩn bị checklist dashboard và redirect URLs.
- Chỉ sửa cấu hình local nếu cần, an toàn và được phép.
- Không tự thay đổi dữ liệu, RLS hoặc xoá Firebase.
- Không giả vờ đã cấu hình Google Cloud/Supabase Dashboard nếu không có quyền truy cập.

## Việc cần làm
1. Xác định Android application ID và cơ chế callback/deep link hiện tại.
2. Xác định cấu hình Google provider trong Supabase Dashboard cần người dùng thực hiện.
3. Liệt kê redirect URLs chính xác theo cấu hình dự án; không đoán scheme hoặc package ID.
4. Giải thích phần cấu hình OAuth consent screen/authorized redirect URI cần thiết, dựa trên tài liệu hiện hành.
5. Kiểm tra callback URL, URL scheme và intent filters Android; chỉ đề xuất thay đổi có căn cứ.
6. Tạo checklist kiểm thử đăng nhập, huỷ đăng nhập, callback sai và lỗi provider.
7. Cập nhật context/progress và báo cáo.

## Bảo mật
- Không yêu cầu người dùng dán client secret vào chat hoặc commit.
- Không đưa Google client secret/service-role key vào ứng dụng Flutter.
- Nếu cần secret, hướng dẫn nhập trực tiếp trong dashboard đáng tin cậy.
- Không log OAuth code hoặc token.

## Đầu ra
- `migration/reports/PHASE_02_OAUTH_SETUP.md`
- Cập nhật `migration/MIGRATION_CONTEXT.md` nếu redirect scheme hoặc cấu hình được xác minh.
- Cập nhật `migration/MIGRATION_PROGRESS.md`.

## Điều kiện hoàn thành
- Các bước dashboard được ghi rõ, phân biệt việc Agent làm và việc người dùng cần làm.
- Redirect URL được xác minh, không suy đoán.
- Người dùng xác nhận provider/callback đã cấu hình trước khi bắt đầu Phase 03.

## Dừng và hỏi người dùng nếu
- Thiếu quyền truy cập dashboard.
- Không xác định được application ID hoặc redirect URL.
- Có xung đột giữa cấu hình Android hiện tại và callback Supabase.
