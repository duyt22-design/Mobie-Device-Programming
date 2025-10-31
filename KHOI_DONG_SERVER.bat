@echo off
title Backend Server - SQLite
color 0A
echo ====================================
echo    Backend Server - SQLite
echo ====================================
echo.

cd /d "%~dp0backend"

if not exist "node_modules" (
    echo 📦 Cài đặt dependencies...
    call npm install
    echo.
)

echo 🚀 Đang khởi động server...
echo.
echo ⚠️  QUAN TRỌNG: Giữ cửa sổ này mở!
echo    Nhấn Ctrl+C để dừng server
echo.
echo ====================================
echo.

node server_sqlite.js

echo.
echo Server đã dừng.
pause

