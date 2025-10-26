# Avatar Verification Script
# Run this after logging in to verify that profile pictures are being saved

Write-Host "=== ChatterBox Avatar Verification ===" -ForegroundColor Cyan
Write-Host ""

# Check if backend is running
Write-Host "1. Checking if backend is running..." -ForegroundColor Yellow
try {
    $healthCheck = Invoke-RestMethod -Uri "http://localhost:8080/actuator/health" -Method Get -ErrorAction Stop
    Write-Host "   ✓ Backend is running" -ForegroundColor Green
} catch {
    Write-Host "   ✗ Backend is NOT running!" -ForegroundColor Red
    Write-Host "   Please start the backend first:" -ForegroundColor Yellow
    Write-Host "   cd 'c:\Java Projects\ChatterBox\backend'" -ForegroundColor Gray
    Write-Host "   .\mvnw.cmd spring-boot:run" -ForegroundColor Gray
    exit
}

Write-Host ""
Write-Host "2. Fetching all users from database..." -ForegroundColor Yellow

try {
    $users = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/debug/users" -Method Get
    
    if ($users.Count -eq 0) {
        Write-Host "   ✗ No users found in database" -ForegroundColor Red
        Write-Host "   Please log in to the app first" -ForegroundColor Yellow
    } else {
        Write-Host "   ✓ Found $($users.Count) user(s)" -ForegroundColor Green
        Write-Host ""
        
        foreach ($user in $users) {
            Write-Host "   User: $($user.username)" -ForegroundColor Cyan
            Write-Host "   Email: $($user.email)" -ForegroundColor Gray
            Write-Host "   Google ID: $($user.googleId)" -ForegroundColor Gray
            
            if ($user.photoUrl -and $user.photoUrl -ne "null" -and $user.photoUrl.Length -gt 0) {
                Write-Host "   Photo URL: $($user.photoUrl)" -ForegroundColor Green
                Write-Host "   ✓ Profile picture is saved!" -ForegroundColor Green
            } else {
                Write-Host "   Photo URL: (not set)" -ForegroundColor Red
                Write-Host "   ✗ Profile picture is missing!" -ForegroundColor Red
                Write-Host "   Action needed: Log out and log back in" -ForegroundColor Yellow
            }
            Write-Host ""
        }
    }
} catch {
    Write-Host "   ✗ Failed to fetch users" -ForegroundColor Red
    Write-Host "   Error: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== Verification Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. If photoUrl is missing, log out and log back in to the app" -ForegroundColor White
Write-Host "2. Send a test message in any channel" -ForegroundColor White
Write-Host "3. Check if your profile picture appears next to the message" -ForegroundColor White
Write-Host ""
