<#
.SYNOPSIS
    Rebuilds the Godot project and launches Rim Rumble.

.DESCRIPTION
    1. Locates Godot 4.5.1+ (from PATH or portable installation in Temp\jam-godot).
    2. (Re)builds the project: runs Godot in headless editor mode to compile all
       GDScript scripts, reimport updated assets/textures/models, and refresh caches.
    3. Launches the freshly built game in its own window.

.PARAMETER Clean
    If specified, clears the .godot/ cache directory first for a full clean rebuild.

.PARAMETER Console
    If specified, launches with the engine console attached for debug output.

.PARAMETER Wait
    If specified, keeps the PowerShell window open until the game process exits.

.PARAMETER Godot
    Optional path to a specific Godot executable.
#>
param(
    [string]$Godot = "",
    [switch]$Clean,
    [switch]$Console,
    [switch]$Wait
)

$ErrorActionPreference = "Stop"
$projectRoot = $PSScriptRoot

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "    Rim Rumble - Build and Launch       " -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

# Step 1: Locate Godot engine
if (-not $Godot) {
    # Check PATH first
    foreach ($name in @('godot', 'godot4', 'godot_console')) {
        $found = Get-Command $name -ErrorAction SilentlyContinue
        if ($found) {
            $Godot = $found.Source
            break
        }
    }
}

if (-not $Godot) {
    # Check portable cache in LocalAppData\Temp\jam-godot
    $portableDir = Join-Path $env:LOCALAPPDATA 'Temp\jam-godot'
    if (Test-Path $portableDir) {
        $filter = if ($Console) { 'Godot*_console.exe' } else { 'Godot*_win64.exe' }
        $engine = Get-ChildItem -LiteralPath $portableDir -Filter $filter -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -notmatch '_console\.exe' -or $Console } |
            Select-Object -First 1

        if (-not $engine) {
            $engine = Get-ChildItem -LiteralPath $portableDir -Filter 'Godot*.exe' -ErrorAction SilentlyContinue | Select-Object -First 1
        }
        if ($engine) { $Godot = $engine.FullName }
    }
}

if (-not $Godot -or -not (Test-Path $Godot)) {
    throw "Godot 4.5.1+ executable not found. Pass -Godot 'C:\path\to\godot.exe'."
}

Write-Host "Engine: $Godot" -ForegroundColor Gray

# Step 2: Clean build cache if requested
if ($Clean) {
    $godotCache = Join-Path $projectRoot ".godot"
    if (Test-Path $godotCache) {
        Write-Host "Performing clean build: removing .godot cache..." -ForegroundColor Yellow
        Remove-Item -Path $godotCache -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# Step 3: (Re)build the Godot project
# Running Godot in headless editor mode triggers full script parsing, compilation,
# resource reimporting, and class cache updates.
$godotConsole = if ($Godot -match '_console\.exe$') {
    $Godot
} else {
    $alt = $Godot -replace '\.exe$', '_console.exe'
    if (Test-Path $alt) { $alt } else { $Godot }
}

Write-Host "Rebuilding Godot project (compiling scripts and reimporting assets)..." -ForegroundColor Yellow

$buildArgs = @("--headless", "--path", $projectRoot, "--editor", "--quit")
$buildProc = Start-Process -FilePath $godotConsole -ArgumentList $buildArgs -WorkingDirectory $projectRoot -PassThru -NoNewWindow -Wait

if ($buildProc.ExitCode -ne 0) {
    throw "Godot rebuild failed with exit code $($buildProc.ExitCode)."
}

Write-Host "Build complete!" -ForegroundColor Green

# Step 4: Choose windowed executable for smooth play (unless -Console requested)
$launchExe = $Godot
if (-not $Console -and ($launchExe -match '_console\.exe$')) {
    $windowed = $launchExe -replace '_console\.exe$', '.exe'
    if (Test-Path $windowed) {
        $launchExe = $windowed
    }
}

# Step 5: Launch the rebuilt game
Write-Host "Launching Rim Rumble..." -ForegroundColor Cyan
$gameArgs = @("--path", $projectRoot)

$process = Start-Process -FilePath $launchExe -ArgumentList $gameArgs -WorkingDirectory $projectRoot -PassThru

Write-Host "Game running! (PID: $($process.Id))" -ForegroundColor Green
Write-Host ""
Write-Host "Controls:" -ForegroundColor Cyan
Write-Host "  Move:      W A S D (or Gamepad Left Stick / D-Pad)"
Write-Host "  Shoot:     J (or Gamepad X / Y)"
Write-Host "  Pass:      K (or Gamepad A / B)"
Write-Host "  Turbo:     Space (or Gamepad RT / RB)"
Write-Host "  Switch:    Tab (or Gamepad LB / LT)"
Write-Host "  Pause:     Escape (or Gamepad Start)"
Write-Host ""

if ($Wait) {
    Write-Host "Waiting for game to exit..." -ForegroundColor Gray
    $process.WaitForExit()
}
