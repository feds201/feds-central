param (
    [string]$BASE_DIR = "P:\FEDS201\Scouting_Suite"
)

# Navigate to the Scout-Ops-Android directory
Set-Location "$BASE_DIR\Scout-Ops-Android"

# Print the current directory for debugging
Write-Host "Current directory: $(Get-Location)"

# Build APK for release
flutter build apk --release

# Move the generated APK into the 'assets' folder
Move-Item "build\app\outputs\flutter-apk\app-release.apk" "$BASE_DIR\assets\app-release.apk"

Write-Host "Android APK build successfully moved to the assets folder."
