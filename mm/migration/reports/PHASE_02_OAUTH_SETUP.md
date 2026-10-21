# PHASE 02 — Checklist Google OAuth cho Supabase

**Ngày khảo sát:** 2026-10-21  
**Trạng thái:** `BLOCKED` — đã xác định cấu hình trong repository và chuẩn bị hướng dẫn; cần người dùng chọn luồng/cung cấp thông tin còn thiếu và thao tác trên Google Cloud/Supabase Dashboard.  
**Giới hạn:** Không truy cập Dashboard/Console, không thay cấu hình, không sửa source hoặc database.

## 1. Kết quả kiểm tra có giới hạn

| Hạng mục | Đã xác minh từ repository | Ảnh hưởng |
|---|---|---|
| Android application ID | [`android/app/build.gradle.kts`](../../android/app/build.gradle.kts#L16) khai báo `applicationId = "com.example.mm"` (namespace cũng là `com.example.mm`). Có TODO nhắc thay application ID trước phát hành; cần người dùng xác nhận đây có phải ID chính thức không. | Android OAuth client phải khớp package ID thực tế và SHA-1 của chứng thư ký từng bản build. Không tự tạo OAuth client bằng giá trị này khi chưa được xác nhận. |
| Supabase Flutter | [`pubspec.yaml`](../../pubspec.yaml#L41) đặt constraint `^2.18.3`; [`pubspec.lock`](../../pubspec.lock#L992) khóa phiên bản `2.18.3`. | Đối chiếu dưới đây dùng tài liệu gói đúng phiên bản và tài liệu Supabase hiện hành. |
| Supabase project URL trong app | [`lib/main.dart`](../../lib/main.dart#L19) có URL project `https://fzzsffkeajsqjjaljojk.supabase.co`. | Không suy ra/điền callback URI bằng cách tự nối URL. URL chính xác phải được sao chép từ Google provider của đúng project trong Dashboard. |
| Android app callback | [`AndroidManifest.xml`](../../android/app/src/main/AndroidManifest.xml) chỉ có launcher intent-filter; không có `VIEW`, `BROWSABLE`, custom scheme hoặc host callback. | Browser OAuth chưa có app deep link được xác minh. Không đăng ký redirect giả định. |
| iOS callback (tham khảo vì dự án có iOS) | [`ios/Runner/Info.plist`](../../ios/Runner/Info.plist) không có `CFBundleURLTypes` trong nội dung đã kiểm tra. | Chưa có scheme callback iOS đã xác minh; chưa thể ghi redirect cho iOS. |
| OAuth/deep-link handling | Không tìm thấy `signInWithOAuth`, `signInWithIdToken`, auth callback handler hoặc xử lý deep link trong `lib/`. `app_links` chỉ xuất hiện là dependency bắc cầu trong [`pubspec.lock`](../../pubspec.lock#L36), không có sử dụng trong app source được kiểm tra. | Cần quyết định triển khai native token exchange hay browser redirect trước khi cấu hình callback cho ứng dụng. |
| Google Sign-In hiện tại | [`lib/main.dart`](../../lib/main.dart#L15) khởi tạo `GoogleSignIn` không truyền client IDs; [`auth_service.dart`](../../lib/services/auth_service.dart#L61) lấy Google authentication ID token để đăng nhập Firebase. Không thấy lấy Google access token. | Native Supabase `signInWithIdToken` cần xác định cấu hình client ID và lấy các token mà API yêu cầu; chưa sẵn sàng chuyển luồng chỉ bằng thay đổi Dashboard. |

## 2. Đối chiếu tài liệu chính thức

Nguồn được kiểm tra ngày 2026-10-21:

1. [Supabase — Sign in with Google](https://supabase.com/docs/guides/auth/social-login/auth-google): hướng dẫn Google Auth Platform, cấu hình client ID, native Flutter (Android/iOS) và Google provider trong Supabase.
2. [Supabase Flutter trên pub.dev — phiên bản 2.18.3](https://pub.dev/packages/supabase_flutter/versions/2.18.3): hướng dẫn phiên bản khớp lockfile; phần Native Google sign-in yêu cầu web client ID và dùng `google_sign_in` để lấy credentials cho Supabase.
3. [Supabase Dart API — signInWithIdToken](https://supabase.com/docs/reference/dart/auth-signinwithidtoken): API token exchange. Tài liệu hiện tại đánh dấu `accessToken` là bắt buộc cho Google; cần đối chiếu lại API trong package 2.18.3 khi triển khai code ở phase sau.
4. [Supabase — Native Mobile Deep Linking](https://supabase.com/docs/guides/auth/native-mobile-deep-linking): Android cần intent-filter nhận URL scheme/host đã chọn; iOS cần đăng ký scheme tương ứng.
5. [Supabase — Redirect URLs](https://supabase.com/docs/guides/auth/redirect-urls): URL redirect ứng dụng dùng khi OAuth trả người dùng về app phải thuộc allow-list trong Authentication → URL Configuration. Site URL không thay thế app callback.

Supabase mô tả hai luồng hợp lệ, nhưng chúng không dùng cùng loại callback:

- **Native Google Sign-In + ID-token exchange:** app gọi Google Sign-In native rồi gửi token Google tới Supabase Auth. Phù hợp với plugin hiện tại và không cần browser quay về custom app URL cho riêng bước sign-in này. Tài liệu Flutter 2.18.3 nêu cần web client ID; tài liệu Supabase còn hướng dẫn Android client ID theo package + SHA-1. API Google token exchange yêu cầu access token theo tài liệu Dart hiện hành.
- **OAuth browser redirect (`signInWithOAuth`):** trình duyệt đi qua Supabase/Google rồi quay về URL của app. Cần scheme/host duy nhất do dự án quyết định, khai báo Android intent-filter (và iOS URL type nếu hỗ trợ iOS), app xử lý callback, và thêm đúng app redirect vào Supabase URL Configuration. Repo hiện chưa có scheme/host hoặc handler nên chưa thể đưa ra URL cụ thể.

Google Cloud **Authorized redirect URI** nhận callback URL do Supabase Dashboard hiển thị cho Google provider. Đây là callback Google → Supabase, khác với app deep link Supabase → ứng dụng. Không được thay bằng app scheme.

## 3. Việc Agent đã làm / không thể làm

### Agent đã làm

- Đọc các file cần thiết nêu tại mục 1.
- Đối chiếu tài liệu Supabase chính thức và tài liệu package `supabase_flutter` phiên bản 2.18.3.
- Ghi checklist và các giá trị chưa thể xác minh vào báo cáo này.
- Không thay file ứng dụng, Gradle, manifest, iOS config, dependency, Firebase config hoặc database.

### Người dùng cần tự làm

Agent không có quyền truy cập Google Cloud Console hay Supabase Dashboard của dự án; vì vậy **chưa bật provider, chưa tạo OAuth client, chưa nhập credential/secret, và chưa đăng ký URL nào**.

## 4. Checklist — trước khi cấu hình

- [ ] Xác nhận `com.example.mm` là Android application ID chính thức dự định dùng. Nếu không, cung cấp ID chính thức; chưa đổi ID trong Phase 02.
- [ ] Chọn luồng cho Android:
  - [ ] **Khuyến nghị phù hợp source hiện tại:** Native Google Sign-In → Supabase `signInWithIdToken`.
  - [ ] OAuth browser redirect → app deep link. Chỉ chọn nếu chủ đích dùng redirect/browser; cần người dùng quyết định scheme và host duy nhất trước khi sửa app/config.
- [ ] Xác định phạm vi phát hành: debug, release, Play App Signing; lấy SHA-1 tương ứng cho từng chứng thư. Từ thư mục `mm\android`, chạy `.\gradlew.bat signingReport` hoặc lấy từ cấu hình ký/phân phối của nhóm. Không gửi keystore, mật khẩu hoặc private key.
- [ ] Xác nhận có cần iOS/web ở đợt này không. Báo cáo hiện xác minh Android ID, nhưng chưa có iOS bundle ID/signing identity hoặc web origin đã được người dùng xác nhận.
- [ ] Mở đúng Supabase project và kiểm tra Google provider/callback đang hiển thị; không dùng giá trị lịch sử hoặc tự dựng callback.

## 5. Checklist — Google Cloud Console (người dùng thao tác)

1. Mở Google Auth Platform của đúng Google Cloud project; kiểm tra **Branding**, **Audience** và **Data Access**. Chọn audience phù hợp chính sách sản phẩm; nếu ở trạng thái Testing, thêm các tài khoản kiểm thử cần thiết.
2. Cấu hình các scope tối thiểu Supabase nêu trong hướng dẫn: `openid`, email và profile. Không thêm scope nhạy cảm/restricted nếu không có yêu cầu.
3. Tạo **Android OAuth client** cho từng loại ký cần hỗ trợ, bằng Android application ID đã xác nhận và SHA-1 chính xác của chứng thư debug/release tương ứng. Không dùng SHA-1 giả định.
4. Tạo/kiểm tra **Web application OAuth client** theo yêu cầu Supabase Flutter native sign-in.
5. Nếu dùng browser redirect flow, mở Google provider trong Supabase Dashboard trước; sao chép chính xác callback URI Google mà Dashboard hiển thị vào **Authorized redirect URIs** của Web client. Không tự nhập callback do Agent suy ra.
6. Chỉ thêm **Authorized JavaScript origins** nếu thực sự có web app origin; không thêm origin mẫu cho ứng dụng Android.
7. Lưu Client ID và Client Secret ở nơi an toàn. Chỉ nhập secret trực tiếp vào Supabase Dashboard; **không gửi secret cho Agent, không đưa vào Flutter, Git, log hoặc tài liệu**.

## 6. Checklist — Supabase Dashboard (người dùng thao tác)

1. Mở đúng project → **Authentication → Providers → Google**; xác nhận provider Google, rồi bật provider khi đã có credential chính xác.
2. Nhập Web Client ID và Client Secret từ Google Cloud trực tiếp tại Dashboard. Đăng ký Android Client ID theo trường/ghi chú được Dashboard và hướng dẫn Supabase hiện hành yêu cầu; giữ các Client ID thuộc cùng Google Cloud project.
3. Nếu chọn browser redirect flow, sao chép callback URI Google hiển thị tại trang Google provider và dùng nguyên văn cho Google Cloud **Authorized redirect URI**.
4. Vào **Authentication → URL Configuration**:
   - Giữ Site URL theo URL website/default redirect thực tế do người dùng quản lý; không đặt thành app scheme chỉ vì ứng dụng là mobile.
   - Chỉ thêm app deep link vào **Additional Redirect URLs** nếu đã chọn browser redirect và scheme/host đã được quyết định, khai báo trong app, và kiểm thử. Chưa có URL nào để thêm ở trạng thái hiện tại.
5. Không thay RLS, schema, policies, quyền sở hữu tài liệu, Firebase hoặc dữ liệu trong giai đoạn này.

## 7. Điều kiện để ghi URL và kiểm thử

Chưa thể đưa ra redirect URL đầy đủ hoặc xác nhận OAuth hoạt động vì chưa có:

1. Xác nhận Android application ID có phải `com.example.mm` không.
2. SHA-1 debug/release/Play App Signing cần được đăng ký.
3. Quyết định native token exchange hay browser redirect; nếu browser redirect, quyết định scheme và host duy nhất.
4. Xác nhận platform cần hỗ trợ.
5. Người dùng thao tác trong Google Cloud/Supabase Dashboard và xác nhận provider/callback đã lưu thành công. Riêng callback Google phải được chép từ đúng Dashboard, không gửi secret.

Sau khi người dùng cấu hình, checklist kiểm thử tối thiểu trước Phase 03:

- Android debug và release/Play signing phù hợp: đăng nhập mới, đăng nhập lại, hủy ở màn hình Google, và sign-out.
- Với native flow: xử lý lỗi khi ID token/access token thiếu hoặc Google audience/client ID không hợp lệ; xác nhận Supabase Auth tạo session.
- Với browser flow: callback thành công khi app đang mở và khi app được mở lạnh; callback sai scheme/host, redirect chưa allow-list, provider tắt và người dùng hủy.
- Xác nhận URL callback không làm lộ authorization code/token trong log. Chỉ dùng tài khoản test.

## 8. Điểm dừng

Phase 02 đang **BLOCKED** chờ các quyết định/xác nhận ở mục 7 và thao tác Dashboard ở mục 5–6. Báo cáo không coi provider đã cấu hình và không cho phép bắt đầu Phase 03. Khi người dùng xác nhận các mục trên, mới có thể cập nhật trạng thái phase; không tự chuyển tiếp.
