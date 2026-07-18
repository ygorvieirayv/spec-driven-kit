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
$VersionFile = Join-Path $Root "VERSION"
if (-not (Test-Path $VersionFile)) {
  throw "Missing VERSION file: $VersionFile"
}
$KitVersion = (Get-Content -Raw -LiteralPath $VersionFile).Trim()
if ($KitVersion -notmatch '^[0-9]+\.[0-9]+\.[0-9]+$') {
  throw "Invalid VERSION: $KitVersion"
}
$StampRel = ".specify/spec-driven-kit.version"

$script:Copied = 0
$script:Skipped = 0
$script:Conflicts = 0
$script:Backups = 0
$script:Sidecars = 0
$CreateTarget = $false
$InstallTimestamp = Get-Date -Format "yyyyMMddHHmmss"

function Full-Path($path) {
  return [System.IO.Path]::GetFullPath($path)
}

function Get-PathEntry($path) {
  return Get-Item -Force -LiteralPath $path -ErrorAction SilentlyContinue
}

function Test-ReparsePoint($item) {
  if ($null -eq $item) { return $false }
  return (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0)
}

function Throw-UnsafePath($path, $reason) {
  throw "Unsafe install path: $path ($reason)"
}

function Assert-SafeTargetPath($path) {
  $full = [System.IO.Path]::GetFullPath($path)
  $root = [System.IO.Path]::GetPathRoot($full)
  $tail = $full.Substring($root.Length)
  $parts = @($tail -split '[\\/]' | Where-Object { $_ -ne '' })
  $current = $root

  for ($i = 0; $i -lt $parts.Count; $i++) {
    $current = Join-Path $current $parts[$i]
    $item = Get-PathEntry $current
    if ($null -eq $item) { continue }
    if (Test-ReparsePoint $item) {
      Throw-UnsafePath $path "target path crosses a symlink/junction/reparse point"
    }
    if ($i -lt ($parts.Count - 1) -and -not $item.PSIsContainer) {
      Throw-UnsafePath $path "target parent component is not a directory"
    }
  }
}

# The only linked leaf that may be read is the documented MERGE lessons file.
# It remains project data and is never overwritten by the installer.
function Assert-SafeRelativePath($relative, [bool]$allowLinkedLeaf = $false) {
  if ([string]::IsNullOrWhiteSpace($relative) -or [System.IO.Path]::IsPathRooted($relative)) {
    Throw-UnsafePath $relative "manifest path must be relative"
  }

  $parts = @($relative -split '[\\/]')
  $current = $TargetAbs
  for ($i = 0; $i -lt $parts.Count; $i++) {
    $component = $parts[$i]
    if ([string]::IsNullOrWhiteSpace($component) -or $component -in @('.', '..')) {
      Throw-UnsafePath $relative "invalid path component '$component'"
    }

    $current = Join-Path $current $component
    $item = Get-PathEntry $current
    if ($null -eq $item) { continue }

    $isLast = $i -eq ($parts.Count - 1)
    if (Test-ReparsePoint $item) {
      if ($isLast -and $allowLinkedLeaf) {
        if (-not (Test-Path -LiteralPath $current -PathType Leaf)) {
          Throw-UnsafePath $relative "allowed MERGE link is dangling or not a file"
        }
      } else {
        Throw-UnsafePath $relative "symlink/junction/reparse point detected"
      }
    } elseif ($isLast) {
      if ($item.PSIsContainer) {
        Throw-UnsafePath $relative "destination is not a regular file"
      }
    } elseif (-not $item.PSIsContainer) {
      Throw-UnsafePath $relative "parent component is not a directory"
    }
  }
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
  $item = Get-PathEntry $base
  if ($null -eq $item) { return $base }
  if (Test-ReparsePoint $item) {
    Throw-UnsafePath $base "generated sidecar/backup is a reparse point"
  }
  $i = 1
  while ($true) {
    $candidate = "$base.$i"
    $item = Get-PathEntry $candidate
    if ($null -eq $item) { return $candidate }
    if (Test-ReparsePoint $item) {
      Throw-UnsafePath $candidate "generated sidecar/backup is a reparse point"
    }
    $i++
  }
}

function Copy-KitFile($src, $dst, $relative) {
  Assert-SafeRelativePath $relative $false
  if ($DryRun) {
    Write-Host "DRY-RUN copy $src -> $dst"
  } else {
    Ensure-Parent $dst
    Copy-Item -LiteralPath $src -Destination $dst -Force
  }
  $script:Copied++
}

function Copy-Sidecar($src, $dst, $relative, [bool]$allowLinkedLeaf) {
  Assert-SafeRelativePath $relative $allowLinkedLeaf
  $sidecar = Unique-Path "$dst.sdk-new"
  if ($DryRun) {
    Write-Host "DRY-RUN sidecar $src -> $sidecar"
  } else {
    Ensure-Parent $sidecar
    Copy-Item -LiteralPath $src -Destination $sidecar -Force
  }
  $script:Sidecars++
}

