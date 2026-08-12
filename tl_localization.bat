@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Throne and Liberty - Astrum English Localization

set "REPO_RAW=https://raw.githubusercontent.com/berkaycimsir/tl-astrum-english/main"
set "EXPECTED_SHA=E33292367CB1277735291CAFEA978221D38C0D900A804A07EC36DBFBD7391F80"
set "CACHE=%LOCALAPPDATA%\TL_Astrum_English"
set "SCRIPTS=%CACHE%\scripts"
set "PAYLOAD=%CACHE%\payload"
set "CONFIG=%CACHE%\game_path.txt"

if not exist "%CACHE%" mkdir "%CACHE%"
if not exist "%SCRIPTS%" mkdir "%SCRIPTS%"
if not exist "%PAYLOAD%" mkdir "%PAYLOAD%"

cls
echo.
echo  ================================================================
echo   Throne and Liberty - Astrum English Localization
echo   T1 + T2 / Talandre
echo  ================================================================
echo.
echo   [1] Install English
echo   [2] Restore Russian
echo   [3] Exit
echo.
choice /C 123 /N /M "  Choose [1/2/3]: "
set "MENU=%errorlevel%"
if "%MENU%"=="3" exit /b 0

call :find_game
if errorlevel 1 goto :failed

echo.
echo   Game folder: !GAME_ROOT!
echo   Updating helper scripts...
call :download "%REPO_RAW%/scripts/install_localization.ps1" "%SCRIPTS%\install_localization.ps1"
if errorlevel 1 goto :failed
call :download "%REPO_RAW%/scripts/restore_localization.ps1" "%SCRIPTS%\restore_localization.ps1"
if errorlevel 1 goto :failed

if "%MENU%"=="2" goto :restore

:install
echo   Checking localization payload...
call :ensure_payload
if errorlevel 1 goto :failed
echo.
echo   Installing English T1 + T2 localization...
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPTS%\install_localization.ps1" -GameRoot "!GAME_ROOT!" -LocresPath "%PAYLOAD%\Game.locres"
if errorlevel 1 goto :failed
goto :success

:restore
echo.
echo   Restoring original Russian localization...
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPTS%\restore_localization.ps1" -GameRoot "!GAME_ROOT!"
if errorlevel 1 goto :failed
goto :success

:find_game
set "GAME_ROOT="

if exist "%CONFIG%" set /p GAME_ROOT=<"%CONFIG%"
if defined GAME_ROOT if exist "!GAME_ROOT!\TL\Content\Paks" goto :game_found
if defined GAME_ROOT if exist "!GAME_ROOT!\Content\Paks" goto :game_found

set "GAME_ROOT=C:\AstrumPlay\Throne and Liberty"
if exist "!GAME_ROOT!\TL\Content\Paks" goto :game_found
if exist "!GAME_ROOT!\Content\Paks" goto :game_found

set "GAME_ROOT="
echo.
echo   Select the Throne and Liberty root game folder.
for /f "usebackq delims=" %%G in (`powershell -NoProfile -Command "Add-Type -AssemblyName System.Windows.Forms; $d=New-Object System.Windows.Forms.FolderBrowserDialog; $d.Description='Select the Throne and Liberty game folder'; $d.ShowNewFolderButton=$false; if($d.ShowDialog().ToString() -eq 'OK'){[Console]::Write($d.SelectedPath)}"`) do set "GAME_ROOT=%%G"

if not defined GAME_ROOT (
    echo   ERROR: No game folder was selected.
    exit /b 1
)
if not exist "!GAME_ROOT!\TL\Content\Paks" if not exist "!GAME_ROOT!\Content\Paks" (
    echo   ERROR: Content\Paks was not found under "!GAME_ROOT!".
    exit /b 1
)

:game_found
>"%CONFIG%" echo !GAME_ROOT!
exit /b 0

:download
set "DOWNLOAD_URL=%~1"
set "DOWNLOAD_DEST=%~2"
set "DOWNLOAD_TMP=%~2.tmp"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -UseBasicParsing -Headers @{'User-Agent'='TL-Astrum-English'} -Uri '%DOWNLOAD_URL%' -OutFile '%DOWNLOAD_TMP%'"
if errorlevel 1 (
    del "%DOWNLOAD_TMP%" 2>nul
    echo   ERROR: Download failed: %DOWNLOAD_URL%
    exit /b 1
)
move /y "%DOWNLOAD_TMP%" "%DOWNLOAD_DEST%" >nul
exit /b 0

:ensure_payload
set "CURRENT_SHA="
if exist "%PAYLOAD%\Game.locres" for /f "delims=" %%H in ('powershell -NoProfile -Command "(Get-FileHash -Algorithm SHA256 -LiteralPath '%PAYLOAD%\Game.locres').Hash"') do set "CURRENT_SHA=%%H"
if /I "!CURRENT_SHA!"=="%EXPECTED_SHA%" (
    echo   Localization payload is current.
    exit /b 0
)

echo   Downloading Game.locres...
call :download "%REPO_RAW%/payload/Game.locres" "%PAYLOAD%\Game.locres"
if errorlevel 1 exit /b 1

set "CURRENT_SHA="
for /f "delims=" %%H in ('powershell -NoProfile -Command "(Get-FileHash -Algorithm SHA256 -LiteralPath '%PAYLOAD%\Game.locres').Hash"') do set "CURRENT_SHA=%%H"
if /I not "!CURRENT_SHA!"=="%EXPECTED_SHA%" (
    del "%PAYLOAD%\Game.locres" 2>nul
    echo   ERROR: The downloaded payload failed SHA-256 verification.
    exit /b 1
)
echo   Payload verified.
exit /b 0

:success
echo.
echo   Done.
echo.
pause
exit /b 0

:failed
echo.
echo   Operation failed. Read the error above.
echo.
pause
exit /b 1
