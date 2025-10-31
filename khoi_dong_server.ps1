# Script khởi động server đơn giản
Write-Host "===================================" -ForegroundColor Cyan
Write-Host "  KHOI DONG BACKEND SERVER" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan
Write-Host ""

# Kiểm tra database
Write-Host "Kiem tra database..." -ForegroundColor Yellow
if (Test-Path "backend\drawing_app.db") {
    Write-Host "OK - Database ton tai" -ForegroundColor Green
} else {
    Write-Host "INFO - Database se duoc tao khi server khoi dong" -ForegroundColor Gray
}
Write-Host ""

# Chuyển đến thư mục backend
Write-Host "Chuyen den thu muc backend..." -ForegroundColor Yellow
Set-Location backend

# Kiểm tra node_modules
if (!(Test-Path "node_modules")) {
    Write-Host "Cai dat dependencies..." -ForegroundColor Yellow
    npm install
    Write-Host ""
}

# Khởi động server
Write-Host "===================================" -ForegroundColor Cyan
Write-Host "  DANG KHOI DONG SERVER..." -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "QUAN TRONG: Giu cua so nay mo!" -ForegroundColor Yellow
Write-Host "Nhan Ctrl+C de dung server" -ForegroundColor Gray
Write-Host ""
Write-Host "===================================" -ForegroundColor Cyan
Write-Host ""

node server_sqlite.js

