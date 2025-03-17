# Script to compile Scout-Ops-Server and move executable to Assets folder

# Set paths
$sourcePath = "P:\FEDS201\Scouting_Suite\Scout-Ops-Server"
$assetsDest = "P:\FEDS201\Scouting_Suite\Assets"
$iconPath = "P:\FEDS201\Scouting_Suite\logo.ico"

# Create Assets directory if it doesn't exist
if (-not (Test-Path -Path $assetsDest)) {
    Write-Host "Creating Assets directory..."
    New-Item -ItemType Directory -Path $assetsDest -Force | Out-Null
}

# Check if PyInstaller is installed
Write-Host "Checking for PyInstaller..."
$pyInstallerInstalled = $false

# Try calling pip to check if PyInstaller is installed
try {
    $pipList = & python -m pip list
    if ($pipList -match "pyinstaller") {
        $pyInstallerInstalled = $true
    }
}
catch {
    Write-Host "Error checking for PyInstaller: $_" -ForegroundColor Yellow
}

# Install PyInstaller if not found
if (-not $pyInstallerInstalled) {
    Write-Host "PyInstaller not found. Attempting to install it..."
    try {
        & python -m pip install pyinstaller
        if ($LASTEXITCODE -eq 0) {
            Write-Host "PyInstaller installed successfully." -ForegroundColor Green
            $pyInstallerInstalled = $true
        }
    }
    catch {
        Write-Host "Error installing PyInstaller: $_" -ForegroundColor Red
    }
}

if (-not $pyInstallerInstalled) {
    Write-Host "PyInstaller is required but could not be installed or found." -ForegroundColor Red
    Write-Host "Please install it manually with: pip install pyinstaller" -ForegroundColor Yellow
    exit 1
}

# Run PyInstaller to compile the application
Write-Host "Compiling Scout-Ops-Server..."
try {
    & python -m PyInstaller --noconfirm --onefile --console --icon "$iconPath" `
        --add-data "$sourcePath\App;App/" `
        --add-data "$sourcePath\templates;templates/" `
        --add-data "$sourcePath\main.py;." `
        "$sourcePath\server.py"

    # Check if compilation was successful
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Compilation successful."
        
        # Get the executable path (PyInstaller puts it in the dist folder)
        $exePath = ".\dist\server.exe"
        
        # Check if executable was created
        if (Test-Path -Path $exePath) {
            # Move executable to Assets folder
            Write-Host "Moving executable to Assets folder..."
            
            try {
                Move-Item -Path $exePath -Destination "$assetsDest\Scout-Ops-Server.exe" -Force
                Write-Host "Executable successfully moved to $assetsDest\Scout-Ops-Server.exe"
            }
            catch {
                Write-Host "Error moving executable: $_" -ForegroundColor Red
                exit 1
            }
            
            # Clean up dist and build folders (optional)
            Write-Host "Cleaning up build files..."
            Remove-Item -Path ".\dist" -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item -Path ".\build" -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item -Path ".\*.spec" -Force -ErrorAction SilentlyContinue
            
            Write-Host "Build process completed successfully." -ForegroundColor Green
        }
        else {
            Write-Host "Error: Executable not found at $exePath" -ForegroundColor Red
            exit 1
        }
    }
    else {
        Write-Host "Compilation failed. Please check the output for errors." -ForegroundColor Red
        exit 1
    }
}
catch {
    Write-Host "Error running PyInstaller: $_" -ForegroundColor Red
    exit 1
}