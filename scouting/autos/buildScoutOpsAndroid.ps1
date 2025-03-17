param (
    [string]$BASE_DIR = "P:\FEDS201\Scouting_Suite"
)

# Navigate to the Scout-Ops-Android directory
Set-Location "$BASE_DIR\Scout-Ops-Android"

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
Rename-Item "$assetsDir\app-release.apk" "$assetsDir\Scout-Ops-Android.apk" -Force

Write-Host "Android APK renamed to Scout-Ops-Android.apk."

Write-Host "Android APK build successfully moved to the Assets folder."

Write-Host "Build process completed for Android."


Set-Location "$BASE_DIR\Scout-Ops-Android"

Write-Host "Starting Windows build process..."
flutter build windows


Write-Host "Current directory: $(Get-Location)"
$windowsAssetsDir = "$assetsDir\Windows"
if (-not (Test-Path -Path $windowsAssetsDir)) {
    New-Item -Path $windowsAssetsDir -ItemType Directory -Force
    Write-Host "Created Windows Assets directory at $windowsAssetsDir"
}

Write-Host "Current directory: $(Get-Location)"

Move-Item "build\windows\x64\runner\Release\*.dll" "$windowsAssetsDir" -Force
Move-Item "build\windows\x64\runner\Release\scouting_app.exe" "$windowsAssetsDir\scouting_app.exe" -Force
Write-Host "Windows executable and DLLs moved to the Assets folder."


Write-Host "Build process completed for Windows."

Write-Host "Current directory: $(Get-Location)"




Write-Host "Script execution completed successfully."
Set-Location "$BASE_DIR"
    