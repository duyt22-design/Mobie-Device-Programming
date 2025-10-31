# 🚀 Hướng Dẫn Kết Nối Với Server

## ❌ Vấn Đề: Không Kết Nối Được Với Server

## ✅ Giải Pháp: Khởi Động Backend Server

### **Bước 1: Mở PowerShell**

Mở PowerShell tại thư mục dự án: `C:\Projects\flutter-application_2`

### **Bước 2: Chạy Script Khởi Động**

Có 2 cách:

#### **Cách 1: Dùng Script PowerShell (Khuyến nghị)**
```powershell
.\start_server.ps1
```

#### **Cách 2: Chạy Thủ Công**
```powershell
cd backend
node server_sqlite.js
```

#### **Cách 3: Dùng File Batch**
```cmd
cd backend
START_BACKEND.bat
```

---

### **Bước 3: Kiểm Tra Server Đã Chạy**

Khi server khởi động thành công, bạn sẽ thấy:

```
📊 Database stats:
   👥 Users: X
   📝 Tasks: X
   📜 History: X

🚀 Server running on http://localhost:5000

🔐 Authentication:
   POST   /api/auth/register
   POST   /api/auth/login
   ...

✅ Server sẵn sàng!
```

---

### **Bước 4: Giữ Terminal Chạy Server**

⚠️ **QUAN TRỌNG**: Giữ terminal này MỞ và chạy server. Đừng đóng!

---

### **Bước 5: Chạy Flutter App**

Mở terminal MỚI và chạy:

```bash
flutter run
```

App sẽ tự động kết nối đến:
- **Web**: `http://localhost:5000/api`
- **Android Emulator**: `http://10.0.2.2:5000/api`
- **Thiết bị thật**: IP của máy tính (tự động phát hiện)

---

## 🔧 Troubleshooting

### **Lỗi: Port 5000 đã được sử dụng**

**Giải pháp:**
```powershell
# Tìm process đang dùng port 5000
netstat -ano | findstr :5000

# Kill process (thay PID bằng số thực tế)
taskkill /PID <PID> /F
```

### **Lỗi: Cannot find module**

**Giải pháp:**
```powershell
cd backend
npm install
```

### **Lỗi: Database không tìm thấy**

**Giải pháp:** Server sẽ tự tạo database nếu chưa có.

### **Lỗi: Kết nối bị timeout**

**Kiểm tra:**
1. Server có đang chạy không? (Xem terminal)
2. Firewall có chặn port 5000 không?
3. IP có đúng không? (Kiểm tra trong `database_service.dart`)

---

## 📱 Test Kết Nối Nhanh

Mở browser và vào:
- http://localhost:5000/api/statistics
- http://localhost:5000/api/users
- http://localhost:5000/api/tasks

Nếu thấy JSON data → Server OK ✅

---

## 🔐 Tài Khoản Mặc Định

**Admin:**
- Email: `admin@uef.edu.vn`
- Password: `admin123`

**User:**
- Email: `nguyenvana@uef.edu.vn`
- Password: `123456`

---

## ✅ Checklist

- [ ] Backend server đang chạy (terminal hiển thị "Server running")
- [ ] Port 5000 không bị chiếm bởi process khác
- [ ] Có thể truy cập http://localhost:5000/api/statistics
- [ ] Flutter app đã được build và chạy
- [ ] Network/IP configuration đúng

---

## 📞 Nếu Vẫn Không Kết Nối

1. Kiểm tra log trong terminal backend
2. Kiểm tra log trong Flutter console
3. Thử restart cả backend và Flutter app
4. Kiểm tra firewall/antivirus có chặn không

