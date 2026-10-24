# Test suite runner for PulsePatch Lite
$ErrorActionPreference = "Stop"
Write-Host "Running Flutter test suite..." -ForegroundColor Cyan
Set-Location "$PSScriptRoot\..\app"
flutter test
if ($LASTEXITCODE -eq 0) {
    Write-Host "All tests passed successfully!" -ForegroundColor Green
} else {
    Write-Host "Test failures detected." -ForegroundColor Red
    exit 1
}
