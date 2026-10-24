# Static analysis script for PulsePatch Lite
$ErrorActionPreference = "Stop"
Write-Host "Running flutter analyze..." -ForegroundColor Cyan
Set-Location "$PSScriptRoot\..\app"
flutter analyze --fatal-infos
if ($LASTEXITCODE -eq 0) {
    Write-Host "Static analysis clean! Zero warnings." -ForegroundColor Green
} else {
    Write-Host "Analysis failed with issues." -ForegroundColor Red
    exit 1
}
