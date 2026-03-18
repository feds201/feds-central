# Automation script to build all applications in the Scouting Suite
# and collect them into an 'output' directory.

$ROOT_DIR = Get-Location
$OUTPUT_DIR = Join-Path $ROOT_DIR "output"

# Create output directory
if (Test-Path -Path $OUTPUT_DIR) {
    # If the directory exists, we clear it. If it fails (e.g., file open), we warn and continue.
    try {
        Remove-Item -Path $OUTPUT_DIR -Recurse -Force -ErrorAction Stop
    } catch {
        Write-Warning "Could not clear output directory. Some files might be in use."
    }
}
if (-not (Test-Path -Path $OUTPUT_DIR)) {
    New-Item -ItemType Directory -Path $OUTPUT_DIR -Force | Out-Null
}
Write-Host "Created output directory at $OUTPUT_DIR"

function Build-FlutterApp {
    param (
        [string]$Path,
        [string]$Name,
        [bool]$BuildWindows = $true
    )
    Write-Host "`n--- Building Flutter app: $Name at $Path ---"
    Push-Location $Path
    
    # Android APK
    Write-Host "Building Android APK..."
    flutter build apk --no-tree-shake-icons
    if ($LASTEXITCODE -eq 0) {
        $apkSource = "build\app\outputs\flutter-apk\app-release.apk"
        $apkDest = Join-Path $OUTPUT_DIR "$Name-Android.apk"
        Copy-Item $apkSource $apkDest -Force
        Write-Host "Copied APK to $apkDest"
    } else {
        Write-Error "Failed to build Android APK for $Name"
    }

    # Windows
    if ($BuildWindows) {
        Write-Host "Building Windows Executable..."
        flutter build windows
        if ($LASTEXITCODE -eq 0) {
            $winOutputDir = Join-Path $OUTPUT_DIR "$Name-Windows"
            New-Item -ItemType Directory -Path $winOutputDir -Force | Out-Null
            $sourceWinDir = "build\windows\x64\runner\Release"
            Copy-Item "$sourceWinDir\*" $winOutputDir -Recurse -Force
            Write-Host "Copied Windows build to $winOutputDir"
        } else {
            Write-Error "Failed to build Windows app for $Name"
        }
    }
    
    Pop-Location
}

function Build-ElectronApp {
    param (
        [string]$Path,
        [string]$Name
    )
    Write-Host "`n--- Building Electron app: $Name at $Path ---"
    Push-Location $Path
    
    # Ensure dependencies are installed
    Write-Host "Installing NPM dependencies..."
    npm install
    
    # Run build script defined in package.json
    Write-Host "Running electron-packager via npm run build..."
    npm run build
    if ($LASTEXITCODE -eq 0) {
        $electronOutputDir = Join-Path $OUTPUT_DIR "$Name"
        New-Item -ItemType Directory -Path $electronOutputDir -Force | Out-Null
        # Assuming build output goes to winx64 as per package.json
        if (Test-Path -Path "winx64") {
            Copy-Item "winx64\*" $electronOutputDir -Recurse -Force
            Write-Host "Copied Electron build to $electronOutputDir"
        } else {
             Write-Error "Expected 'winx64' folder after build not found in $Path"
        }
    } else {
        Write-Error "Failed to build Electron app $Name"
    }
    
    Pop-Location
}

function Build-PythonApp {
    param (
        [string]$Path,
        [string]$EntryFile,
        [string]$Name,
        [string[]]$AddData = @()
    )
    Write-Host "`n--- Building Python app: $Name at $Path ---"
    Push-Location $Path
    
    # Install requirements
    if (Test-Path -Path "requirements.txt") {
        Write-Host "Installing Python requirements..."
        python -m pip install -r requirements.txt
    }

    # Ensure PyInstaller is installed
    python -m pip install pyinstaller | Out-Null
    
    $args = @("--noconfirm", "--onefile", "--console", "--name", $Name)
    foreach ($data in $AddData) {
        $args += "--add-data"
        $args += $data
    }
    $args += $EntryFile
    
    Write-Host "Running PyInstaller..."
    python -m PyInstaller @args
    
    if ($LASTEXITCODE -eq 0) {
        $exeSource = Join-Path "dist" "$Name.exe"
        $exeDest = Join-Path $OUTPUT_DIR "$Name.exe"
        Copy-Item $exeSource $exeDest -Force
        Write-Host "Copied Python EXE to $exeDest"
        
        # Cleanup
        Remove-Item -Path "dist" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "build" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "*.spec" -Force -ErrorAction SilentlyContinue
    } else {
        Write-Error "Failed to build Python app $Name"
    }
    
    Pop-Location
}

# 1. Build Android Flutter App
Build-FlutterApp -Path "android" -Name "Scout-Ops-Android"

# 2. Build Scan Flutter App (No windows build requested for scan typically)
Build-FlutterApp -Path "scan" -Name "Scout-Ops-Scan" -BuildWindows $false

# 3. Build Desktop Client (Electron)
Build-ElectronApp -Path "desktop-client" -Name "Scout-Ops-Desktop"

# 4. Build Server (Python)
Build-PythonApp -Path "server" -EntryFile "server.py" -Name "Scout-Ops-Server" -AddData @("templates;templates/", "static;static/", "main.py;.")

# 5. Build Toolchains (Python)
Build-PythonApp -Path "toolchains" -EntryFile "cache.py" -Name "Scout-Ops-ToolChain-Analysis"
Build-PythonApp -Path "toolchains" -EntryFile "adit.py" -Name "Scout-Ops-ToolChain-Blue-Analysis"

Write-Host "`nAll builds completed. Check the 'output' directory." -ForegroundColor Green
