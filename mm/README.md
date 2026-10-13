Được. Vì chúng ta đã đi xuyên suốt project **StudyCashew**, README nên phản ánh đúng project hiện tại, đặc biệt là cách bạn **phân tích và áp dụng cách tổ chức mã nguồn của Cashew**, chứ không mô tả Cashew như một “kiến trúc chuẩn” có sẵn.

Bạn có thể **thay toàn bộ nội dung `README.md`** bằng nội dung dưới đây:

````markdown
# StudyCashew

Ứng dụng quản lý tài liệu học tập được xây dựng bằng **Flutter**, lấy cảm hứng từ cách tổ chức mã nguồn và các nguyên tắc phân tách trách nhiệm trong dự án **Cashew**.

StudyCashew cho phép người dùng quản lý các tài liệu học tập như bài giảng, bài tập và tài liệu tham khảo. Ứng dụng tập trung vào việc tổ chức mã nguồn theo các module có trách nhiệm rõ ràng, giúp dễ bảo trì, kiểm thử và mở rộng.

---

## 1. Giới thiệu

### Tên dự án

**StudyCashew – Ứng dụng quản lý tài liệu học tập**

### Mục tiêu

Xây dựng một ứng dụng quản lý tài liệu học tập bằng Flutter, đồng thời áp dụng các nguyên tắc:

- Phân tách trách nhiệm giữa các thành phần.
- Tách giao diện khỏi xử lý nghiệp vụ.
- Tách xử lý nghiệp vụ khỏi truy cập cơ sở dữ liệu.
- Tổ chức mã nguồn thành các module rõ ràng.
- Hỗ trợ kiểm thử độc lập các thành phần.
- Tạo nền tảng thuận lợi cho việc mở rộng ứng dụng.

Trong project này, cách tổ chức được xây dựng dựa trên việc **phân tích cách tổ chức mã nguồn của dự án Cashew**, sau đó áp dụng các nguyên tắc phù hợp vào một ứng dụng quản lý tài liệu học tập đơn giản hơn.

---

# 2. Chức năng

StudyCashew hiện hỗ trợ các chức năng chính:

### Quản lý tài liệu

- Thêm tài liệu.
- Xem danh sách tài liệu.
- Xem chi tiết tài liệu.
- Chỉnh sửa tài liệu.
- Xóa tài liệu.

### Tìm kiếm

Có thể tìm kiếm tài liệu theo:

- Tên tài liệu.
- Mô tả.
- Môn học.

### Lọc

Có thể lọc tài liệu theo loại:

- Bài giảng.
- Bài tập.
- Tài liệu tham khảo.
- Khác.

### Kết hợp tìm kiếm và lọc

Người dùng có thể đồng thời:

- Nhập từ khóa tìm kiếm.
- Chọn loại tài liệu.

Điều kiện tìm kiếm được xử lý theo dạng:

```text
(
    title contains keyword
    OR
    description contains keyword
    OR
    subject contains keyword
)
AND
documentType = selectedType
````

### Lưu trữ

Dữ liệu được lưu trữ cục bộ bằng:

```text
Drift
   ↓
SQLite
```

Do đó dữ liệu vẫn được giữ lại sau khi đóng và mở lại ứng dụng.

---

# 3. Công nghệ sử dụng

| Công nghệ    | Mục đích                    |
| ------------ | --------------------------- |
| Flutter      | Xây dựng giao diện ứng dụng |
| Dart         | Ngôn ngữ lập trình          |
| Drift        | ORM / lớp truy cập SQLite   |
| SQLite       | Lưu trữ dữ liệu cục bộ      |
| Material 3   | Thiết kế giao diện          |
| Flutter Test | Kiểm thử                    |
| Build Runner | Sinh mã cho Drift           |

---

# 4. Kiến trúc

StudyCashew được tổ chức theo hướng phân tách trách nhiệm giữa các thành phần.

Luồng xử lý chính:

```text
Presentation
     ↓
DocumentService
     ↓
DocumentDao
     ↓
