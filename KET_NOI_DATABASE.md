# 🔌 Hướng Dẫn Kết Nối Database - SAU KHI ĐỔI TÊN THƯ MỤC

## ✅ Kiểm Tra Đã Hoàn Thành

Script kiểm tra cho thấy:
- ✅ File database: `drawing_app.db` tồn tại (432 KB)
- ✅ Cấu hình trong code: ĐÚNG
- ✅ Đường dẫn database: ĐÚNG

---

## 🚀 BƯỚC TIẾP THEO: Khởi Động Backend Server

### **Bước 1: Khởi Động Backend**

Mở **PowerShell** hoặc **CMD** và chạy:

```powershell
cd C:\Projects\flutter-application_2\backend
node server_sqlite.js
```

**Hoặc dùng file batch:**

```cmd
cd C:\Projects\flutter-application_2\backend
START_BACKEND.bat
```

**Kết quả mong đợi:**
```
🚀 Server running on http://localhost:5000
✅ Database đã sẵn sàng!
📊 Database stats:
   👥 Users: X
   📝 Tasks: X
```

### **Bước 2: Kiểm Tra Server Đang Chạy**

**Mở Terminal/Browser MỚI** (giữ nguyên terminal backend):

**Test trong Browser:**
- http://localhost:5000/api/users
- http://localhost:5000/api/tasks
- http://localhost:5000/api/statistics

**Hoặc test trong PowerShell:**
```powershell
Invoke-RestMethod -Uri "http://localhost:5000/api/statistics" -Method GET
```

**Nếu thấy dữ liệu JSON → Server đang chạy tốt! ✅**

### **Bước 3: Chạy Flutter App**

```bash
flutter run
```

App sẽ tự động kết nối đến:
- **Android Emulator**: `http://10.0.2.2:5000/api`
- **Web**: `http://localhost:5000/api`

---

## ❌ Nếu Vẫn Không Kết Nối

### **1. Kiểm tra port 5000 có đang chạy không:**

```powershell
netstat -ano | findstr :5000
```

**Nếu không có kết quả** → Backend chưa chạy, cần khởi động lại.

### **2. Kiểm tra lỗi khi khởi động backend:**

Xem terminal nơi chạy `node server_sqlite.js` có lỗi gì không:
- ❌ `Cannot find module` → Chạy `npm install` trong thư mục backend
- ❌ `Port already in use` → Port 5000 bị chiếm, cần kill process hoặc đổi port

### **3. Test kết nối từ Flutter:**

Trong Flutter app, ở màn hình **Login**, nhấn nút **"Test Kết Nối Database"** để xem lỗi cụ thể.

---

## 📋 Checklist

- [ ] ✅ File database tồn tại (`drawing_app.db`)
- [ ] ✅ Cấu hình code đúng
- [ ] ✅ Backend server đã khởi động
- [ ] ✅ Test API trong browser thành công
- [ ] ✅ Flutter app có thể kết nối

---

## 💡 Lưu Ý Quan Trọng

1. **Luôn khởi động backend TRƯỚC khi chạy Flutter app**
2. **Giữ terminal backend mở** (đừng đóng)
3. **Nếu đổi tên/move thư mục project:**
   - Database file vẫn ở `backend/drawing_app.db` (tương đối)
   - Code tự động tìm file trong cùng thư mục
   - Không cần sửa gì nếu file database cùng thư mục với `server_sqlite.js`

---

## 🔧 Script Kiểm Tra

Chạy để kiểm tra tự động:

```powershell
cd C:\Projects\flutter-application_2\backend
node kiem_tra_va_sua_duong_dan.js
```

---

**Chúc bạn thành công! 🚀**



