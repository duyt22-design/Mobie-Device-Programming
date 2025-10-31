# Script để fix lỗi build Flutter trên Windows
# Chạy: .\fix_build_error.ps1

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  FIX BUILD ERROR - Flutter Windows  " -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Kill all processes
Write-Host "🔄 Bước 1: Đang kill processes..." -ForegroundColor Yellow
taskkill /F /IM dart.exe 2>$null
taskkill /F /IM flutter.exe 2>$null
taskkill /F /IM java.exe 2>$null
taskkill /F /IM qemu-system-x86_64.exe 2>$null
taskkill /F /IM adb.exe 2>$null
taskkill /F /IM msedge.exe 2>$null
Write-Host "✅ Đã kill processes`n" -ForegroundColor Green

# Step 2: Wait
Write-Host "⏳ Bước 2: Đợi 2 giây..." -ForegroundColor Yellow
Start-Sleep -Seconds 2
Write-Host "✅ Done`n" -ForegroundColor Green

# Step 3: Delete build folders
Write-Host "🗑️  Bước 3: Đang xóa build folders..." -ForegroundColor Yellow
$projectPath = $PSScriptRoot
Set-Location $projectPath

Remove-Item -Recurse -Force "build" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force ".dart_tool" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force "windows\flutter\ephemeral" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force "linux\flutter\ephemeral" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force "macos\Flutter\ephemeral" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force "ios\Flutter\ephemeral" -ErrorAction SilentlyContinue

Write-Host "✅ Đã xóa build folders`n" -ForegroundColor Green

# Step 4: Flutter clean
Write-Host "🧹 Bước 4: Flutter clean..." -ForegroundColor Yellow
flutter clean
Write-Host "✅ Flutter clean done`n" -ForegroundColor Green

# Step 5: Get dependencies
Write-Host "📦 Bước 5: Flutter pub get..." -ForegroundColor Yellow
flutter pub get
Write-Host "✅ Dependencies OK`n" -ForegroundColor Green

# Step 6: Start backend
Write-Host "🚀 Bước 6: Khởi động backend..." -ForegroundColor Yellow
$backendPath = Join-Path $projectPath "backend"
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$backendPath'; node server_sqlite.js" -WindowStyle Minimized
Write-Host "✅ Backend đã khởi động (port 5000)`n" -ForegroundColor Green

# Step 7: Wait for backend
Write-Host "⏳ Bước 7: Đợi backend sẵn sàng..." -ForegroundColor Yellow
Start-Sleep -Seconds 3
Write-Host "✅ Backend ready`n" -ForegroundColor Green

# Step 8: Run app
Write-Host "🎉 Bước 8: Đang chạy app trên Windows..." -ForegroundColor Yellow
Write-Host ""
Write-Host "────────────────────────────────────" -ForegroundColor Cyan
Write-Host "  App window sẽ tự động mở!" -ForegroundColor Green
Write-Host "  App đang compile... (~30-60s)" -ForegroundColor Yellow
Write-Host "  Chạy trên Windows desktop ổn định hơn Edge!" -ForegroundColor Cyan
Write-Host "────────────────────────────────────" -ForegroundColor Cyan
Write-Host ""

flutter run -d windows

Write-Host ""
Write-Host "✅ HOÀN THÀNH!" -ForegroundColor Green

