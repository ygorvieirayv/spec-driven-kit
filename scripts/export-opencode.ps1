# Portable PowerShell entrypoint for the canonical Bash exporter.
[CmdletBinding()]
param(
  [switch]$Check
)

$ErrorActionPreference = "Stop"
$runner = Join-Path $PSScriptRoot "export-opencode.sh"
if (-not (Test-Path -LiteralPath $runner -PathType Leaf)) {
  Write-Error "export-opencode.ps1: export-opencode.sh not found next to this wrapper"
  exit 2
}

$candidates = [System.Collections.Generic.List[string]]::new()
if ($IsWindows -or $env:OS -eq "Windows_NT") {
  $git = Get-Command git.exe -ErrorAction SilentlyContinue
  if ($git) {
    $gitRoot = Split-Path (Split-Path $git.Source -Parent) -Parent
    $candidates.Add((Join-Path $gitRoot "bin\bash.exe"))
  }
  if ($env:ProgramFiles) {
    $candidates.Add((Join-Path $env:ProgramFiles "Git\bin\bash.exe"))
  }
  if (${env:ProgramFiles(x86)}) {
    $candidates.Add((Join-Path ${env:ProgramFiles(x86)} "Git\bin\bash.exe"))
  }
  if ($env:LOCALAPPDATA) {
    $candidates.Add((Join-Path $env:LOCALAPPDATA "Programs\Git\bin\bash.exe"))
  }
}
$bashCommand = Get-Command bash -ErrorAction SilentlyContinue
if ($bashCommand) {
  $candidates.Add($bashCommand.Source)
}

$bash = $candidates | Where-Object { $_ -and (Test-Path -LiteralPath $_ -PathType Leaf) } |
  Select-Object -Unique -First 1
if (-not $bash) {
  Write-Error "export-opencode.ps1: Bash not found. Install Git for Windows or Bash before exporting OpenCode commands."
  exit 2
}

$runnerArgs = @($runner)
if ($Check) {
  $runnerArgs += "--check"
}
$ErrorActionPreference = "Continue"
& $bash @runnerArgs
exit $LASTEXITCODE
