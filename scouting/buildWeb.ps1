param (
    [string]$BASE_DIR = "P:\FEDS201\Scouting_Suite"
)

# Navigate to the Scout-Ops-Android directory
Set-Location "$BASE_DIR\Scout-Ops-Android"

# Print the current directory for debugging
Write-Host "Current directory: $(Get-Location)"

# Build Web target
flutter build web

# Move the entire 'web' folder to the assets folder
Copy-Item "build\web" "$BASE_DIR\assets\web" -Recurse -Force

Write-Host "Web build successfully moved to the assets folder."
