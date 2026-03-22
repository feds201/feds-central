param (
    [string]$BASE_DIR = "$PSScriptRoot\.."
)

# Navigate to the scan directory
Set-Location "$BASE_DIR\scan"

# Prep Flutter environment
Write-Host "Cleaning and fetching dependencies for Scout Ops Scan..."
flutter clean
flutter pub get

# Create Assets folder if it doesn't exist
$assetsDir = "$BASE_DIR\Assets"
if (-not (Test-Path -Path $assetsDir)) {
    New-Item -Path $assetsDir -ItemType Directory -Force
    Write-Host "Created Assets directory at $assetsDir"
}

# Build APK for release
Write-Host "Building Android APK for Scout Ops Scan..."
flutter build apk --no-tree-shake-icons

# Move the generated APK into the 'Assets' folder
$apkSource = "build\app\outputs\flutter-apk\app-release.apk"
if (Test-Path -Path $apkSource) {
    Move-Item $apkSource "$assetsDir\Scout-Ops-Scan.apk" -Force
    Write-Host "Scout Ops Scan APK moved to $assetsDir\Scout-Ops-Scan.apk"
} else {
    Write-Host "Error: Scout Ops Scan APK not found at $apkSource" -ForegroundColor Red
}

# Build Windows for release
Write-Host "Starting Windows build process for Scout Ops Scan..."
flutter build windows

# Create Assets\Windows folder if it doesn't exist
$windowsAssetsDir = "$assetsDir\Windows"
if (-not (Test-Path -Path $windowsAssetsDir)) {
    New-Item -Path $windowsAssetsDir -ItemType Directory -Force
    Write-Host "Created Windows Assets directory at $windowsAssetsDir"
}

# Move the generated Windows executable and DLLs into the 'Assets\Windows' folder
$windowsBuildDir = "build\windows\x64\runner\Release"
if (Test-Path -Path $windowsBuildDir) {
    # We'll put it in a subfolder or rename to avoid conflict with Scout Ops Android's scouting_app.exe
    $scanDestDir = "$windowsAssetsDir\Scout-Ops-Scan"
    if (-not (Test-Path -Path $scanDestDir)) {
        New-Item -Path $scanDestDir -ItemType Directory -Force
    }
    Copy-Item "$windowsBuildDir\*.dll" $scanDestDir -Force
    Copy-Item "$windowsBuildDir\*.exe" "$scanDestDir\Scout-Ops-Scan.exe" -Force
    Write-Host "Scout Ops Scan Windows executable and DLLs moved to $scanDestDir"
} else {
    Write-Host "Error: Scout Ops Scan Windows build not found at $windowsBuildDir" -ForegroundColor Red
}

Write-Host "Build process completed for Scout Ops Scan."
Set-Location "$BASE_DIR"
