Write-Host "🔍 KIỂM TRA KẾT NỐI DATABASE" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Bước 1: Kiểm tra backend server có chạy không
Write-Host "📡 Bước 1: Kiểm tra backend server..." -ForegroundColor Yellow
$port5000 = Get-NetTCPConnection -LocalPort 5000 -ErrorAction SilentlyContinue

if ($port5000) {
    Write-Host "✅ Port 5000 đang được sử dụng - Server có thể đang chạy" -ForegroundColor Green
} else {
    Write-Host "❌ Port 5000 không có process - Backend server CHƯA chạy!" -ForegroundColor Red
    Write-Host ""
    Write-Host "💡 CẦN KHỞI ĐỘNG BACKEND TRƯỚC:" -ForegroundColor Yellow
    Write-Host "   1. Mở PowerShell MỚI" -ForegroundColor White
    Write-Host "   2. Chạy: cd C:\Projects\flutter-application_2" -ForegroundColor Gray
    Write-Host "   3. Chạy: .\start_backend.ps1" -ForegroundColor Gray
    Write-Host "   4. Hoặc: cd backend && node server_sqlite.js" -ForegroundColor Gray
    Write-Host ""
}

Write-Host ""

# Bước 2: Test API
Write-Host "🌐 Bước 2: Test kết nối API..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "http://localhost:5000/api/statistics" -Method GET -TimeoutSec 5
    Write-Host "✅ KẾT NỐI THÀNH CÔNG!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📊 Dữ liệu database:" -ForegroundColor Cyan
    Write-Host "   👥 Users: $($response.totalUsers)" -ForegroundColor White
    Write-Host "   📝 Tasks: $($response.totalTasks)" -ForegroundColor White
    Write-Host "   📜 Completions: $($response.totalCompletions)" -ForegroundColor White
    Write-Host ""
    Write-Host "✅ Database hoạt động tốt!" -ForegroundColor Green
    
} catch {
    Write-Host "❌ KHÔNG THỂ KẾT NỐI!" -ForegroundColor Red
    Write-Host "   Lỗi: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "🔧 NGUYÊN NHÂN CÓ THỂ LÀ:" -ForegroundColor Yellow
    Write-Host "   1. Backend server chưa chạy" -ForegroundColor White
    Write-Host "   2. Port 5000 bị chặn bởi firewall" -ForegroundColor White
    Write-Host "   3. Database file bị lỗi" -ForegroundColor White
    Write-Host ""
    Write-Host "💡 GIẢI PHÁP:" -ForegroundColor Cyan
    Write-Host "   → Xem file KIEM_TRA_KET_NOI.md" -ForegroundColor White
}

Write-Host ""
Write-Host "================================" -ForegroundColor Cyan

