# Script kiểm tra trạng thái server
Write-Host "🔍 Đang kiểm tra trạng thái server..." -ForegroundColor Cyan
Write-Host ""

# Kiểm tra port 5000
Write-Host "📡 Kiểm tra port 5000..." -ForegroundColor Yellow
$portCheck = Get-NetTCPConnection -LocalPort 5000 -ErrorAction SilentlyContinue

if ($portCheck) {
    Write-Host "✅ Port 5000 đang được sử dụng" -ForegroundColor Green
    Write-Host "   Process ID: $($portCheck.OwningProcess)" -ForegroundColor Gray
    
    $process = Get-Process -Id $portCheck.OwningProcess -ErrorAction SilentlyContinue
    if ($process) {
        Write-Host "   Process: $($process.ProcessName)" -ForegroundColor Gray
        Write-Host "   Server có thể đang chạy! ✅" -ForegroundColor Green
    }
} else {
    Write-Host "❌ Port 5000 không có process nào" -ForegroundColor Red
    Write-Host "   Backend server CHƯA chạy!" -ForegroundColor Red
}

Write-Host ""

# Test kết nối HTTP
Write-Host "🌐 Test kết nối HTTP..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:5000/api/statistics" -Method GET -TimeoutSec 3 -ErrorAction Stop
    Write-Host "✅ Server đang chạy và phản hồi!" -ForegroundColor Green
    Write-Host "   Status: $($response.StatusCode)" -ForegroundColor Gray
    
    $data = $response.Content | ConvertFrom-Json
    Write-Host ""
    Write-Host "📊 Thống kê:" -ForegroundColor Cyan
    Write-Host "   👥 Total Users: $($data.totalUsers)" -ForegroundColor Gray
    Write-Host "   📝 Total Tasks: $($data.totalTasks)" -ForegroundColor Gray
    Write-Host "   📜 Total Completions: $($data.totalCompletions)" -ForegroundColor Gray
    
} catch {
    Write-Host "❌ Không thể kết nối đến server!" -ForegroundColor Red
    Write-Host "   Lỗi: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "💡 Giải pháp:" -ForegroundColor Cyan
    Write-Host "   1. Khởi động backend server:" -ForegroundColor White
    Write-Host "      .\start_backend.ps1" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   2. Hoặc chạy trực tiếp:" -ForegroundColor White
    Write-Host "      cd backend" -ForegroundColor Gray
    Write-Host "      node server_sqlite.js" -ForegroundColor Gray
}

Write-Host ""

# Kiểm tra file server
Write-Host "📂 Kiểm tra file server..." -ForegroundColor Yellow
if (Test-Path "backend\server_sqlite.js") {
    Write-Host "✅ File server_sqlite.js tồn tại" -ForegroundColor Green
} else {
    Write-Host "❌ Không tìm thấy server_sqlite.js" -ForegroundColor Red
}

if (Test-Path "backend\node_modules") {
    Write-Host "✅ node_modules đã cài đặt" -ForegroundColor Green
} else {
    Write-Host "⚠️  node_modules chưa có, cần chạy: cd backend && npm install" -ForegroundColor Yellow
}

if (Test-Path "backend\drawing_app.db") {
    Write-Host "✅ Database file tồn tại" -ForegroundColor Green
} else {
    Write-Host "⚠️  Database file chưa có, sẽ được tạo tự động khi chạy server" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow

