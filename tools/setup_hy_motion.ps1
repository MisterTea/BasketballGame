param([string]$Python = "python")
$ErrorActionPreference = "Stop"
$projectRoot = Split-Path $PSScriptRoot -Parent
$runtime = Join-Path $projectRoot '.runtime'
$upstream = Join-Path $runtime 'HY-Motion-1.0'
New-Item -ItemType Directory -Path $runtime -Force | Out-Null
New-Item -ItemType File -Path (Join-Path $runtime '.gdignore') -Force | Out-Null
if (-not (Test-Path -LiteralPath $upstream)) {
 $env:GIT_LFS_SKIP_SMUDGE = '1'
 git clone https://github.com/Tencent-Hunyuan/HY-Motion-1.0.git $upstream
 if ($LASTEXITCODE -ne 0) { throw 'HY-Motion clone failed' }
}
git -C $upstream checkout 4e426f5a1021cbcf7f375458c37b840ee7225229
if ($LASTEXITCODE -ne 0) { throw 'HY-Motion revision checkout failed' }
git -C $upstream lfs pull --include='stats/*,scripts/gradio/static/assets/dump_wooden/*.bin'
if ($LASTEXITCODE -ne 0) { throw 'HY-Motion asset download failed' }
$venv = Join-Path $runtime 'venv'
if (-not (Test-Path -LiteralPath $venv)) { & $Python -m venv --system-site-packages $venv }
$enginePython = Join-Path $venv 'Scripts/python.exe'
& $enginePython -m pip install -r (Join-Path $PSScriptRoot 'requirements-hy-motion.txt')
if ($LASTEXITCODE -ne 0) { throw 'Dependency installation failed' }
& $enginePython (Join-Path $PSScriptRoot 'download_hy_motion.py')
if ($LASTEXITCODE -ne 0) { throw 'Model download failed' }
& $enginePython (Join-Path $PSScriptRoot 'generate_hy_motion.py')
if ($LASTEXITCODE -ne 0) { throw 'Motion generation failed' }
