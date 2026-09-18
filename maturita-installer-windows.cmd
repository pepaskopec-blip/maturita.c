@echo off
rem maturita.c installer for Windows.
rem
rem Carries no application of its own. Fastly caches branch-named URLs on
rem raw.githubusercontent.com, so this script looks up the tip of `builds`
rem and downloads that commit — not a stale zip from the last five minutes.
rem
rem Double-click the file to run it. The app updates itself from then on.

setlocal EnableDelayedExpansion
set "REPO=pepaskopec-blip/maturita.c"
set "BRANCH=builds"
set "ASSET=maturita-windows-x64.zip"
set "DEST=%LOCALAPPDATA%\Programs\Maturita"

echo Installing maturita.C
echo ---------------------

where curl >nul 2>&1 || goto :no_tools
where tar  >nul 2>&1 || goto :no_tools

set "TMP_DIR=%TEMP%\maturita-installer"
rmdir /s /q "%TMP_DIR%" 2>nul
mkdir "%TMP_DIR%" || goto :fail_tmp

echo Looking up the latest build...
set "SHA="
for /f "usebackq delims=" %%S in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "$r = & curl.exe -fsSL --max-time 20 'https://github.com/%REPO%/commits/%BRANCH%.atom'; if ($r -match 'Commit/([0-9a-f]{40})') { $Matches[1] }"`) do set "SHA=%%S"
if not defined SHA goto :fail_download
set "URL=https://raw.githubusercontent.com/%REPO%/%SHA%/%ASSET%"

echo Downloading build %SHA:~0,7%...
curl -fL --progress-bar --max-time 1800 -o "%TMP_DIR%\%ASSET%" "%URL%" || goto :fail_download

echo Installing to %DEST%
if not exist "%DEST%" mkdir "%DEST%" || goto :fail_dest

tar -xf "%TMP_DIR%\%ASSET%" -C "%DEST%" || goto :fail_extract

set "LNK=%APPDATA%\Microsoft\Windows\Start Menu\Programs\maturita.C.lnk"
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$s=(New-Object -ComObject WScript.Shell).CreateShortcut('%LNK%');" ^
  "$s.TargetPath='%DEST%\maturita.exe';$s.WorkingDirectory='%DEST%';$s.Save()" >nul 2>&1

rmdir /s /q "%TMP_DIR%" 2>nul

echo.
echo Done. Starting the app...
start "" "%DEST%\maturita.exe"
exit /b 0

:no_tools
echo.
echo Error: this installer needs curl and tar, which come with Windows 10
echo version 1803 and later. Please update Windows, or download the zip
echo manually from https://github.com/%REPO%/tree/%BRANCH%
pause
exit /b 1

:fail_tmp
echo.
echo Error: could not create a temporary folder in %TEMP%.
pause
exit /b 1

:fail_download
echo.
echo Error: the download failed. Check your internet connection.
pause
exit /b 1

:fail_dest
echo.
echo Error: could not create %DEST%.
pause
exit /b 1

:fail_extract
echo.
echo Error: the archive could not be unpacked.
pause
exit /b 1
