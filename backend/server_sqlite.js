// Backend API sử dụng SQLite thay vì SQL Server
const express = require('express');
const Database = require('better-sqlite3');
const cors = require('cors');
const bodyParser = require('body-parser');
const bcrypt = require('bcryptjs');

const app = express();
const port = 5000;

// Middleware
app.use(cors());
app.use(bodyParser.json({ limit: '50mb' })); // Cho phép upload ảnh lớn
app.use(bodyParser.urlencoded({ limit: '50mb', extended: true }));

// Khởi tạo SQLite database
const db = new Database('drawing_app.db');
db.pragma('journal_mode = WAL'); // Tăng hiệu suất

// Tạo tables
function initDatabase() {
  console.log('📦 Khởi tạo database...');
  
  // Table Users
  db.exec(`
    CREATE TABLE IF NOT EXISTS Users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      email TEXT NOT NULL UNIQUE,
      password TEXT,
      role TEXT DEFAULT 'user',
      totalTasksCompleted INTEGER DEFAULT 0,
      averageScore REAL DEFAULT 0,
      rank INTEGER DEFAULT 0,
      createdAt TEXT DEFAULT (datetime('now')),
      updatedAt TEXT DEFAULT (datetime('now'))
    )
  `);

  // Migrate existing database: add password, role, birthDate, gender, avatar, and face data columns if they don't exist
  try {
    const columns = db.prepare("PRAGMA table_info(Users)").all();
    const hasPassword = columns.some(col => col.name === 'password');
    const hasRole = columns.some(col => col.name === 'role');
    const hasBirthDate = columns.some(col => col.name === 'birthDate');
    const hasScore = columns.some(col => col.name === 'score');
    const hasGender = columns.some(col => col.name === 'gender');
    const hasAvatar = columns.some(col => col.name === 'avatar');
    const hasFaceData = columns.some(col => col.name === 'faceData');
    const hasFaceEnabled = columns.some(col => col.name === 'faceEnabled');
    
    if (!hasPassword) {
      console.log('🔄 Migrating: Adding password column...');
      db.exec('ALTER TABLE Users ADD COLUMN password TEXT');
    }
    if (!hasRole) {
      console.log('🔄 Migrating: Adding role column...');
      db.exec("ALTER TABLE Users ADD COLUMN role TEXT DEFAULT 'user'");
    }
    if (!hasBirthDate) {
      console.log('🔄 Migrating: Adding birthDate column...');
      db.exec('ALTER TABLE Users ADD COLUMN birthDate TEXT');
    }
    if (!hasScore) {
      console.log('🔄 Migrating: Adding score column...');
      db.exec('ALTER TABLE Users ADD COLUMN score INTEGER DEFAULT 0');
    }
    if (!hasGender) {
      console.log('🔄 Migrating: Adding gender column...');
      db.exec("ALTER TABLE Users ADD COLUMN gender TEXT DEFAULT 'other'");
    }
    if (!hasAvatar) {
      console.log('🔄 Migrating: Adding avatar column...');
      db.exec('ALTER TABLE Users ADD COLUMN avatar TEXT');
    }
    if (!hasFaceData) {
      console.log('🔄 Migrating: Adding faceData column...');
      db.exec('ALTER TABLE Users ADD COLUMN faceData TEXT');
    }
    if (!hasFaceEnabled) {
      console.log('🔄 Migrating: Adding faceEnabled column...');
      db.exec('ALTER TABLE Users ADD COLUMN faceEnabled INTEGER DEFAULT 0');
    }
  } catch (err) {
    console.log('⚠️ Migration check:', err.message);
  }

  // Table Tasks
  db.exec(`
    CREATE TABLE IF NOT EXISTS Tasks (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      description TEXT,
      type TEXT NOT NULL,
      timeLimit INTEGER DEFAULT 300,
      isCompleted INTEGER DEFAULT 0,
      createdAt TEXT DEFAULT (datetime('now')),
      updatedAt TEXT DEFAULT (datetime('now'))
    )
  `);

  // Migrate existing database: add timeLimit column if it doesn't exist
  try {
    const taskColumns = db.prepare("PRAGMA table_info(Tasks)").all();
    const hasTimeLimit = taskColumns.some(col => col.name === 'timeLimit');
    
    if (!hasTimeLimit) {
      console.log('🔄 Migrating: Adding timeLimit column to Tasks...');
      db.exec('ALTER TABLE Tasks ADD COLUMN timeLimit INTEGER DEFAULT 300');
    }
  } catch (err) {
    console.log('⚠️ Migration check (Tasks):', err.message);
  }

  // Table UserTaskCompletion - Track which tasks each user has completed
  db.exec(`
    CREATE TABLE IF NOT EXISTS UserTaskCompletion (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      userId INTEGER NOT NULL,
      taskId INTEGER NOT NULL,
      completedAt TEXT DEFAULT (datetime('now')),
      UNIQUE(userId, taskId),
      FOREIGN KEY (userId) REFERENCES Users(id) ON DELETE CASCADE,
      FOREIGN KEY (taskId) REFERENCES Tasks(id) ON DELETE CASCADE
    )
  `);

  // Table TaskHistory - Detailed history with scores and drawings
  db.exec(`
    CREATE TABLE IF NOT EXISTS TaskHistory (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      userId INTEGER,
      taskTitle TEXT NOT NULL,
      score REAL NOT NULL,
      timeUsed INTEGER NOT NULL,
      completedAt TEXT NOT NULL,
      drawingData TEXT,
      FOREIGN KEY (userId) REFERENCES Users(id) ON DELETE CASCADE
    )
  `);

  // Table Notifications
  db.exec(`
    CREATE TABLE IF NOT EXISTS Notifications (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      userId INTEGER,
      type TEXT NOT NULL,
      title TEXT NOT NULL,
      message TEXT NOT NULL,
      isRead INTEGER DEFAULT 0,
      relatedId INTEGER,
      createdAt TEXT DEFAULT (datetime('now')),
      FOREIGN KEY (userId) REFERENCES Users(id) ON DELETE CASCADE
    )
  `);

  // Migrate: add drawingData column if not exists
  try {
    const historyColumns = db.prepare("PRAGMA table_info(TaskHistory)").all();
    const hasDrawingData = historyColumns.some(col => col.name === 'drawingData');
    
    if (!hasDrawingData) {
      console.log('🔄 Migrating: Adding drawingData column to TaskHistory...');
      db.exec('ALTER TABLE TaskHistory ADD COLUMN drawingData TEXT');
    }
  } catch (err) {
    console.log('⚠️ Migration check (TaskHistory drawingData):', err.message);
  }

  // Insert dữ liệu mẫu nếu chưa có
  const userCount = db.prepare('SELECT COUNT(*) as count FROM Users').get().count;
  
  if (userCount === 0) {
    console.log('➕ Thêm dữ liệu mẫu...');
    
    // Insert Users with password (default: 123456)
    const defaultPassword = bcrypt.hashSync('123456', 10);
    const adminPassword = bcrypt.hashSync('admin123', 10);
    
    const insertUser = db.prepare(`
      INSERT INTO Users (name, email, password, role, birthDate, gender, totalTasksCompleted, averageScore, rank)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    `);
    
    // Admin account
    insertUser.run('Admin', 'admin@uef.edu.vn', adminPassword, 'admin', '1985-01-15', 'other', 0, 0, 0);
    
    // Regular users với birthDate và gender đa dạng
    insertUser.run('Nguyễn Văn A', 'nguyenvana@uef.edu.vn', defaultPassword, 'user', '2000-05-20', 'male', 15, 92.5, 1); // 18-25, Nam
    insertUser.run('Trần Thị B', 'tranthib@uef.edu.vn', defaultPassword, 'user', '1995-08-10', 'female', 12, 88.3, 5); // 26-35, Nữ
    insertUser.run('Lê Văn C', 'levanc@uef.edu.vn', defaultPassword, 'user', '1990-03-15', 'male', 10, 85.7, 8); // 26-35, Nam
    insertUser.run('Phạm Thị D', 'phamthid@uef.edu.vn', defaultPassword, 'user', '1980-12-25', 'female', 8, 90.2, 3); // 36-45, Nữ
    insertUser.run('Hoàng Văn E', 'hoangvane@uef.edu.vn', defaultPassword, 'user', '2005-07-08', 'male', 14, 91.8, 2); // Dưới 18, Nam
    insertUser.run('Võ Thị F', 'vothif@uef.edu.vn', defaultPassword, 'user', '1972-09-30', 'female', 9, 87.5, 6); // Trên 45, Nữ
    insertUser.run('Đặng Văn G', 'dangvang@uef.edu.vn', defaultPassword, 'user', '1998-11-11', 'male', 11, 89.0, 4); // 18-25, Nam

    // Insert Tasks
    const insertTask = db.prepare(`
      INSERT INTO Tasks (title, description, type, timeLimit, isCompleted)
      VALUES (?, ?, ?, ?, ?)
    `);
    
    insertTask.run('Vẽ Tự Do', 'Thỏa sức sáng tạo với bảng vẽ trống', 'freeDrawing', 300, 0);
    insertTask.run('Tô Màu Hình Tròn', 'Tô màu cho hình tròn', 'colorCircle', 300, 0);
    insertTask.run('Tô Màu Hình Vuông', 'Tô màu cho hình vuông', 'colorSquare', 300, 0);
    insertTask.run('Tô Màu Ngôi Sao', 'Tô màu cho ngôi sao', 'colorStar', 300, 0);
    insertTask.run('Tô Màu Trái Tim', 'Tô màu cho trái tim', 'colorHeart', 300, 0);
    insertTask.run('Tô Màu Ngôi Nhà', 'Tô màu cho ngôi nhà', 'colorHouse', 300, 0);
    insertTask.run('Vẽ Cầu Vồng', 'Vẽ cầu vồng 7 sắc màu', 'rainbow', 300, 0);

    // Insert Task History
    const insertHistory = db.prepare(`
      INSERT INTO TaskHistory (userId, taskTitle, score, timeUsed, completedAt)
      VALUES (?, ?, ?, ?, datetime('now', ?))
    `);
    
    insertHistory.run(1, 'Tô Màu Ngôi Sao', 98.5, 180, '-1 day');
    insertHistory.run(1, 'Tô Màu Hình Tròn', 95.2, 200, '-2 days');
    insertHistory.run(1, 'Vẽ Cầu Vồng', 87.8, 250, '-3 days');
    insertHistory.run(2, 'Tô Màu Trái Tim', 92.3, 220, '-1 day');
    insertHistory.run(2, 'Tô Màu Hình Vuông', 85.6, 240, '-2 days');
    insertHistory.run(3, 'Vẽ Tự Do', 88.9, 210, '-1 day');

    console.log('✅ Dữ liệu mẫu đã được thêm');
  } else {
    // Cập nhật users hiện có nếu chưa có birthDate/gender
    try {
      const usersWithoutBirthDate = db.prepare(`
        SELECT id, email FROM Users 
        WHERE (birthDate IS NULL OR birthDate = '') 
        AND role = 'user'
      `).all();
      
      if (usersWithoutBirthDate.length > 0) {
        console.log(`🔄 Cập nhật ${usersWithoutBirthDate.length} users chưa có birthDate...`);
        
        const sampleBirthDates = [
          { date: '2005-03-15', gender: 'male' },    // Under 18
          { date: '2001-06-20', gender: 'female' },  // 18-25
          { date: '1995-08-10', gender: 'male' },    // 26-35  
          { date: '1985-12-05', gender: 'female' },  // 36-45
          { date: '1970-04-25', gender: 'other' },   // Over 45
        ];
        
        const updateStmt = db.prepare(`
          UPDATE Users 
          SET birthDate = ?, gender = ?
          WHERE id = ?
        `);
        
        usersWithoutBirthDate.forEach((user, index) => {
          const sample = sampleBirthDates[index % sampleBirthDates.length];
          updateStmt.run(sample.date, sample.gender, user.id);
        });
        
        console.log('✅ Đã cập nhật birthDate/gender cho users hiện có');
      }
    } catch (err) {
      console.log('⚠️ Lỗi khi cập nhật demographics:', err.message);
    }
  }

  console.log('✅ Database đã sẵn sàng!');
  
  // Tính lại điểm và rank cho tất cả users từ history hiện có
  console.log('🔄 Đang tính lại điểm và xếp hạng...');
  recalculateAllUserStats();
}

