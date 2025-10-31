# Script to delete all users except admin
Write-Host "⚠️  WARNING: This will delete ALL users (except admin)!" -ForegroundColor Red
$response = Read-Host "Are you sure? (yes/no)"

if ($response -eq "yes") {
    try {
        $result = Invoke-RestMethod -Uri "http://localhost:5000/api/users" -Method DELETE
        Write-Host "✅ Success: $($result.message)" -ForegroundColor Green
        Write-Host "Deleted count: $($result.deletedCount)" -ForegroundColor Yellow
    } catch {
        Write-Host "❌ Error: $_" -ForegroundColor Red
    }
} else {
    Write-Host "Cancelled." -ForegroundColor Yellow
}