Drift / SQLite
```

## 4.1. Presentation Layer

Bao gồm:

```text
pages/
widgets/
```

### Pages

Chịu trách nhiệm điều phối giao diện và tương tác với người dùng.

Các page chính:

```text
DocumentListPage
DocumentDetailPage
DocumentFormPage
```

### Widgets

Chứa các thành phần giao diện có thể tái sử dụng:

```text
DocumentCard
DocumentSearch
DocumentFilter
DocumentForm
EmptyState
```

Presentation Layer không trực tiếp thực hiện truy vấn SQLite.

---

## 4.2. Service Layer

File:

```text
lib/services/document_service.dart
```

Thành phần chính:

```text
DocumentService
```

Service chịu trách nhiệm xử lý các nghiệp vụ liên quan đến tài liệu, chẳng hạn:

* Kiểm tra dữ liệu đầu vào.
* Chuẩn hóa dữ liệu.
* Kiểm tra tên tài liệu.
* Xử lý thêm tài liệu.
* Xử lý cập nhật.
* Xử lý xóa.
* Xử lý tìm kiếm.
* Xử lý lọc.

Ví dụ:

```text
DocumentFormPage
        ↓
DocumentService
        ↓
DocumentDao
```

Nhờ đó UI không cần biết chi tiết cách dữ liệu được lưu trong SQLite.

---

## 4.3. DAO Layer

File:

```text
lib/database/daos/document_dao.dart
```

Thành phần chính:

```text
DocumentDao
```

DAO chịu trách nhiệm giao tiếp với database.

Các thao tác chính:

```text
INSERT
SELECT
UPDATE
DELETE
SEARCH
FILTER
```

Ví dụ:

```text
DocumentService
       ↓
DocumentDao
       ↓
Drift
       ↓
SQLite
```

DAO không chịu trách nhiệm xây dựng giao diện hoặc xử lý logic hiển thị.

---

## 4.4. Database Layer

Các file chính:

```text
lib/database/app_database.dart
lib/database/tables.dart
```

Database sử dụng:

```text
Drift + SQLite
```

Bảng chính:

```text
Documents
```

Các trường:

| Trường       | Kiểu     | Mô tả              |
| ------------ | -------- | ------------------ |
| id           | Integer  | ID tự tăng         |
| title        | Text     | Tên tài liệu       |
| description  | Text?    | Mô tả              |
| filePath     | Text?    | Đường dẫn file     |
| documentType | Enum     | Loại tài liệu      |
| subject      | Text?    | Môn học            |
| createdAt    | DateTime | Thời gian tạo      |
| updatedAt    | DateTime | Thời gian cập nhật |

---

# 5. Cấu trúc thư mục

```text
lib/
│
├── config/
│   ├── app_dependencies.dart
│   └── app_theme.dart
│
├── database/
│   ├── app_database.dart
│   ├── app_database.g.dart
│   ├── tables.dart
│   │
│   └── daos/
│       ├── document_dao.dart
│       └── document_dao.g.dart
│
├── pages/
│   ├── document_list_page.dart
│   ├── document_detail_page.dart
│   └── document_form_page.dart
│
├── widgets/
│   ├── document_card.dart
│   ├── document_filter.dart
│   ├── document_form.dart
│   ├── document_search.dart
│   └── empty_state.dart
│
├── services/
│   └── document_service.dart
│
├── struct/
│   └── document_type.dart
│
└── main.dart
```

---

# 6. Dependency Injection

Project sử dụng:

```text
lib/config/app_dependencies.dart
```

để khởi tạo các dependency cần thiết.

Luồng khởi tạo:

```text
AppDependencies
       │
       ├── AppDatabase
       │       │
       │       └── DocumentDao
       │
       └── DocumentService
               │
               └── DocumentDao
```

Các Page nhận `DocumentService` từ bên ngoài thay vì tự tạo database.

Ví dụ:

```text
DocumentListPage
       ↓
DocumentService
```

Cách tổ chức này giúp giảm sự phụ thuộc trực tiếp giữa Presentation Layer và Database Layer.

---

# 7. Data Flow

## Thêm tài liệu

```text
User
 ↓
DocumentForm
 ↓
DocumentFormPage
 ↓
DocumentService
 ↓
DocumentDao
 ↓
Drift
 ↓
SQLite
```

Service thực hiện kiểm tra và chuẩn hóa dữ liệu trước khi DAO thực hiện thao tác database.

---

## Tìm kiếm

```text
User
 ↓
DocumentSearch
 ↓
DocumentListPage
 ↓
DocumentService
 ↓
DocumentDao
 ↓
SQLite
 ↓
Search Result
 ↓
DocumentListPage
 ↓
DocumentCard
```

---

## Tìm kiếm + lọc

```text
Keyword
   +
Document Type
        ↓
DocumentListPage
        ↓
DocumentService
        ↓
DocumentDao
        ↓
SQLite
        ↓