// ==================== NOTIFICATION HELPERS ====================

// Tạo notification cho user hoặc broadcast cho tất cả
function createNotification({ userId, type, title, message, relatedId }) {
  try {
    if (userId) {
      // Notification cho 1 user cụ thể
      db.prepare(`
        INSERT INTO Notifications (userId, type, title, message, relatedId)
        VALUES (?, ?, ?, ?, ?)
      `).run(userId, type, title, message, relatedId || null);
    } else {
      // Broadcast cho tất cả users (không gửi cho admin)
      const users = db.prepare(`SELECT id FROM Users WHERE role = 'user'`).all();
      const insertStmt = db.prepare(`
        INSERT INTO Notifications (userId, type, title, message, relatedId)
        VALUES (?, ?, ?, ?, ?)
      `);
      
      users.forEach(user => {
        insertStmt.run(user.id, type, title, message, relatedId || null);
      });
      
      console.log(`📢 Broadcast notification to ${users.length} users: ${title}`);
    }
  } catch (err) {
    console.error('Error creating notification:', err.message);
  }
}

// Kiểm tra và thông báo khi user vào TOP 5
function checkAndNotifyTopRank(userId, newRank, oldRank) {
  try {
    // Nếu vào TOP 5 lần đầu hoặc thăng hạng trong TOP 5
    if (newRank <= 5 && (oldRank > 5 || oldRank === 0)) {
      const rankNames = {
        1: '🥇 TOP 1 - Xuất sắc nhất',
        2: '🥈 TOP 2 - Rất giỏi',
        3: '🥉 TOP 3 - Tuyệt vời',
        4: '⭐ TOP 4',
        5: '⭐ TOP 5'
      };
      
      const user = db.prepare('SELECT name FROM Users WHERE id = ?').get(userId);
      
      createNotification({
        userId: userId,
        type: 'achievement',
        title: `🎉 Chúc mừng vào ${rankNames[newRank]}!`,
        message: `Chúc mừng ${user?.name}! Bạn đã vào ${rankNames[newRank]} của bảng xếp hạng! Tiếp tục phát huy nhé! 🎨`,
        relatedId: newRank
      });
      
      console.log(`🏆 User ${userId} achieved rank ${newRank}`);
    }
  } catch (err) {
    console.error('Error checking top rank:', err.message);
  }
}

