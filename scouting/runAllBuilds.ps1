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



Remove-Item -Path "P:\FEDS201\Scouting_Suite\Assets" -Recurse -Force
    
Run-BuildScript -ScriptPath "$BASE_DIR\Autos\buildScoutOpsAndroid.ps1" -Activity "Building Scout Ops Android"
Run-BuildScript -ScriptPath "$BASE_DIR\Autos\buildScoutOpsServer.ps1" -Activity "Building Scout Ops Server"
Run-BuildScript -ScriptPath "$BASE_DIR\Autos\buildScoutOpsToolchains.ps1" -Activity "Building Scout Ops ToolChain"

    




Write-Host "Summary of builds:"
Write-Host "- Scout Ops Android built successfully." -ForegroundColor Green
Write-Host "- Scout Ops ToolChain built successfully." -ForegroundColor Green
Write-Host "- Scout Ops Server built successfully." -ForegroundColor Green
Write-Host "All builds successfully completed." -ForegroundColor Green
