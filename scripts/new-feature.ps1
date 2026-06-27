<#
  new-feature.ps1 — cria o esqueleto de uma feature (pasta de spec/plano + branch).
  Uso:  ./scripts/new-feature.ps1 "nome-da-feature"
  Opcional do Spec Driven Kit (Fase 4). O núcleo do kit funciona sem isto.
#>

param(
  [Parameter(Mandatory = $true, Position = 0)]
  [string]$Name
)

$ErrorActionPreference = "Stop"

# slug: minúsculas, espaços -> hífen, remove o que não for [a-z0-9-]
$slug = $Name.ToLower()
$slug = ($slug -replace '\s+', '-')
$slug = ($slug -replace '[^a-z0-9-]', '')
$slug = ($slug -replace '-+', '-').Trim('-')

if ([string]::IsNullOrWhiteSpace($slug)) {
  Write-Error "Nome inválido após normalização: '$Name'"
  exit 1
}

$root     = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$specDir  = Join-Path $root "docs/specs/$slug"
$planDir  = Join-Path $root "docs/plans/$slug"
$templates = Join-Path $root ".specify/templates"

New-Item -ItemType Directory -Force -Path $specDir, $planDir | Out-Null

# Copia os moldes se ainda não existirem (não sobrescreve).
$specFile  = Join-Path $specDir "spec.md"
$planFile  = Join-Path $planDir "plan.md"
$tasksFile = Join-Path $planDir "tasks.md"
if (-not (Test-Path $specFile))  { Copy-Item (Join-Path $templates "spec-template.md")  $specFile }
if (-not (Test-Path $planFile))  { Copy-Item (Join-Path $templates "plan-template.md")  $planFile }
if (-not (Test-Path $tasksFile)) { Copy-Item (Join-Path $templates "tasks-template.md") $tasksFile }

Write-Host "Criado:"
Write-Host "  $specFile"
Write-Host "  $planFile"
Write-Host "  $tasksFile"

# Cria a branch dedicada, se estivermos num repo git.
git -C $root rev-parse --git-dir > $null 2>&1
if ($LASTEXITCODE -eq 0) {
  $branch = "feature/$slug"
  git -C $root show-ref --verify --quiet "refs/heads/$branch"
  if ($LASTEXITCODE -eq 0) {
    Write-Host "Branch '$branch' já existe — alternando."
    git -C $root checkout $branch
  } else {
    git -C $root checkout -b $branch
    Write-Host "Branch '$branch' criada."
  }
}

Write-Host "Pronto. Detalhe a feature com /sdk-spec e depois /sdk-plan."