// Tính lại thống kê cho tất cả users từ history
function recalculateAllUserStats() {
  try {
    // Lấy tất cả users có role='user'
    const users = db.prepare(`
      SELECT id FROM Users WHERE role = 'user'
    `).all();
    
    // Cập nhật stats cho từng user
    users.forEach(user => {
      updateUserStatistics(user.id);
    });
    
    // Cập nhật rank
    updateAllUserRanks();
    
    console.log(`✅ Đã tính lại điểm cho ${users.length} users`);
  } catch (err) {
    console.error('❌ Lỗi khi tính lại stats:', err.message);
  }
}

// ==================== USER ROUTES ====================

// GET: Lấy tất cả users
app.get('/api/users', (req, res) => {
  try {
    const users = db.prepare('SELECT * FROM Users ORDER BY createdAt DESC').all();
    res.json(users);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET: Lấy user theo ID
app.get('/api/users/:id', (req, res) => {
  try {
    const { id } = req.params;
    const user = db.prepare('SELECT * FROM Users WHERE id = ?').get(id);
    
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    // Không trả về password
    const { password, ...userWithoutPassword } = user;
    res.json(userWithoutPassword);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST: Thêm user mới
app.post('/api/users', (req, res) => {
  try {
    const { name, email, totalTasksCompleted = 0, averageScore = 0, rank = 0 } = req.body;
    
    const insert = db.prepare(`
      INSERT INTO Users (name, email, totalTasksCompleted, averageScore, rank)
      VALUES (?, ?, ?, ?, ?)
    `);
    
    const result = insert.run(name, email, totalTasksCompleted, averageScore, rank);
    const newUser = db.prepare('SELECT * FROM Users WHERE id = ?').get(result.lastInsertRowid);
    
    res.status(201).json(newUser);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// PUT: Cập nhật user
app.put('/api/users/:id', (req, res) => {
  try {
    const { id } = req.params;
    const { name, email, totalTasksCompleted, averageScore, rank, birthDate, gender, avatar, role, faceData, faceEnabled } = req.body;
    
    const update = db.prepare(`
      UPDATE Users 
      SET name = ?, email = ?, totalTasksCompleted = ?, 
          averageScore = ?, rank = ?, birthDate = ?, gender = ?, avatar = ?, 
          role = ?, faceData = ?, faceEnabled = ?,
          updatedAt = datetime('now')
      WHERE id = ?
    `);
    
    update.run(
      name, 
      email, 
      totalTasksCompleted, 
      averageScore, 
      rank, 
      birthDate || null, 
      gender || 'other', 
      avatar || null,
      role || 'user',
      faceData || null,
      faceEnabled !== undefined ? faceEnabled : 0,
      id
    );
    
    const updatedUser = db.prepare('SELECT * FROM Users WHERE id = ?').get(id);
    const { password, ...userWithoutPassword } = updatedUser;
    
    console.log(`✅ Updated user ${id}`);
    res.json(userWithoutPassword);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// DELETE: Xóa user
app.delete('/api/users/:id', (req, res) => {
  try {
    const { id } = req.params;
    db.prepare('DELETE FROM Users WHERE id = ?').run(id);
    
    res.json({ message: 'User deleted successfully' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// DELETE: Xóa TẤT CẢ users (trừ admin) - CẨN THẬN!!!
app.delete('/api/users', (req, res) => {
  try {
    const result = db.prepare('DELETE FROM Users WHERE role != "admin"').run();
    
    console.log(`⚠️  WARNING: Deleted ${result.changes} users (excluding admin)`);
    res.json({ 
      success: true, 
      message: `Đã xóa ${result.changes} users (giữ lại admin)`,
      deletedCount: result.changes
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ==================== TASK ROUTES ====================

// GET: Lấy tất cả tasks
app.get('/api/tasks', (req, res) => {
  try {
    const tasks = db.prepare('SELECT * FROM Tasks ORDER BY createdAt DESC').all();
    res.json(tasks);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET: Lấy tasks mới (TẤT CẢ - để test)
app.get('/api/tasks/recent', (req, res) => {
  try {
    // TẠM THỜI: Lấy tất cả tasks để test
    const tasks = db.prepare(`
      SELECT * FROM Tasks 
      ORDER BY createdAt DESC
      LIMIT 20
    `).all();
    
    console.log(`📋 API /tasks/recent returned ${tasks.length} tasks`);
    res.json(tasks);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST: Thêm task mới
app.post('/api/tasks', (req, res) => {
  try {
    const { title, description, type, timeLimit = 300, isCompleted = 0 } = req.body;
    
    const insert = db.prepare(`
      INSERT INTO Tasks (title, description, type, timeLimit, isCompleted)
      VALUES (?, ?, ?, ?, ?)
    `);
    
    const result = insert.run(title, description, type, timeLimit, isCompleted);
    const newTask = db.prepare('SELECT * FROM Tasks WHERE id = ?').get(result.lastInsertRowid);
    
    // Broadcast notification cho tất cả users về nhiệm vụ mới
    createNotification({
      userId: null, // null = broadcast to all
      type: 'new_task',
      title: '🎨 Nhiệm vụ mới!',
      message: `Admin vừa tạo nhiệm vụ mới: "${title}". Hãy thử thách bản thân ngay!`,
      relatedId: result.lastInsertRowid
    });
    
    res.status(201).json(newTask);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// PUT: Cập nhật task
app.put('/api/tasks/:id', (req, res) => {
  try {
    const { id } = req.params;
    const { title, description, type, timeLimit, isCompleted } = req.body;
    
    const update = db.prepare(`
      UPDATE Tasks 
      SET title = ?, description = ?, type = ?, timeLimit = ?, isCompleted = ?,
          updatedAt = datetime('now')
      WHERE id = ?
    `);
    
    update.run(title, description, type, timeLimit, isCompleted, id);
    const updatedTask = db.prepare('SELECT * FROM Tasks WHERE id = ?').get(id);
    
    res.json(updatedTask);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// DELETE: Xóa task
app.delete('/api/tasks/:id', (req, res) => {
  try {
    const { id } = req.params;
    const task = db.prepare('SELECT * FROM Tasks WHERE id = ?').get(id);
    
    if (!task) {
      return res.status(404).json({ error: 'Task not found' });
    }
    
    db.prepare('DELETE FROM Tasks WHERE id = ?').run(id);
    
    res.json({ success: true, message: 'Task deleted successfully' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ==================== HELPER FUNCTIONS ====================

// Cập nhật thống kê của user (tổng tasks và điểm trung bình)
function updateUserStatistics(userId) {
  try {
    const stats = db.prepare(`
      SELECT 
        COUNT(*) as totalCompleted,
        AVG(score) as avgScore
      FROM TaskHistory
      WHERE userId = ?
    `).get(userId);
    
    db.prepare(`
      UPDATE Users 
      SET 
        totalTasksCompleted = ?,
        averageScore = ?,
        updatedAt = datetime('now')
      WHERE id = ?
    `).run(stats.totalCompleted, stats.avgScore || 0, userId);
    
    console.log(`✅ Updated stats for user ${userId}: ${stats.totalCompleted} tasks, avg: ${(stats.avgScore || 0).toFixed(1)}`);
  } catch (err) {
    console.error('Error updating user statistics:', err);
  }
}

// Cập nhật rank cho tất cả users dựa trên điểm trung bình
function updateAllUserRanks() {
  try {
    // Lấy tất cả users có role='user' với rank hiện tại, sắp xếp theo averageScore giảm dần
    const users = db.prepare(`
      SELECT id, rank as oldRank, averageScore 
      FROM Users 
      WHERE role = 'user'
      ORDER BY averageScore DESC, totalTasksCompleted DESC
    `).all();
    
    // Cập nhật rank cho từng user và kiểm tra TOP 5
    const updateRank = db.prepare('UPDATE Users SET rank = ? WHERE id = ?');
    
    users.forEach((user, index) => {
      const newRank = index + 1; // rank từ 1, 2, 3...
      const oldRank = user.oldRank || 0;
      
      updateRank.run(newRank, user.id);
      
      // Kiểm tra và thông báo nếu vào TOP 5
      checkAndNotifyTopRank(user.id, newRank, oldRank);
    });
    
    console.log(`✅ Updated ranks for ${users.length} users`);
  } catch (err) {
    console.error('Error updating user ranks:', err);
  }
}

// ==================== TASK HISTORY ROUTES ====================

// POST: Thêm lịch sử hoàn thành và cập nhật điểm user
app.post('/api/history', (req, res) => {
  try {
    const { userId, taskTitle, score, timeUsed, completedAt, drawingData } = req.body;
    
    // Insert task history
    const insert = db.prepare(`
      INSERT INTO TaskHistory (userId, taskTitle, score, timeUsed, completedAt, drawingData)
      VALUES (?, ?, ?, ?, ?, ?)
    `);
    
    const result = insert.run(
      userId, 
      taskTitle, 
      score, 
      timeUsed, 
      completedAt || new Date().toISOString(),
      drawingData || null
    );
    
    // Tự động cập nhật thống kê user
    updateUserStatistics(userId);
    
    // Cập nhật rank cho tất cả users
    updateAllUserRanks();
    
    const newHistory = db.prepare('SELECT * FROM TaskHistory WHERE id = ?').get(result.lastInsertRowid);
    
    res.status(201).json(newHistory);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST: Đánh dấu task đã hoàn thành cho user (track completion)
app.post('/api/tasks/:taskId/complete', (req, res) => {
  try {
    const { taskId } = req.params;
    const { userId } = req.body;
    
    // Insert hoặc ignore nếu đã tồn tại
    const insert = db.prepare(`
      INSERT OR IGNORE INTO UserTaskCompletion (userId, taskId)
      VALUES (?, ?)
    `);
    
    const result = insert.run(userId, taskId);
    res.json({ success: true, changes: result.changes });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET: Lấy danh sách tasks đã hoàn thành của user
app.get('/api/users/:userId/completed-tasks', (req, res) => {
  try {
    const { userId } = req.params;
    const completedTasks = db.prepare(`
      SELECT taskId FROM UserTaskCompletion WHERE userId = ?
    `).all(userId);
    
    const taskIds = completedTasks.map(t => t.taskId);
    res.json(taskIds);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET: Lấy lịch sử theo user
app.get('/api/history/user/:userId', (req, res) => {
  try {
    const { userId } = req.params;
    const history = db.prepare(`
      SELECT * FROM TaskHistory 
      WHERE userId = ?
      ORDER BY completedAt DESC
    `).all(userId);
    
    res.json(history);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ==================== STATISTICS ROUTES ====================

// GET: Lấy thống kê tổng quan
app.get('/api/statistics', (req, res) => {
  try {
    const stats = db.prepare(`
      SELECT 
        (SELECT COUNT(*) FROM Users) as totalUsers,
        (SELECT COUNT(*) FROM Tasks) as totalTasks,
        (SELECT COUNT(*) FROM TaskHistory) as totalCompletions,
        (SELECT AVG(averageScore) FROM Users) as averageScore
    `).get();
    
    res.json(stats);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET: Lấy top users
app.get('/api/statistics/top-users', (req, res) => {
  try {
    const topUsers = db.prepare(`
      SELECT id, name, email, role, totalTasksCompleted, averageScore, rank, createdAt 
      FROM Users 
      ORDER BY averageScore DESC, totalTasksCompleted DESC 
      LIMIT 10
    `).all();
    
    res.json(topUsers);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET: Lấy thống kê cho admin (bao gồm số tài khoản)
app.get('/api/statistics/admin', (req, res) => {
  try {
    const stats = db.prepare(`
      SELECT 
        (SELECT COUNT(*) FROM Users) as totalAccounts,
        (SELECT COUNT(*) FROM Users WHERE role = 'admin') as adminAccounts,
        (SELECT COUNT(*) FROM Users WHERE role = 'user') as userAccounts,
        (SELECT COUNT(*) FROM Users WHERE date(createdAt) = date('now')) as newAccountsToday,
        (SELECT COUNT(*) FROM Tasks) as totalTasks,
        (SELECT COUNT(*) FROM TaskHistory) as totalCompletions,
        (SELECT AVG(averageScore) FROM Users WHERE role = 'user') as averageScore
    `).get();
    
    res.json(stats);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ==================== NOTIFICATION ROUTES ====================

// GET: Lấy notifications của user
app.get('/api/notifications/:userId', (req, res) => {
  try {
    const { userId } = req.params;
    const notifications = db.prepare(`
      SELECT * FROM Notifications 
      WHERE userId = ?
      ORDER BY createdAt DESC
      LIMIT 50
    `).all(userId);
    
    res.json(notifications);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET: Đếm số notifications chưa đọc
app.get('/api/notifications/:userId/unread-count', (req, res) => {
  try {
    const { userId } = req.params;
    const result = db.prepare(`
      SELECT COUNT(*) as count
      FROM Notifications 
      WHERE userId = ? AND isRead = 0
    `).get(userId);
    
    res.json({ count: result.count });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// PUT: Đánh dấu notification đã đọc
app.put('/api/notifications/:id/read', (req, res) => {
  try {
    const { id } = req.params;
    db.prepare(`
      UPDATE Notifications 
      SET isRead = 1
      WHERE id = ?
    `).run(id);
    
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// PUT: Đánh dấu tất cả notifications của user đã đọc
app.put('/api/notifications/:userId/read-all', (req, res) => {
  try {
    const { userId } = req.params;
    db.prepare(`
      UPDATE Notifications 
      SET isRead = 1
      WHERE userId = ?
    `).run(userId);
    
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// DELETE: Xóa notification
app.delete('/api/notifications/:id', (req, res) => {
  try {
    const { id } = req.params;
    db.prepare('DELETE FROM Notifications WHERE id = ?').run(id);
    
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ==================== ADMIN TOOLS ====================

// POST: Tính lại điểm và rank cho tất cả users (Admin only)
app.post('/api/admin/recalculate-stats', (req, res) => {
  try {
    recalculateAllUserStats();
    res.json({ 
      success: true, 
      message: 'Đã tính lại điểm và xếp hạng cho tất cả users' 
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET: Lấy bảng xếp hạng (TOP users)
app.get('/api/leaderboard', (req, res) => {
  try {
    const limit = req.query.limit || 10; // Mặc định lấy TOP 10
    
    const users = db.prepare(`
      SELECT id, name, email, averageScore, totalTasksCompleted, rank, avatar, gender
      FROM Users 
      WHERE role = 'user'
      ORDER BY averageScore DESC, totalTasksCompleted DESC
      LIMIT ?
    `).all(limit);
    
    res.json(users);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET: Thống kê chi tiết theo độ tuổi và giới tính
app.get('/api/statistics/demographics', (req, res) => {
  try {
    // Lấy tất cả users có birthDate
    const users = db.prepare(`
      SELECT birthDate, gender 
      FROM Users 
      WHERE birthDate IS NOT NULL AND birthDate != ''
    `).all();
    
    // Phân loại theo độ tuổi
    const ageGroups = {
      'under18': 0,
      '18-25': 0,
      '26-35': 0,
      '36-45': 0,
      'over45': 0
    };
    
    // Phân loại theo giới tính
    const genderStats = {
      'male': 0,
      'female': 0,
      'other': 0
    };
    
    const currentYear = new Date().getFullYear();
    
    users.forEach(user => {
      // Tính tuổi
      if (user.birthDate) {
        const birthYear = new Date(user.birthDate).getFullYear();
        const age = currentYear - birthYear;
        
        if (age < 18) ageGroups['under18']++;
        else if (age >= 18 && age <= 25) ageGroups['18-25']++;
        else if (age >= 26 && age <= 35) ageGroups['26-35']++;
        else if (age >= 36 && age <= 45) ageGroups['36-45']++;
        else ageGroups['over45']++;
      }
      
      // Đếm giới tính
      if (user.gender === 'male') genderStats.male++;
      else if (user.gender === 'female') genderStats.female++;
      else genderStats.other++;
    });
    
    res.json({
      totalUsers: users.length,
      ageGroups,
      genderStats
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ==================== AUTHENTICATION ROUTES ====================

// POST: Đăng ký tài khoản mới
app.post('/api/auth/register', async (req, res) => {
  try {
    const { name, email, password, birthDate, gender } = req.body;
    
    // Validate input
    if (!name || !email || !password) {
      return res.status(400).json({ error: 'Vui lòng điền đầy đủ thông tin!' });
    }
    
    if (password.length < 6) {
      return res.status(400).json({ error: 'Mật khẩu phải có ít nhất 6 ký tự!' });
    }
    
    // Check if email already exists
    const existingUser = db.prepare('SELECT * FROM Users WHERE email = ?').get(email);
    if (existingUser) {
      return res.status(400).json({ error: 'Email đã được sử dụng!' });
    }
    
    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);
    
    // Insert new user
    const insert = db.prepare(`
      INSERT INTO Users (name, email, password, role, birthDate, gender, score, totalTasksCompleted, averageScore, rank)
      VALUES (?, ?, ?, 'user', ?, ?, 0, 0, 0, 0)
    `);
    
    const result = insert.run(name, email, hashedPassword, birthDate || null, gender || 'other');
    const newUser = db.prepare(`
      SELECT id, name, email, role, birthDate, gender, score, totalTasksCompleted, averageScore, rank, createdAt 
      FROM Users WHERE id = ?
    `).get(result.lastInsertRowid);
    
    res.status(201).json({
      success: true,
      message: 'Đăng ký thành công!',
      user: newUser
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST: Đăng nhập
app.post('/api/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    
    // Validate input
    if (!email || !password) {
      return res.status(400).json({ error: 'Vui lòng điền email và mật khẩu!' });
    }
    
    // Find user by email
    const user = db.prepare('SELECT * FROM Users WHERE email = ?').get(email);
    
    if (!user) {
      return res.status(401).json({ error: 'Email hoặc mật khẩu không đúng!' });
    }
    
    // Check password
    const isValidPassword = await bcrypt.compare(password, user.password);
    
    if (!isValidPassword) {
      return res.status(401).json({ error: 'Email hoặc mật khẩu không đúng!' });
    }
    
    // Remove password from response
    const { password: _, ...userWithoutPassword } = user;
    
    res.json({
      success: true,
      message: 'Đăng nhập thành công!',
      user: userWithoutPassword
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST: Đăng nhập bằng khuôn mặt
app.post('/api/auth/face-login', (req, res) => {
  try {
    const { faceSignature } = req.body; // Gửi một signature đơn giản từ client
    
    if (!faceSignature) {
      return res.status(400).json({ error: 'Face signature is required' });
    }
    
    // Tìm user có face data matching (đơn giản hóa cho demo)
    const users = db.prepare('SELECT * FROM Users WHERE faceEnabled = 1 AND faceData IS NOT NULL').all();
    
    // Trong thực tế, cần so sánh face encoding phức tạp
    // Ở đây demo đơn giản: tìm user có faceData chứa signature
    const matchedUser = users.find(u => u.faceData && u.faceData.includes(faceSignature));
    
    if (!matchedUser) {
      return res.status(401).json({ error: 'Không nhận diện được khuôn mặt' });
    }
    
    // Remove password from response
    const { password, ...userWithoutPassword } = matchedUser;
    
    console.log(`✅ Face login success: ${matchedUser.email}`);
    res.json({
      success: true,
      message: 'Đăng nhập thành công!',
      user: userWithoutPassword
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET: Kiểm tra email đã tồn tại chưa
app.get('/api/auth/check-email/:email', (req, res) => {
  try {
    const { email } = req.params;
    const user = db.prepare('SELECT id FROM Users WHERE email = ?').get(email);
    
    res.json({ exists: !!user });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET: Kiểm tra có user nào đã đăng ký face chưa
app.get('/api/auth/has-face-users', (req, res) => {
  try {
    const count = db.prepare('SELECT COUNT(*) as count FROM Users WHERE faceEnabled = 1 AND faceData IS NOT NULL').get();
    res.json({ hasFaceUsers: count.count > 0 });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET: Lấy user theo email (cho Google Sign-In)
app.get('/api/auth/get-user-by-email/:email', (req, res) => {
  try {
    const { email } = req.params;
    const user = db.prepare('SELECT * FROM Users WHERE email = ?').get(email);
    
    if (!user) {
      return res.status(404).json({ user: null });
    }
    
    // Remove password from response
    const { password, ...userWithoutPassword } = user;
    
    res.json({ user: userWithoutPassword });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST: Đăng ký tài khoản với Google
app.post('/api/auth/register-google', async (req, res) => {
  try {
    const { email, name, photoUrl, authProvider } = req.body;
    
    // Validate input
    if (!name || !email) {
      return res.status(400).json({ error: 'Email và tên không được để trống!' });
    }
    
    // Check if email already exists
    const existingUser = db.prepare('SELECT * FROM Users WHERE email = ?').get(email);
    if (existingUser) {
      // User đã tồn tại, trả về thông tin user
      const { password, ...userWithoutPassword } = existingUser;
      return res.json({
        success: true,
        message: 'User đã tồn tại, đăng nhập thành công!',
        user: userWithoutPassword
      });
    }
    
    // Insert new user (không cần password vì dùng Google OAuth)
    const insert = db.prepare(`
      INSERT INTO Users (name, email, password, role, avatar, score, totalTasksCompleted, averageScore, rank)
      VALUES (?, ?, NULL, 'user', ?, 0, 0, 0, 0)
    `);
    
    const result = insert.run(name, email, photoUrl || null);
    const newUser = db.prepare(`
      SELECT id, name, email, role, avatar, score, totalTasksCompleted, averageScore, rank, createdAt 
      FROM Users WHERE id = ?
    `).get(result.lastInsertRowid);
    
    console.log(`✅ Registered new user via Google: ${email}`);
    
    res.status(201).json({
      success: true,
      message: 'Đăng ký thành công!',
      user: newUser
    });
  } catch (err) {
    console.error('Error in Google registration:', err);
    res.status(500).json({ error: err.message });
  }
});

// ==================== START SERVER ====================

function startServer() {
  try {
    // Khởi tạo database
    initDatabase();
    
    // Hiển thị thống kê
    const stats = db.prepare(`
      SELECT 
        (SELECT COUNT(*) FROM Users) as users,
        (SELECT COUNT(*) FROM Tasks) as tasks,
        (SELECT COUNT(*) FROM TaskHistory) as history
    `).get();
    
    console.log('📊 Database stats:');
    console.log(`   👥 Users: ${stats.users}`);
    console.log(`   📝 Tasks: ${stats.tasks}`);
    console.log(`   📜 History: ${stats.history}`);
    
    // Start server
    app.listen(port, () => {
      console.log('');
      console.log('🚀 Server running on http://localhost:' + port);
      console.log('');
      console.log('🔐 Authentication:');
      console.log('   POST   /api/auth/register');
      console.log('   POST   /api/auth/login');
      console.log('   GET    /api/auth/check-email/:email');
      console.log('');
      console.log('👥 Users:');
      console.log('   GET    /api/users');
      console.log('   POST   /api/users');
      console.log('   PUT    /api/users/:id');
      console.log('   DELETE /api/users/:id');
      console.log('');
      console.log('📝 Tasks:');
      console.log('   GET    /api/tasks');
      console.log('   GET    /api/tasks/recent  (tasks trong 2 ngày)');
      console.log('   POST   /api/tasks');
      console.log('');
      console.log('📜 History:');
      console.log('   POST   /api/history');
      console.log('   GET    /api/history/user/:userId');
      console.log('');
      console.log('📊 Statistics:');
      console.log('   GET    /api/statistics');
      console.log('   GET    /api/statistics/top-users');
      console.log('   GET    /api/statistics/admin');
      console.log('   GET    /api/statistics/demographics');
      console.log('');
      console.log('🏆 Leaderboard:');
      console.log('   GET    /api/leaderboard');
      console.log('');
      console.log('🔔 Notifications:');
      console.log('   GET    /api/notifications/:userId');
      console.log('   GET    /api/notifications/:userId/unread-count');
      console.log('   PUT    /api/notifications/:id/read');
      console.log('   PUT    /api/notifications/:userId/read-all');
      console.log('   DELETE /api/notifications/:id');
      console.log('');
      console.log('🔧 Admin Tools:');
      console.log('   POST   /api/admin/recalculate-stats');
      console.log('');
      console.log('✅ Server sẵn sàng!');
      console.log('👤 Admin: admin@uef.edu.vn / admin123');
      console.log('👤 User: nguyenvana@uef.edu.vn / 123456');
    });
  } catch (err) {
    console.error('❌ Failed to start server:', err);
    process.exit(1);
  }
}

startServer();

// Graceful shutdown
process.on('SIGINT', () => {
  console.log('\n👋 Shutting down gracefully...');
  db.close();
  process.exit(0);
});

