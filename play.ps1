param(
    [string]$Godot = "",
    [Alias("Quick", "qp", "q")]
    [switch]$QuickPlay,
    [switch]$Bot,
    [float]$Duration = 0,
    [float]$Seconds = 0,
    [string]$Record = "",
    [int]$HomeTeam = -1,
    [int]$AwayTeam = -1,
    [string]$Teams = ""
)
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

$godotExeArgs = @('--path', $PSScriptRoot)
$userArgs = @()

$tempAvi = ""
if ($Record) {
    $resolvedRecord = [System.IO.Path]::GetFullPath($Record)
    $tempAvi = if ($resolvedRecord -like "*.mp4") { [System.IO.Path]::ChangeExtension($resolvedRecord, ".avi") } else { $resolvedRecord }
    if (Test-Path $tempAvi) { Remove-Item $tempAvi -Force }
    $godotExeArgs += @('--write-movie', $tempAvi, '--fixed-fps', '60', '--disable-vsync')
    $QuickPlay = $true
}

if ($QuickPlay -or $HomeTeam -ge 0 -or $AwayTeam -ge 0 -or (-not [string]::IsNullOrWhiteSpace($Teams))) {
    $userArgs += @('--quickplay')
    if ($HomeTeam -ge 0) { $userArgs += @('--home', $HomeTeam.ToString()) }
    if ($AwayTeam -ge 0) { $userArgs += @('--away', $AwayTeam.ToString()) }
    if (-not [string]::IsNullOrWhiteSpace($Teams)) { $userArgs += @('--teams', $Teams) }
}
if ($Bot) {
    $userArgs += @('--bot')
}
if ($Duration -gt 0) {
    $userArgs += @('--record-duration', $Duration.ToString())
}
if ($Seconds -gt 0) {
    $userArgs += @('--seconds', $Seconds.ToString())
}

$launchArgs = $godotExeArgs
if ($userArgs.Count -gt 0) {
    $launchArgs += @('--') + $userArgs
}

& $Godot @launchArgs

if ($Record -and ($Record -like "*.mp4") -and (Test-Path $tempAvi)) {
    Write-Host "Encoding $Record with ffmpeg..." -ForegroundColor Cyan
    $ffmpeg = Get-Command ffmpeg -ErrorAction SilentlyContinue
    if ($ffmpeg) {
        if (Test-Path $Record) { Remove-Item $Record -Force }
        & $ffmpeg.Source -y -i $tempAvi -c:v libx264 -pix_fmt yuv420p -preset fast -crf 22 -c:a aac -b:a 192k $Record
        Remove-Item $tempAvi -Force -ErrorAction SilentlyContinue
        Write-Host "Recording saved to $Record" -ForegroundColor Green
    } else {
        Write-Host "ffmpeg not found; raw AVI preserved at $tempAvi" -ForegroundColor Yellow
    }
}
