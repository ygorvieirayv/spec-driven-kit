<#
  Safe installer for Spec Driven Kit.
  ASCII-only on purpose: Windows PowerShell 5.1 reads .ps1 without BOM as ANSI.
#>

param(
  [string]$Target = ".",
  [switch]$DryRun,
  [switch]$Force,
  [switch]$Yes,
  [Alias("h")]
  [switch]$Help
)

$ErrorActionPreference = "Stop"

function Show-Usage {
  Write-Host "Usage: ./install.ps1 [-Target <dir>] [-DryRun] [-Force] [-Yes] [-h]"
  Write-Host ""
  Write-Host "Options:"
  Write-Host "  -Target <dir>  Destination project directory (default: current directory)."
  Write-Host "  -DryRun        Print the plan without writing anything."
  Write-Host "  -Force         Overwrite divergent ENGINE files only, after .sdk-bak timestamp backup."
  Write-Host "  -Yes           Non-interactive safe defaults; create missing target and skip conflicts."
  Write-Host "  -h             Show this help."
}

if ($Help) {
  Show-Usage
  exit 0
}

$Root = (Resolve-Path (Join-Path $PSScriptRoot ".")).Path
$Manifest = Join-Path $Root "scripts\kit-manifest.txt"
if (-not (Test-Path $Manifest)) {
  throw "Missing manifest: $Manifest"
}

$script:Copied = 0
$script:Skipped = 0
$script:Conflicts = 0
$script:Backups = 0
$script:Sidecars = 0

function Full-Path($path) {
  return [System.IO.Path]::GetFullPath($path)
}

function Ensure-Parent($path) {
  $parent = Split-Path -Parent $path
  if ($parent -and -not (Test-Path $parent)) {
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
  }
}

function Same-File($a, $b) {
  if (-not (Test-Path $a) -or -not (Test-Path $b)) { return $false }
  $ha = (Get-FileHash -Algorithm SHA256 -LiteralPath $a).Hash
  $hb = (Get-FileHash -Algorithm SHA256 -LiteralPath $b).Hash
  return $ha -eq $hb
}

function Unique-Path($base) {
  if (-not (Test-Path $base)) { return $base }
  $i = 1
  while (Test-Path "$base.$i") { $i++ }
  return "$base.$i"
}

function Copy-KitFile($src, $dst) {
  if ($DryRun) {
    Write-Host "DRY-RUN copy $src -> $dst"
  } else {
    Ensure-Parent $dst
    Copy-Item -LiteralPath $src -Destination $dst -Force
  }
  $script:Copied++
}

function Copy-Sidecar($src, $dst) {
  $sidecar = Unique-Path "$dst.sdk-new"
  if ($DryRun) {
    Write-Host "DRY-RUN sidecar $src -> $sidecar"
  } else {
    Ensure-Parent $sidecar
    Copy-Item -LiteralPath $src -Destination $sidecar -Force
  }
  $script:Sidecars++
}

function Backup-And-Overwrite($src, $dst) {
  $stamp = Get-Date -Format "yyyyMMddHHmmss"
  $backup = Unique-Path "$dst.sdk-bak.$stamp"
  if ($DryRun) {
    Write-Host "DRY-RUN backup $dst -> $backup"
    Write-Host "DRY-RUN overwrite $dst"
  } else {
    Ensure-Parent $backup
    Copy-Item -LiteralPath $dst -Destination $backup -Force
    Copy-Item -LiteralPath $src -Destination $dst -Force
  }
  $script:Backups++
  $script:Copied++
}

