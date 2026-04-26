@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"

set "REPO_ROOT=%CD%"
set "EXPECTED_REMOTE_URL=https://github.com/Baegagopa/baegagopa.github.io.git"
set "INCOMING_DIR=%REPO_ROOT%\incoming"
set "INCOMING_CONFIG=%INCOMING_DIR%\config\crosspromo.json"
set "INCOMING_ASSETS=%INCOMING_DIR%\assets"
set "INCOMING_ASSETS_FULL=%INCOMING_DIR%\assets_full"
set "TARGET_CONFIG=%REPO_ROOT%\config\crosspromo.json"
set "TARGET_ASSETS=%REPO_ROOT%\assets"
set "TARGET_BRANCH=main"
set "DEFAULT_COMMIT_MSG=chore: crosspromo content update"
set "VALIDATOR=%REPO_ROOT%\crosspromo_validate.ps1"
set "GIT_USER_NAME=Baegagopa"
set "GIT_USER_EMAIL=Baegagopa@users.noreply.github.com"

if /I "%~1"=="help" goto :help
if /I "%~1"=="--help" goto :help
if /I "%~1"=="/?" goto :help

echo.
echo [CrossPromo Publisher]

if not exist ".git" (
    echo [ERROR] Run this script from the GitHub Pages repository root.
    exit /b 1
)

if not exist "%VALIDATOR%" (
    echo [ERROR] Missing validator script: crosspromo_validate.ps1
    exit /b 1
)

for /f "delims=" %%R in ('git rev-parse --show-toplevel 2^>nul') do set "ACTUAL_TOP=%%R"
set "ACTUAL_TOP=%ACTUAL_TOP:/=\%"
if /I not "%ACTUAL_TOP%"=="%REPO_ROOT%" (
    echo [ERROR] Current folder does not match the git top-level.
    echo [ERROR] Git top-level: %ACTUAL_TOP%
    exit /b 1
)

for /f "delims=" %%R in ('git remote get-url origin 2^>nul') do set "CURRENT_REMOTE=%%R"
if /I not "%CURRENT_REMOTE%"=="%EXPECTED_REMOTE_URL%" (
    echo [ERROR] Unexpected origin remote.
    echo [ERROR] Current: %CURRENT_REMOTE%
    echo [ERROR] Expected: %EXPECTED_REMOTE_URL%
    exit /b 1
)

for /f "delims=" %%B in ('git branch --show-current 2^>nul') do set "CURRENT_BRANCH=%%B"
if not defined CURRENT_BRANCH (
    echo [ERROR] Detached HEAD is not allowed. Switch to %TARGET_BRANCH% first.
    exit /b 1
)
if /I not "%CURRENT_BRANCH%"=="%TARGET_BRANCH%" (
    echo [ERROR] Current branch is %CURRENT_BRANCH%.
    echo [ERROR] Switch to %TARGET_BRANCH% before running this script.
    exit /b 1
)

set "HAS_BLOCKING_CHANGES="
for /f "delims=" %%S in ('git status --porcelain 2^>nul') do (
    echo %%S | findstr /B /C:"?? incoming\\" >nul
    if errorlevel 1 set "HAS_BLOCKING_CHANGES=1"
)
if defined HAS_BLOCKING_CHANGES (
    echo [ERROR] Working tree has changes outside incoming\.
    echo [ERROR] Commit or clean them before running this script.
    exit /b 1
)

git fetch origin %TARGET_BRANCH% >nul 2>nul
if errorlevel 1 (
    echo [ERROR] git fetch failed.
    exit /b 1
)

git pull --ff-only origin %TARGET_BRANCH% >nul 2>nul
if errorlevel 1 (
    echo [ERROR] Fast-forward pull failed. Resolve local/remote divergence first.
    exit /b 1
)

if not exist "%INCOMING_DIR%\config" mkdir "%INCOMING_DIR%\config"
if not exist "%INCOMING_ASSETS%" mkdir "%INCOMING_ASSETS%"
if not exist "%INCOMING_ASSETS_FULL%" mkdir "%INCOMING_ASSETS_FULL%"
if not exist "%TARGET_ASSETS%" mkdir "%TARGET_ASSETS%"

if exist "%INCOMING_CONFIG%" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%VALIDATOR%" -Path "%INCOMING_CONFIG%"
    if errorlevel 1 (
        echo [ERROR] incoming\config\crosspromo.json failed validation.
        exit /b 1
    )
    copy /Y "%INCOMING_CONFIG%" "%TARGET_CONFIG%" >nul
    if errorlevel 1 (
        echo [ERROR] Failed to copy incoming config.
        exit /b 1
    )
    echo [OK] Replaced config\crosspromo.json from incoming\config\crosspromo.json
) else (
    echo [INFO] No incoming config found. Keeping current config\crosspromo.json
)

