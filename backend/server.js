// Backend API để kết nối Flutter với SQL Server
// Yêu cầu: Node.js và các package: express, mssql, cors, body-parser

const express = require('express');
const sql = require('mssql');
const cors = require('cors');
const bodyParser = require('body-parser');

const app = express();
const port = 5000;

// Middleware
app.use(cors());
app.use(bodyParser.json());

// Cấu hình kết nối SQL Server với Windows Authentication
const config = {
  server: 'localhost\\SQLEXPRESS',  // Hoặc .\\SQLEXPRESS
  database: 'DrawingAppDB',         // Tên database
  options: {
    encrypt: false,                  // Tắt encrypt cho local
    trustServerCertificate: true,    // Cho local development
    enableArithAbort: true           // Bắt buộc cho mssql v9+
  },
  authentication: {
    type: 'default'                  // Windows Authentication
  },
  pool: {
    max: 10,
    min: 0,
    idleTimeoutMillis: 30000
  }
};

// Kết nối database
let pool;

async function connectDB() {
  try {
    pool = await sql.connect(config);
    console.log('✅ Connected to SQL Server');
  } catch (err) {
    console.error('❌ Database connection failed:', err);
  }
}

connectDB();

// ==================== USER ROUTES ====================

// GET: Lấy tất cả users
app.get('/api/users', async (req, res) => {
  try {
    const result = await pool.request().query(`
      SELECT * FROM Users ORDER BY createdAt DESC
    `);
    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET: Lấy user theo ID
app.get('/api/users/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.request()
      .input('id', sql.Int, id)
      .query('SELECT * FROM Users WHERE id = @id');
    
    if (result.recordset.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    res.json(result.recordset[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST: Thêm user mới
app.post('/api/users', async (req, res) => {
  try {
    const { name, email, totalTasksCompleted, averageScore, rank } = req.body;
    
    const result = await pool.request()
      .input('name', sql.NVarChar, name)
      .input('email', sql.NVarChar, email)
      .input('totalTasksCompleted', sql.Int, totalTasksCompleted || 0)
      .input('averageScore', sql.Float, averageScore || 0)
      .input('rank', sql.Int, rank || 0)
      .query(`
        INSERT INTO Users (name, email, totalTasksCompleted, averageScore, rank, createdAt)
        OUTPUT INSERTED.*
        VALUES (@name, @email, @totalTasksCompleted, @averageScore, @rank, GETDATE())
      `);
    
    res.status(201).json(result.recordset[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// PUT: Cập nhật user
app.put('/api/users/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { name, email, totalTasksCompleted, averageScore, rank } = req.body;
    
    const result = await pool.request()
      .input('id', sql.Int, id)
      .input('name', sql.NVarChar, name)
      .input('email', sql.NVarChar, email)
      .input('totalTasksCompleted', sql.Int, totalTasksCompleted)
      .input('averageScore', sql.Float, averageScore)
      .input('rank', sql.Int, rank)
      .query(`
        UPDATE Users 
        SET name = @name, email = @email, 
            totalTasksCompleted = @totalTasksCompleted,
            averageScore = @averageScore, rank = @rank
        OUTPUT INSERTED.*
        WHERE id = @id
      `);
    
    res.json(result.recordset[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// DELETE: Xóa user
app.delete('/api/users/:id', async (req, res) => {
  try {
    const { id } = req.params;
    await pool.request()
      .input('id', sql.Int, id)
      .query('DELETE FROM Users WHERE id = @id');
    
    res.json({ message: 'User deleted successfully' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ==================== TASK ROUTES ====================

// GET: Lấy tất cả tasks
app.get('/api/tasks', async (req, res) => {
  try {
    const result = await pool.request().query(`
      SELECT * FROM Tasks ORDER BY createdAt DESC
    `);
    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST: Thêm task mới
app.post('/api/tasks', async (req, res) => {
  try {
    const { title, description, type, isCompleted } = req.body;
    
    const result = await pool.request()
      .input('title', sql.NVarChar, title)
      .input('description', sql.NVarChar, description)
      .input('type', sql.NVarChar, type)
      .input('isCompleted', sql.Bit, isCompleted || 0)
      .query(`
        INSERT INTO Tasks (title, description, type, isCompleted, createdAt)
        OUTPUT INSERTED.*
        VALUES (@title, @description, @type, @isCompleted, GETDATE())
      `);
    
    res.status(201).json(result.recordset[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// PUT: Cập nhật task
app.put('/api/tasks/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { title, description, type, isCompleted } = req.body;
    
    const result = await pool.request()
      .input('id', sql.Int, id)
      .input('title', sql.NVarChar, title)
      .input('description', sql.NVarChar, description)
      .input('type', sql.NVarChar, type)
      .input('isCompleted', sql.Bit, isCompleted)
      .query(`
        UPDATE Tasks 
        SET title = @title, description = @description, 
            type = @type, isCompleted = @isCompleted
        OUTPUT INSERTED.*
        WHERE id = @id
      `);
    
    res.json(result.recordset[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ==================== TASK HISTORY ROUTES ====================

// POST: Thêm lịch sử hoàn thành
app.post('/api/history', async (req, res) => {
  try {
    const { userId, taskTitle, score, timeUsed, completedAt } = req.body;
    
    const result = await pool.request()
      .input('userId', sql.Int, userId)
      .input('taskTitle', sql.NVarChar, taskTitle)
      .input('score', sql.Float, score)
      .input('timeUsed', sql.Int, timeUsed)
      .input('completedAt', sql.DateTime, completedAt)
      .query(`
        INSERT INTO TaskHistory (userId, taskTitle, score, timeUsed, completedAt)
        OUTPUT INSERTED.*
        VALUES (@userId, @taskTitle, @score, @timeUsed, @completedAt)
      `);
    
    res.status(201).json(result.recordset[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET: Lấy lịch sử theo user
app.get('/api/history/user/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const result = await pool.request()
      .input('userId', sql.Int, userId)
      .query(`
        SELECT * FROM TaskHistory 
        WHERE userId = @userId 
        ORDER BY completedAt DESC
      `);
    
    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ==================== STATISTICS ROUTES ====================

// GET: Lấy thống kê tổng quan
app.get('/api/statistics', async (req, res) => {
  try {
    const result = await pool.request().query(`
      SELECT 
        (SELECT COUNT(*) FROM Users) as totalUsers,
        (SELECT COUNT(*) FROM Tasks) as totalTasks,
        (SELECT COUNT(*) FROM TaskHistory) as totalCompletions,
        (SELECT AVG(averageScore) FROM Users) as averageScore
    `);
    
    res.json(result.recordset[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET: Lấy top users
app.get('/api/statistics/top-users', async (req, res) => {
  try {
    const result = await pool.request().query(`
      SELECT TOP 10 * FROM Users 
      ORDER BY averageScore DESC, totalTasksCompleted DESC
    `);
    
    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ==================== START SERVER ====================

async function startServer() {
  try {
    // Kết nối database trước
    await connectDB();
    
    // Sau đó mới start server
    app.listen(port, () => {
      console.log(`🚀 Server running on http://localhost:${port}`);
      console.log(`📊 API endpoints:`);
      console.log(`   GET    /api/users`);
      console.log(`   POST   /api/users`);
      console.log(`   PUT    /api/users/:id`);
      console.log(`   DELETE /api/users/:id`);
      console.log(`   GET    /api/tasks`);
      console.log(`   POST   /api/tasks`);
      console.log(`   POST   /api/history`);
      console.log(`   GET    /api/statistics`);
    });
  } catch (err) {
    console.error('❌ Failed to start server:', err);
    process.exit(1);
  }
}

startServer();

