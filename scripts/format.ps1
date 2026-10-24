# Format check script for PulsePatch Lite
$ErrorActionPreference = "Stop"
Write-Host "Formatting Dart files..." -ForegroundColor Cyan
Set-Location "$PSScriptRoot\..\app"
dart format --output=none --set-exit-if-changed .
if ($LASTEXITCODE -eq 0) {
    Write-Host "Format check passed." -ForegroundColor Green
} else {
    Write-Host "Format check failed! Please run 'dart format .' to fix formatting." -ForegroundColor Red
    exit 1
}
