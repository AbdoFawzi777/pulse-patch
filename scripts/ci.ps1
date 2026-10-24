# Master CI Verification Script for PulsePatch Lite
$ErrorActionPreference = "Stop"
Write-Host "=== Running PulsePatch Lite CI Checks ===" -ForegroundColor Magenta

Write-Host "1. Code Formatting" -ForegroundColor Yellow
& "$PSScriptRoot\format.ps1"
if ($LASTEXITCODE -ne 0) { exit 1 }

Write-Host "2. Static Analysis" -ForegroundColor Yellow
& "$PSScriptRoot\analyze.ps1"
if ($LASTEXITCODE -ne 0) { exit 1 }

Write-Host "3. Full Test Suite" -ForegroundColor Yellow
& "$PSScriptRoot\test.ps1"
if ($LASTEXITCODE -ne 0) { exit 1 }

Write-Host "=== All CI Checks Passed Cleanly! ===" -ForegroundColor Green
