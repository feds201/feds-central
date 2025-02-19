@echo off
setlocal

REM Set the base directory where the project folder is located
set "BASE_DIR=P:\FEDS201\Scouting_Suite"

REM Navigate to the Scout-Ops-Android directory
cd "%BASE_DIR%\Scout-Ops-Android"

REM Print the current directory for debugging
echo Current directory:
cd

REM Build APK for release
flutter build apk --release

REM Move the generated APK into the 'assets' folder
move "build\app\outputs\flutter-apk\app-release.apk" "%BASE_DIR%\assets\app-release.apk"

echo "Android APK build successfully moved to the assets folder."

endlocal
