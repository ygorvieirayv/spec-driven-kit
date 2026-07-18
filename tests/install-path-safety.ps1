<# Focused regression tests for install.ps1 path containment. ASCII only. #>
$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$TempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("sdk-path-safety-" + [Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $TempRoot | Out-Null

function Invoke-ExpectUnsafe($label, [scriptblock]$action) {
  $failed = $false
  $output = ""
  try {
    $output = (& $action 2>&1 | Out-String)
  } catch {
    $failed = $true
    $output += $_ | Out-String
  }
  if (-not $failed) {
    throw "$label unexpectedly succeeded: $output"
  }
  if ($output -notmatch 'Unsafe install path:') {
    throw "$label failed without the path-safety diagnostic: $output"
  }
}

function Assert-OnlySentinel($directory, $expected) {
  $files = @(Get-ChildItem -LiteralPath $directory -File -Recurse -Force)
  if ($files.Count -ne 1) {
    throw "Outside directory changed: $directory ($($files.Count) files)"
  }
  $actual = Get-Content -Raw -LiteralPath (Join-Path $directory "sentinel")
  if ($actual -ne $expected) { throw "Outside sentinel changed: $directory" }
}

function Install-Clean($parent, $target) {
  New-Item -ItemType Directory -Force -Path $parent | Out-Null
  & (Join-Path $Root "install.ps1") -Target $target -Yes *> $null
}

try {
  $dryParent = Join-Path $TempRoot "dry-parent"
  $dryTarget = Join-Path $dryParent "project"
  New-Item -ItemType Directory -Path $dryParent | Out-Null
  & (Join-Path $Root "install.ps1") -Target $dryTarget -DryRun -Yes *> $null
  if (Test-Path -LiteralPath $dryTarget) { throw "Dry-run created its target" }
  if (@(Get-ChildItem -LiteralPath $dryParent -Force).Count -ne 0) {
    throw "Dry-run created staging files"
  }

  $targetPathOutside = Join-Path $TempRoot "target-path-outside"
  $targetPathAlias = Join-Path $TempRoot "target-path-alias"
  New-Item -ItemType Directory -Path $targetPathOutside | Out-Null
  [System.IO.File]::WriteAllText((Join-Path $targetPathOutside "sentinel"), "target-path-safe")
  New-Item -ItemType Junction -Path $targetPathAlias -Target $targetPathOutside | Out-Null
  Invoke-ExpectUnsafe "target-path-ancestor-junction" {
    & (Join-Path $Root "install.ps1") -Target (Join-Path $targetPathAlias "project") -Yes | Out-Null
  }
  Assert-OnlySentinel $targetPathOutside "target-path-safe"
  if (Test-Path -LiteralPath (Join-Path $targetPathOutside "project")) {
    throw "Target path ancestor junction redirected the installation"
  }

  $ancestorTarget = Join-Path $TempRoot "ancestor-target"
  $ancestorOutside = Join-Path $TempRoot "ancestor-outside"
  New-Item -ItemType Directory -Path $ancestorTarget, $ancestorOutside | Out-Null
  [System.IO.File]::WriteAllText((Join-Path $ancestorOutside "sentinel"), "ancestor-safe")
  New-Item -ItemType Junction -Path (Join-Path $ancestorTarget ".claude") -Target $ancestorOutside | Out-Null
  Invoke-ExpectUnsafe "ancestor-junction" {
    & (Join-Path $Root "install.ps1") -Target $ancestorTarget -Yes -Force | Out-Null
  }
  Assert-OnlySentinel $ancestorOutside "ancestor-safe"
  if (Test-Path (Join-Path $ancestorTarget ".specify")) {
    throw "Ancestor-junction failure wrote before completing preflight"
  }

  $stampTarget = Join-Path $TempRoot "stamp-target"
  $stampOutside = Join-Path $TempRoot "stamp-outside"
  New-Item -ItemType Directory -Force -Path (Join-Path $stampTarget ".specify"), $stampOutside | Out-Null
  [System.IO.File]::WriteAllText((Join-Path $stampOutside "sentinel"), "stamp-safe")
  New-Item -ItemType Junction -Path (Join-Path $stampTarget ".specify\spec-driven-kit.version") -Target $stampOutside | Out-Null
  Invoke-ExpectUnsafe "stamp-junction" {
    & (Join-Path $Root "install.ps1") -Target $stampTarget -Yes | Out-Null
  }
  Assert-OnlySentinel $stampOutside "stamp-safe"
  if (Test-Path (Join-Path $stampTarget ".claude")) {
    throw "Stamp-junction failure wrote before completing preflight"
  }

  $sidecarParent = Join-Path $TempRoot "sidecar-parent"
  $sidecarTarget = Join-Path $sidecarParent "project"
  $sidecarOutside = Join-Path $TempRoot "sidecar-outside"
  Install-Clean $sidecarParent $sidecarTarget
  New-Item -ItemType Directory -Path $sidecarOutside | Out-Null
  [System.IO.File]::WriteAllText((Join-Path $sidecarOutside "sentinel"), "sidecar-safe")
  [System.IO.File]::WriteAllText((Join-Path $sidecarTarget ".claude\commands\sdk-next.md"), "custom-engine`n")
  & (Join-Path $Root "install.ps1") -Target $sidecarTarget -DryRun -Yes *> $null
  & (Join-Path $Root "install.ps1") -Target $sidecarTarget -DryRun -Yes -Force *> $null
  $dryArtifacts = @(Get-ChildItem -LiteralPath $sidecarTarget -Recurse -Force | Where-Object {
    $_.Name -like '*.sdk-new*' -or $_.Name -like '*.sdk-bak.*'
  })
  if ($dryArtifacts.Count -ne 0) { throw "Conflicting dry-run created sidecar or backup staging" }
  $engine = (Get-Content -Raw -LiteralPath (Join-Path $sidecarTarget ".claude\commands\sdk-next.md")).Trim()
  if ($engine -ne "custom-engine") { throw "Conflicting dry-run changed ENGINE" }
  New-Item -ItemType Junction -Path (Join-Path $sidecarTarget ".claude\commands\sdk-next.md.sdk-new") -Target $sidecarOutside | Out-Null
  Invoke-ExpectUnsafe "sidecar-junction" {
    & (Join-Path $Root "install.ps1") -Target $sidecarTarget -Yes | Out-Null
  }
  Assert-OnlySentinel $sidecarOutside "sidecar-safe"
  $engine = (Get-Content -Raw -LiteralPath (Join-Path $sidecarTarget ".claude\commands\sdk-next.md")).Trim()
  if ($engine -ne "custom-engine") { throw "ENGINE changed after sidecar preflight failure" }

  $backupParent = Join-Path $TempRoot "backup-parent"
  $backupTarget = Join-Path $backupParent "project"
  $backupOutside = Join-Path $TempRoot "backup-outside"
  Install-Clean $backupParent $backupTarget
  New-Item -ItemType Directory -Path $backupOutside | Out-Null
  [System.IO.File]::WriteAllText((Join-Path $backupOutside "sentinel"), "backup-safe")
  [System.IO.File]::WriteAllText((Join-Path $backupTarget ".claude\commands\sdk-next.md"), "custom-engine`n")
  New-Item -ItemType Junction -Path (Join-Path $backupTarget ".claude\commands\sdk-next.md.sdk-bak.20000101000000") -Target $backupOutside | Out-Null
  function global:Get-Date { param([string]$Format) return "20000101000000" }
  try {
    Invoke-ExpectUnsafe "backup-junction" {
      & (Join-Path $Root "install.ps1") -Target $backupTarget -Yes -Force | Out-Null
    }
  } finally {
    Remove-Item Function:\Get-Date -ErrorAction SilentlyContinue
  }
  Assert-OnlySentinel $backupOutside "backup-safe"
  $engine = (Get-Content -Raw -LiteralPath (Join-Path $backupTarget ".claude\commands\sdk-next.md")).Trim()
  if ($engine -ne "custom-engine") { throw "ENGINE changed after backup preflight failure" }

  $mergeParent = Join-Path $TempRoot "merge-parent"
  $mergeTarget = Join-Path $mergeParent "project"
  $mergeOutside = Join-Path $TempRoot "merge-outside"
  Install-Clean $mergeParent $mergeTarget
  New-Item -ItemType Directory -Path $mergeOutside | Out-Null
  $sharedLessons = Join-Path $mergeOutside "lessons.md"
  [System.IO.File]::WriteAllText($sharedLessons, "# shared lessons`n")
  Remove-Item -LiteralPath (Join-Path $mergeTarget ".specify\memory\lessons.md") -Force
  $linkCreated = $false
  try {
    New-Item -ItemType SymbolicLink -Path (Join-Path $mergeTarget ".specify\memory\lessons.md") -Target $sharedLessons -ErrorAction Stop | Out-Null
    $linkCreated = $true
  } catch {
    Write-Host "SKIP linked MERGE case: host cannot create file symbolic links"
  }
  if ($linkCreated) {
    $before = (Get-FileHash -Algorithm SHA256 -LiteralPath $sharedLessons).Hash
    & (Join-Path $Root "install.ps1") -Target $mergeTarget -Yes *> $null
    $after = (Get-FileHash -Algorithm SHA256 -LiteralPath $sharedLessons).Hash
    if ($before -ne $after) { throw "Linked MERGE data was overwritten" }
    if (-not (Test-Path (Join-Path $mergeTarget ".specify\memory\lessons.md.sdk-new") -PathType Leaf)) {
      throw "Linked MERGE data did not receive a safe sidecar"
    }
  }

  Write-Host "install path safety (PowerShell): ok"
} finally {
  if (Test-Path -LiteralPath $TempRoot) {
    Remove-Item -LiteralPath $TempRoot -Recurse -Force
  }
}
