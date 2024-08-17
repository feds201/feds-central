@echo off

REM Create the Output directory if it doesn't exist
if not exist ".\Output" (
    mkdir ".\Output"
)

REM Run PyInstaller
pyinstaller --noconfirm --onefile --console ^
--add-data ".\devices.db;." ^
--add-data ".\identifier.sqlite;." ^
--add-data ".\match.db;." ^
--add-data ".\README.md;." ^
--add-data ".\requirements.txt;." ^
--add-data ".\server.py;." ^
--add-data ".\App;App/" ^
--add-data ".\output;output/" ^
--add-data ".\templates;templates/" ^
--add-data ".\templates\clear_data.html;." ^
--add-data ".\templates\clear_devices.html;." ^
--add-data ".\templates\client_images.html;." ^
--add-data ".\templates\data.html;." ^
--add-data ".\templates\delete_device.html;." ^
--add-data ".\templates\devices.html;." ^
--add-data ".\templates\index.html;." ^
--add-data ".\templates\info.html;." ^
--add-data ".\App\app-release.apk;." ^
--distpath ".\Output" ^
".\server.py"

REM Display a message box indicating completion
powershell -command "Add-Type -AssemblyName PresentationFramework;[System.Windows.MessageBox]::Show('The executable has been compiled and is located in the Output folder. ', 'Compilation Complete')"
powershell -command "Add-Type -AssemblyName PresentationFramework;[System.Windows.MessageBox]::Show('Init Clean Up. ', 'Compilation Complete')"

REM Run the cleanup script
call cleanup.bat