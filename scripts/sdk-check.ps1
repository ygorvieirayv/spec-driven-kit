<#
  sdk-check.ps1 - validacao deterministica dos marcadores de estado do Spec Driven Kit.
  Implementa o contrato de .specify/memory/state-markers.md. Zero token: so regex.
  Uso: ./scripts/sdk-check.ps1
  Saida: ERRO (viola o contrato - exit 1) / AVISO (incompleto/molde - nao bloqueia).

  IMPORTANTE: arquivo ASCII puro (o PowerShell 5.1 le .ps1 sem BOM como ANSI).
  Por isso os vocabularios acentuados usam '.' no regex: 'em revis.o' casa com a
  forma acentuada de "em revisao"; 'constru..o' e 'conclu.da' idem para os estados
  do ledger.
#>

$ErrorActionPreference = "Stop"
$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$script:Erros = 0
$script:Avisos = 0

function Erro($m)  { Write-Host "ERRO  $m"; $script:Erros++ }
function Aviso($m) { Write-Host "AVISO $m"; $script:Avisos++ }
function Rel($p)   { $p.Substring($Root.Length + 1).Replace('\', '/') }

function Get-Text($path) { Get-Content -Raw -Encoding UTF8 $path }

# ---------------------------------------------------------------- specs: Status
$specDirs = Get-ChildItem -Path (Join-Path $Root "docs/specs") -Directory -ErrorAction SilentlyContinue
foreach ($d in @($specDirs)) {
  $spec = Join-Path $d.FullName "spec.md"
  if (-not (Test-Path $spec)) { continue }
  $r = Rel $spec
  $t = Get-Text $spec
  $m = [regex]::Match($t, '(?m)^- \*\*Status:\*\* (.+)$')
  if (-not $m.Success) { Erro "${r}: sem a linha '- **Status:**' (contrato: state-markers.md)" }
  elseif ($m.Groups[1].Value -match 'rascunho \| em revis.o \| aprovada') { Aviso "${r}: Status ainda no molde (nao preenchido)" }
  elseif ($m.Groups[1].Value -notmatch '^(rascunho|em revis.o|aprovada)\b') { Erro "${r}: Status fora do vocabulario (rascunho | em revisao | aprovada)" }
}

# ------------------------------------------- planos: Status, Analyze, Review
$planDirs = Get-ChildItem -Path (Join-Path $Root "docs/plans") -Directory -ErrorAction SilentlyContinue
foreach ($d in @($planDirs)) {
  $plan = Join-Path $d.FullName "plan.md"
  if (-not (Test-Path $plan)) { continue }
  $r = Rel $plan
  $t = Get-Text $plan

  $m = [regex]::Match($t, '(?m)^- \*\*Status:\*\* (.+)$')
  if (-not $m.Success) { Erro "${r}: sem a linha '- **Status:**'" }
  elseif ($m.Groups[1].Value -match 'rascunho \| aprovado') { Aviso "${r}: Status ainda no molde (nao preenchido)" }
  elseif ($m.Groups[1].Value -notmatch '^(rascunho|aprovado)\b') { Erro "${r}: Status fora do vocabulario (rascunho | aprovado)" }

  $m = [regex]::Match($t, '(?m)^- \*\*Analyze:\*\* (.+)$')
  if (-not $m.Success) { Aviso "${r}: sem a linha '- **Analyze:**' (plano anterior ao contrato? adicione-a)" }
  elseif ($m.Groups[1].Value -notmatch '^(pendente|consistente|ajustar|bloqueado)\b') { Erro "${r}: Analyze fora do vocabulario (pendente | consistente | ajustar | bloqueado)" }

  $m = [regex]::Match($t, '(?m)^- \*\*Review:\*\* (.+)$')
  if (-not $m.Success) { Aviso "${r}: sem a linha '- **Review:**' (plano anterior ao contrato? adicione-a)" }
  elseif ($m.Groups[1].Value -notmatch ('^(' + [char]0x2014 + '|aprovado( com ressalvas)?|bloqueado)')) { Erro "${r}: Review fora do vocabulario (- | aprovado | aprovado com ressalvas | bloqueado)" }
}

# ------------------------------------------------------- tasks: estados validos
function Check-TaskStates($file) {
  $r = Rel $file
  foreach ($line in (Get-Content -Encoding UTF8 $file)) {
    if ($line -notmatch '^\| *T[0-9]+ *\|') { continue }
    $cells = $line.Trim() -split '\|'
    if ($cells.Count -lt 3) { continue }
    $estado = $cells[$cells.Count - 2].Trim()
    if ($estado -match '^(backlog|ready|in-progress|done)$') { continue }
    if ($estado -eq '' -or $estado -like '*<*') { continue }  # placeholder de molde
    Erro "${r}: estado de task invalido: '$estado' (backlog | ready | in-progress | done)"
  }
}
foreach ($d in @($planDirs)) {
  foreach ($name in @("plan.md", "tasks.md")) {
    $f = Join-Path $d.FullName $name
    if (Test-Path $f) { Check-TaskStates $f }
  }
}

# ------------------------------------------------- AC <-> task (por feature)
foreach ($d in @($planDirs)) {
  $feature = $d.Name
  $plan  = Join-Path $d.FullName "plan.md"
  $tasks = Join-Path $d.FullName "tasks.md"
  if (-not (Test-Path $plan) -and -not (Test-Path $tasks)) { continue }
  $spec = Join-Path $Root "docs/specs/$feature/spec.md"
  if (-not (Test-Path $spec)) {
    Erro "docs/plans/${feature}: existe plano mas nao existe docs/specs/$feature/spec.md"
    continue
  }

  $specAcs = [regex]::Matches((Get-Text $spec), '\*\*(AC[0-9]+)\*\*') |
    ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
  $taskAcs = @()
  foreach ($f in @($plan, $tasks)) {
    if (-not (Test-Path $f)) { continue }
    foreach ($line in (Get-Content -Encoding UTF8 $f)) {
      if ($line -match '^\| *T[0-9]+') {
        $taskAcs += ([regex]::Matches($line, 'AC[0-9]+') | ForEach-Object { $_.Value })
      }
    }
  }
  $taskAcs = $taskAcs | Sort-Object -Unique

  foreach ($ac in @($taskAcs)) {
    if ($specAcs -notcontains $ac) { Erro "docs/plans/${feature}: task referencia $ac, que nao existe na spec" }
  }
  if (@($taskAcs).Count -gt 0) {
    foreach ($ac in @($specAcs)) {
      if ($taskAcs -notcontains $ac) { Aviso "docs/specs/${feature}: $ac nao tem task que o cubra" }
    }
  }
}

# ----------------------------------------------------- ledger: coluna Estado
$epics = Join-Path $Root "docs/epics.md"
if (Test-Path $epics) {
  foreach ($line in (Get-Content -Encoding UTF8 $epics)) {
    if ($line -notmatch '^\| *[0-9]+ *\|') { continue }
    $cells = $line.Trim() -split '\|'
    if ($cells.Count -lt 7) { continue }
    $estado = $cells[5].Trim()
    if ($estado -match '^(a fazer|em spec|em plano|em constru..o|em review|conclu.da)$') { continue }
    if ($estado -eq '' -or $estado -like '*_(*') { continue }  # placeholder de molde
    Erro "docs/epics.md: Estado de ledger invalido: '$estado' (ver state-markers.md)"
  }
}

# ------------------------------------------------ [VERIFICAR] (informativo)
$pend = @()
$alvos = @(Get-ChildItem -Path (Join-Path $Root "docs") -Recurse -Filter *.md -ErrorAction SilentlyContinue)
$ctx = Join-Path $Root ".specify/memory/project-context.md"
if (Test-Path $ctx) { $alvos += Get-Item $ctx }
foreach ($f in $alvos) {
  $n = ([regex]::Matches((Get-Text $f.FullName), '\[VERIFICAR\]')).Count
  if ($n -gt 0) { $pend += "      $(Rel $f.FullName):$n" }
}
if ($pend.Count -gt 0) {
  Write-Host "INFO  pendencias [VERIFICAR] por arquivo:"
  $pend | ForEach-Object { Write-Host $_ }
}

# -------------------------------------------------------------------- resumo
Write-Host "----------------------------------------"
Write-Host "sdk-check: $($script:Erros) erro(s), $($script:Avisos) aviso(s)."
if ($script:Erros -gt 0) {
  Write-Host "Contrato violado - ver .specify/memory/state-markers.md."
  exit 1
}
exit 0