Filtered Result
```

---

# 8. Data Flow Diagram

### Context Diagram

```text
                 ┌─────────────────┐
                 │      User       │
                 └────────┬────────┘
                          │
                          │
                          ▼
              ┌───────────────────────┐
              │     StudyCashew       │
              │                       │
              │ Document Management   │
              └───────────┬───────────┘
                          │
                          │
                          ▼
                 Document Results
```

### Level 1

```text
                    User
                     │
                     ▼
          ┌─────────────────────┐
          │ P1. Manage Documents│
          └──────────┬──────────┘
                     │
                     ▼
          ┌─────────────────────┐
          │ P2. Search          │
          │ Documents           │
          └──────────┬──────────┘
                     │
                     ▼
          ┌─────────────────────┐
          │ P3. Filter          │
          │ Documents           │
          └──────────┬──────────┘
                     │
                     ▼
          ┌─────────────────────┐
          │ P4. Store Data      │
          └──────────┬──────────┘
                     │
                     ▼
             ┌───────────────┐
             │ SQLite        │
             │ Documents     │
             └───────────────┘
```

Các sơ đồ chi tiết được trình bày trong tài liệu báo cáo của project.

---

# 9. Kiểm thử

Project có kiểm thử cho hai thành phần chính:

```text
test/
├── database/
│   └── document_dao_test.dart
│
└── services/
    └── document_service_test.dart
```

## DAO Tests

Kiểm thử:

* Insert document.
* Get document.
* Get all documents.
* Update document.
* Delete document.
* Search document.
* Filter document.
* Search + filter.

## Service Tests

Kiểm thử:

* Thêm tài liệu hợp lệ.
* Không cho phép tên rỗng.
* Giới hạn tên tối đa 250 ký tự.
* Chuẩn hóa tên tài liệu.
* Chuẩn hóa dữ liệu tùy chọn.
* Search.
* Filter.
* Delete.
* Delete tài liệu không tồn tại.

Chạy toàn bộ test:

```bash
flutter test
```

---

# 10. Validation

Tên tài liệu có các quy tắc:

```text
Không được để trống.
Không vượt quá 250 ký tự.
```

Service cũng thực hiện:

```text
trim()
```

để chuẩn hóa dữ liệu.

Ví dụ:

```text
"   Java OOP   "
```

được chuẩn hóa thành:

```text
"Java OOP"
```

Các trường tùy chọn nếu chỉ chứa khoảng trắng sẽ được chuyển thành:

```text
null
```

---

# 11. Giao diện

Ứng dụng sử dụng Material 3.

Các trạng thái giao diện gồm:

* Loading.
* Empty State.
* Search result.
* Filter result.
* Error message.
* Form validation.
* Confirmation dialog.

Ứng dụng hỗ trợ:

```text
Light Theme
Dark Theme
```

theo theme của hệ điều hành.

---

# 12. Cài đặt và chạy project

## Yêu cầu

Cần cài đặt:

* Flutter SDK.
* Dart SDK đi kèm Flutter.
* Android Studio hoặc Visual Studio phù hợp với target platform.

Kiểm tra Flutter:

```bash
flutter doctor
```

---

## Clone project

```bash
git clone <repository-url>
```

Di chuyển vào project:

```bash
cd mm
```

---

## Cài đặt dependencies

```bash
flutter pub get
```

---

## Generate Drift code

```bash
dart run build_runner build
```

---

## Chạy ứng dụng

### Windows

```bash
flutter run -d windows
```

### Android

Kiểm tra thiết bị:

```bash
flutter devices
```

Sau đó:

```bash
flutter run -d <device-id>
```

---

# 13. Kiểm tra project

## Phân tích mã nguồn

```bash
flutter analyze
```

## Chạy unit test

```bash
flutter test
```

## Clean project

```bash
flutter clean
```

Sau đó:

```bash
flutter pub get
```

---

# 14. Kiến trúc tổng quát

```text
┌────────────────────────────────────────────┐
│            PRESENTATION LAYER              │
│                                            │
│  Pages                 Widgets              │
│  ├─ List               ├─ Card             │
│  ├─ Detail             ├─ Search           │
│  └─ Form               ├─ Filter           │
│                        └─ EmptyState        │
└───────────────────────┬────────────────────┘
                        │
                        ▼
┌────────────────────────────────────────────┐
│               SERVICE LAYER                │
│                                            │
│             DocumentService                │
│                                            │
│  Validation                                │
│  Normalization                             │
│  Business Logic                            │
└───────────────────────┬────────────────────┘
                        │
                        ▼
