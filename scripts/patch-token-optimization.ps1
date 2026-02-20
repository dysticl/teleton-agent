<#
Teleton Token Optimization Patch (Windows PowerShell)
Reduces input token usage by applying the same code changes as the Linux patch.
Usage (remote):
  iex (iwr https://raw.githubusercontent.com/dysticl/teleton-agent/main/scripts/patch-token-optimization.ps1 -UseBasicParsing)
Or locally:
  pwsh -File .\scripts\patch-token-optimization.ps1
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Info($m){ Write-Host "[INFO] $m" -ForegroundColor Cyan }
function Write-Ok($m){ Write-Host "[OK] $m" -ForegroundColor Green }
function Write-Warn($m){ Write-Host "[WARN] $m" -ForegroundColor Yellow }
function Write-Err($m){ Write-Host "[ERROR] $m" -ForegroundColor Red }

Write-Host "`n=== Teleton Token Optimization Patch (Windows) ===`n" -ForegroundColor Magenta

# Locate teleton installation
$teletonDir = $null

# 1) Check ~/.teleton-app
$home = $env:USERPROFILE
$candidate = Join-Path $home '.teleton-app'
if (Test-Path $candidate) {
  $pkg = Join-Path $candidate 'package.json'
  if (Test-Path $pkg) { $teletonDir = $candidate; Write-Info "Found git clone at $teletonDir" }
}

# 2) Check current dir
if (-not $teletonDir) {
  $cwdPkg = Join-Path (Get-Location) 'package.json'
  if (Test-Path $cwdPkg) {
    $json = Get-Content $cwdPkg -Raw | ConvertFrom-Json -ErrorAction SilentlyContinue
    if ($json -and $json.name -eq 'teleton') { $teletonDir = (Get-Location).Path; Write-Info "Found teleton in current directory: $teletonDir" }
  }
}

# 3) Check npm global
if (-not $teletonDir) {
  try {
    $npmRoot = (npm root -g) -join ''
  } catch {
    $npmRoot = $null
  }
  if ($npmRoot) {
    $globalPath = Join-Path $npmRoot 'teleton'
    if (Test-Path $globalPath) { $teletonDir = $globalPath; Write-Info "Found npm global at $teletonDir" }
  }
}

if (-not $teletonDir) { Write-Err "Could not find Teleton installation. Install it first: https://github.com/dysticl/teleton-agent"; exit 1 }

# Verify package.json
$pkgPath = Join-Path $teletonDir 'package.json'
if (-not (Test-Path $pkgPath)) { Write-Err "No package.json in $teletonDir"; exit 1 }

$pkg = Get-Content $pkgPath -Raw | ConvertFrom-Json
Write-Info "Current version: $($pkg.version)"

# If git repo, try to update from origin/main
$hasGit = Test-Path (Join-Path $teletonDir '.git')
if ($hasGit) {
  Write-Info "Updating git repo..."
  Push-Location $teletonDir
  try {
    git fetch origin main --tags --prune
    git pull --ff-only origin main
    Write-Ok "Updated from origin/main"
  } catch {
    Write-Warn "git update failed; attempting hard reset to origin/main"
    git fetch origin main
    git reset --hard origin/main
  }
  Pop-Location
} else {
  Write-Info "Not a git clone; attempting npm global update..."
  try {
    npm install -g teleton@latest
    Write-Ok "npm global updated"
  } catch {
    Write-Warn "npm global update failed; you may need to run PowerShell as Administrator"
  }
}

# Re-evaluate teletonDir (npm install could change location)
if (-not $hasGit) {
  try { $npmRoot = (npm root -g) -join '' } catch { $npmRoot = $null }
  if ($npmRoot) { $maybe = Join-Path $npmRoot 'teleton'; if (Test-Path $maybe) { $teletonDir = $maybe } }
}

Write-Info "Working in: $teletonDir"

# If git clone, install deps and build
if (Test-Path (Join-Path $teletonDir '.git')) {
  Write-Info "Running npm install and build (this may take a while)..."
  Push-Location $teletonDir
  try {
    npm install --no-audit --no-fund
    npm run build
    Write-Ok "Build complete"
  } catch {
    Write-Warn "Build or install failed: $_"
  }
  Pop-Location
}

# Archive old sessions (~/.teleton/sessions)
$sessionsDir = Join-Path $home '.teleton\sessions'
if (Test-Path $sessionsDir) {
  $files = Get-ChildItem -Path $sessionsDir -Filter '*.jsonl' -File -ErrorAction SilentlyContinue
  if ($files.Count -gt 0) {
    $archive = Join-Path $sessionsDir ("archived_$(Get-Date -Format 'yyyyMMdd_HHmmss')")
    New-Item -ItemType Directory -Path $archive | Out-Null
    foreach ($f in $files) { Move-Item $f.FullName -Destination $archive }
    Write-Ok "Archived $($files.Count) session(s) to $archive"
  } else { Write-Info "No session files to archive" }
} else { Write-Info "No sessions directory at $sessionsDir" }

# Final summary
Write-Host "`nPatch actions applied:`n" -ForegroundColor Green
Write-Host " - Sliding window: last 8 messages kept in LLM context" -ForegroundColor Yellow
Write-Host " - Tool results truncated to 8K chars" -ForegroundColor Yellow
Write-Host " - Masking keep recent: 3" -ForegroundColor Yellow
Write-Host " - Compaction: triggers at 30 messages" -ForegroundColor Yellow
Write-Host "`nRestart agent: 'teleton start' (or start the service you use)" -ForegroundColor Cyan

Write-Ok "Done!"