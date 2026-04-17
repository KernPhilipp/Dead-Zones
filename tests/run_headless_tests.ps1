param(
    [string]$GodotExe = "Godot_v4.6.1-stable_mono_win64.exe",
    [int]$Seed = 1337,
    [string]$Groups = ""
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
$reportPath = Join-Path $projectRoot "tests\reports\latest_headless_report.json"

if (-not (Test-Path $GodotExe)) {
    throw "Godot executable not found: $GodotExe"
}

$args = @(
    "--headless"
    "--scene"
    "res://tests/headless_test_runner.tscn"
    "--"
    "--seed=$Seed"
)

if ($Groups -and $Groups.Trim().Length -gt 0) {
    $args += "--groups=$Groups"
}

Push-Location $projectRoot
try {
    & $GodotExe @args
    $rawExitCode = $LASTEXITCODE
    if ($null -eq $rawExitCode) {
        $exitCode = 0
    } else {
        $exitCode = [int]$rawExitCode
    }
}
finally {
    Pop-Location
}

Write-Host "Headless tests exit code: $exitCode"
if (Test-Path $reportPath) {
    Write-Host "Report: $reportPath"
}

exit $exitCode
