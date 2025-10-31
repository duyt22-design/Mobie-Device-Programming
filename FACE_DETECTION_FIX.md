# Sửa Lỗi Nhận Diện Khuôn Mặt

## ✅ Các Thay Đổi Đã Thực Hiện

### 1. **Sửa InputImage Format**
- Thay đổi từ `yuv420` sang tự động detect format
- Hỗ trợ cả `yuv420` và `nv21` tùy theo thiết bị

### 2. **Sửa Rotation**
- Thêm function `_getImageRotation()` để xử lý rotation đúng
- Front camera sử dụng `rotation270deg` trên Android
- Tự động map sensor orientation

### 3. **Giảm Số Lần Scan**
- Giảm từ 15 lần xuống **5 lần** để test dễ hơn
- Face Recognition: giảm từ 10 xuống **5 lần**

### 4. **Thêm Debug Logs**
- Print số faces được detect: `👁️ Faces detected: X`
- Giúp debug khi có vấn đề

## 🔧 Cách Test

### Bước 1: Stop App Hiện Tại
```bash
# Nhấn Ctrl+C trong terminal đang chạy flutter
```

### Bước 2: Hot Restart
```bash
flutter run
# Hoặc nhấn 'R' trong terminal để hot restart
```

### Bước 3: Đăng Ký Khuôn Mặt

1. Đăng nhập vào app (hoặc đăng ký tài khoản mới)
2. Vào **Profile** → **Đăng ký khuôn mặt**
3. Cho phép quyền camera
4. **Quan trọng:** Đảm bảo:
   - ✅ Chỉ có 1 người trong khung hình
   - ✅ Ánh sáng đủ (không quá tối)
   - ✅ Nhìn thẳng vào camera
   - ✅ Giữ đầu ổn định
5. Chờ thanh tiến trình chạy từ 0 → 5
6. Thành công sẽ hiện popup xanh

### Bước 4: Kiểm Tra Logs (Nếu Vẫn Không Detect)

Mở terminal và xem logs:

```bash
# Tìm dòng có 👁️
👁️ Faces detected: 1  ← Thành công (1 khuôn mặt)
👁️ Faces detected: 0  ← Thất bại (không detect được)
👁️ Faces detected: 2  ← Lỗi (nhiều người)
```

## 🐛 Troubleshooting

### Vấn đề 1: "Không phát hiện khuôn mặt" (màu đỏ)

**Nguyên nhân:**
- Ánh sáng quá yếu
- Khuôn mặt quá xa hoặc quá gần
- Camera bị che khuất
- Face detection chưa hoạt động

**Giải pháp:**
1. Bật đèn trong phòng
2. Di chuyển khuôn mặt gần hơn (khoảng 30-50cm từ màn hình)
3. Đảm bảo camera trước được sử dụng (không phải camera sau)
4. Kiểm tra logs: nếu `👁️ Faces detected: 0` liên tục → vấn đề về rotation/format

### Vấn đề 2: Hiện "Phát hiện nhiều khuôn mặt"

**Nguyên nhân:**
- Có người khác trong khung hình
- Có ảnh/poster có khuôn mặt phía sau
- Camera detect nhầm vật thể khác

**Giải pháp:**
- Đảm bảo chỉ có 1 người
- Xóa ảnh/poster có khuôn mặt khỏi background

### Vấn đề 3: Counter không tăng (0/5)

**Nguyên nhân:**
- Face detection không ổn định
- Khuôn mặt di chuyển quá nhiều
- Image stream bị lag

**Giải pháp:**
1. Giữ đầu hoàn toàn ổn định
2. Nhìn thẳng vào camera (không nghiêng đầu)
3. Chờ 2-3 giây cho camera focus
4. Restart app nếu cần

### Vấn đề 4: "Lỗi khởi tạo camera"

**Nguyên nhân:**
- Chưa cấp quyền camera
- Camera đang được sử dụng bởi app khác
- Lỗi driver camera

**Giải pháp:**
1. Vào **Settings → Apps → Drawing App → Permissions**
2. Bật **Camera** permission
3. Đóng app khác đang dùng camera
4. Restart thiết bị nếu cần

