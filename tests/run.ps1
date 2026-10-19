param([string]$Godot = "godot", [switch]$Capture)
$ErrorActionPreference = "Stop"

if (-not (Get-Command $Godot -ErrorAction SilentlyContinue)) {
    $portable = Join-Path $env:LOCALAPPDATA 'Temp\jam-godot\Godot_v4.5.1-stable_win64_console.exe'
    if (Test-Path $portable) { $Godot = $portable }
}
$projectRoot = Split-Path $PSScriptRoot -Parent

# =========================================================================
# 10-MINUTE GLOBAL WATCHDOG
# Kills all child Godot processes and exits if total run exceeds 10 minutes.
# =========================================================================
$parentPid = $PID
$watchdogJob = Start-Job -ScriptBlock {
    param($targetPid, $maxSeconds)
    Start-Sleep -Seconds $maxSeconds
    $proc = Get-Process -Id $targetPid -ErrorAction SilentlyContinue
    if ($proc -and -not $proc.HasExited) {
        Write-Host "`n[WATCHDOG TRIGGERED] Test suite exceeded 10-minute maximum timeout ($maxSeconds seconds). Aborting all tests!" -ForegroundColor Red
        Get-Process | Where-Object { $_.Name -like "*Godot*" } | Stop-Process -Force -ErrorAction SilentlyContinue
        Stop-Process -Id $targetPid -Force -ErrorAction SilentlyContinue
    }
} -ArgumentList $parentPid, 600

function Run-GodotTest {
    param(
        [string]$ScriptPath,
        [int]$TimeoutSeconds = 45,
        [string]$Description = ""
    )
    if ([string]::IsNullOrWhiteSpace($Description)) {
        $Description = $ScriptPath
    }
    $argsList = @('--headless', '--path', $projectRoot, '--script', $ScriptPath)
    $proc = Start-Process -FilePath $Godot -ArgumentList $argsList -PassThru -NoNewWindow
    if (-not $proc.WaitForExit($TimeoutSeconds * 1000)) {
        try { Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue } catch {}
        throw "[TIMEOUT ERROR] Test '$Description' timed out after $TimeoutSeconds seconds without exiting."
    }
    if ($proc.ExitCode -ne 0) {
        throw "[TEST FAILURE] Test '$Description' failed with exit code $($proc.ExitCode)."
    }
}

try {
    # 1. Editor Import (allow 90s for asset scanning)
    $importProc = Start-Process -FilePath $Godot -ArgumentList @('--headless', '--path', $projectRoot, '--editor', '--quit') -PassThru -NoNewWindow
    if (-not $importProc.WaitForExit(90000)) {
        try { Stop-Process -Id $importProc.Id -Force -ErrorAction SilentlyContinue } catch {}
        throw "[TIMEOUT ERROR] Editor asset import timed out after 90 seconds."
    }
    if ($importProc.ExitCode -ne 0) { throw "Editor import failed with exit code $($importProc.ExitCode)" }

    # 2. Standalone Unit Tests (each protected by timeout)
    Run-GodotTest "res://tests/simulation.gd" 45 "Simulation tests"
    Run-GodotTest "res://tests/tipoff.gd" 45 "Tip-off tests"
    Run-GodotTest "res://tests/arcade_rules.gd" 45 "Arcade rules tests"
    Run-GodotTest "res://tests/shot_percentage.gd" 45 "Shot percentage tests"
    Run-GodotTest "res://tests/finishing.gd" 45 "Finishing and passing tests"
    Run-GodotTest "res://tests/alley_oop.gd" 45 "Coordinated alley-oop tests"
    Run-GodotTest "res://tests/backboards.gd" 45 "Backboard tests"
    Run-GodotTest "res://tests/arena_3d.gd" 45 "3D arena tests"
    Run-GodotTest "res://tests/hy_motion.gd" 45 "HY-Motion rig and playback tests"
    Run-GodotTest "res://tests/gamepad.gd" 45 "Gamepad tests"
    Run-GodotTest "res://tests/arcade_mechanics_update.gd" 45 "Arcade mechanics update tests"
    Run-GodotTest "res://tests/arcade_mechanics_pass2.gd" 45 "Arcade mechanics pass 2 tests"
    Run-GodotTest "res://tests/arcade_mechanics_pass3.gd" 45 "Arcade mechanics pass 3 tests"
    Run-GodotTest "res://tests/arcade_mechanics_pass4.gd" 45 "Arcade mechanics pass 4 tests"
    Run-GodotTest "res://tests/arcade_mechanics_pass5.gd" 45 "Arcade mechanics pass 5 tests"

    # 3. Multiplayer Network Peer Tests
    foreach ($scenario in @(@{ Script = "network_peer"; Peers = 4 }, @{ Script = "network_actions"; Peers = 2 }, @{ Script = "network_tipoff"; Peers = 2 }, @{ Script = "network_alley"; Peers = 4 })) {
        $processes = @()
        try {
            for ($i = 0; $i -lt $scenario.Peers; $i++) {
                $arguments = @('--headless','--path',('"' + $projectRoot + '"'),'--script',("res://tests/" + $scenario.Script + ".gd"))
                if ($i -eq 0) { $arguments += @('--','--host') }
                $log = Join-Path $projectRoot ("tests/" + $scenario.Script + "-$i.log")
                $errLog = Join-Path $projectRoot ("tests/" + $scenario.Script + "-$i-error.log")
                $processes += Start-Process -FilePath $Godot -ArgumentList $arguments -PassThru -WindowStyle Hidden -RedirectStandardOutput $log -RedirectStandardError $errLog
                if ($i -eq 0) { Start-Sleep -Milliseconds 1000 }
            }
            foreach ($process in $processes) {
                if (-not $process.WaitForExit(20000)) {
                    try { Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue } catch {}
                    throw "Network peer timed out in scenario $($scenario.Script)"
                }
                if ($null -ne $process.ExitCode -and $process.ExitCode -ne 0) {
                    throw ("Network peer failed in scenario $($scenario.Script): inspect tests/" + $scenario.Script + "-*.log")
                }
            }
            Get-Content (Join-Path $projectRoot ("tests/" + $scenario.Script + "-*.log"))
            $errors = Get-Content (Join-Path $projectRoot ("tests/" + $scenario.Script + "-*-error.log")) -Raw
            if ($errors -match "ERROR|SCRIPT ERROR") {
                throw "Godot reported errors during the network test scenario $($scenario.Script)"
            }
        } finally {
            foreach ($process in $processes) {
                if (-not $process.HasExited) { Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue }
            }
        }
    }

    if ($Capture) {
        Run-GodotTest "res://tests/capture.gd" 60 "Render capture test"
    }

    Write-Host "`nALL TEST SUITES PASSED SUCCESSFULLY!" -ForegroundColor Green
}
finally {
    if ($watchdogJob) {
        Stop-Job -Job $watchdogJob -ErrorAction SilentlyContinue
        Remove-Job -Job $watchdogJob -Force -ErrorAction SilentlyContinue
    }
}
