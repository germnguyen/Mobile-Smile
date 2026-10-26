# Migration Progress

> Agent phải cập nhật file này sau mỗi phiên làm việc. Không tự đánh dấu giai đoạn đã được người dùng phê duyệt.

## Trạng thái tổng quan
- [ ] Phase 01 — Audit hiện trạng
- [ ] Phase 02 — Google OAuth trên Supabase
- [ ] Phase 03 — Flutter Auth migration
- [ ] Phase 04 — Database identity / RLS migration
- [ ] Phase 05 — Storage và integration testing

## Trạng thái chi tiết

| Phase | Status | Kết quả / báo cáo | Điều kiện để tiếp tục |
|---|---|---|---|
| 01 Audit | READY_FOR_REVIEW | `migration/reports/PHASE_01_AUDIT_REPORT.md` | Người dùng xem báo cáo; chỉ tiếp tục Phase 02 sau khi có xác nhận |
| 02 Google OAuth | BLOCKED | `migration/reports/PHASE_02_OAUTH_SETUP.md` | Người dùng xác nhận app ID/signing/platform/luồng; tự cấu hình Google Cloud và Supabase Dashboard; callback chỉ ghi sau khi lấy từ Dashboard và chọn scheme nếu dùng browser flow |
| 03 Flutter Auth | NOT_STARTED | `migration/phases/PHASE_03_FLUTTER_AUTH.md` | Đăng nhập, callback, logout và session được kiểm thử |
| 04 Database/RLS | NOT_STARTED | `migration/phases/PHASE_04_DATABASE_RLS.md` | Kế hoạch UID mapping, backup và rollback được người dùng duyệt |
| 05 Storage/Test | NOT_STARTED | `migration/phases/PHASE_05_STORAGE_TESTING.md` | Kiểm thử quyền sở hữu/chia sẻ đạt yêu cầu; người dùng duyệt dọn Firebase |

## Nhật ký quyết định
| Ngày | Quyết định | Người quyết định | Ghi chú |
|---|---|---|---|
| 2026-10-21 | Chọn Supabase Auth + Google OAuth thay Firebase Authentication cho luồng đăng nhập chính | Người dùng | Giữ Supabase backend và bảo toàn dữ liệu |

## Phiên làm việc gần nhất
- Ngày: 2026-10-21
- Phase: 02 — Google OAuth trên Supabase
- Đã làm: Đọc hướng dẫn/context/progress/Phase 02; xác định Android application ID, Supabase Flutter version, hiện trạng callback/deep link và flow hiện có; đối chiếu tài liệu Supabase chính thức; tạo checklist dashboard và báo cáo.
- File thay đổi: `mm/migration/reports/PHASE_02_OAUTH_SETUP.md`, `mm/migration/MIGRATION_PROGRESS.md`.
- Kiểm tra đã chạy và kết quả: Đọc có giới hạn `pubspec.yaml`, lockfile, Android Gradle/Manifest, `main.dart`, iOS Info.plist; tìm kiếm flow/callback trong `lib/`; truy cập tài liệu Supabase chính thức. Không chạy test/build/SQL, không truy cập dashboard.
- Vấn đề bị chặn: Chưa xác nhận application ID chính thức, SHA-1 signing fingerprints, platform scope hoặc lựa chọn native/browser; không có quyền thao tác Google Cloud/Supabase Dashboard. Chưa xác minh provider/callback live.
- Câu hỏi cần người dùng trả lời: Xác nhận app ID, SHA-1 cần hỗ trợ, platform, chọn native token exchange hay browser redirect; thực hiện checklist Dashboard mà không gửi secret.
- Bước tiếp theo được phép: Chờ người dùng hoàn tất/xác nhận cấu hình Phase 02. Không triển khai Phase 03 trở đi.
