@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"

set "REPO_ROOT=%CD%"
set "INCOMING_DIR=%REPO_ROOT%\incoming"
set "INCOMING_CONFIG=%INCOMING_DIR%\config\crosspromo.json"
set "INCOMING_ASSETS=%INCOMING_DIR%\assets"
set "TARGET_CONFIG=%REPO_ROOT%\config\crosspromo.json"
set "TARGET_ASSETS=%REPO_ROOT%\assets"
set "TARGET_BRANCH=main"
set "DEFAULT_COMMIT_MSG=chore: crosspromo content update"
set "GIT_USER_NAME=Baegagopa"
set "GIT_USER_EMAIL=Baegagopa@users.noreply.github.com"

if /I "%~1"=="help" goto :help
if /I "%~1"=="--help" goto :help
if /I "%~1"=="/?" goto :help

if not exist ".git" (
    echo [ERROR] Run this script from the GitHub Pages repository root.
    exit /b 1
)

if not exist "%INCOMING_DIR%\config" mkdir "%INCOMING_DIR%\config"
if not exist "%INCOMING_ASSETS%" mkdir "%INCOMING_ASSETS%"
if not exist "%TARGET_ASSETS%" mkdir "%TARGET_ASSETS%"

if exist "%INCOMING_CONFIG%" (
    copy /Y "%INCOMING_CONFIG%" "%TARGET_CONFIG%" >nul
    if errorlevel 1 (
        echo [ERROR] Failed to copy incoming config.
        exit /b 1
    )
    echo [OK] Copied incoming\config\crosspromo.json to config\crosspromo.json
) else (
    echo [INFO] No incoming config found. Keeping current config\crosspromo.json
)

set "HAS_INCOMING_ASSETS="
for /f %%F in ('dir /b /a-d "%INCOMING_ASSETS%" 2^>nul') do set "HAS_INCOMING_ASSETS=1"
if defined HAS_INCOMING_ASSETS (
    xcopy "%INCOMING_ASSETS%\*" "%TARGET_ASSETS%\" /E /I /Y >nul
    if errorlevel 1 (
        echo [ERROR] Failed to copy incoming asset files.
        exit /b 1
    )
    echo [OK] Copied incoming\assets files to assets\
) else (
    echo [INFO] No incoming asset files found. Keeping current assets\
)

if not exist "%TARGET_CONFIG%" (
    echo [ERROR] config\crosspromo.json is missing.
    exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-Content -Raw '%TARGET_CONFIG%' | ConvertFrom-Json | Out-Null"
if errorlevel 1 (
    echo [ERROR] JSON validation failed. Fix config\crosspromo.json and retry.
    exit /b 1
)

echo [OK] JSON validation passed.

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

git add config assets
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

git push origin HEAD:%TARGET_BRANCH%
if errorlevel 1 (
    echo [ERROR] git push failed.
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
echo 1. Put a new JSON file at incoming\config\crosspromo.json if needed.
echo 2. Put new or changed images in incoming\assets\ if needed.
echo 3. Run this bat file.
echo 4. Optional: pass a commit message.
echo.
echo Example:
echo   crosspromo_publish.bat feat: update spring campaign assets
echo.
echo Notes:
echo - If incoming\config\crosspromo.json is missing, the current config file is kept.
echo - If incoming\assets\ is empty, the current assets are kept.
echo - The script only stages and publishes config/ and assets/.
exit /b 0
