$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
$target = Join-Path $env:TEMP ("sdk-ci-wrapper-" + [guid]::NewGuid().ToString("N"))

try {
  $scripts = Join-Path $target "scripts"
  $gates = Join-Path $target ".specify\ci\gates"
  $memory = Join-Path $target ".specify\memory"
  $workflows = Join-Path $target ".github\workflows"
  New-Item -ItemType Directory -Force -Path $scripts, $gates, $memory, $workflows | Out-Null
  Copy-Item (Join-Path $root "scripts\sdk-ci.sh") $scripts
  Copy-Item (Join-Path $root "scripts\sdk-ci.ps1") $scripts

  $rows = @(
    "## Contrato de CI",
    "- **Runner de quality:** ``ubuntu-24.04``",
    "| Gate | Contrato | Detalhe |",
    "|------|----------|---------|",
    "| install | required | fixture |",
    "| lint | required | fixture |",
    "| typecheck | required | fixture |",
    "| test | required | fixture |",
    "| build | required | fixture |",
    "| dependency-audit | required | fixture |"
  ) -join "`n"
  [IO.File]::WriteAllText((Join-Path $memory "project-context.md"), $rows, [Text.UTF8Encoding]::new($false))
  $workflow = "name: Fixture`njobs:`n  quality:`n    runs-on: ubuntu-24.04`n    steps: []`n"
  [IO.File]::WriteAllText((Join-Path $workflows "sdk-quality.yml"), $workflow, [Text.UTF8Encoding]::new($false))

  foreach ($gate in "install", "lint", "typecheck", "test", "build", "dependency-audit") {
    $body = 'printf "%s\n" "$SDK_CI_GATE" >> .wrapper-order' + "`n"
    [IO.File]::WriteAllText((Join-Path $gates "$gate.sh"), $body, [Text.UTF8Encoding]::new($false))
  }

  & (Join-Path $scripts "sdk-ci.ps1") -Validate
  if ($LASTEXITCODE -ne 0) { throw "PowerShell wrapper validation failed" }
  & (Join-Path $scripts "sdk-ci.ps1")
  if ($LASTEXITCODE -ne 0) { throw "PowerShell wrapper execution failed" }

  $actual = (Get-Content (Join-Path $target ".wrapper-order")) -join "`n"
  $expected = "install`nlint`ntypecheck`ntest`nbuild`ndependency-audit"
  if ($actual -ne $expected) { throw "PowerShell wrapper changed gate order" }

  Remove-Item (Join-Path $gates "test.sh")
  [IO.File]::WriteAllText((Join-Path $gates "test.skip"), "Test intentionally disabled for mismatch fixture.", [Text.UTF8Encoding]::new($false))
  & (Join-Path $scripts "sdk-ci.ps1") -Validate *> $null
  if ($LASTEXITCODE -eq 0) { throw "Context/gate mismatch unexpectedly passed through wrapper" }

  Write-Output "sdk-ci PowerShell wrapper matrix passed."
}
finally {
  if (Test-Path -LiteralPath $target) {
    Remove-Item -LiteralPath $target -Recurse -Force
  }
}
