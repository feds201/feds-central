param (
    [string]$BASE_DIR = "P:\FEDS201\Scouting_Suite"
)

# Navigate to the Scout-Ops-Android directory
Set-Location "$BASE_DIR\Scout-Ops-Android"

# Print the current directory for debugging
Write-Host "Current directory: $(Get-Location)"

# Build Windows target
flutter build windows

# Create MSIX package
dart run msix:create

# Move the entire 'windows' folder to the assets folder
Copy-Item "build\windows" "$BASE_DIR\assets\windows" -Recurse -Force

Write-Host "Windows build successfully moved to the assets folder."