$targetExists = Test-Path $Target
if ($targetExists) {
  $TargetAbs = (Resolve-Path $Target).Path
} else {
  $parent = Split-Path -Parent $Target
  if ([string]::IsNullOrWhiteSpace($parent)) { $parent = "." }
  if (-not (Test-Path $parent)) { throw "Target parent does not exist: $parent" }
  $TargetAbs = Join-Path (Resolve-Path $parent).Path (Split-Path -Leaf $Target)
  if ($DryRun) {
    Write-Host "DRY-RUN would create target directory: $TargetAbs"
  } elseif ($Yes) {
    New-Item -ItemType Directory -Force -Path $TargetAbs | Out-Null
    Write-Host "Created target directory: $TargetAbs"
  } elseif ([Environment]::UserInteractive) {
    $answer = Read-Host "Target does not exist. Create '$TargetAbs'? [y/N]"
    if ($answer -match '^(y|yes)$') {
      New-Item -ItemType Directory -Force -Path $TargetAbs | Out-Null
    } else {
      Write-Host "Aborted."
      exit 1
    }
  } else {
    throw "Target does not exist and -Yes was not provided: $TargetAbs"
  }
}

$rootFull = Full-Path $Root
$targetFull = Full-Path $TargetAbs
if ($targetFull.Equals($rootFull, [System.StringComparison]::OrdinalIgnoreCase) -or
    $targetFull.StartsWith($rootFull + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) {
  throw "Refusing to install into the kit repository itself: $TargetAbs"
}

Write-Host "Spec Driven Kit installer"
Write-Host "Source: $Root"
Write-Host "Target: $TargetAbs"
if ($DryRun) { Write-Host "Mode: dry-run (no writes)" }

foreach ($line in Get-Content -LiteralPath $Manifest) {
  $trim = $line.Trim()
  if ($trim -eq "" -or $trim.StartsWith("#")) { continue }
  $parts = $trim -split '\s+', 2
  if ($parts.Count -ne 2) { throw "Invalid manifest line: $line" }
  $category = $parts[0]
  $path = $parts[1]

  if ($category -eq "SKIP") {
    $script:Skipped++
    continue
  }
  if ($category -notin @("ENGINE", "SEED", "MERGE")) {
    throw "Invalid category in manifest: $category ($path)"
  }

  $src = Join-Path $Root ($path -replace '/', '\')
  $dst = Join-Path $TargetAbs ($path -replace '/', '\')
  if (-not (Test-Path $src)) { throw "Manifest source missing: $path" }

  if (-not (Test-Path $dst)) {
    Copy-KitFile $src $dst
    continue
  }

  if (Same-File $src $dst) {
    Write-Host "skip unchanged $path"
    $script:Skipped++
    continue
  }

  if ($category -eq "ENGINE") {
    $script:Conflicts++
    if ($Force) {
      Write-Host "force update ENGINE $path"
      Backup-And-Overwrite $src $dst
    } else {
      Write-Host "conflict ENGINE $path -> writing .sdk-new sidecar"
      Copy-Sidecar $src $dst
    }
  } elseif ($category -eq "SEED") {
    Write-Host "skip existing SEED $path"
    $script:Skipped++
    if ($path -eq ".gitignore") {
      Write-Host "  note: confirm your .gitignore protects .env and secrets"
    }
  } elseif ($category -eq "MERGE") {
    Write-Host "existing MERGE $path -> writing .sdk-new for manual merge"
    $script:Conflicts++
    Copy-Sidecar $src $dst
  }
}

Write-Host "----------------------------------------"
Write-Host "install: copied=$($script:Copied) skipped=$($script:Skipped) conflicts=$($script:Conflicts) sidecars=$($script:Sidecars) backups=$($script:Backups)"

if ($DryRun) {
  Write-Host "Dry-run complete. No files were written."
  Write-Host "After a real install, run: scripts/sdk-check.ps1"
  exit 0
}

$check = Join-Path $TargetAbs "scripts\sdk-check.ps1"
if (Test-Path $check) {
  Write-Host "Running sdk-check..."
  & $check
} else {
  Write-Host "sdk-check not found. Run scripts/sdk-check.ps1 after install."
}

Write-Host "Next: open Claude Code in the target project and run /sdk-bootstrap."