┌────────────────────────────────────────────┐
│                  DAO LAYER                 │
│                                            │
│              DocumentDao                   │
│                                            │
│  CRUD / Search / Filter                    │
└───────────────────────┬────────────────────┘
                        │
                        ▼
┌────────────────────────────────────────────┐
│               DATABASE LAYER               │
│                                            │
│              Drift + SQLite                │
│                                            │
│                Documents                   │
└────────────────────────────────────────────┘
```

---

# 15. Nguyên tắc thiết kế

Project tập trung vào các nguyên tắc:

### Separation of Concerns

Mỗi module có trách nhiệm riêng.

```text
UI       → giao diện
Service  → nghiệp vụ
DAO      → truy vấn dữ liệu
Database → lưu trữ
```

### Modularity

Các chức năng được chia thành các module nhỏ:

```text
pages
widgets
services
database
config
struct
```

### Testability

Service và DAO có thể được kiểm thử riêng.

### Extensibility

Cấu trúc cho phép mở rộng thêm chức năng mà không cần đưa toàn bộ logic vào Page.

Ví dụ trong tương lai có thể bổ sung:

```text
File Picker
Favorite Documents
Categories
Tags
Sorting
Cloud Storage
Authentication
```

mà vẫn giữ được cách phân tách hiện tại.

---

# 16. Hạn chế hiện tại

Phiên bản hiện tại tập trung vào quản lý tài liệu cục bộ.

Một số chức năng chưa được triển khai:

* Đăng nhập người dùng.
* Đồng bộ dữ liệu cloud.
* Chia sẻ tài liệu giữa nhiều người dùng.
* Upload file trực tiếp.
* Preview nội dung PDF.
* Đồng bộ giữa nhiều thiết bị.

Đây là những hướng có thể phát triển trong các phiên bản tiếp theo.

---

# 17. Hướng phát triển

Một số hướng phát triển:

```text
StudyCashew
     │
     ├── File Picker
     │
     ├── PDF Preview
     │
     ├── Categories
     │
     ├── Tags
     │
     ├── Favorite
     │
     ├── Sorting
     │
     ├── Cloud Storage
     │
     └── User Authentication
```

Khi bổ sung các chức năng mới, có thể tiếp tục giữ nguyên nguyên tắc:

```text
Presentation
      ↓
Service
      ↓
DAO
      ↓
Data Source
```

---

# 18. Kết luận

StudyCashew là ứng dụng quản lý tài liệu học tập được xây dựng bằng Flutter với khả năng thêm, chỉnh sửa, xóa, tìm kiếm và lọc tài liệu.

Điểm trọng tâm của project không chỉ nằm ở các chức năng CRUD mà còn ở việc tổ chức mã nguồn thành các thành phần có trách nhiệm rõ ràng:

```text
Pages / Widgets
       ↓
DocumentService
       ↓
DocumentDao
       ↓
Drift / SQLite
```

Việc phân tách này giúp giảm sự phụ thuộc giữa giao diện, nghiệp vụ và dữ liệu, đồng thời hỗ trợ kiểm thử và mở rộng ứng dụng.

Cách tổ chức của StudyCashew được xây dựng dựa trên việc phân tích cách tổ chức mã nguồn của dự án Cashew và áp dụng các nguyên tắc phân tách trách nhiệm, modularity và extensibility vào phạm vi của bài tập.

---

# 19. Tác giả

**Project:** StudyCashew
**Technology:** Flutter / Dart
**Database:** Drift / SQLite
**Architecture approach:** Separation of Concerns, Modularity, Testability

````

### Một điểm mình khuyên bạn giữ nguyên

Trong README mình cố ý dùng câu:

> **“lấy cảm hứng từ cách tổ chức mã nguồn và các nguyên tắc phân tách trách nhiệm trong dự án Cashew”**

thay vì viết:

> “StudyCashew sử dụng kiến trúc Cashew gồm 4 layer...”

Vì project của bạn là **bài tập phân tích và áp dụng nguyên lý từ Cashew**, không phải một framework kiến trúc chính thức tên “Cashew Architecture”. Cách viết này cũng khớp với hướng chúng ta đã xây dựng trong **Phase 13 – DFD + Architecture**.

Bạn chỉ cần thay:

```text
<repository-url>
````

bằng URL GitHub repo của project nếu đã upload lên GitHub.
