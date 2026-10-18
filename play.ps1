param([string]$Godot = "")
$ErrorActionPreference = "Stop"
if (-not $Godot) {
 foreach ($name in @('godot','godot4','godot_console')) {
  $command = Get-Command $name -ErrorAction SilentlyContinue
  if ($command) { $Godot = $command.Source; break }
 }
}
if (-not $Godot) {
 $portable = Join-Path $env:LOCALAPPDATA 'Temp\jam-godot'
 $engine = Get-ChildItem -LiteralPath $portable -Filter 'Godot*_console.exe' -ErrorAction SilentlyContinue | Select-Object -First 1
 if ($engine) { $Godot = $engine.FullName }
}
if (-not $Godot) { throw "Install Godot 4.5.1+ or pass -Godot 'C:/path/to/godot.exe'." }
& $Godot --path $PSScriptRoot