### Vấn đề 5: App crash khi mở camera

**Nguyên nhân:**
- Thiếu permissions trong AndroidManifest.xml
- Incompatible camera format

**Giải pháp:**
Kiểm tra `android/app/src/main/AndroidManifest.xml` có dòng:

```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-feature android:name="android.hardware.camera" />
<uses-feature android:name="android.hardware.camera.front" />
```

Nếu chưa có, thêm vào và rebuild:

```bash
flutter clean
flutter pub get
flutter run
```

## 📊 Kiểm Tra Backend

Nếu đã đăng ký khuôn mặt thành công nhưng không đăng nhập được:

### 1. Kiểm tra Backend đang chạy
```bash
cd backend
node server_sqlite.js
```

Phải thấy:
```
✅ Database đã sẵn sàng!
🚀 Server running on http://localhost:5000
```

### 2. Kiểm tra Database có face data

```bash
# Trong terminal backend
sqlite3 drawing_app.db

# Trong sqlite console
SELECT id, name, email, faceEnabled FROM Users WHERE faceEnabled = 1;
```

Phải có ít nhất 1 user với `faceEnabled = 1`.

### 3. Test Face Login API

Mở `backend/test_api.html` trong browser:

```javascript
// Test face login endpoint
fetch('http://localhost:5000/api/auth/face-login', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    faceSignature: 'test_signature'
  })
})
.then(r => r.json())
.then(console.log);
```

## 🎯 Kiểm Tra Thành Công

Khi đăng ký khuôn mặt thành công, bạn sẽ thấy:

1. ✅ Thanh tiến trình chạy từ 0/5 → 5/5
2. ✅ Màu xanh lá xuất hiện trên UI
3. ✅ Popup "Đăng ký khuôn mặt thành công!"
4. ✅ Trong database: `faceEnabled = 1` và `faceData` có giá trị

Sau đó, tại màn hình Login:

1. ✅ Hiển thị nút "Đăng nhập bằng khuôn mặt" (nếu có users đã đăng ký)
2. ✅ Nhấn nút → Mở camera
3. ✅ Nhìn vào camera → Tự động nhận diện
4. ✅ Popup "Đăng nhập thành công!"

## 🔍 Debug Advanced

### Xem toàn bộ logs chi tiết

```bash
flutter run -v
```

### Lọc chỉ face detection logs

**Windows PowerShell:**
```powershell
flutter run | Select-String "Faces detected"
```

**macOS/Linux:**
```bash
flutter run | grep "Faces detected"
```

### Capture screenshot khi lỗi

```bash
flutter screenshot --out=debug_face.png
```

## 📱 Test Trên Thiết Bị Thật

Nếu test trên Android emulator không ổn, thử trên thiết bị thật:

1. Kết nối điện thoại qua USB
2. Bật Developer Options + USB Debugging
3. Run:
   ```bash
   flutter devices  # Kiểm tra thiết bị
   flutter run -d <device_id>
   ```

Thiết bị thật thường có camera tốt hơn → face detection chính xác hơn.

## 📝 Các Cải Tiến Đã Làm

| Trước | Sau |
|-------|-----|
| Scan 15 lần | Scan 5 lần (nhanh hơn 3x) |
| Fixed rotation | Auto-detect rotation |
| Fixed format yuv420 | Auto yuv420/nv21 |
| Không có logs | Debug logs đầy đủ |
| Không xử lý errors | Try-catch + logging |

## ✨ Tính Năng Mới

- ✅ Tự động phát hiện camera orientation
- ✅ Hỗ trợ nhiều định dạng image
- ✅ Progress bar hiển thị tiến trình scan
- ✅ Màu sắc thay đổi theo trạng thái (đỏ/xanh)
- ✅ Debug logs giúp troubleshoot

## 🚀 Next Steps

Nếu vẫn gặp vấn đề, cung cấp:

1. **Logs** từ terminal (có dòng `👁️`)
2. **Screenshot** màn hình lỗi
3. **Thiết bị** đang test (emulator hay real device)
4. **Ánh sáng** môi trường (tối/sáng)

Chúc bạn thành công! 🎉