function Backup-And-Overwrite($src, $dst, $relative) {
  Assert-SafeRelativePath $relative $false
  $backup = Unique-Path "$dst.sdk-bak.$InstallTimestamp"
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

function Read-InstalledVersion($path) {
  if (-not (Test-Path $path)) { return "none" }
  $value = (Get-Content -Raw -LiteralPath $path).Trim()
  if ($value -match '^[0-9]+\.[0-9]+\.[0-9]+$') { return $value }
  return "none"
}

function Stamp-Version {
  $stampPath = Join-Path $TargetAbs ($StampRel -replace '/', '\')
  Assert-SafeRelativePath $StampRel $false
  if ($DryRun) {
    Write-Host "DRY-RUN would stamp ${StampRel}: $InstalledVersion -> $KitVersion"
  } else {
    Ensure-Parent $stampPath
    [System.IO.File]::WriteAllText($stampPath, $KitVersion + [Environment]::NewLine, [System.Text.Encoding]::ASCII)
    Write-Host "stamped ${StampRel}: $InstalledVersion -> $KitVersion"
  }
}

$targetItem = Get-PathEntry $Target
if ($null -ne $targetItem) {
  if (Test-ReparsePoint $targetItem) {
    Throw-UnsafePath $Target "target root is a symlink/junction/reparse point"
  }
  if (-not $targetItem.PSIsContainer) {
    Throw-UnsafePath $Target "target exists and is not a directory"
  }
  $TargetAbs = (Resolve-Path -LiteralPath $Target).Path
} else {
  $parent = Split-Path -Parent $Target
  if ([string]::IsNullOrWhiteSpace($parent)) { $parent = "." }
  if (-not (Test-Path $parent)) { throw "Target parent does not exist: $parent" }
  $TargetAbs = Join-Path (Resolve-Path $parent).Path (Split-Path -Leaf $Target)
  if ($DryRun) {
    Write-Host "DRY-RUN would create target directory: $TargetAbs"
    $CreateTarget = $true
  } elseif ($Yes) {
    $CreateTarget = $true
  } elseif ([Environment]::UserInteractive) {
    $answer = Read-Host "Target does not exist. Create '$TargetAbs'? [y/N]"
    if ($answer -match '^(y|yes)$') {
      $CreateTarget = $true
    } else {
      Write-Host "Aborted."
      exit 1
    }
  } else {
    throw "Target does not exist and -Yes was not provided: $TargetAbs"
  }
}

Assert-SafeTargetPath $TargetAbs

$rootFull = Full-Path $Root
$targetFull = Full-Path $TargetAbs
if ($targetFull.Equals($rootFull, [System.StringComparison]::OrdinalIgnoreCase) -or
    $targetFull.StartsWith($rootFull + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) {
  throw "Refusing to install into the kit repository itself: $TargetAbs"
}

$ManifestEntries = @()
Assert-SafeRelativePath $StampRel $false

foreach ($line in Get-Content -LiteralPath $Manifest) {
  $trim = $line.Trim()
  if ($trim -eq "" -or $trim.StartsWith("#")) { continue }
  $parts = $trim -split '\s+', 2
  if ($parts.Count -ne 2) { throw "Invalid manifest line: $line" }
  $category = $parts[0]
  $path = $parts[1]

  if ($category -notin @("ENGINE", "SEED", "MERGE", "SKIP")) {
    throw "Invalid category in manifest: $category ($path)"
  }

  if ($category -eq "SKIP") {
    $ManifestEntries += [PSCustomObject]@{
      Category = $category
      Path = $path
      Source = $null
      Destination = $null
      AllowLinkedLeaf = $false
    }
    continue
  }

  $src = Join-Path $Root ($path -replace '/', '\')
  $dst = Join-Path $TargetAbs ($path -replace '/', '\')
  if (-not (Test-Path -LiteralPath $src -PathType Leaf)) {
    throw "Manifest source missing: $path"
  }

  $allowLinkedLeaf = $category -eq "MERGE" -and $path -eq ".specify/memory/lessons.md"
  Assert-SafeRelativePath $path $allowLinkedLeaf

  $entry = [PSCustomObject]@{
    Category = $category
    Path = $path
    Source = $src
    Destination = $dst
    AllowLinkedLeaf = $allowLinkedLeaf
  }
  $ManifestEntries += $entry

  $dstItem = Get-PathEntry $dst
  if ($null -eq $dstItem -or (Same-File $src $dst)) { continue }

  if ($category -eq "ENGINE") {
    if ($Force) {
      $null = Unique-Path "$dst.sdk-bak.$InstallTimestamp"
    } else {
      $null = Unique-Path "$dst.sdk-new"
    }
  } elseif ($category -eq "MERGE") {
    $null = Unique-Path "$dst.sdk-new"
  }
}

$InstalledVersion = Read-InstalledVersion (Join-Path $TargetAbs ($StampRel -replace '/', '\'))

if ($CreateTarget -and -not $DryRun) {
  if ($null -ne (Get-PathEntry $TargetAbs)) {
    Throw-UnsafePath $TargetAbs "target appeared after preflight"
  }
  New-Item -ItemType Directory -Path $TargetAbs | Out-Null
  Write-Host "Created target directory: $TargetAbs"
}

Write-Host "Spec Driven Kit v$KitVersion"
Write-Host "Source: $Root"
Write-Host "Target: $TargetAbs"
Write-Host "installed: $InstalledVersion -> $KitVersion"
if ($DryRun) { Write-Host "Mode: dry-run (no writes)" }

foreach ($entry in $ManifestEntries) {
  $category = $entry.Category
  $path = $entry.Path

  if ($category -eq "SKIP") {
    $script:Skipped++
    continue
  }
  $src = $entry.Source
  $dst = $entry.Destination

  if ($null -eq (Get-PathEntry $dst)) {
    Copy-KitFile $src $dst $path
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
      Backup-And-Overwrite $src $dst $path
    } else {
      Write-Host "conflict ENGINE $path -> writing .sdk-new sidecar"
      Copy-Sidecar $src $dst $path $false
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
    Copy-Sidecar $src $dst $path $entry.AllowLinkedLeaf
  }
}

Write-Host "----------------------------------------"
Write-Host "install: copied=$($script:Copied) skipped=$($script:Skipped) conflicts=$($script:Conflicts) sidecars=$($script:Sidecars) backups=$($script:Backups)"
Stamp-Version

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
