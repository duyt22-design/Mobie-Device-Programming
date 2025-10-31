# 🚀 HƯỚNG DẪN KHỞI ĐỘNG SERVER - NHANH

## ⚠️ QUAN TRỌNG: Bạn đang ở thư mục sai!

Bạn đang ở: `C:\Users\bayan`  
Cần chuyển đến: `C:\Projects\flutter-application_2`

---

## ✅ CÁCH 1: Dùng File Batch (Dễ nhất)

**Bước 1:** Mở File Explorer  
**Bước 2:** Đi đến: `C:\Projects\flutter-application_2`  
**Bước 3:** Double-click file: **`KHOI_DONG_SERVER.bat`**

Hoặc:

**Bước 1:** Mở PowerShell  
**Bước 2:** Gõ lệnh:
```powershell
cd C:\Projects\flutter-application_2
.\KHOI_DONG_SERVER.bat
```

---

## ✅ CÁCH 2: Chạy Thủ Công

Mở PowerShell và gõ từng lệnh:

```powershell
cd C:\Projects\flutter-application_2
cd backend
node server_sqlite.js
```

---

## ✅ CÁCH 3: Dùng Script PowerShell

```powershell
cd C:\Projects\flutter-application_2
.\start_server.ps1
```

---

## 📋 KẾT QUẢ MONG ĐỢI

Khi server chạy thành công, bạn sẽ thấy:

```
📊 Database stats:
   👥 Users: X
   📝 Tasks: X
   📜 History: X

🚀 Server running on http://localhost:5000
```

---

## ⚠️ LƯU Ý

- **GIỮ CỬA SỔ TERMINAL MỞ** - Đừng đóng!
- Mở terminal MỚI để chạy Flutter app

---

## 🧪 Test Server

Mở browser và vào: http://localhost:5000/api/statistics

Nếu thấy JSON → Server OK ✅

