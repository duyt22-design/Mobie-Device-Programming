-- SQL Script để tạo database và tables cho Drawing App
-- Chạy script này trong SQL Server Management Studio (SSMS)

-- Tạo database
CREATE DATABASE DrawingAppDB;
GO

USE DrawingAppDB;
GO

-- Tạo bảng Users
CREATE TABLE Users (
    id INT PRIMARY KEY IDENTITY(1,1),
    name NVARCHAR(255) NOT NULL,
    email NVARCHAR(255) NOT NULL UNIQUE,
    totalTasksCompleted INT DEFAULT 0,
    averageScore FLOAT DEFAULT 0,
    rank INT DEFAULT 0,
    createdAt DATETIME DEFAULT GETDATE(),
    updatedAt DATETIME DEFAULT GETDATE()
);
GO

-- Tạo bảng Tasks
CREATE TABLE Tasks (
    id INT PRIMARY KEY IDENTITY(1,1),
    title NVARCHAR(255) NOT NULL,
    description NVARCHAR(MAX),
    type NVARCHAR(50) NOT NULL,
    isCompleted BIT DEFAULT 0,
    createdAt DATETIME DEFAULT GETDATE(),
    updatedAt DATETIME DEFAULT GETDATE()
);
GO

-- Tạo bảng TaskHistory
CREATE TABLE TaskHistory (
    id INT PRIMARY KEY IDENTITY(1,1),
    userId INT,
    taskTitle NVARCHAR(255) NOT NULL,
    score FLOAT NOT NULL,
    timeUsed INT NOT NULL, -- thời gian tính bằng giây
    completedAt DATETIME NOT NULL,
    FOREIGN KEY (userId) REFERENCES Users(id) ON DELETE CASCADE
);
GO

-- Tạo indexes để tăng hiệu suất
CREATE INDEX idx_users_email ON Users(email);
CREATE INDEX idx_tasks_type ON Tasks(type);
CREATE INDEX idx_history_userId ON TaskHistory(userId);
CREATE INDEX idx_history_completedAt ON TaskHistory(completedAt);
GO

-- Insert dữ liệu mẫu cho Users
INSERT INTO Users (name, email, totalTasksCompleted, averageScore, rank) VALUES
('Nguyễn Văn A', 'nguyenvana@uef.edu.vn', 15, 92.5, 1),
('Trần Thị B', 'tranthib@uef.edu.vn', 12, 88.3, 5),
('Lê Văn C', 'levanc@uef.edu.vn', 10, 85.7, 8),
('Phạm Thị D', 'phamthid@uef.edu.vn', 8, 90.2, 3),
('Hoàng Văn E', 'hoangvane@uef.edu.vn', 14, 91.8, 2);
GO

-- Insert dữ liệu mẫu cho Tasks
INSERT INTO Tasks (title, description, type, isCompleted) VALUES
(N'Vẽ Tự Do', N'Thỏa sức sáng tạo với bảng vẽ trống', 'freeDrawing', 0),
(N'Tô Màu Hình Tròn', N'Tô màu cho hình tròn', 'colorCircle', 0),
(N'Tô Màu Hình Vuông', N'Tô màu cho hình vuông', 'colorSquare', 0),
(N'Tô Màu Ngôi Sao', N'Tô màu cho ngôi sao', 'colorStar', 0),
(N'Tô Màu Trái Tim', N'Tô màu cho trái tim', 'colorHeart', 0),
(N'Tô Màu Ngôi Nhà', N'Tô màu cho ngôi nhà', 'colorHouse', 0),
(N'Vẽ Cầu Vồng', N'Vẽ cầu vồng 7 sắc màu', 'rainbow', 0);
GO

-- Insert dữ liệu mẫu cho TaskHistory
INSERT INTO TaskHistory (userId, taskTitle, score, timeUsed, completedAt) VALUES
(1, N'Tô Màu Ngôi Sao', 98.5, 180, DATEADD(day, -1, GETDATE())),
(1, N'Tô Màu Hình Tròn', 95.2, 200, DATEADD(day, -2, GETDATE())),
(1, N'Vẽ Cầu Vồng', 87.8, 250, DATEADD(day, -3, GETDATE())),
(2, N'Tô Màu Trái Tim', 92.3, 220, DATEADD(day, -1, GETDATE())),
(2, N'Tô Màu Hình Vuông', 85.6, 240, DATEADD(day, -2, GETDATE())),
(3, N'Vẽ Tự Do', 88.9, 210, DATEADD(day, -1, GETDATE()));
GO

-- Tạo stored procedures để thống kê

-- SP: Lấy thống kê tổng quan
CREATE PROCEDURE sp_GetStatistics
AS
BEGIN
    SELECT 
        (SELECT COUNT(*) FROM Users) as totalUsers,
        (SELECT COUNT(*) FROM Tasks) as totalTasks,
        (SELECT COUNT(*) FROM TaskHistory) as totalCompletions,
        (SELECT AVG(averageScore) FROM Users) as averageScore
END
GO

-- SP: Lấy top users theo điểm
CREATE PROCEDURE sp_GetTopUsers
    @limit INT = 10
AS
BEGIN
    SELECT TOP (@limit) * 
    FROM Users 
    ORDER BY averageScore DESC, totalTasksCompleted DESC
END
GO

-- SP: Lấy lịch sử của user
CREATE PROCEDURE sp_GetUserHistory
    @userId INT
AS
BEGIN
    SELECT * 
    FROM TaskHistory 
    WHERE userId = @userId 
    ORDER BY completedAt DESC
END
GO

-- SP: Cập nhật thống kê user sau khi hoàn thành task
CREATE PROCEDURE sp_UpdateUserStats
    @userId INT
AS
BEGIN
    UPDATE Users
    SET 
        totalTasksCompleted = (
            SELECT COUNT(*) FROM TaskHistory WHERE userId = @userId
        ),
        averageScore = (
            SELECT AVG(score) FROM TaskHistory WHERE userId = @userId
        ),
        updatedAt = GETDATE()
    WHERE id = @userId
END
GO

-- Trigger: Tự động cập nhật thống kê user khi thêm task history
CREATE TRIGGER trg_UpdateUserStatsOnHistory
ON TaskHistory
AFTER INSERT
AS
BEGIN
    DECLARE @userId INT
    SELECT @userId = userId FROM inserted
    
    EXEC sp_UpdateUserStats @userId
END
GO

-- View: Xem thống kê user với lịch sử
CREATE VIEW vw_UserWithStats AS
SELECT 
    u.id,
    u.name,
    u.email,
    u.totalTasksCompleted,
    u.averageScore,
    u.rank,
    COUNT(th.id) as historyCount,
    MAX(th.completedAt) as lastCompletedAt
FROM Users u
LEFT JOIN TaskHistory th ON u.id = th.userId
GROUP BY u.id, u.name, u.email, u.totalTasksCompleted, u.averageScore, u.rank
GO

PRINT 'Database created successfully!'
PRINT 'Total Users: ' + CAST((SELECT COUNT(*) FROM Users) AS VARCHAR)
PRINT 'Total Tasks: ' + CAST((SELECT COUNT(*) FROM Tasks) AS VARCHAR)
PRINT 'Total Completions: ' + CAST((SELECT COUNT(*) FROM TaskHistory) AS VARCHAR)
GO

