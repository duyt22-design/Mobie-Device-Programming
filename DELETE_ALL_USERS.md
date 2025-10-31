# Hướng dẫn xóa tất cả users

## Cách 1: Sử dụng SQLite Command Line

Mở terminal trong thư mục `backend` và chạy:

```bash
# Backup database trước (khuyến nghị)
cp drawing_app.db drawing_app.db.backup

# Xóa tất cả users trừ admin
sqlite3 drawing_app.db "DELETE FROM Users WHERE role != 'admin';"

# Xóa task history của users đã xóa
sqlite3 drawing_app.db "DELETE FROM TaskHistory WHERE userId NOT IN (SELECT id FROM Users);"

# Xóa notifications của users đã xóa
sqlite3 drawing_app.db "DELETE FROM Notifications WHERE userId NOT IN (SELECT id FROM Users);"
```

## Cách 2: Sử dụng SQL Query trong Node.js

Tạo file `delete_users.js` trong thư mục `backend`:

```javascript
const Database = require('better-sqlite3');
const db = new Database('drawing_app.db');

// Xóa tất cả users trừ admin
const result = db.prepare('DELETE FROM Users WHERE role != "admin"').run();
console.log(`✅ Đã xóa ${result.changes} users (giữ lại admin)`);

// Xóa task history
db.prepare('DELETE FROM TaskHistory WHERE userId NOT IN (SELECT id FROM Users)').run();

// Xóa notifications
db.prepare('DELETE FROM Notifications WHERE userId NOT IN (SELECT id FROM Users)').run();

db.close();
```

Chạy: `node delete_users.js`

## Cách 3: Sử dụng API (sau khi khởi động backend)

```bash
# Khởi động backend
cd backend
node server_sqlite.js

# Trong terminal khác, chạy:
curl -X DELETE http://localhost:5000/api/users
```

## ⚠️ CẢNH BÁO

- Thao tác này xóa VĨNH VIỄN tất cả users (trừ admin)
- Tất cả task history và notifications cũng sẽ bị xóa
- KHÔNG THỂ hoàn tác sau khi xóa
- Nên backup database trước khi thực hiện





