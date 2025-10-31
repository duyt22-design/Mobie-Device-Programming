# Script kiểm tra kết nối database
Write-Host "===================================" -ForegroundColor Cyan
Write-Host "  KIEM TRA KET NOI DATABASE" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan
Write-Host ""

# 1. Kiểm tra database file
Write-Host "[1] Kiem tra database file..." -ForegroundColor Yellow
$dbPath = "backend\drawing_app.db"
if (Test-Path $dbPath) {
    $dbSize = (Get-Item $dbPath).Length / 1KB
    Write-Host "    OK - Database file ton tai" -ForegroundColor Green
    Write-Host "    Kich thuoc: $([math]::Round($dbSize, 2)) KB" -ForegroundColor Gray
} else {
    Write-Host "    WARNING - Database file chua ton tai" -ForegroundColor Yellow
    Write-Host "    (Se duoc tao khi server khoi dong)" -ForegroundColor Gray
}
Write-Host ""

# 2. Kiểm tra port 5000
Write-Host "[2] Kiem tra server (port 5000)..." -ForegroundColor Yellow
$portCheck = Get-NetTCPConnection -LocalPort 5000 -ErrorAction SilentlyContinue
if ($portCheck) {
    Write-Host "    OK - Port 5000 dang duoc su dung" -ForegroundColor Green
} else {
    Write-Host "    FAIL - Port 5000 khong co process nao" -ForegroundColor Red
    Write-Host "    ==> Server CHUA chay!" -ForegroundColor Red
    Write-Host ""
    Write-Host "    Giai phap:" -ForegroundColor Yellow
    Write-Host "    1. Chay: cd backend" -ForegroundColor White
    Write-Host "    2. Chay: node server_sqlite.js" -ForegroundColor White
    Write-Host ""
    exit 1
}
Write-Host ""

# 3. Test kết nối HTTP
Write-Host "[3] Test ket noi HTTP..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "http://localhost:5000/api/statistics" -Method GET -TimeoutSec 3 -ErrorAction Stop
    Write-Host "    OK - Server phan hoi thanh cong!" -ForegroundColor Green
    Write-Host "    Users: $($response.totalUsers)" -ForegroundColor Gray
    Write-Host "    Tasks: $($response.totalTasks)" -ForegroundColor Gray
    Write-Host "    History: $($response.totalCompletions)" -ForegroundColor Gray
} catch {
    Write-Host "    FAIL - Server khong phan hoi!" -ForegroundColor Red
    Write-Host "    Loi: $_" -ForegroundColor Gray
    Write-Host ""
    exit 1
}
Write-Host ""

# 4. Kiểm tra IP
Write-Host "[4] Kiem tra IP hien tai..." -ForegroundColor Yellow
$currentIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -like "192.168.*" -or $_.IPAddress -like "10.*"} | Select-Object -First 1).IPAddress
Write-Host "    IP hien tai: $currentIP" -ForegroundColor White
Write-Host ""
Write-Host "    Kiem tra trong database_service.dart..." -ForegroundColor Gray
$dartFile = "lib\services\database_service.dart"
if (Test-Path $dartFile) {
    $content = Get-Content $dartFile -Raw
    if ($content -match $currentIP) {
        Write-Host "    OK - IP co trong danh sach possibleIPs" -ForegroundColor Green
    } else {
        Write-Host "    WARNING - IP chua co trong danh sach!" -ForegroundColor Yellow
        Write-Host "    Can them IP: $currentIP vao danh sach" -ForegroundColor Yellow
    }
} else {
    Write-Host "    WARNING - Khong tim thay file database_service.dart" -ForegroundColor Yellow
}
Write-Host ""

# 5. Tổng kết
Write-Host "===================================" -ForegroundColor Cyan
Write-Host "  KET QUA" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "✅ Database: OK" -ForegroundColor Green
Write-Host "✅ Server: Dang chay" -ForegroundColor Green
Write-Host "✅ Ket noi: Thanh cong" -ForegroundColor Green
Write-Host ""
Write-Host "🎉 Tat ca deu OK! App co the ket noi." -ForegroundColor Green
Write-Host ""

