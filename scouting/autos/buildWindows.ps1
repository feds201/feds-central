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

# Build Windows target
flutter build windows

# Create MSIX package
dart run msix:create

# Copy the EXE file to the Assets folder
$exePath = "build\windows\runner\Release"
Copy-Item "$exePath\Scout-Ops-Android.exe" "$assetsDir\Scout-Ops-Android.exe" -Force
Write-Host "Windows EXE successfully copied to the Assets folder."

# Also copy any necessary DLLs and dependencies
Copy-Item "$exePath\*.dll" "$assetsDir\" -Force
Copy-Item "$exePath\data" "$assetsDir\data" -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "Windows build artifacts successfully moved to the Assets folder."
