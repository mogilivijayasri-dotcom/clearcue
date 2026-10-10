@echo off
cd /d "%~dp0"
title ClearCue - Build

echo "%CD%" | findstr /i "OneDrive" >nul
if %errorlevel%==0 (
  echo.
  echo This folder is inside OneDrive. OneDrive locks build files and the build will fail.
  echo Please move this folder to C:\clearcue and run build.bat again.
  pause
  exit /b 1
)

if not exist lib\db\app_database.dart (
  echo.
  echo The new project files are missing. Please extract the latest clearcue.zip again.
  pause
  exit /b 1
)

if not exist android (
  echo.
  echo [1/3] Creating the Android part of the project...
  call flutter create --platforms=android .
)

echo.
echo [2/3] Downloading packages...
call flutter pub get

echo.
echo [3/3] Building the APK. This can take 5 to 10 minutes...
call flutter build apk --debug

if exist build\app\outputs\flutter-apk\app-debug.apk (
  echo.
  echo SUCCESS. Your APK is ready: app-debug.apk
  explorer build\app\outputs\flutter-apk
) else (
  echo.
  echo BUILD FAILED. Please copy the red error text above and send it.
)
pause
