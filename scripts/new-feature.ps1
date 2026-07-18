<#
  new-feature.ps1 - inicia a spec de uma feature e cria a branch dedicada.
  Uso:  ./scripts/new-feature.ps1 "nome-da-feature"
  Opcional do Spec Driven Kit (Fase 4). O nucleo do kit funciona sem isto.

  IMPORTANTE: este arquivo e ASCII puro de proposito. O Windows PowerShell 5.1 le
  .ps1 sem BOM como ANSI, o que corrompe acentos e pode quebrar o parser. Ao editar,
  nao introduza caracteres acentuados nem travessoes.
#>

param(
  [Parameter(Mandatory = $true, Position = 0)]
  [string]$Name
)

$ErrorActionPreference = "Stop"

# slug: minusculas, espacos -> hifen, remove o que nao for [a-z0-9-]
$slug = $Name.ToLower()
$slug = ($slug -replace '\s+', '-')
$slug = ($slug -replace '[^a-z0-9-]', '')
$slug = ($slug -replace '-+', '-').Trim('-')

if ([string]::IsNullOrWhiteSpace($slug)) {
  Write-Error "Nome invalido apos normalizacao: '$Name'"
  exit 1
}

$root     = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$specDir  = Join-Path $root "docs/specs/$slug"
$templates = Join-Path $root ".specify/templates"

New-Item -ItemType Directory -Force -Path $specDir | Out-Null

# Copia e materializa os moldes somente na primeira criacao (nao sobrescreve).
$specFile  = Join-Path $specDir "spec.md"

function New-FromTemplate($source, $target) {
  if (Test-Path $target) { return }
  $content = [System.IO.File]::ReadAllText($source)
  $content = $content.Replace("<feature>", $slug).Replace("<Nome da Feature>", $slug)
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($target, $content, $utf8NoBom)
}

New-FromTemplate (Join-Path $templates "spec-template.md") $specFile

Write-Host "Criado:"
Write-Host "  $specFile"

# Cria a branch dedicada, se estivermos num repo git. O probe nao pode abortar em pasta sem .git.
$previousErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = "SilentlyContinue"
git -C $root rev-parse --git-dir > $null 2>&1
$isGitRepo = ($LASTEXITCODE -eq 0)
$ErrorActionPreference = $previousErrorActionPreference

if ($isGitRepo) {
  $branch = "feature/$slug"
  git -C $root show-ref --verify --quiet "refs/heads/$branch"
  if ($LASTEXITCODE -eq 0) {
    Write-Host "Branch '$branch' ja existe - alternando."
    git -C $root checkout $branch
  } else {
    git -C $root checkout -b $branch
    Write-Host "Branch '$branch' criada."
  }
}

Write-Host "Pronto. Detalhe a feature com /sdk-spec; depois use /sdk-next para seguir o estado gravado."
