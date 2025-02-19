@echo off
setlocal

REM Set the base directory where the project folder is located
set "BASE_DIR=P:\FEDS201\Scouting_Suite"

REM Navigate to the Scout-Ops-Android directory
cd "%BASE_DIR%\Scout-Ops-Android"

REM Print the current directory for debugging
echo Current directory:
cd

REM Build Web target
flutter build web

REM Move the entire 'web' folder to the assets folder
xcopy /e /i /h "build\web" "%BASE_DIR%\assets\web"

echo "Web build successfully moved to the assets folder."

endlocal
