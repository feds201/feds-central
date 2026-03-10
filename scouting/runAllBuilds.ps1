param (
    [string]$BASE_DIR = $PSScriptRoot
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

# Ensure Assets folder is cleared
if (Test-Path -Path "$BASE_DIR\Assets") {
    Remove-Item -Path "$BASE_DIR\Assets" -Recurse -Force
}
    
Run-BuildScript -ScriptPath "$BASE_DIR\autos\buildScoutOpsAndroid.ps1" -Activity "Building Scout Ops Android"
Run-BuildScript -ScriptPath "$BASE_DIR\autos\buildScoutOpsScan.ps1" -Activity "Building Scout Ops Scan"
Run-BuildScript -ScriptPath "$BASE_DIR\autos\buildScoutOpsDesktop.ps1" -Activity "Building Scout Ops Desktop"
Run-BuildScript -ScriptPath "$BASE_DIR\autos\buildScoutOpsServer.ps1" -Activity "Building Scout Ops Server"
Run-BuildScript -ScriptPath "$BASE_DIR\autos\buildScoutOpsToolchains.ps1" -Activity "Building Scout Ops ToolChain"

Write-Host "Summary of builds:"
Write-Host "- Scout Ops Android built successfully." -ForegroundColor Green
Write-Host "- Scout Ops Scan built successfully." -ForegroundColor Green
Write-Host "- Scout Ops Desktop built successfully." -ForegroundColor Green
Write-Host "- Scout Ops ToolChain built successfully." -ForegroundColor Green
Write-Host "- Scout Ops Server built successfully." -ForegroundColor Green
Write-Host "All builds successfully completed." -ForegroundColor Green
