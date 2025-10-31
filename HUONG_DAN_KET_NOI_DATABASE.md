# 🔌 HƯỚNG DẪN KIỂM TRA VÀ KẾT NỐI DATABASE

## 📊 Kết Quả Kiểm Tra

✅ **Database file**: Tồn tại (432 KB)  
❌ **Server**: Chưa chạy  
⚠️ **Kết nối**: Chưa thể kết nối

---

## 🚀 BƯỚC 1: Khởi Động Server

### **Cách 1: Dùng Script PowerShell (Khuyến nghị)**

Mở PowerShell và chạy:

```powershell
.\khoi_dong_server.ps1
```

### **Cách 2: Chạy Thủ Công**

```powershell
cd backend
node server_sqlite.js
```

### **Cách 3: Dùng File Batch**

Double-click: `KHOI_DONG_SERVER.bat`

---

## ✅ BƯỚC 2: Kiểm Tra Server Đã Chạy

Khi server khởi động thành công, bạn sẽ thấy:

```
📊 Database stats:
   👥 Users: X
   📝 Tasks: X
   📜 History: X

🚀 Server running on http://localhost:5000
```

---

## 🧪 BƯỚC 3: Test Kết Nối

### **Chạy script kiểm tra:**

```powershell
.\test_connection.ps1
```

### **Hoặc test trong Browser:**

1. http://localhost:5000/api/statistics
2. http://localhost:5000/api/users
3. http://localhost:5000/api/tasks

Nếu thấy JSON data → Server OK ✅

---

## 📱 BƯỚC 4: Kết Nối Từ Flutter App

### **1. Giữ Terminal Server MỞ**

⚠️ **QUAN TRỌNG**: Đừng đóng terminal đang chạy server!

### **2. Mở Terminal MỚI**

Chạy Flutter app:

```bash
flutter run
```

### **3. App Tự Động Kết Nối**

App sẽ tự động thử các IP sau (theo thứ tự):

1. ✅ `192.168.10.107` ← **IP hiện tại (ưu tiên)**
2. `10.19.252.97`
3. `10.215.60.97`
4. `192.168.1.249`
5. `192.168.0.100`
6. `192.168.1.100`
7. `10.0.2.2` ← Android Emulator (fallback)

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

## ✅ Checklist Kết Nối

- [ ] Database file tồn tại (✅ Đã có - 432 KB)
- [ ] Backend server đang chạy (❌ Cần khởi động)
- [ ] Port 5000 không bị chiếm
- [ ] Có thể truy cập http://localhost:5000/api/statistics
- [ ] IP hiện tại (`192.168.10.107`) có trong code (✅ Đã có)
- [ ] Flutter app đã rebuild sau khi sửa code

---

## 📞 Nếu Vẫn Không Kết Nối

1. **Kiểm tra log trong terminal backend**
2. **Kiểm tra log trong Flutter console**
3. **Thử restart cả backend và Flutter app**
4. **Kiểm tra firewall/antivirus có chặn không**

---

## 🎯 Tóm Tắt

1. **Chạy**: `.\khoi_dong_server.ps1` để khởi động server
2. **Giữ terminal server mở**
3. **Chạy Flutter app** trong terminal mới
4. **Kiểm tra**: `.\test_connection.ps1` để verify

---

## 📍 Thông Tin Quan Trọng

- **Database**: `backend\drawing_app.db` (432 KB)
- **IP hiện tại**: `192.168.10.107`
- **Port**: `5000`
- **URL API**: `http://localhost:5000/api`

