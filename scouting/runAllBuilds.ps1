param (
    [string]$BASE_DIR = "P:\FEDS201\Scouting_Suite"
)

function Show-Progress {
    param (
        [string]$Activity,
        [int]$PercentComplete
    )
    Write-Progress -Activity $Activity -PercentComplete $PercentComplete
}

function Run-BuildScript {
    param (
        [string]$ScriptPath,
        [string]$Activity
    )
    Write-Host "Running $Activity..."
    for ($i = 0; $i -le 100; $i += 20) {
        Show-Progress -Activity $Activity -PercentComplete $i
        Start-Sleep -Seconds 1
    }
    & $ScriptPath
    Write-Host "$Activity completed."
}

# Run Android build
Run-BuildScript -ScriptPath "$BASE_DIR\buildAndroid.ps1" -Activity "Building Android APK"

# Run Web build
Run-BuildScript -ScriptPath "$BASE_DIR\buildWeb.ps1" -Activity "Building Web"

# Run Windows build
Run-BuildScript -ScriptPath "$BASE_DIR\buildWindows.ps1" -Activity "Building Windows"

# Run Scout-Ops server build
Run-BuildScript -ScriptPath "$BASE_DIR\Scout-Ops-Server\generateExe.bat" -Activity "Building Scout-Ops Server"

# Run Scout-Ops client build
Run-BuildScript -ScriptPath "$BASE_DIR\Scout-Ops-Client\buildClient.bat" -Activity "Building Scout-Ops Client"

Write-Host "All builds successfully completed."