set "HAS_FULL_ASSET_SNAPSHOT="
for /f %%F in ('powershell -NoProfile -ExecutionPolicy Bypass -Command "$files = Get-ChildItem -Path ''%INCOMING_ASSETS_FULL%'' -Recurse -File | Where-Object { $_.Name -ne ''.gitkeep'' }; if ($files.Count -gt 0) { ''1'' }" 2^>nul') do set "HAS_FULL_ASSET_SNAPSHOT=1"

if defined HAS_FULL_ASSET_SNAPSHOT (
    robocopy "%INCOMING_ASSETS_FULL%" "%TARGET_ASSETS%" /MIR /R:1 /W:1 /NFL /NDL /NJH /NJS /NP /XF .gitkeep >nul
    set "ROBOCOPY_EXIT=!ERRORLEVEL!"
    if !ROBOCOPY_EXIT! GEQ 8 (
        echo [ERROR] Full asset sync failed. robocopy exit !ROBOCOPY_EXIT!
        exit /b 1
    )
    echo [OK] Mirrored incoming\assets_full to assets\ including deletions
) else (
    set "HAS_INCOMING_ASSETS="
    for /f %%F in ('powershell -NoProfile -ExecutionPolicy Bypass -Command "$files = Get-ChildItem -Path ''%INCOMING_ASSETS%'' -Recurse -File | Where-Object { $_.Name -ne ''.gitkeep'' }; if ($files.Count -gt 0) { ''1'' }" 2^>nul') do set "HAS_INCOMING_ASSETS=1"
    if defined HAS_INCOMING_ASSETS (
        robocopy "%INCOMING_ASSETS%" "%TARGET_ASSETS%" /E /R:1 /W:1 /NFL /NDL /NJH /NJS /NP /XF .gitkeep >nul
        set "ROBOCOPY_EXIT=!ERRORLEVEL!"
        if !ROBOCOPY_EXIT! GEQ 8 (
            echo [ERROR] Add/replace asset copy failed. robocopy exit !ROBOCOPY_EXIT!
            exit /b 1
        )
        echo [OK] Copied incoming\assets into assets\ as add/replace mode
    ) else (
        echo [INFO] No incoming assets found. Keeping current assets\
    )
)

if not exist "%TARGET_CONFIG%" (
    echo [ERROR] config\crosspromo.json is missing.
    exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%VALIDATOR%" -Path "%TARGET_CONFIG%"
if errorlevel 1 (
    echo [ERROR] Final config\crosspromo.json validation failed.
    exit /b 1
)

echo [OK] Final JSON validation passed.

set "HAS_CHANGES="
for /f %%S in ('git status --porcelain -- config assets 2^>nul') do set "HAS_CHANGES=1"
if not defined HAS_CHANGES (
    echo [INFO] No changes detected in config/ or assets/.
    echo [INFO] Nothing to commit.
    exit /b 0
)

set "COMMIT_MSG=%*"
if not defined COMMIT_MSG set "COMMIT_MSG=%DEFAULT_COMMIT_MSG%"

echo [INFO] Commit message: %COMMIT_MSG%

git add -A -- config assets
if errorlevel 1 (
    echo [ERROR] git add failed.
    exit /b 1
)

if defined GIT_USER_NAME if defined GIT_USER_EMAIL (
    git -c user.name="%GIT_USER_NAME%" -c user.email="%GIT_USER_EMAIL%" commit -m "%COMMIT_MSG%"
) else (
    git commit -m "%COMMIT_MSG%"
)
if errorlevel 1 (
    echo [ERROR] git commit failed.
    exit /b 1
)

git push origin %TARGET_BRANCH%:%TARGET_BRANCH%
if errorlevel 1 (
    echo [ERROR] git push failed. Check whether remote main changed first.
    exit /b 1
)

echo.
echo [DONE] CrossPromo update published.
echo [DONE] JSON URL: https://baegagopa.github.io/config/crosspromo.json
echo [DONE] Asset URL example: https://baegagopa.github.io/assets/sample-utility-icon.svg
exit /b 0

:help
echo.
echo CrossPromo Publisher
echo.
echo [Quick start]
echo 1. Put a new JSON file at incoming\config\crosspromo.json if needed.
echo 2. Put new or changed images in incoming\assets\ for add/replace updates.
echo 3. Put a full asset snapshot in incoming\assets_full\ if you want deletions mirrored too.
echo 4. Make sure the repo is clean and checked out on main.
echo 5. Run this bat file.
echo 6. Optional: pass a commit message.
echo.
echo [Example]
echo   crosspromo_publish.bat feat: update summer promo assets
echo.
echo [Guards]
echo - The script requires the repo root, main branch, and the expected origin remote.
echo - The script blocks execution if there are changes outside incoming\.
echo - The script fast-forwards main from origin before applying updates.
echo.
echo [Notes]
echo - incoming\assets\ only adds or overwrites files.
echo - incoming\assets_full\ mirrors the whole assets folder and removes missing files.
echo - The script ignores .gitkeep marker files in both asset source folders.
echo - The validator checks required root fields, display rules, games, localized content, and HTTPS URLs.
echo - If no changes are detected, it exits without committing.
exit /b 0
