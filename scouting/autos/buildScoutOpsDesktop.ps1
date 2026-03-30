param (
    [string]$BASE_DIR = "$PSScriptRoot\.."
)

# Navigate to the desktop-client directory
Set-Location "$BASE_DIR\desktop-client"

# Prep Node environment
Write-Host "Fetching dependencies for Scout Ops Desktop..."
npm install

# Build the desktop app
Write-Host "Building Scout Ops Desktop..."
npm run build

# Create Assets\Windows folder if it doesn't exist
$assetsDir = "$BASE_DIR\Assets"
$windowsAssetsDir = "$assetsDir\Windows"
if (-not (Test-Path -Path $windowsAssetsDir)) {
    New-Item -Path $windowsAssetsDir -ItemType Directory -Force
    Write-Host "Created Windows Assets directory at $windowsAssetsDir"
}

# Move the generated executable into the 'Assets\Windows' folder
# The path is based on the electron-packager output
$desktopExeSourceDir = "winx64\Scout_Ops_Windowsapp-win32-x64"
if (Test-Path -Path $desktopExeSourceDir) {
    Copy-Item "$desktopExeSourceDir\*" $windowsAssetsDir -Recurse -Force
    Write-Host "Scout Ops Desktop executable and files moved to $windowsAssetsDir"
} else {
    Write-Host "Error: Scout Ops Desktop build not found at $desktopExeSourceDir" -ForegroundColor Red
}

Write-Host "Build process completed for Scout Ops Desktop."
Set-Location "$BASE_DIR"
