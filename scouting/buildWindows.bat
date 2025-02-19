@echo off
setlocal

REM Set the base directory where the project folder is located
set "BASE_DIR=P:\FEDS201\Scouting_Suite"

REM Navigate to the Scout-Ops-Android directory
cd "%BASE_DIR%\Scout-Ops-Android"

REM Print the current directory for debugging
echo Current directory:
cd

REM Build Windows target
flutter build windows

REM Create MSIX package
dart run msix:create

REM Move the entire 'windows' folder to the assets folder
xcopy /e /i /h "build\windows" "%BASE_DIR%\assets\windows"

echo "Windows build successfully moved to the assets folder."

endlocal
