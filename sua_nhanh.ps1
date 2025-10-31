Write-Host "🔧 TỰ ĐỘNG TÌM VÀ SỬA CẤU HÌNH DATABASE" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host ""

# Tìm file database
Write-Host "🔍 Đang tìm file database..." -ForegroundColor Yellow
$dbFiles = Get-ChildItem "backend\*.db" -ErrorAction SilentlyContinue | 
    Where-Object {$_.Name -notlike "*-shm" -and $_.Name -notlike "*-wal"}

if ($dbFiles.Count -eq 0) {
    Write-Host "❌ Không tìm thấy file database nào!" -ForegroundColor Red
    Write-Host "   Tạo file database mới? (y/n)" -ForegroundColor Yellow
    $response = Read-Host
    if ($response -eq 'y') {
        Write-Host "💡 File database sẽ được tạo tự động khi chạy server" -ForegroundColor Cyan
    }
} else {
    Write-Host "✅ Tìm thấy $($dbFiles.Count) file database:" -ForegroundColor Green
    foreach ($file in $dbFiles) {
        Write-Host "   - $($file.Name) ($([math]::Round($file.Length/1KB, 2)) KB)" -ForegroundColor White
    }
    
    $mainDb = $dbFiles[0].Name
    Write-Host ""
    Write-Host "📝 Sẽ sử dụng: $mainDb" -ForegroundColor Cyan
}

Write-Host ""

# Tìm file server
Write-Host "🔍 Đang tìm file server..." -ForegroundColor Yellow
$serverFiles = Get-ChildItem "backend\server*.js" -ErrorAction SilentlyContinue

if ($serverFiles.Count -eq 0) {
    Write-Host "❌ Không tìm thấy file server!" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Tìm thấy $($serverFiles.Count) file server:" -ForegroundColor Green
foreach ($file in $serverFiles) {
    Write-Host "   - $($file.Name)" -ForegroundColor White
}

Write-Host ""

# Sửa file server_sqlite.js
$serverFile = "backend\server_sqlite.js"
if (Test-Path $serverFile) {
    Write-Host "🔧 Đang sửa $serverFile..." -ForegroundColor Yellow
    
    $content = Get-Content $serverFile -Raw -Encoding UTF8
    
    # Tìm và thay thế
    if ($content -match "const db = new Database\('([^']+)'\);") {
        $oldDb = $matches[1]
        Write-Host "   Tìm thấy: $oldDb" -ForegroundColor Gray
        
        if ($dbFiles -and $oldDb -ne $mainDb) {
            Write-Host "   Đổi từ: $oldDb" -ForegroundColor Yellow
            Write-Host "   Thành: $mainDb" -ForegroundColor Green
            
            $content = $content -replace "const db = new Database\('$oldDb'\);", "const db = new Database('$mainDb');"
            
            Set-Content -Path $serverFile -Value $content -Encoding UTF8 -NoNewline
            
            Write-Host "   ✅ Đã cập nhật!" -ForegroundColor Green
        } else {
            Write-Host "   ✅ Đã đúng ($oldDb)" -ForegroundColor Green
        }
    } else {
        Write-Host "   ⚠️  Không tìm thấy dòng khởi tạo database" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "✅ Hoàn thành!" -ForegroundColor Green
Write-Host ""
Write-Host "💡 Bây giờ khởi động backend:" -ForegroundColor Cyan
Write-Host "   .\start_backend.ps1" -ForegroundColor White

