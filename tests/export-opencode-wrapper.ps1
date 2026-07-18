$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
$target = Join-Path ([System.IO.Path]::GetTempPath()) ("sdk opencode wrapper " + [guid]::NewGuid().ToString("N"))

try {
  $scripts = Join-Path $target "scripts"
  $sources = Join-Path $target ".claude\commands"
  New-Item -ItemType Directory -Force -Path $scripts, $sources | Out-Null
  Copy-Item (Join-Path $root "scripts\export-opencode.sh") $scripts
  Copy-Item (Join-Path $root "scripts\export-opencode.ps1") $scripts

  $source = @"
---
description: Wrapper fixture
argument-hint: "[target]"
---

# Wrapper fixture
"@
  [IO.File]::WriteAllText((Join-Path $sources "sdk-wrapper.md"), $source, [Text.UTF8Encoding]::new($false))

  & (Join-Path $scripts "export-opencode.ps1")
  if ($LASTEXITCODE -ne 0) { throw "PowerShell export wrapper failed" }

  $generated = Join-Path $target ".opencode\commands\sdk-wrapper.md"
  if (-not (Test-Path -LiteralPath $generated -PathType Leaf)) { throw "Wrapper did not generate the command" }
  $content = [IO.File]::ReadAllText($generated)
  if ([regex]::Matches($content, '\$ARGUMENTS').Count -ne 1) { throw "Wrapper output does not contain exactly one argument interpolation" }
  if ($content -match '(?m)^argument-hint:') { throw "Wrapper preserved argument-hint" }

  & (Join-Path $scripts "export-opencode.ps1") -Check
  if ($LASTEXITCODE -ne 0) { throw "PowerShell wrapper check failed" }

  [IO.File]::AppendAllText($generated, "`nwrapper drift`n", [Text.UTF8Encoding]::new($false))
  & (Join-Path $scripts "export-opencode.ps1") -Check *> $null
  if ($LASTEXITCODE -eq 0) { throw "PowerShell wrapper did not propagate stale-export failure" }

  Write-Output "export-opencode PowerShell wrapper matrix passed."
}
finally {
  if (Test-Path -LiteralPath $target) {
    Remove-Item -LiteralPath $target -Recurse -Force
  }
}
