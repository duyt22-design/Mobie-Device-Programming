# Script khởi động Backend Server
Write-Host "🔍 Đang kiểm tra Backend Server..." -ForegroundColor Cyan
Write-Host ""

# Kiểm tra port 5000
$portCheck = Get-NetTCPConnection -LocalPort 5000 -ErrorAction SilentlyContinue

if ($portCheck) {
    Write-Host "✅ Port 5000 đang được sử dụng" -ForegroundColor Green
    Write-Host "   Server có thể đang chạy!" -ForegroundColor Green
    Write-Host ""
    Write-Host "🧪 Test kết nối..." -ForegroundColor Yellow
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:5000/api/statistics" -Method GET -TimeoutSec 3 -ErrorAction Stop
        Write-Host "✅ Server đang chạy và phản hồi!" -ForegroundColor Green
        Write-Host "   👥 Total Users: $($response.totalUsers)" -ForegroundColor Gray
        Write-Host "   📝 Total Tasks: $($response.totalTasks)" -ForegroundColor Gray
        Write-Host ""
        Write-Host "🎉 Server đã sẵn sàng!" -ForegroundColor Green
    } catch {
        Write-Host "❌ Port 5000 bị chiếm nhưng server không phản hồi!" -ForegroundColor Red
        Write-Host "   Vui lòng dừng process khác đang dùng port 5000" -ForegroundColor Yellow
    }
} else {
    Write-Host "❌ Port 5000 không có process nào" -ForegroundColor Red
    Write-Host "   Backend server CHƯA chạy!" -ForegroundColor Red
    Write-Host ""
    Write-Host "🚀 Khởi động Backend Server..." -ForegroundColor Yellow
    Write-Host ""
    
    # Chuyển đến thư mục backend
    Push-Location backend
    
    # Kiểm tra node_modules
    if (!(Test-Path "node_modules")) {
        Write-Host "📦 Cài đặt dependencies..." -ForegroundColor Yellow
        npm install
        Write-Host ""
    }
    
    # Khởi động server
    Write-Host "🚀 Đang khởi động server..." -ForegroundColor Cyan
    Write-Host "   Nhấn Ctrl+C để dừng server" -ForegroundColor Gray
    Write-Host ""
    Write-Host "====================================" -ForegroundColor Cyan
    Write-Host ""
    
    node server_sqlite.js
    
    Pop-Location
}

