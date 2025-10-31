# Hướng Dẫn Cấu Hình Google Sign-In

## 📋 Tổng Quan

Tài liệu này hướng dẫn cách thiết lập Google Sign-In cho ứng dụng Flutter của bạn.

## 🔧 Các Bước Cấu Hình

### Bước 1: Cài Đặt Dependencies

Package `google_sign_in` đã được thêm vào `pubspec.yaml`. Chạy lệnh:

```bash
flutter pub get
```

### Bước 2: Cấu Hình Firebase (Android)

#### 2.1. Tạo Firebase Project

1. Truy cập [Firebase Console](https://console.firebase.google.com/)
2. Nhấn **"Add project"** hoặc chọn project có sẵn
3. Nhập tên project (ví dụ: `drawing-app`)
4. Bỏ tích **"Enable Google Analytics"** (tùy chọn)
5. Nhấn **"Create project"**

#### 2.2. Thêm Android App vào Firebase

1. Trong Firebase Console, chọn project vừa tạo
2. Nhấn biểu tượng **Android** để thêm ứng dụng Android
3. Điền thông tin:
   - **Android package name**: `com.example.flutter_application_2`
   - **App nickname**: `Drawing App` (tùy chọn)
   - **Debug signing certificate SHA-1**: (xem bước 2.3)

#### 2.3. Lấy SHA-1 Certificate

Mở terminal trong thư mục dự án và chạy:

**Windows:**
```powershell
cd android
./gradlew signingReport
```

**macOS/Linux:**
```bash
cd android
./gradlew signingReport
```

Tìm dòng có **`SHA1:`** trong phần **`Variant: debug`** và copy giá trị (khoảng 40 ký tự).

Ví dụ:
```
SHA1: AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD
```

#### 2.4. Download google-services.json

1. Sau khi điền SHA-1, nhấn **"Register app"**
2. Download file **`google-services.json`**
3. Copy file vào thư mục: `android/app/`

#### 2.5. Cấu Hình Gradle

File `android/build.gradle.kts` đã được cấu hình. Nếu chưa, thêm:

```kotlin
buildscript {
    dependencies {
        classpath("com.google.gms:google-services:4.4.0")
    }
}
```

File `android/app/build.gradle.kts`:

```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") // ← Thêm dòng này
}
```

### Bước 3: Kích Hoạt Google Sign-In trong Firebase

1. Trong Firebase Console, vào **Authentication** → **Sign-in method**
2. Nhấn **"Get started"** (nếu chưa kích hoạt)
3. Chọn **Google** trong danh sách providers
4. Bật **"Enable"**
5. Chọn **Support email** (email của bạn)
6. Nhấn **"Save"**

### Bước 4: Cấu Hình iOS (Nếu cần)

#### 4.1. Thêm iOS App vào Firebase

1. Trong Firebase Console, nhấn biểu tượng **iOS**
2. Điền:
   - **iOS bundle ID**: `com.example.flutterApplication2`
3. Download **`GoogleService-Info.plist`**
4. Copy vào `ios/Runner/`

#### 4.2. Cập nhật Info.plist

Mở `ios/Runner/Info.plist` và thêm:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <!-- Sao chép REVERSED_CLIENT_ID từ GoogleService-Info.plist -->
      <string>com.googleusercontent.apps.YOUR-CLIENT-ID</string>
    </array>
  </dict>
</array>
```

### Bước 5: Kiểm Tra Cấu Hình

1. **Khởi động backend:**
   ```bash
   cd backend
   node server_sqlite.js
   ```

2. **Chạy ứng dụng:**
   ```bash
   flutter run
   ```

3. **Test Google Sign-In:**
   - Nhấn nút **"Đăng nhập bằng Google"**
   - Chọn tài khoản Google
   - Xác nhận quyền truy cập

## 🎨 Tùy Chỉnh Logo Google

Để hiển thị logo Google đẹp hơn:

1. Download logo Google: [Google Brand Resources](https://developers.google.com/identity/branding-guidelines)
2. Lưu vào: `assets/google_logo.png`
3. Thêm vào `pubspec.yaml`:

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/google_logo.png
```

## 🔍 Troubleshooting

### Lỗi: "PlatformException(sign_in_failed)"

**Nguyên nhân:** SHA-1 certificate không đúng hoặc chưa được thêm vào Firebase.

**Giải pháp:**
1. Xác minh lại SHA-1 certificate
2. Thêm SHA-1 vào Firebase Console
3. Download lại `google-services.json`
4. Clean và rebuild:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

### Lỗi: "ApiException: 10"

**Nguyên nhân:** `google-services.json` không đúng hoặc không có trong `android/app/`.

**Giải pháp:**
1. Kiểm tra file `android/app/google-services.json` có tồn tại
2. Xác minh package name trong `google-services.json` khớp với `android/app/build.gradle.kts`

### Lỗi: Không hiển thị popup chọn tài khoản

**Nguyên nhân:** Google Sign-In đã cache tài khoản.

**Giải pháp:** 
- Code đã xử lý bằng cách gọi `signOut()` trước khi `signIn()`
- Hoặc xóa cache ứng dụng trong Settings

### Backend không nhận được request

**Nguyên nhân:** Backend chưa chạy hoặc URL sai.

**Giải pháp:**
1. Kiểm tra backend đang chạy: `http://localhost:5000`
2. Android Emulator dùng: `http://10.0.2.2:5000`
3. Kiểm tra `lib/services/database_service.dart` có đúng baseUrl

## 📱 Test Trên Thiết Bị Thật

Nếu test trên thiết bị Android thật:

1. **Lấy SHA-1 của release keystore:**
   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```

2. **Thêm SHA-1 vào Firebase Console**

3. **Cập nhật baseUrl trong `database_service.dart`:**
   ```dart
   static String get baseUrl {
     if (kIsWeb) {
       return 'http://localhost:5000/api';
     } else {
       return 'http://YOUR_COMPUTER_IP:5000/api'; // Thay YOUR_COMPUTER_IP
     }
   }
   ```

## ✅ Checklist Hoàn Thành

- [ ] Đã tạo Firebase project
- [ ] Đã thêm Android app vào Firebase
- [ ] Đã lấy và thêm SHA-1 certificate
- [ ] Đã download và copy `google-services.json`
- [ ] Đã kích hoạt Google Sign-In trong Firebase Authentication
- [ ] Đã chạy `flutter pub get`
- [ ] Backend đang chạy trên port 5000
- [ ] Đã test đăng nhập thành công

## 🚀 Sử Dụng

Sau khi cấu hình xong:

1. Mở ứng dụng
2. Tại màn hình đăng nhập, nhấn **"Đăng nhập bằng Google"**
3. Chọn tài khoản Google
4. Lần đầu đăng nhập sẽ tự động tạo tài khoản mới
5. Các lần sau sẽ đăng nhập trực tiếp

## 📚 Tài Liệu Tham Khảo

- [Google Sign-In for Flutter](https://pub.dev/packages/google_sign_in)
- [Firebase Authentication](https://firebase.google.com/docs/auth)
- [Google Identity Platform](https://developers.google.com/identity)

## 💡 Lưu Ý

- Google Sign-In yêu cầu kết nối Internet
- Tài khoản được tạo sẽ không có mật khẩu (chỉ đăng nhập qua Google)
- Có thể kết hợp với đăng nhập email/password và face recognition
- Backend tự động tạo user mới nếu email chưa tồn tại trong database

