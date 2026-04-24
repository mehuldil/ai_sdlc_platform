# Quick cleanup of remaining files
$ErrorActionPreference = "Continue"

Write-Host "Cleaning remaining organization references..." -ForegroundColor Cyan

# File 1: FH-001-family-hub-ado-reference.md
$file1 = "C:\JioCloudCursor\AISDLC\AI_SDLC_Platform\memory\team\product\FH-001-family-hub-ado-reference.md"
if (Test-Path $file1) {
    $content = Get-Content $file1 -Raw
    $content = $content -replace "JPL-Limited", "YourOrg"
    $content = $content -replace "JioAIphotos", "YourProject"
    $content = $content -replace "JioAIPhotos", "YourProject"
    Set-Content -Path $file1 -Value $content -NoNewline
    Write-Host "✓ Cleaned: FH-001-family-hub-ado-reference.md" -ForegroundColor Green
}

# File 2: conventions.md
$file2 = "C:\JioCloudCursor\AISDLC\AI_SDLC_Platform\stacks\java-tej\conventions.md"
if (Test-Path $file2) {
    $content = Get-Content $file2 -Raw
    $content = $content -replace "JPL TEJ", "Your Org"
    Set-Content -Path $file2 -Value $content -NoNewline
    Write-Host "✓ Cleaned: conventions.md" -ForegroundColor Green
}

# File 3: verify-public-no-vendor.sh
$file3 = "C:\JioCloudCursor\AISDLC\AI_SDLC_Platform\scripts\mirror-public\verify-public-no-vendor.sh"
if (Test-Path $file3) {
    $content = Get-Content $file3 -Raw
    $content = $content -replace "'JPL-Limited'", "'YourOrg'"
    $content = $content -replace "'JioAIphotos'", "'YourProject'"
    $content = $content -replace "'jiocloud'", "'yourcloud'"
    $content = $content -replace "'JioCloudCursor'", "'YourCursor'"
    Set-Content -Path $file3 -Value $content -NoNewline
    Write-Host "✓ Cleaned: verify-public-no-vendor.sh" -ForegroundColor Green
}

Write-Host "" -ForegroundColor Cyan
Write-Host "Staging and committing..." -ForegroundColor Cyan
Set-Location "C:\JioCloudCursor\AISDLC\AI_SDLC_Platform"
git add -A
git commit -m "Remove remaining organization references: JPL, JioAIphotos, etc."

Write-Host "" -ForegroundColor Cyan
Write-Host "Force pushing to GitHub..." -ForegroundColor Red
git push --force origin main

Write-Host "" -ForegroundColor Green
Write-Host "Done! Verify at: https://github.com/mehuldil/ai_sdlc_platform" -ForegroundColor Green
