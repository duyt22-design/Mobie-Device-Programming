# 🔧 SỬA LỖI KẾT NỐI VỚI SERVER DATABASE

## ❌ Vấn Đề Hiện Tại

- Server chưa chạy (port 5000 không phản hồi)
- IP mới `192.168.10.107` chưa có trong danh sách

## ✅ Đã Sửa

1. ✅ **Cập nhật IP mới** vào danh sách `possibleIPs`
2. ✅ **Bật auto-detect IP** thay vì chỉ dùng `10.0.2.2`
3. ✅ **IP ưu tiên**: `192.168.10.107` (IP hiện tại)

---

## 🚀 BƯỚC TIẾP THEO: Khởi Động Server

### **Cách 1: Dùng Script PowerShell (Khuyến nghị)**

```powershell
.\kiem_tra_va_khoi_dong_server.ps1
```

### **Cách 2: Chạy Thủ Công**

```powershell
cd C:\Projects\flutter-application_2\backend
node server_sqlite.js
```

### **Cách 3: Dùng File Batch**

Double-click: `KHOI_DONG_SERVER.bat`

---

## 📋 Kết Quả Mong Đợi

Khi server chạy thành công:

```
📊 Database stats:
   👥 Users: X
   📝 Tasks: X
   📜 History: X

🚀 Server running on http://localhost:5000
```

---

## 🔍 Kiểm Tra Kết Nối

### **Test trong Browser:**

1. http://localhost:5000/api/statistics
2. http://localhost:5000/api/users
3. http://localhost:5000/api/tasks

Nếu thấy JSON data → Server OK ✅

### **Test trong PowerShell:**

```powershell
Invoke-RestMethod -Uri "http://localhost:5000/api/statistics" -Method GET
```

---

## 📱 Kết Nối Từ Flutter App

App sẽ tự động thử các IP sau (theo thứ tự):

1. ✅ `192.168.10.107` ← **IP hiện tại (ưu tiên)**
2. `10.19.252.97`
3. `10.215.60.97`
4. `192.168.1.249`
5. `192.168.0.100`
6. `192.168.1.100`
7. `10.0.2.2` ← Android Emulator (fallback)

---

## ⚠️ Lưu Ý Quan Trọng

1. **GIỮ TERMINAL SERVER MỞ** - Không đóng terminal chạy server
2. **Mở terminal mới** để chạy Flutter app:
   ```bash
   flutter run
   ```
3. **Nếu IP thay đổi**, cập nhật lại trong `lib/services/database_service.dart` dòng 25

---

## 🔧 Nếu Vẫn Không Kết Nối

### **1. Kiểm tra Firewall:**

```powershell
# Cho phép port 5000 qua firewall
New-NetFirewallRule -DisplayName "Backend Server" -Direction Inbound -LocalPort 5000 -Protocol TCP -Action Allow
```

### **2. Kiểm tra IP có đúng không:**

```powershell
ipconfig | findstr /i "IPv4"
```

Đảm bảo IP này có trong danh sách `possibleIPs`

### **3. Test từ thiết bị/emulator:**

- **Android Emulator**: Dùng `10.0.2.2:5000`
- **Thiết bị thật**: Dùng IP của máy tính (vd: `192.168.10.107:5000`)

---

## ✅ Checklist

- [ ] Backend server đang chạy (terminal hiển thị "Server running")
- [ ] Port 5000 không bị chiếm
- [ ] Có thể truy cập http://localhost:5000/api/statistics
- [ ] IP hiện tại (`192.168.10.107`) có trong code
- [ ] Firewall không chặn port 5000
- [ ] Flutter app đã rebuild sau khi sửa code

---

## 📞 Debug Logs

Kiểm tra console Flutter để xem:
- IP nào đang được dùng
- Có lỗi kết nối không
- Server có phản hồi không

