# PHASE 05 — Storage, tích hợp và dọn Firebase có kiểm soát

## Điều kiện tiên quyết
- Phase 03 và Phase 04 đã được người dùng duyệt.
- Luồng Auth mới hoạt động.
- UID mapping/RLS đã được kiểm thử.
- Đã biết chính xác bucket, storage path conventions và policy hiện tại.

## Mục tiêu
Kiểm chứng toàn bộ luồng tài liệu và quyền chia sẻ với Supabase Auth, sau đó đề xuất dọn các phần Firebase không còn sử dụng.

## Ma trận tài khoản bắt buộc
- A: chủ sở hữu tài liệu.
- B: được chia sẻ quyền viewer; thử đọc/tải, phải bị từ chối khi sửa/xoá.
- B: được nâng lên editor; thử sửa theo quyền đã cấp.
- C: không được chia sẻ; không đọc/tải/sửa/xoá tài liệu của A.
- A: vẫn có toàn quyền phù hợp với chủ sở hữu.
- Kiểm tra người dùng đăng xuất/session hết hạn.
- Kiểm tra file metadata và object trong Storage không bị lệch nhau.

## Luồng cần kiểm tra
1. Tạo tài liệu chỉ có metadata.
2. Upload file và xác minh metadata/storage path.
3. Đọc/tải file theo đúng quyền.
4. Cập nhật metadata/file.
5. Chia sẻ, đổi quyền, thu hồi quyền.
6. Xoá tài liệu và kiểm tra xử lý object/file liên quan.
7. Lỗi mạng hoặc upload thất bại; kiểm tra cleanup và trạng thái không nhất quán.
8. Mở app lại và xác minh session/permissions.
9. Kiểm tra Android redirect/OAuth trên thiết bị hoặc emulator khi có điều kiện.

## Dọn Firebase
Chỉ sau khi tất cả kiểm thử đạt và người dùng duyệt:
1. Tìm toàn bộ import, package, initialization và resource Firebase.
2. Phân loại từng dependency/resource: còn sử dụng, không còn sử dụng, chưa rõ.
3. Xoá từng phần không còn sử dụng, không xoá hàng loạt theo tên.
4. Chạy `flutter pub get`, `flutter analyze`, tests và build Android phù hợp.
5. Giữ lại hướng dẫn rollback cho đến khi bản mới được xác nhận ổn định.

## Bảo mật
- Không dùng service-role key trong client.
- Không mở policy Storage rộng để làm test pass.
- Không kiểm tra chỉ bằng UI; xác minh quyền ở backend/RLS/Storage policy.
- Không dùng cùng một tài khoản để giả lập tất cả vai trò.
- Không log token hoặc dữ liệu nhạy cảm.

## Đầu ra
- `migration/reports/PHASE_05_INTEGRATION_TEST_REPORT.md`
- Bảng test case với expected/actual/pass-fail.
- Danh sách Firebase dependencies/resources được giữ hoặc gỡ và lý do.
- Cập nhật context/progress.

## Điều kiện hoàn thành
Tất cả case quan trọng đạt hoặc có lỗi được phân loại rõ ràng; không có quyền truy cập ngoài ý muốn; người dùng duyệt trước khi coi migration hoàn tất.
