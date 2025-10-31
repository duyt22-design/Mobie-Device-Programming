# 🗄️ Hướng Dẫn Kết Nối SQL Server

## 📋 Yêu Cầu

### 1. SQL Server
- SQL Server 2019 hoặc mới hơn
- SQL Server Management Studio (SSMS)

### 2. Node.js Backend
- Node.js v16 hoặc mới hơn
- npm hoặc yarn

### 3. Flutter App
- Flutter SDK 3.0+
- Dart 3.0+

---

## 🚀 Bước 1: Cài Đặt SQL Server

### Windows:
1. Tải SQL Server Developer Edition (miễn phí):
   - https://www.microsoft.com/en-us/sql-server/sql-server-downloads

2. Tải SQL Server Management Studio (SSMS):
   - https://docs.microsoft.com/en-us/sql/ssms/download-sql-server-management-studio-ssms

3. Cài đặt và khởi động SQL Server

---

## 🗃️ Bước 2: Tạo Database

1. Mở **SQL Server Management Studio (SSMS)**

2. Kết nối với SQL Server:
   - Server name: `localhost` hoặc `.` hoặc `(localdb)\MSSQLLocalDB`
   - Authentication: Windows Authentication

3. Mở file `backend/database.sql`

4. Chạy script để tạo database và tables:
   - Nhấn **F5** hoặc **Execute**

5. Kiểm tra:
   ```sql
   USE DrawingAppDB;
   SELECT * FROM Users;
   SELECT * FROM Tasks;
   SELECT * FROM TaskHistory;
   ```

---

## 🔧 Bước 3: Cài Đặt Backend API

1. Mở Terminal/CMD trong thư mục `backend`:
   ```bash
   cd backend
   ```

2. Cài đặt dependencies:
   ```bash
   npm install
   ```

3. Cấu hình kết nối trong `server.js`:
   ```javascript
   const config = {
     user: 'your_username',       // SA hoặc username của bạn
     password: 'your_password',   // Password SQL Server
     server: 'localhost',
     database: 'DrawingAppDB',
     options: {
       encrypt: true,
       trustServerCertificate: true
     },
     port: 1433
   };
   ```

4. Chạy server:
   ```bash
   npm start
   ```

5. Kiểm tra server đang chạy:
   - Mở trình duyệt: http://localhost:5000/api/users
   - Hoặc dùng Postman để test API

---

## 📱 Bước 4: Cấu Hình Flutter App

1. Cài đặt dependencies:
   ```bash
   flutter pub get
   ```

2. Cập nhật URL API trong `lib/services/database_service.dart`:
   ```dart
   static const String baseUrl = 'http://localhost:5000/api';
   ```

   **Lưu ý:** 
   - Nếu chạy trên **Android Emulator**: dùng `http://10.0.2.2:5000/api`
   - Nếu chạy trên **Physical Device**: dùng IP máy tính `http://192.168.x.x:5000/api`

3. Sử dụng DatabaseService trong code:
   ```dart
   // Import service
   import 'package:flutter_application_2/services/database_service.dart';

   // Sử dụng
   final dbService = DatabaseService();
   
   // Lấy users
   final users = await dbService.fetchUsersFromAPI();
   
   // Thêm user
   await dbService.addUserToAPI({
     'name': 'Nguyen Van A',
     'email': 'test@example.com',
   });
   
   // Đồng bộ dữ liệu
   await dbService.syncData();
   ```

---

## 🔒 Bước 5: Cấu Hình Bảo Mật (Production)

### Tạo file `.env` trong thư mục backend:
```env
DB_USER=your_username
DB_PASSWORD=your_password
DB_SERVER=localhost
DB_NAME=DrawingAppDB
DB_PORT=1433
PORT=5000
```

### Cập nhật `server.js`:
```javascript
require('dotenv').config();

const config = {
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  server: process.env.DB_SERVER,
  database: process.env.DB_NAME,
  port: parseInt(process.env.DB_PORT)
};
```

---

## 📊 API Endpoints

### Users
- `GET /api/users` - Lấy tất cả users
- `GET /api/users/:id` - Lấy user theo ID
- `POST /api/users` - Thêm user mới
- `PUT /api/users/:id` - Cập nhật user
- `DELETE /api/users/:id` - Xóa user

### Tasks
- `GET /api/tasks` - Lấy tất cả tasks
- `POST /api/tasks` - Thêm task mới
- `PUT /api/tasks/:id` - Cập nhật task

### History
- `POST /api/history` - Thêm lịch sử hoàn thành
- `GET /api/history/user/:userId` - Lấy lịch sử theo user

### Statistics
- `GET /api/statistics` - Lấy thống kê tổng quan
- `GET /api/statistics/top-users` - Lấy top users

---

## 🧪 Test API với Postman

### 1. Thêm User Mới
```
POST http://localhost:5000/api/users
Content-Type: application/json

{
  "name": "Nguyễn Văn Test",
  "email": "test@example.com",
  "totalTasksCompleted": 5,
  "averageScore": 85.5,
  "rank": 10
}
```

### 2. Lấy Tất Cả Users
```
GET http://localhost:5000/api/users
```

### 3. Thêm Task History
```
POST http://localhost:5000/api/history
Content-Type: application/json

{
  "userId": 1,
  "taskTitle": "Tô Màu Ngôi Sao",
  "score": 95.5,
  "timeUsed": 180,
  "completedAt": "2025-10-27T14:30:00"
}
```

---

## ⚠️ Xử Lý Lỗi Thường Gặp

### 1. Không kết nối được SQL Server
```
Error: Failed to connect to localhost:1433
```
**Giải pháp:**
- Kiểm tra SQL Server đã khởi động chưa
- Bật TCP/IP trong SQL Server Configuration Manager
- Kiểm tra port 1433 có mở không

### 2. Login failed
```
Error: Login failed for user 'username'
```
**Giải pháp:**
- Kiểm tra username/password
- Bật SQL Server Authentication
- Tạo login mới trong SSMS

### 3. CORS Error
```
Access to fetch at 'http://localhost:5000' has been blocked by CORS policy
```
**Giải pháp:**
- Đã được xử lý với `app.use(cors())` trong server.js

### 4. Android Emulator không kết nối được
**Giải pháp:**
- Dùng `http://10.0.2.2:5000/api` thay vì `http://localhost:5000/api`

---

## 📚 Tài Liệu Tham Khảo

- [SQL Server Documentation](https://docs.microsoft.com/en-us/sql/)
- [Node.js mssql Package](https://www.npmjs.com/package/mssql)
- [Express.js](https://expressjs.com/)
- [Flutter HTTP Package](https://pub.dev/packages/http)

---

## 🎯 Tiếp Theo

Sau khi setup xong, bạn có thể:
1. Tạo thêm API endpoints cho các chức năng khác
2. Thêm authentication (JWT)
3. Deploy lên cloud (Azure, AWS, Google Cloud)
4. Tối ưu hóa database với indexes và caching

---

## 💡 Tips

1. **Development**: Dùng `nodemon` để auto-restart server
   ```bash
   npm install -g nodemon
   nodemon server.js
   ```

2. **Logging**: Thêm console.log để debug
   ```javascript
   app.use((req, res, next) => {
     console.log(`${req.method} ${req.url}`);
     next();
   });
   ```

3. **Database Backup**: Backup database định kỳ
   ```sql
   BACKUP DATABASE DrawingAppDB 
   TO DISK = 'C:\Backup\DrawingAppDB.bak'
   ```

Chúc bạn thành công! 🚀

