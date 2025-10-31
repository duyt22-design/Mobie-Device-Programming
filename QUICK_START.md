# 🚀 Quick Start - Chạy App

## ✅ Hiện Tại Đã Có

1. **Backend đang chạy**: http://localhost:5000
2. **Database**: SQLite với 9 users, 8 tasks
3. **IP mới**: `10.19.252.97`
4. **Auto-detect**: Flutter app tự động phát hiện server

---

## 🎯 Chạy App Ngay Bây Giờ

### Bước 1: Kiểm tra Backend đang chạy
```powershell
Invoke-RestMethod -Uri "http://localhost:5000/api/statistics" -Method GET
```

Nếu thấy dữ liệu → Backend OK ✅

Nếu không → Chạy backend:
```powershell
cd backend
node server_sqlite.js
```

### Bước 2: Chạy Flutter App
```bash
flutter run
```

---

## 🔐 Đăng Nhập

### Admin:
- Email: `admin@uef.edu.vn`
- Password: `admin123`

### User:
- Email: `nguyenvana@uef.edu.vn`
- Password: `123456`

---

## 📍 IP Configuration

### IP Hiện Tại:
```
10.19.252.97
```

### Flutter Auto-Detect (đã cấu hình):
Flutter app sẽ tự động thử các IP sau:
1. `10.19.252.97` ← IP hiện tại ⭐
2. `10.215.60.97` ← IP cũ
3. `192.168.1.249` ← Mạng gia đình
4. `10.0.2.2` ← Android Emulator

---

## 🛠️ Troubleshooting

### Không kết nối được backend:
1. Kiểm tra backend có chạy không:
   ```powershell
   Get-Process -Name "node"
   ```

2. Nếu không có → Chạy lại:
   ```powershell
   cd backend
   node server_sqlite.js
   ```

### IP đã thay đổi:
1. Kiểm tra IP mới:
   ```powershell
   ipconfig | findstr /i "IPv4"
   ```

2. Cập nhật trong file:
   `lib/services/database_service.dart` dòng 24

3. Hot restart app:
   ```bash
   # Nhấn 'R' trong terminal Flutter
   # Hoặc Stop và chạy lại
   ```

---

## 📊 Test API Nhanh

### Users:
```powershell
Invoke-RestMethod -Uri "http://localhost:5000/api/users" -Method GET
```

### Tasks:
```powershell
Invoke-RestMethod -Uri "http://localhost:5000/api/tasks" -Method GET
```

### Leaderboard:
```powershell
Invoke-RestMethod -Uri "http://localhost:5000/api/leaderboard?limit=5" -Method GET
```

---

## ✅ Checklist

- [x] Backend đang chạy
- [x] Database có dữ liệu
- [x] IP mới đã cập nhật
- [x] Flutter auto-detect hoạt động
- [x] Có thể đăng nhập

---

**Happy Coding! 🎨**



