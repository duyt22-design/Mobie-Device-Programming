# Script kiểm tra và khởi động Backend Server
Write-Host "===================================" -ForegroundColor Cyan
Write-Host "  KIỂM TRA VÀ KHỞI ĐỘNG SERVER" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan
Write-Host ""

# Kiểm tra port 5000
Write-Host "🔍 Đang kiểm tra port 5000..." -ForegroundColor Yellow
$portCheck = Get-NetTCPConnection -LocalPort 5000 -ErrorAction SilentlyContinue

if ($portCheck) {
    Write-Host "✅ Port 5000 đang được sử dụng" -ForegroundColor Green
    Write-Host ""
    Write-Host "🧪 Test kết nối server..." -ForegroundColor Yellow
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:5000/api/statistics" -Method GET -TimeoutSec 3 -ErrorAction Stop
        Write-Host "✅ Server đang chạy và phản hồi!" -ForegroundColor Green
        Write-Host "   👥 Total Users: $($response.totalUsers)" -ForegroundColor Gray
        Write-Host "   📝 Total Tasks: $($response.totalTasks)" -ForegroundColor Gray
        Write-Host ""
        Write-Host "🎉 Server đã sẵn sàng!" -ForegroundColor Green
        Write-Host ""
        Write-Host "📍 IP hiện tại của máy: " -NoNewline -ForegroundColor Cyan
        $currentIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -like "192.168.*" -or $_.IPAddress -like "10.*"} | Select-Object -First 1).IPAddress
        Write-Host $currentIP -ForegroundColor White
        Write-Host ""
        Write-Host "💡 Đảm bảo IP này có trong danh sách possibleIPs trong database_service.dart" -ForegroundColor Yellow
        exit 0
    } catch {
        Write-Host "❌ Port 5000 bị chiếm nhưng server không phản hồi!" -ForegroundColor Red
        Write-Host "   Vui lòng dừng process khác đang dùng port 5000" -ForegroundColor Yellow
        exit 1
    }
} else {
    Write-Host "❌ Port 5000 không có process nào" -ForegroundColor Red
    Write-Host "   Backend server CHƯA chạy!" -ForegroundColor Red
    Write-Host ""
    Write-Host "📍 IP hiện tại của máy: " -NoNewline -ForegroundColor Cyan
    $currentIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -like "192.168.*" -or $_.IPAddress -like "10.*"} | Select-Object -First 1).IPAddress
    Write-Host $currentIP -ForegroundColor White
    Write-Host ""
    Write-Host "🚀 Khởi động Backend Server..." -ForegroundColor Yellow
    Write-Host ""
    
    # Chuyển đến thư mục backend
    $backendPath = Join-Path $PSScriptRoot "backend"
    if (!(Test-Path $backendPath)) {
        Write-Host "❌ Không tìm thấy thư mục backend!" -ForegroundColor Red
        Write-Host "   Đường dẫn: $backendPath" -ForegroundColor Gray
        exit 1
    }
    
    Push-Location $backendPath
    
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

