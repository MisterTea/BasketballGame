param([string]$Godot = "godot", [switch]$Capture)
$ErrorActionPreference = "Stop"
$projectRoot = Split-Path $PSScriptRoot -Parent
& $Godot --headless --path $projectRoot --editor --quit
if ($LASTEXITCODE -ne 0) { throw "Editor import failed" }
& $Godot --headless --path $projectRoot --script res://tests/simulation.gd
if ($LASTEXITCODE -ne 0) { throw "Simulation tests failed" }
& $Godot --headless --path $projectRoot --script res://tests/tipoff.gd
if ($LASTEXITCODE -ne 0) { throw "Tip-off tests failed" }
& $Godot --headless --path $projectRoot --script res://tests/arcade_rules.gd
if ($LASTEXITCODE -ne 0) { throw "Arcade rules tests failed" }
& $Godot --headless --path $projectRoot --script res://tests/finishing.gd
if ($LASTEXITCODE -ne 0) { throw "Finishing and passing tests failed" }
& $Godot --headless --path $projectRoot --script res://tests/alley_oop.gd
if ($LASTEXITCODE -ne 0) { throw "Coordinated alley-oop tests failed" }
& $Godot --headless --path $projectRoot --script res://tests/backboards.gd
if ($LASTEXITCODE -ne 0) { throw "Backboard tests failed" }
& $Godot --headless --path $projectRoot --script res://tests/arena_3d.gd
if ($LASTEXITCODE -ne 0) { throw "3D arena tests failed" }
& $Godot --headless --path $projectRoot --script res://tests/hy_motion.gd
if ($LASTEXITCODE -ne 0) { throw "HY-Motion rig and playback tests failed" }
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
   if (-not $process.WaitForExit(20000)) { throw "Network peer timed out" }
   if ($process.ExitCode -ne 0) { throw ("Network peer failed: inspect tests/" + $scenario.Script + "-*.log") }
  }
  Get-Content (Join-Path $projectRoot ("tests/" + $scenario.Script + "-*.log"))
  $errors = Get-Content (Join-Path $projectRoot ("tests/" + $scenario.Script + "-*-error.log")) -Raw
  if ($errors -match "ERROR|SCRIPT ERROR") { throw "Godot reported errors during the network test" }
 } finally {
  foreach ($process in $processes) {
   if (-not $process.HasExited) { Stop-Process -Id $process.Id }
  }
 }
}
if ($Capture) {
 & $Godot --path $projectRoot --script res://tests/capture.gd
 if ($LASTEXITCODE -ne 0) { throw "Render test failed" }
}

