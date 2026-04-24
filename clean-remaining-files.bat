@echo off
echo ==========================================
echo Cleaning Remaining Organization References
echo ==========================================
cd /d C:\JioCloudCursor\AISDLC\AI_SDLC_Platform
echo.

echo [1] Cleaning FH-001-family-hub-ado-reference.md...
powershell -Command "(Get-Content 'memory\team\product\FH-001-family-hub-ado-reference.md') -replace 'JPL-Limited', 'YourOrg' -replace 'JioAIphotos', 'YourProject' -replace 'JioAIPhotos', 'YourProject' -replace 'dev.azure.com/YourOrg/YourProject/_git/AI-sdlc-platform', 'dev.azure.com/YourOrg/YourProject/_git/your-repo' | Set-Content 'memory\team\product\FH-001-family-hub-ado-reference.md'"
echo.

echo [2] Cleaning stacks/java-tej/conventions.md...
powershell -Command "(Get-Content 'stacks\java-tej\conventions.md') -replace 'JPL TEJ', 'Your Org' | Set-Content 'stacks\java-tej\conventions.md'"
echo.

echo [3] Cleaning verify-public-no-vendor.sh...
powershell -Command "(Get-Content 'scripts\mirror-public\verify-public-no-vendor.sh') -replace \"'JPL-Limited'\", \"'YourOrg'\" -replace \"'JioAIphotos'\", \"'YourProject'\" -replace \"'jiocloud'\", \"'yourcloud'\" -replace \"'JioCloudCursor'\", \"'YourCursor'\" | Set-Content 'scripts\mirror-public\verify-public-no-vendor.sh'"
echo.

echo [4] Checking for any remaining Jio/JPL references...
findstr /s /i "JPL-Limited\|JioAIphotos\|JioAIPhotos" *.md *.sh *.py *.js *.json 2>nul | findstr /v /i "YourOrg\|YourProject"
echo.

echo [5] Committing changes...
git add -A
git commit -m "Clean remaining organization references (JPL, Jio, etc.)"
echo.

echo [6] Force pushing...
git push --force origin main
echo.

if %errorlevel% == 0 (
    echo ==========================================
    echo SUCCESS! All files cleaned and pushed!
    echo ==========================================
    echo.
    echo Verify: https://github.com/mehuldil/ai_sdlc_platform
    echo Search for 'JPL' - should return 0 results
) else (
    echo Push failed!
)

pause
