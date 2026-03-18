param (
    [string]$BASE_DIR = "$PSScriptRoot\.."
)

# Navigate to the android directory
Set-Location "$BASE_DIR\android"

# Prep Flutter environment
Write-Host "Cleaning and fetching dependencies..."
flutter clean
flutter pub get

# Print the current directory for debugging
Write-Host "Current directory: $(Get-Location)"

# Create Assets folder if it doesn't exist
$assetsDir = "$BASE_DIR\Assets"
if (-not (Test-Path -Path $assetsDir)) {
    New-Item -Path $assetsDir -ItemType Directory -Force
    Write-Host "Created Assets directory at $assetsDir"
}

# Build APK for release
flutter build apk --no-tree-shake-icons

# Move the generated APK into the 'Assets' folder
Move-Item "build\app\outputs\flutter-apk\app-release.apk" "$assetsDir\app-release.apk" -Force

# Rename the APK file for clarity
Rename-Item "$assetsDir\app-release.apk" "Scout-Ops-Android.apk" -Force

Write-Host "Android APK renamed to Scout-Ops-Android.apk."

Write-Host "Android APK build successfully moved to the Assets folder."

Write-Host "Build process completed for Android."


Set-Location "$BASE_DIR\android"

Write-Host "Starting Windows build process..."
flutter build windows


Write-Host "Current directory: $(Get-Location)"

# Ensure Assets\Windows folder exists
$windowsAssetsDir = "$assetsDir\Windows"
if (-not (Test-Path -Path $windowsAssetsDir)) {
    New-Item -Path $windowsAssetsDir -ItemType Directory -Force
    Write-Host "Created Windows Assets directory at $windowsAssetsDir"
}

# Move the generated Windows executable and DLLs into a specific folder
$windowsBuildDir = "build\windows\x64\runner\Release"
if (Test-Path -Path $windowsBuildDir) {
    $androidDestDir = "$windowsAssetsDir\Scout-Ops-Android"
    if (-not (Test-Path -Path $androidDestDir)) {
        New-Item -Path $androidDestDir -ItemType Directory -Force
    }
    
    # We use Copy-Item or Move-Item. Original script used Move-Item.
    Move-Item "$windowsBuildDir\*.dll" "$androidDestDir" -Force
    
    # The executable name in 'android/' project might be scouting_app.exe or similar.
    # We'll look for any .exe and rename it to Scout-Ops-Android.exe
    $exeFile = Get-ChildItem -Path $windowsBuildDir -Filter *.exe | Select-Object -First 1
    if ($exeFile) {
        Move-Item $exeFile.FullName "$androidDestDir\Scout-Ops-Android.exe" -Force
        Write-Host "Windows executable and DLLs moved to $androidDestDir"
    } else {
        Write-Host "Error: No executable found in $windowsBuildDir" -ForegroundColor Red
    }
} else {
    Write-Host "Error: Windows build folder not found at $windowsBuildDir" -ForegroundColor Red
}

Write-Host "Build process completed for Windows."

Write-Host "Current directory: $(Get-Location)"




Write-Host "Script execution completed successfully."
Set-Location "$BASE_DIR"
    