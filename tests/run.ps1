param([string]$Godot = "godot", [switch]$Capture)
$ErrorActionPreference = "Stop"
$projectRoot = Split-Path $PSScriptRoot -Parent
& $Godot --headless --path $projectRoot --editor --quit
& $Godot --headless --path $projectRoot --script res://tests/simulation.gd
if ($LASTEXITCODE -ne 0) { throw "Simulation tests failed" }
& $Godot --headless --path $projectRoot --script res://tests/arena_3d.gd
if ($LASTEXITCODE -ne 0) { throw "3D arena tests failed" }
& $Godot --headless --path $projectRoot --script res://tests/hy_motion.gd
if ($LASTEXITCODE -ne 0) { throw "HY-Motion rig and playback tests failed" }
$processes = @()
try {
 for ($i = 0; $i -lt 4; $i++) {
  $arguments = @('--headless','--path',('"' + $projectRoot + '"'),'--script','res://tests/network_peer.gd')
  if ($i -eq 0) { $arguments += @('--','--host') }
  $log = Join-Path $projectRoot "tests/network-$i.log"
  $errLog = Join-Path $projectRoot "tests/network-$i-error.log"
  $processes += Start-Process -FilePath $Godot -ArgumentList $arguments -PassThru -WindowStyle Hidden -RedirectStandardOutput $log -RedirectStandardError $errLog
  if ($i -eq 0) { Start-Sleep -Milliseconds 1000 }
 }
 foreach ($process in $processes) {
  if (-not $process.WaitForExit(20000)) { throw "Network peer timed out" }
  if ($process.ExitCode -ne 0) { throw "Network peer failed: inspect tests/network-*.log" }
 }
 Get-Content (Join-Path $projectRoot 'tests/network-*.log')
 $errors = Get-Content (Join-Path $projectRoot "tests/network-*-error.log") -Raw
 if ($errors -match "ERROR|SCRIPT ERROR") { throw "Godot reported errors during the network test" }
} finally {
 foreach ($process in $processes) {
  if (-not $process.HasExited) { Stop-Process -Id $process.Id }
 }
}
if ($Capture) {
 & $Godot --path $projectRoot --script res://tests/capture.gd
 if ($LASTEXITCODE -ne 0) { throw "Render test failed" }
}

