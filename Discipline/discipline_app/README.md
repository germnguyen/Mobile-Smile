# Ứng Dụng Kỷ Luật Cá Nhân (Discipline Habit Tracker)

Ứng dụng di động giúp theo dõi và quản lý thói quen hàng ngày nhằm rèn luyện kỷ luật cá nhân, được xây dựng bằng Flutter. Ứng dụng hỗ trợ trải nghiệm mượt mà trên cả Mobile và **Flutter Web** với giao diện responsive chuẩn khung hình điện thoại, phù hợp cho máy tính cấu hình nhẹ.

---

## 📱 Các Chức Năng Chính

1. **Giao diện người dùng trực quan & Responsive**:
   - Màn hình danh sách thói quen với thẻ tổng quan tiến độ hàng ngày và thanh chọn ngày trong tuần.
   - Màn hình Thêm / Chỉnh sửa thói quen đầy đủ tính năng.
   - Màn hình Thống kê tiến độ đa chiều (Ngày, Tuần, Tháng).
   - Khung hình điện thoại mô phỏng (Phone Mockup Frame) khi chạy trên Web Desktop giúp giữ tỷ lệ chuẩn mà không bị vỡ giao diện.

2. **Quản lý thói quen (CRUD đầy đủ)**:
   - Thêm thói quen mới với các thuộc tính: **Tên**, **Mô tả**, **Tần suất** (Mỗi ngày, Thứ 2 - Thứ 6, Cuối tuần), và **Thời gian nhắc nhở** (chọn giờ phút qua TimePicker).
   - Chỉnh sửa thông tin thói quen đã tạo.
   - Xóa thói quen với hộp thoại xác nhận an toàn.

3. **Hệ thống đánh dấu hoàn thành & Chuỗi ngày (Streaks)**:
   - Check-in hoàn thành hàng ngày chỉ bằng một chạm với hiệu ứng chuyển đổi mượt mà.
   - Tự động tính toán chuỗi ngày liên tiếp (Streak 🔥) và chuỗi kỷ lục.
   - Lọc và theo dõi lại trạng thái hoàn thành của từng ngày trong tuần.

4. **Lưu trữ dữ liệu cục bộ (Local Storage)**:
   - Sử dụng **SharedPreferences** kết hợp mã hóa JSON qua `StorageService`.
   - Dữ liệu thói quen và lịch sử hoàn thành được lưu bền vững, không bị mất khi reload trình duyệt hoặc tắt ứng dụng.
   - Hoạt động 100% trơn tru trên cả Web (LocalStorage/IndexedDB) và thiết bị Android/iOS mà không gặp lỗi thiếu thư viện `.wasm`.

5. **Thống kê tiến độ chi tiết (Ngày, Tuần, Tháng)**:
   - **Theo Ngày**: Tỷ lệ hoàn thành hôm nay, phân loại rõ ràng danh sách thói quen đã làm và thói quen còn tồn đọng.
   - **Theo Tuần**: Biểu đồ cột 7 ngày gần nhất hiển thị tỷ lệ %, số ngày đạt 100% mục tiêu, tổng lượt hoàn thành.
   - **Theo Tháng**: Tỷ lệ hoàn thành cả tháng, tổng số ngày hoạt động (Active days), vinh danh thói quen kiên trì nhất và đánh giá mức độ kỷ luật (Xuất sắc / Khá tốt / Cần cố gắng).

---

## 🛠️ Công Nghệ & Kiến Trúc

- **Framework**: Flutter 3.x (Dart 3.x)
- **State Management**: `provider: ^6.1.2` (Mô hình MVVM Clean Architecture)
- **Local Persistence**: `shared_preferences: ^2.2.2`
- **Formatting**: `intl: ^0.19.0`
- **Design System**: Material Design 3 với bảng màu chuyên dụng rèn luyện kỷ luật (Teal / Indigo / Emerald).

---

## 🚀 Hướng Dẫn Chạy Ứng Dụng

### Chạy trực tiếp trên Web (Khuyên dùng cho máy yếu)
Không cần cài đặt máy ảo Android nặng nề, bạn chỉ cần mở terminal tại thư mục `discipline_app` và chạy:

```bash
cd discipline_app
flutter run -d chrome
```
*Hoặc mở bằng Edge:*
```bash
flutter run -d edge
```

### Chạy kiểm thử tự động (Unit & Widget Tests)
```bash
flutter test
```

### Kiểm tra chất lượng mã nguồn (Linter & Static Analysis)
```bash
flutter analyze
```

---

## 📝 Danh Sách Commit Theo Kế Hoạch

1. `feat: setup dependencies, theme, and responsive mobile shell`
2. `feat: implement habit data models and shared preferences storage service`
3. `feat: implement habit provider with streaks and statistics logic`
4. `feat: implement habit list screen with interactive check-in and streak badges`
5. `feat: implement add and edit habit form with reminder time picker`
6. `feat: implement progress statistics screen for day, week, and month`
7. `feat: finalize discipline tracker app with responsive web support`
