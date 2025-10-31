# 🛠️ Hướng Dẫn Fix Lỗi Build Flutter

## 🐛 Lỗi Thường Gặp

```
Flutter failed to delete a directory at "build\flutter_assets"
The flutter tool cannot access the file or directory
```

**Nguyên nhân:** Files bị lock bởi các processes đang chạy (dart, flutter, edge, adb...)

---

## ✅ Giải Pháp 1: Tự Động (KHUYẾN NGHỊ)

### Chạy Script PowerShell

```powershell
.\fix_build_error.ps1
```

**Script sẽ tự động:**
1. ✅ Kill tất cả processes
2. ✅ Xóa build folders
3. ✅ Flutter clean
4. ✅ Flutter pub get
5. ✅ Khởi động backend
6. ✅ Chạy app trên Edge

**Thời gian:** ~2-3 phút

---

## 🔧 Giải Pháp 2: Thủ Công

### Bước 1: Kill Processes
```powershell
taskkill /F /IM dart.exe /IM flutter.exe /IM java.exe /IM adb.exe /IM msedge.exe
```

### Bước 2: Xóa Build Folders
```powershell
cd C:\Users\bayan\OneDrive\Desktop\Mobile\flutter_application_2
Remove-Item -Recurse -Force "build" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force ".dart_tool" -ErrorAction SilentlyContinue
```

### Bước 3: Flutter Clean
```powershell
flutter clean
flutter pub get
```

### Bước 4: Khởi Động Backend
```powershell
cd backend
node server_sqlite.js
```

### Bước 5: Chạy App
```powershell
# Terminal mới
flutter run -d edge
```

---

## 🚨 Nếu Vẫn Lỗi

### Cách 1: Restart Computer
Đôi khi cần restart máy để giải phóng hoàn toàn file locks.

### Cách 2: Chạy Trên Device Khác
```powershell
# Xem devices available
flutter devices

# Chạy trên Windows Desktop
flutter run -d windows

# Hoặc Chrome
flutter run -d chrome
```

### Cách 3: Delete Toàn Bộ Build
```powershell
# CẢNH BÁO: Sẽ mất cache, lần build đầu sẽ lâu
flutter clean
Remove-Item -Recurse -Force "build", ".dart_tool", "windows\flutter", "linux\flutter"
flutter pub get
```

---

## 📋 Checklist Khi Gặp Lỗi

- [ ] Đã kill tất cả dart/flutter processes?
- [ ] Đã xóa build folder?
- [ ] Đã flutter clean?
- [ ] Backend có đang chạy không?
- [ ] Có processes nào đang lock files?

---

## 🔍 Kiểm Tra Processes Đang Chạy

```powershell
# Kiểm tra dart
Get-Process | Where-Object {$_.ProcessName -like "*dart*"}

# Kiểm tra flutter
Get-Process | Where-Object {$_.ProcessName -like "*flutter*"}

# Kiểm tra edge
Get-Process | Where-Object {$_.ProcessName -like "*edge*"}
```

---

## 💡 Tips Để Tránh Lỗi

1. **Luôn Stop App Đúng Cách**
   - Trong VS Code: Nhấn Stop button (không Ctrl+C)
   - Trong terminal: Nhấn `q` để quit gracefully

2. **Đóng Edge Trước Khi Build Lại**
   - Đảm bảo không có tab Flutter app đang mở

3. **Restart Backend Đúng Cách**
   - Ctrl+C để stop
   - Đợi 2-3 giây
   - Rồi mới `node server_sqlite.js`

4. **Sử dụng Hot Reload**
   - Nhấn `r` để reload thay vì restart
   - Nhấn `R` (Shift+R) để restart app

---

## 🎯 Quick Commands

### Kill Everything & Clean
```powershell
taskkill /F /IM dart.exe /IM flutter.exe /IM msedge.exe 2>$null; Remove-Item -Recurse -Force "build" -ErrorAction SilentlyContinue; flutter clean
```

### Start Backend & Run App
```powershell
# Terminal 1
cd backend; node server_sqlite.js

# Terminal 2 (sau 3 giây)
flutter run -d edge
```

---

## 📞 Nếu Script Không Chạy

### Enable PowerShell Scripts
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Run Script
```powershell
.\fix_build_error.ps1
```

---

**Tạo:** 27/10/2025  
**Status:** ✅ Tested & Working


