# 🚀 Hướng Dẫn Chạy Backend SQLite

## ✅ Bước 1: Cài Đặt Dependencies (Đã xong!)

```bash
cd backend
npm install
```

✅ **Đã hoàn thành!** 290 packages đã được cài đặt.

---

## 🎯 Bước 2: Chạy Backend Server

**Mở Terminal MỚI** và chạy:

### **Windows PowerShell:**
```powershell
cd C:\Projects\flutter_application_2\backend
node server_sqlite.js
```

### **Windows CMD:**
```cmd
cd C:\Projects\flutter_application_2\backend
node server_sqlite.js
```

---

## 📊 Kết Quả Mong Đợi

Khi backend chạy thành công, bạn sẽ thấy:

```
📦 Khởi tạo database...
✅ Database đã sẵn sàng!
📊 Database stats:
   👥 Users: 7
   📝 Tasks: 7
   📜 History: 6

🚀 Server running on http://localhost:5000

🔐 Authentication:
   POST   /api/auth/register
   POST   /api/auth/login
   GET    /api/auth/check-email/:email

👥 Users:
   GET    /api/users
   POST   /api/users
   PUT    /api/users/:id
   DELETE /api/users/:id

📝 Tasks:
   GET    /api/tasks
   GET    /api/tasks/recent
   POST   /api/tasks

📜 History:
   POST   /api/history
   GET    /api/history/user/:userId

📊 Statistics:
   GET    /api/statistics
   GET    /api/statistics/top-users
   GET    /api/statistics/admin
   GET    /api/statistics/demographics

🏆 Leaderboard:
   GET    /api/leaderboard

🔔 Notifications:
   GET    /api/notifications/:userId
   GET    /api/notifications/:userId/unread-count
   PUT    /api/notifications/:id/read
   PUT    /api/notifications/:userId/read-all
   DELETE /api/notifications/:id

🔧 Admin Tools:
   POST   /api/admin/recalculate-stats

✅ Server sẵn sàng!
👤 Admin: admin@uef.edu.vn / admin123
👤 User: nguyenvana@uef.edu.vn / 123456
```

---

## 🧪 Bước 3: Test Kết Nối

### **Test trong Browser:**

Mở browser và vào các URL sau:

1. **Test Users API:**
   ```
   http://localhost:5000/api/users
   ```
   → Phải thấy danh sách users dạng JSON

2. **Test Tasks API:**
   ```
   http://localhost:5000/api/tasks
   ```
   → Phải thấy danh sách tasks

3. **Test Statistics:**
   ```
   http://localhost:5000/api/statistics
   ```
   → Phải thấy thống kê tổng quan

4. **Test Leaderboard:**
   ```
   http://localhost:5000/api/leaderboard?limit=5
   ```
   → Phải thấy TOP 5 users

---

### **Test trong PowerShell:**

```powershell
# Test API Users
Invoke-RestMethod -Uri "http://localhost:5000/api/users" -Method GET

# Test API Tasks
Invoke-RestMethod -Uri "http://localhost:5000/api/tasks" -Method GET

# Test Statistics
Invoke-RestMethod -Uri "http://localhost:5000/api/statistics" -Method GET
```

---

## 🔍 Kiểm Tra Database File

Database SQLite được lưu tại:

```
C:\Projects\flutter_application_2\backend\drawing_app.db
```

**Kiểm tra:**
- File có tồn tại không?
- Kích thước > 0 KB?

**Xem database với SQLite Browser:**
1. Download: https://sqlitebrowser.org/
2. Mở file `drawing_app.db`
3. Xem tables: Users, Tasks, TaskHistory, Notifications

---

## ❌ Troubleshooting

### Lỗi: "Cannot find module 'express'"

**Nguyên nhân:** Chưa cài npm packages

**Giải pháp:**
```bash
cd backend
npm install
```

---

### Lỗi: "EADDRINUSE: address already in use :::5000"

**Nguyên nhân:** Port 5000 đã bị chiếm

**Giải pháp 1 - Tìm và kill process:**
```powershell
# Tìm process đang dùng port 5000
netstat -ano | findstr :5000

# Kill process (thay PID bằng số thực tế)
taskkill /PID <PID> /F
```

**Giải pháp 2 - Đổi port:**

Sửa file `server_sqlite.js`:
```javascript
const port = 5001; // Thay 5000 thành 5001
```

Và sửa file `lib/services/database_service.dart`:
```dart
static String get baseUrl {
  if (kIsWeb) {
    return 'http://localhost:5001/api';
  } else {
    return 'http://10.0.2.2:5001/api';
  }
}
```

---

### Backend chạy nhưng Flutter không connect được

**Nguyên nhân:** Flutter trên Android Emulator dùng `10.0.2.2` thay vì `localhost`

**Giải pháp:** 

File `lib/services/database_service.dart` đã được cấu hình đúng:
```dart
static String get baseUrl {
  if (kIsWeb) {
    return 'http://localhost:5000/api'; // Web
  } else {
    return 'http://10.0.2.2:5000/api'; // Android Emulator
  }
}
```

✅ Không cần sửa gì!

---

### Lỗi: Database file locked

**Nguyên nhân:** File `.db-wal` hoặc `.db-shm` đang bị lock

**Giải pháp:**
1. Stop backend (Ctrl+C)
2. Xóa file `drawing_app.db-wal` và `drawing_app.db-shm`
3. Chạy lại backend

---

## 📱 Kết Nối Với Flutter App

Sau khi backend chạy thành công:

1. **Chạy Flutter app:**
   ```bash
   flutter run
   ```

2. **Test trong app:**
   - Đăng nhập: admin@uef.edu.vn / admin123
   - Xem danh sách tasks
   - Hoàn thành một task
   - Xem history
   - Xem leaderboard

---

## 🎉 Checklist Hoàn Thành

- [ ] ✅ npm install thành công (290 packages)
- [ ] ✅ Backend chạy thành công (thấy 🚀 Server running)
- [ ] ✅ Test browser: http://localhost:5000/api/users OK
- [ ] ✅ Flutter app kết nối được backend
- [ ] ✅ Có thể đăng nhập vào app
- [ ] ✅ Có thể xem và hoàn thành tasks

---

## 💡 Tips

1. **Luôn chạy backend TRƯỚC khi chạy Flutter app**
2. **Giữ terminal backend mở** (đừng đóng)
3. **Check logs** trong terminal backend để debug
4. **Test API trong browser** trước khi test trong app

---

## 🆘 Cần Giúp Đỡ?

Nếu vẫn gặp vấn đề:

1. **Chụp screenshot** terminal backend
2. **Copy error message** đầy đủ
3. **Cho biết:**
   - Node.js version: `node --version`
   - Port có bị chiếm không: `netstat -ano | findstr :5000`
   - Database file có tồn tại không

---

**Good luck! 🚀**


