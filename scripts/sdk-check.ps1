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

function Get-Text($path) {
  return [IO.File]::ReadAllText($path, [Text.Encoding]::UTF8)
}

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

  $riskMatches = [regex]::Matches($t, '(?m)^- \*\*Risco:\*\* (.+)$')
  $m = if ($riskMatches.Count -gt 0) { $riskMatches[0] } else { $null }
  if ($riskMatches.Count -eq 0) { Erro "${r}: sem a linha '- **Risco:**'" }
  elseif ($riskMatches.Count -ne 1) { Erro "${r}: exige exatamente uma linha '- **Risco:**'" }
  elseif ($m.Groups[1].Value -match 'baixo \| medio \| alto') { Aviso "${r}: Risco ainda no molde (nao preenchido)" }
  elseif ($m.Groups[1].Value -notmatch '^(baixo|medio|alto)[ \t]*\r?$') { Erro "${r}: Risco fora do vocabulario (baixo | medio | alto)" }

  $fidelityHeadingCount = [regex]::Matches($t, '(?m)^## Limites de fidelidade[ \t]*\r?$').Count
  $fidelityMarkerCount = [regex]::Matches($t, '(?m)^- \*\*Limites intencionais:\*\* (nenhum|declarados abaixo)[ \t]*\r?$').Count
  if ($fidelityHeadingCount -ne 1) { Erro "${r}: exige exatamente uma secao '## Limites de fidelidade'" }
  if ($fidelityMarkerCount -ne 1) { Erro "${r}: Limites intencionais deve ser 'nenhum' ou 'declarados abaixo'" }
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
  if (-not $m.Success) { Erro "${r}: sem a linha obrigatoria '- **Analyze:**'" }
  elseif ($m.Groups[1].Value -notmatch '^(pendente|consistente|ajustar|bloqueado)\b') { Erro "${r}: Analyze fora do vocabulario (pendente | consistente | ajustar | bloqueado)" }

  $m = [regex]::Match($t, '(?m)^- \*\*Review:\*\* (.+)$')
  if (-not $m.Success) { Erro "${r}: sem a linha obrigatoria '- **Review:**'" }
  elseif ($m.Groups[1].Value -notmatch ('^(' + [char]0x2014 + '|aprovado( com ressalvas)?|bloqueado)')) { Erro "${r}: Review fora do vocabulario (- | aprovado | aprovado com ressalvas | bloqueado)" }

  $profileHeadingCount = [regex]::Matches($t, '(?m)^## Perfis de prova[ \t]*\r?$').Count
  if ($profileHeadingCount -ne 1) { Erro "${r}: exige exatamente uma secao '## Perfis de prova'" }
  foreach ($profile in @('visual', 'logic', 'journey', 'data-security', 'operational', 'delivery')) {
    $profilePattern = '(?m)^\|[ \t]*' + [regex]::Escape($profile) + '[ \t]*\|'
    if ([regex]::Matches($t, $profilePattern).Count -ne 1) {
      Erro "${r}: perfil '$profile' deve aparecer exatamente uma vez na matriz"
    }
  }
  if ($t -match '(?m)^## Tasks[ \t]*\r?$') { Erro "${r}: secao inline '## Tasks' e proibida; use tasks.md" }
}

# ------------------------- tasks + evidence: fonte autoritativa e estados validos
function Is-Placeholder($value) {
  if ([string]::IsNullOrWhiteSpace($value)) { return $true }
  $v = $value.Trim()
  return ($v -eq '-' -or $v -eq '...' -or $v -eq [string][char]0x2014 -or $v -match '^<.*>$')
}

function Test-Iso8601($value) {
  if ($value -notmatch '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?(Z|[+-]\d{2}:\d{2})$') {
    return $false
  }
  $parsed = [DateTimeOffset]::MinValue
  return [DateTimeOffset]::TryParse(
    $value,
    [Globalization.CultureInfo]::InvariantCulture,
    [Globalization.DateTimeStyles]::RoundtripKind,
    [ref]$parsed
  )
}

function Latest-Record($records, $task, $phase) {
  $found = @($records | Where-Object { $_.Task -eq $task -and $_.Phase -eq $phase })
  if ($found.Count -eq 0) { return $null }
  return $found[$found.Count - 1]
}

function Test-RecordCoversAcs($record, $declaredAcs) {
  foreach ($declaredAc in @($declaredAcs)) {
    if ($record.Acs -notcontains $declaredAc) { return $false }
  }
  return $true
}

foreach ($d in @($planDirs)) {
  $feature  = $d.Name
  $plan     = Join-Path $d.FullName "plan.md"
  $tasks    = Join-Path $d.FullName "tasks.md"
  $evidence = Join-Path $d.FullName "evidence.md"

  if (-not (Test-Path $plan)) {
    if (Test-Path $tasks) { Erro "docs/plans/${feature}: existe tasks.md sem plan.md" }
    continue
  }

  $spec = Join-Path $Root "docs/specs/$feature/spec.md"
  if (-not (Test-Path $spec)) {
    Erro "docs/plans/${feature}: existe plano mas nao existe docs/specs/$feature/spec.md"
    continue
  }

  if (-not (Test-Path $tasks)) {
    if (Test-Path $evidence) { Erro "docs/plans/${feature}: evidence.md existe sem tasks.md canonico" }
    $planText = Get-Text $plan
    $analyze = [regex]::Match($planText, '(?m)^- \*\*Analyze:\*\* (.+)$')
    if ($analyze.Success -and $analyze.Groups[1].Value -notmatch '^pendente\b') {
      Erro "docs/plans/${feature}: Analyze nao pode avancar sem tasks.md canonico"
    }
    continue
  }

  $taskFile = $tasks

  $taskRel = Rel $taskFile
  $taskIds = @{}
  $taskStates = @{}
  $taskAcsById = @{}
  $taskDepsById = @{}
  $taskAcs = @()
  $taskLines = @(Get-Content -Encoding UTF8 $taskFile)
  $acColumnIndex = $null
  $depColumnIndex = $null
  $profilesColumnIndex = $null
  foreach ($line in $taskLines) {
    if ($line -notmatch '^\|') { continue }
    $headerCells = $line -split '\|'
    for ($cellIndex = 0; $cellIndex -lt $headerCells.Count; $cellIndex++) {
      if ($headerCells[$cellIndex].Trim() -eq 'AC') {
        $acColumnIndex = $cellIndex
      }
      if ($headerCells[$cellIndex].Trim() -eq 'Depende de') {
        $depColumnIndex = $cellIndex
      }
      if ($headerCells[$cellIndex].Trim() -eq 'Perfis') {
        $profilesColumnIndex = $cellIndex
      }
    }
    if ($null -ne $acColumnIndex) { break }
  }
  if ($null -eq $profilesColumnIndex) { Erro "${taskRel}: tabela de tasks exige a coluna 'Perfis'" }

  foreach ($line in $taskLines) {
    $tm = [regex]::Match($line, '^\| *(T[0-9]+) *\|')
    if (-not $tm.Success) { continue }
    $task = $tm.Groups[1].Value
    $cells = $line -split '\|'
    if ($cells.Count -lt 3) { continue }
    if ($taskIds.ContainsKey($task)) {
      Erro "${taskRel}: ID de task duplicado: $task"
      continue
    }
    $state = $cells[$cells.Count - 2].Trim()
    $rowAcs = @()
    if ($null -ne $acColumnIndex -and $cells.Count -gt $acColumnIndex) {
      $rowAcs = @([regex]::Matches($cells[$acColumnIndex], 'AC[0-9]+') |
        ForEach-Object { $_.Value } | Sort-Object -Unique)
    }
    $rowDeps = @()
    if ($null -ne $depColumnIndex -and $cells.Count -gt $depColumnIndex) {
      $rowDeps = @([regex]::Matches($cells[$depColumnIndex], 'T[0-9]+') |
        ForEach-Object { $_.Value } | Sort-Object -Unique)
    }
    $taskIds[$task] = $true
    $taskStates[$task] = $state
    $taskAcsById[$task] = $rowAcs
    $taskDepsById[$task] = $rowDeps
    $taskAcs += $rowAcs

    if ($state -match '^(backlog|ready|in-progress|verification-pending|blocked|done)$') { continue }
    if ($state -eq '' -or $state -like '*<*') { continue }  # placeholder de molde
    Erro "${taskRel}: estado de task invalido: '$state' (backlog | ready | in-progress | verification-pending | blocked | done)"
  }
  $taskAcs = @($taskAcs | Sort-Object -Unique)

  $specAcs = @()
  if (Test-Path $spec) {
    $canonicalAcMatches = @([regex]::Matches(
      (Get-Text $spec),
      '(?m)^- \*\*(AC[0-9]+)\*\*[ \t]+\u2014[ \t]+.+$'
    ))
    $specAcOccurrences = @($canonicalAcMatches | ForEach-Object { $_.Groups[1].Value })
    foreach ($duplicateAc in @($specAcOccurrences | Group-Object | Where-Object { $_.Count -gt 1 })) {
      Erro "docs/specs/${feature}/spec.md: ID de criterio de aceite duplicado: $($duplicateAc.Name)"
    }
    $specAcs = @($specAcOccurrences | Sort-Object -Unique)

    foreach ($ac in @($taskAcs)) {
      if ($specAcs -notcontains $ac) { Erro "docs/plans/${feature}: task referencia $ac, que nao existe na spec" }
    }
    if (@($taskAcs).Count -gt 0) {
      foreach ($ac in @($specAcs)) {
        if ($taskAcs -notcontains $ac) { Aviso "docs/specs/${feature}: $ac nao tem task que o cubra" }
      }
    }
  }

  $hasEvidenceMarker = $false
  $expectedEvidencePath = "docs/plans/$feature/evidence.md"
  $escapedEvidencePath = [regex]::Escape($expectedEvidencePath)
  $evidenceMarkerPattern = (
    '^- \*\*Evidence:\*\*[ \t]+(?:`' + $escapedEvidencePath + '`|' +
    $escapedEvidencePath + ')(?:[ \t]+.*)?$'
  )
  foreach ($markerFile in @($plan, $tasks)) {
    if (-not (Test-Path $markerFile)) { continue }
    $markerLines = @(Get-Content -Encoding UTF8 $markerFile)
    $artifactHasTaskTable = $false
    foreach ($candidateTableHeader in $markerLines) {
      if ($candidateTableHeader -notmatch '^\|') { continue }
      $candidateHeaderCells = @($candidateTableHeader -split '\|' | ForEach-Object { $_.Trim() })
      if ($candidateHeaderCells -contains 'ID' -and
          $candidateHeaderCells -contains 'AC' -and
          $candidateHeaderCells -contains 'Estado') {
        $artifactHasTaskTable = $true
        break
      }
    }
    $artifactHasEvidenceMarker = $false
    $markerLineNumber = 0
    foreach ($markerLine in $markerLines) {
      $markerLineNumber++
      if ($markerLine -notmatch '^- \*\*Evidence:\*\*') { continue }
      $hasEvidenceMarker = $true
      $artifactHasEvidenceMarker = $true
      if ($markerLine -notmatch $evidenceMarkerPattern) {
        $markerRel = Rel $markerFile
        Erro "${markerRel}:${markerLineNumber}: Evidence deve apontar para '$expectedEvidencePath'"
      }
    }
    if ($artifactHasTaskTable -and -not $artifactHasEvidenceMarker) {
      $markerRel = Rel $markerFile
      Erro "${markerRel}: artefato com tabela de tasks exige '- **Evidence:** $expectedEvidencePath'"
    }
  }
  $hasEvidenceFile = Test-Path $evidence
  $hasNewState = @($taskStates.Values | Where-Object {
    $_ -match '^(verification-pending|blocked)$'
  }).Count -gt 0
  $contractActive = $hasEvidenceMarker -or $hasEvidenceFile -or $hasNewState

  foreach ($task in @($taskStates.Keys)) {
    $state = $taskStates[$task]
    if ($state -ne 'verification-pending' -and $state -ne 'done') { continue }
    if (@($taskAcsById[$task]).Count -eq 0) {
      Erro "${taskRel}: task $task em $state sob contrato Evidence exige ao menos um AC declarado na propria linha"
    }

    foreach ($dep in @($taskDepsById[$task])) {
      if (-not $taskStates.ContainsKey($dep)) {
        Erro "${taskRel}: task $task em $state depende de task inexistente $dep"
        continue
      }
      $depState = $taskStates[$dep]
      if ($state -eq 'verification-pending' -and $depState -notmatch '^(verification-pending|done)$') {
        Erro "${taskRel}: task $task verification-pending exige dependencia $dep em verification-pending ou done; atual: $depState"
      }
      if ($state -eq 'done' -and $depState -ne 'done') {
        Erro "${taskRel}: task $task done exige dependencia $dep em done; atual: $depState"
      }
    }
  }

  if (-not $hasEvidenceFile) {
    foreach ($task in @($taskStates.Keys)) {
      $state = $taskStates[$task]
      if ($state -notmatch '^(verification-pending|blocked|done)$') { continue }
      Erro "docs/plans/${feature}/evidence.md: ausente para task $task em estado $state"
    }
    continue
  }

  $evidenceRel = Rel $evidence
  $records = @()
  $evidenceBlocks = @()
  $currentBlock = $null
  $lines = @(Get-Content -Encoding UTF8 $evidence)
  $requiredFields = @(
    'Acao/comando',
    'Diretorio',
    'Fonte',
    'Exit code',
    'Saida/referencia',
    'Branch',
    'Limitacoes'
  )

  for ($index = 0; $index -lt $lines.Count; $index++) {
    $lineNo = $index + 1
    $line = $lines[$index]

    if ($line -match '^### ') {
      if ($null -ne $currentBlock) {
        $evidenceBlocks += $currentBlock
        $currentBlock = $null
      }

      $hm = [regex]::Match(
        $line,
        '^### (E[0-9]+) - (\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}:\d{2})) - (T[0-9]+) - (implement|review)$'
      )
      if (-not $hm.Success) {
        Erro "${evidenceRel}:${lineNo}: cabecalho invalido; esperado '### E<n> - <ISO-8601> - T<n> - <implement|review>'"
        continue
      }

      $headerValid = $true
      $headerTime = $hm.Groups[2].Value
      $headerTask = $hm.Groups[3].Value
      if (-not (Test-Iso8601 $headerTime)) {
        Erro "${evidenceRel}:${lineNo}: data/hora invalida no cabecalho: '$headerTime'"
        $headerValid = $false
      }
      if (-not $taskIds.ContainsKey($headerTask)) {
        Erro "${evidenceRel}:${lineNo}: cabecalho referencia task $headerTask ausente em $taskRel"
        $headerValid = $false
      }

      $currentBlock = [pscustomobject]@{
        Id = $hm.Groups[1].Value
        Time = $headerTime
        Task = $headerTask
        Phase = $hm.Groups[4].Value
        HeaderLine = $lineNo
        Valid = $headerValid
        Records = @()
        Blockers = @()
        Reclassifications = @()
        Fields = @{}
        FieldCounts = @{}
      }
      continue
    }

    if ($line -match '^- \*\*Reclassificacao:\*\*') {
      if ($null -eq $currentBlock) {
        Erro "${evidenceRel}:${lineNo}: Reclassificacao fora de bloco de evidencia"
        continue
      }
      $reclassificationAfterRecord = @($currentBlock.Records).Count -eq 1
      if (-not $reclassificationAfterRecord) {
        Erro "${evidenceRel}:${lineNo}: Reclassificacao deve aparecer depois do unico Registro do bloco"
        $currentBlock.Valid = $false
      }
      $rcm = [regex]::Match($line, '^- \*\*Reclassificacao:\*\* (.*)$')
      if (-not $rcm.Success) {
        Erro "${evidenceRel}:${lineNo}: Reclassificacao invalida; esperado 5 campos"
        $currentBlock.Valid = $false
        continue
      }
      $rcCells = @($rcm.Groups[1].Value -split '\|' | ForEach-Object { $_.Trim() })
      if ($rcCells.Count -ne 5) {
        Erro "${evidenceRel}:${lineNo}: Reclassificacao invalida; esperado 5 campos"
        $currentBlock.Valid = $false
        continue
      }
      $rcValid = $reclassificationAfterRecord
      if ($rcCells[0] -notmatch '^T[0-9]+$' -or -not $taskIds.ContainsKey($rcCells[0])) {
        Erro "${evidenceRel}:${lineNo}: task invalida na Reclassificacao: '$($rcCells[0])'"
        $rcValid = $false
      }
      if ($rcCells[1] -ne 'done') {
        Erro "${evidenceRel}:${lineNo}: origem da Reclassificacao deve ser done"
        $rcValid = $false
      }
      if ($rcCells[2] -ne 'ready') {
        Erro "${evidenceRel}:${lineNo}: destino da Reclassificacao deve ser ready"
        $rcValid = $false
      }
      if (-not (Test-Iso8601 $rcCells[3])) {
        Erro "${evidenceRel}:${lineNo}: data/hora invalida na Reclassificacao: '$($rcCells[3])'"
        $rcValid = $false
      }
      if (Is-Placeholder $rcCells[4]) {
        Erro "${evidenceRel}:${lineNo}: motivo/referencia vazio ou placeholder na Reclassificacao"
        $rcValid = $false
      }
      if ($rcCells[0] -ne $currentBlock.Task) {
        Erro "${evidenceRel}:${lineNo}: task $($rcCells[0]) da Reclassificacao diverge do cabecalho $($currentBlock.Task)"
        $rcValid = $false
      }
      if ($currentBlock.Phase -ne 'review') {
        Erro "${evidenceRel}:${lineNo}: Reclassificacao exige bloco review"
        $rcValid = $false
      }
      $currentBlock.Reclassifications += [pscustomobject]@{
        Task = $rcCells[0]; Line = $lineNo; Valid = $rcValid
      }
      continue
    }

    if ($line -match '^- \*\*Registro:\*\*') {
      if ($null -eq $currentBlock) {
        Erro "${evidenceRel}:${lineNo}: Registro fora de bloco de evidencia"
        continue
      }
      $rm = [regex]::Match($line, '^- \*\*Registro:\*\* (.*)$')
      if (-not $rm.Success) {
        Erro "${evidenceRel}:${lineNo}: Registro invalido; esperado 5 campos"
        $currentBlock.Valid = $false
        continue
      }
      $cells = @($rm.Groups[1].Value -split '\|' | ForEach-Object { $_.Trim() })
      if ($cells.Count -ne 5) {
        Erro "${evidenceRel}:${lineNo}: Registro invalido; esperado 5 campos"
        $currentBlock.Valid = $false
        continue
      }

      $task = $cells[0]
      $acs = $cells[1]
      $phase = $cells[2]
      $result = $cells[3]
      $ref = $cells[4]
      $recordAcs = @()
      $valid = $true

      if ($task -notmatch '^T[0-9]+$') {
        Erro "${evidenceRel}:${lineNo}: task invalida no Registro: '$task'"
        $valid = $false
      } elseif (-not $taskIds.ContainsKey($task)) {
        Erro "${evidenceRel}:${lineNo}: Registro referencia task $task ausente em $taskRel"
        $valid = $false
      }

      if ($acs -notmatch '^AC[0-9]+(\s*,\s*AC[0-9]+)*$') {
        Erro "${evidenceRel}:${lineNo}: lista de AC invalida no Registro: '$acs'"
        $valid = $false
      } else {
        $recordAcs = @($acs -split ',' | ForEach-Object { $_.Trim() } | Sort-Object -Unique)
        foreach ($ac in $recordAcs) {
          if ($specAcs -notcontains $ac) {
            Erro "${evidenceRel}:${lineNo}: Registro referencia $ac, que nao existe na spec"
            $valid = $false
          }
        }
      }

      if ($phase -notmatch '^(implement|review)$') {
        Erro "${evidenceRel}:${lineNo}: origem invalida no Registro: '$phase'"
        $valid = $false
      }
      if ($result -notmatch '^(pass|fail|observed|not-run|unavailable)$') {
        Erro "${evidenceRel}:${lineNo}: resultado invalido no Registro: '$result'"
        $valid = $false
      }
      if ($ref -notmatch '^((commit|worktree)@[0-9A-Fa-f]{7,40}|unavailable)$') {
        Erro "${evidenceRel}:${lineNo}: referencia invalida no Registro: '$ref'"
        $valid = $false
      }
      if ($task -ne $currentBlock.Task) {
        Erro "${evidenceRel}:${lineNo}: task $task do Registro diverge do cabecalho $($currentBlock.Task)"
        $valid = $false
      }
      if ($phase -ne $currentBlock.Phase) {
        Erro "${evidenceRel}:${lineNo}: fase $phase do Registro diverge do cabecalho $($currentBlock.Phase)"
        $valid = $false
      }

      $recordObject = [pscustomobject]@{
        Task = $task; Acs = $recordAcs; Phase = $phase; Result = $result; Ref = $ref
        Line = $lineNo; Valid = $valid; BlockLine = $currentBlock.HeaderLine
        HasValidBlocker = $false; HasValidReclassification = $false
      }
      $currentBlock.Records += $recordObject
      continue
    }

    if ($line -match '^- \*\*Bloqueio:\*\*') {
      if ($null -eq $currentBlock) {
        Erro "${evidenceRel}:${lineNo}: Bloqueio fora de bloco de evidencia"
        continue
      }
      if (@($currentBlock.Records).Count -ne 1) {
        Erro "${evidenceRel}:${lineNo}: Bloqueio deve aparecer depois do unico Registro do bloco"
        $currentBlock.Valid = $false
      }
      $bm = [regex]::Match($line, '^- \*\*Bloqueio:\*\* (.*)$')
      if (-not $bm.Success) {
        Erro "${evidenceRel}:${lineNo}: Bloqueio invalido; esperado 3 campos"
        $currentBlock.Valid = $false
        continue
      }
      $cells = @($bm.Groups[1].Value -split '\|' | ForEach-Object { $_.Trim() })
      if ($cells.Count -ne 3) {
        Erro "${evidenceRel}:${lineNo}: Bloqueio invalido; esperado 3 campos"
        $currentBlock.Valid = $false
        continue
      }

      $task = $cells[0]
      $reason = $cells[1]
      $condition = $cells[2]
      $valid = $true
      if ($task -notmatch '^T[0-9]+$') {
        Erro "${evidenceRel}:${lineNo}: task invalida no Bloqueio: '$task'"
        $valid = $false
      } elseif (-not $taskIds.ContainsKey($task)) {
        Erro "${evidenceRel}:${lineNo}: Bloqueio referencia task $task ausente em $taskRel"
        $valid = $false
      }
      if (Is-Placeholder $reason) {
        Erro "${evidenceRel}:${lineNo}: motivo vazio ou placeholder no Bloqueio de $task"
        $valid = $false
      }
      if (Is-Placeholder $condition) {
        Erro "${evidenceRel}:${lineNo}: condicao vazia ou placeholder no Bloqueio de $task"
        $valid = $false
      }
      if ($task -ne $currentBlock.Task) {
        Erro "${evidenceRel}:${lineNo}: task $task do Bloqueio diverge do cabecalho $($currentBlock.Task)"
        $valid = $false
      }
      $currentBlock.Blockers += [pscustomobject]@{ Task = $task; Line = $lineNo; Valid = $valid }
      continue
    }

    $fm = [regex]::Match(
      $line,
      '^- \*\*(Acao/comando|Diretorio|Fonte|Exit code|Saida/referencia|Branch|Limitacoes):\*\*(?: (.*))?$'
    )
    if ($fm.Success) {
      if ($null -eq $currentBlock) {
        Erro "${evidenceRel}:${lineNo}: campo $($fm.Groups[1].Value) fora de bloco de evidencia"
        continue
      }
      if (@($currentBlock.Records).Count -eq 0) {
        Erro "${evidenceRel}:${lineNo}: campo canonico deve aparecer depois do Registro"
        $currentBlock.Valid = $false
      }
      $fieldName = $fm.Groups[1].Value
      $fieldValue = $fm.Groups[2].Value.Trim()
      if (-not $currentBlock.FieldCounts.ContainsKey($fieldName)) {
        $currentBlock.FieldCounts[$fieldName] = 0
      }
      $currentBlock.FieldCounts[$fieldName]++
      if ($currentBlock.FieldCounts[$fieldName] -gt 1) {
        Erro "${evidenceRel}:${lineNo}: campo $fieldName duplicado no bloco iniciado na linha $($currentBlock.HeaderLine)"
        $currentBlock.Valid = $false
      } else {
        $currentBlock.Fields[$fieldName] = [pscustomobject]@{ Value = $fieldValue; Line = $lineNo }
      }
      if (Is-Placeholder $fieldValue) {
        Erro "${evidenceRel}:${lineNo}: campo $fieldName vazio ou placeholder"
        $currentBlock.Valid = $false
      }
    }
  }

  if ($null -ne $currentBlock) { $evidenceBlocks += $currentBlock }
  if (@($evidenceBlocks).Count -eq 0) {
    Erro "${evidenceRel}: evidence.md existe, mas nao contem nenhum bloco canonico de evidencia"
  }

  $previousEntryNumber = [long]0
  foreach ($block in @($evidenceBlocks)) {
    $actualEntryNumber = [long]0
    $numericId = $block.Id.Substring(1)
    if (-not [long]::TryParse($numericId, [ref]$actualEntryNumber)) {
      Erro "${evidenceRel}:$($block.HeaderLine): ID de evidencia fora do intervalo suportado: $($block.Id)"
      $block.Valid = $false
      continue
    }
    $expectedEntryNumber = $previousEntryNumber + 1
    $expectedEntryId = "E$expectedEntryNumber"
    if ($block.Id -ne $expectedEntryId) {
      Erro "${evidenceRel}:$($block.HeaderLine): sequencia de evidencia invalida; esperado $expectedEntryId apos E$previousEntryNumber, encontrado $($block.Id)"
      $block.Valid = $false
    }
    $previousEntryNumber = $actualEntryNumber
  }

  foreach ($block in @($evidenceBlocks)) {
    if (@($block.Records).Count -ne 1) {
      Erro "${evidenceRel}:$($block.HeaderLine): bloco deve conter exatamente um Registro; encontrados $(@($block.Records).Count)"
      $block.Valid = $false
    }
    foreach ($fieldName in $requiredFields) {
      if (-not $block.Fields.ContainsKey($fieldName)) {
        Erro "${evidenceRel}:$($block.HeaderLine): bloco sem campo obrigatorio '- **${fieldName}:**'"
        $block.Valid = $false
      }
    }
    if (@($block.Blockers).Count -gt 1) {
      Erro "${evidenceRel}:$($block.HeaderLine): bloco contem mais de um Bloqueio"
      $block.Valid = $false
    }
    if (@($block.Reclassifications).Count -gt 1) {
      Erro "${evidenceRel}:$($block.HeaderLine): bloco contem mais de uma Reclassificacao"
      $block.Valid = $false
    }

    if (@($block.Records).Count -eq 1) {
      $record = $block.Records[0]
      if (@($block.Blockers).Count -eq 1 -and $record.Result -notmatch '^(fail|not-run|unavailable)$') {
        Erro "${evidenceRel}:$($block.HeaderLine): bloco com Bloqueio exige Registro fail, not-run ou unavailable; atual: $($record.Result)"
        $block.Valid = $false
      }
      if (@($block.Reclassifications).Count -eq 1 -and
          ($record.Phase -ne 'review' -or $record.Result -ne 'not-run' -or
           $record.Task -ne $block.Reclassifications[0].Task)) {
        Erro "${evidenceRel}:$($block.HeaderLine): Reclassificacao exige Registro review | not-run da mesma task"
        $block.Valid = $false
      }
      if ($block.Fields.ContainsKey('Exit code')) {
        $exitValue = $block.Fields['Exit code'].Value
        $exitValid = $true
        switch ($record.Result) {
          'pass' {
            if ($exitValue -ne '0') { $exitValid = $false }
          }
          'fail' {
            $parsedExit = [long]0
            if ($exitValue -notmatch '^-?[0-9]+$' -or
                -not [long]::TryParse($exitValue, [ref]$parsedExit) -or
                $parsedExit -eq 0) {
              $exitValid = $false
            }
          }
          'observed' {
            if ($exitValue -ne 'not-applicable') { $exitValid = $false }
          }
          'not-run' {
            if ($exitValue -ne 'not-applicable') { $exitValid = $false }
          }
          'unavailable' {
            if ($exitValue -ne 'unavailable') { $exitValid = $false }
          }
        }
        if (-not $exitValid) {
          Erro "${evidenceRel}:$($block.Fields['Exit code'].Line): Exit code '$exitValue' incoerente com resultado $($record.Result)"
          $block.Valid = $false
        }
      }

      $validBlocker = @($block.Blockers | Where-Object {
        $_.Valid -and $_.Task -eq $record.Task
      })
      $record.HasValidBlocker = $validBlocker.Count -eq 1
      $record.Valid = $record.Valid -and $block.Valid
      $validReclassification = @($block.Reclassifications | Where-Object {
        $_.Valid -and $_.Task -eq $record.Task
      })
      $record.HasValidReclassification = (
        $record.Valid -and $record.Phase -eq 'review' -and $record.Result -eq 'not-run' -and
        $validReclassification.Count -eq 1
      )
      $records += $record
    }
  }

  foreach ($block in @($evidenceBlocks)) {
    foreach ($reclassification in @($block.Reclassifications)) {
      $reclassificationTask = $reclassification.Task
      if (-not $taskStates.ContainsKey($reclassificationTask)) { continue }

      if (@($block.Records).Count -ne 1) { continue }
      $reclassificationReview = $block.Records[0]
      $hasImplementAfterReclassification = @($records | Where-Object {
        $_.Task -eq $reclassificationTask -and $_.Phase -eq 'implement' -and
        $_.Line -gt $reclassificationReview.Line
      }).Count -gt 0
      if (-not $hasImplementAfterReclassification -and $taskStates[$reclassificationTask] -ne 'ready') {
        Erro "${evidenceRel}:$($reclassification.Line): Reclassificacao exige task atual $reclassificationTask em ready; atual: $($taskStates[$reclassificationTask])"
      }

      if ($reclassificationReview.Phase -ne 'review' -or
          $reclassificationReview.Result -ne 'not-run' -or
          $reclassificationReview.Task -ne $reclassificationTask) {
        continue
      }

      $priorImplementRecords = @($records | Where-Object {
        $_.Task -eq $reclassificationTask -and $_.Phase -eq 'implement' -and
        $_.Line -lt $reclassificationReview.Line
      })
      $priorImplement = $null
      if ($priorImplementRecords.Count -gt 0) {
        $priorImplement = $priorImplementRecords[$priorImplementRecords.Count - 1]
      }

      $implementationProvesDone = (
        $null -ne $priorImplement -and $priorImplement.Valid -and
        $priorImplement.Result -match '^(pass|observed)$' -and
        $priorImplement.Ref -match '^(commit|worktree)@[0-9A-Fa-f]{7,40}$' -and
        (Test-RecordCoversAcs $priorImplement $taskAcsById[$reclassificationTask])
      )
      $reviewProvesDone = $false
      if ($implementationProvesDone) {
        foreach ($candidate in @($records | Where-Object {
          $_.Task -eq $reclassificationTask -and $_.Phase -eq 'review' -and
          $_.Line -gt $priorImplement.Line -and $_.Line -lt $reclassificationReview.Line
        })) {
          if ($candidate.Valid -and $candidate.Result -match '^(pass|observed)$' -and
              $candidate.Ref -match '^(commit|worktree)@[0-9A-Fa-f]{7,40}$' -and
              (Test-RecordCoversAcs $candidate $taskAcsById[$reclassificationTask])) {
            $negativeReviewBeforeSuccess = @($records | Where-Object {
              $_.Task -eq $reclassificationTask -and $_.Phase -eq 'review' -and
              $_.Line -gt $priorImplement.Line -and $_.Line -lt $candidate.Line -and
              $_.Result -match '^(fail|unavailable)$'
            }).Count -gt 0
            if (-not $negativeReviewBeforeSuccess) {
              $reviewProvesDone = $true
            }
          }
        }
      }

      if (-not $implementationProvesDone -or -not $reviewProvesDone) {
        Erro "${evidenceRel}:$($reclassification.Line): Reclassificacao de $reclassificationTask sem prova anterior valida de done (implement + review success)"
      }
    }
  }

  if ($contractActive) {
    foreach ($task in @($taskStates.Keys)) {
      $taskImplements = @($records | Where-Object {
        $_.Task -eq $task -and $_.Phase -eq 'implement'
      })
      foreach ($candidateImplement in $taskImplements) {
        $latestDoneReviewBeforeImplement = $null
        foreach ($candidateReview in @($records | Where-Object {
          $_.Task -eq $task -and $_.Phase -eq 'review' -and
          $_.Line -lt $candidateImplement.Line -and $_.Result -match '^(pass|observed)$'
        })) {
          if (-not $candidateReview.Valid -or
              $candidateReview.Ref -notmatch '^(commit|worktree)@[0-9A-Fa-f]{7,40}$' -or
              -not (Test-RecordCoversAcs $candidateReview $taskAcsById[$task])) {
            continue
          }

          $implementsBeforeReview = @($records | Where-Object {
            $_.Task -eq $task -and $_.Phase -eq 'implement' -and
            $_.Line -lt $candidateReview.Line
          })
          if ($implementsBeforeReview.Count -eq 0) { continue }
          $implementBeforeReview = $implementsBeforeReview[$implementsBeforeReview.Count - 1]
          if (-not $implementBeforeReview.Valid -or
              $implementBeforeReview.Result -notmatch '^(pass|observed)$' -or
              $implementBeforeReview.Ref -notmatch '^(commit|worktree)@[0-9A-Fa-f]{7,40}$' -or
              -not (Test-RecordCoversAcs $implementBeforeReview $taskAcsById[$task])) {
            continue
          }

          $negativeReviewBeforeSuccess = @($records | Where-Object {
            $_.Task -eq $task -and $_.Phase -eq 'review' -and
            $_.Line -gt $implementBeforeReview.Line -and $_.Line -lt $candidateReview.Line -and
            $_.Result -match '^(fail|unavailable)$'
          }).Count -gt 0
          if (-not $negativeReviewBeforeSuccess) {
            $latestDoneReviewBeforeImplement = $candidateReview
          }
        }

        if ($null -eq $latestDoneReviewBeforeImplement) { continue }
        $reclassificationBeforeImplement = @($records | Where-Object {
          $_.Task -eq $task -and $_.Phase -eq 'review' -and $_.Result -eq 'not-run' -and
          $_.Line -gt $latestDoneReviewBeforeImplement.Line -and $_.Line -lt $candidateImplement.Line -and
          $_.HasValidReclassification
        })
        if ($reclassificationBeforeImplement.Count -eq 0) {
          Erro "${evidenceRel}: task $task tem implement na linha $($candidateImplement.Line) apos review done sem review not-run + Reclassificacao valida entre as transicoes"
        }
      }
    }
  }

  if ($contractActive) {
    foreach ($task in @($taskStates.Keys)) {
      if ($taskStates[$task] -eq 'done') { continue }
      $latestDoneProof = $null
      $baseValid = $false
      $reviewTainted = $false
      foreach ($candidate in @($records | Where-Object { $_.Task -eq $task })) {
        if ($candidate.Phase -eq 'implement') {
          if ($candidate.Valid -and $candidate.Result -match '^(pass|observed)$' -and
              $candidate.Ref -match '^(commit|worktree)@[0-9A-Fa-f]{7,40}$' -and
              (Test-RecordCoversAcs $candidate $taskAcsById[$task])) {
            $baseValid = $true
            $reviewTainted = $false
          }
          continue
        }
        if ($candidate.Phase -ne 'review' -or -not $baseValid) { continue }
        if ($candidate.Result -match '^(fail|unavailable)$') {
          $reviewTainted = $true
          continue
        }
        if (-not $reviewTainted -and $candidate.Valid -and
            $candidate.Result -match '^(pass|observed)$' -and
            $candidate.Ref -match '^(commit|worktree)@[0-9A-Fa-f]{7,40}$' -and
            (Test-RecordCoversAcs $candidate $taskAcsById[$task])) {
          $latestDoneProof = $candidate
        }
      }

      if ($null -eq $latestDoneProof) { continue }
      $reclassificationAfterDone = @($records | Where-Object {
        $_.Task -eq $task -and $_.Phase -eq 'review' -and $_.Result -eq 'not-run' -and
        $_.Line -gt $latestDoneProof.Line -and $_.HasValidReclassification
      })
      if ($reclassificationAfterDone.Count -eq 0) {
        Erro "${evidenceRel}: task $task tem prova valida de done na linha $($latestDoneProof.Line), mas estado atual '$($taskStates[$task])' sem Reclassificacao posterior"
      }
    }
  }

  foreach ($task in @($taskStates.Keys)) {
    $state = $taskStates[$task]
    if ($state -eq 'ready' -and $contractActive) {
      $readyImpl = Latest-Record $records $task 'implement'
      if ($null -ne $readyImpl -and $readyImpl.Valid -and
          $readyImpl.Result -match '^(pass|observed)$' -and
          $readyImpl.Ref -match '^(commit|worktree)@[0-9A-Fa-f]{7,40}$' -and
          (Test-RecordCoversAcs $readyImpl $taskAcsById[$task])) {
        $doneReviews = @()
        foreach ($candidate in @($records | Where-Object {
          $_.Task -eq $task -and $_.Phase -eq 'review' -and $_.Line -gt $readyImpl.Line
        })) {
          if ($candidate.Valid -and $candidate.Result -match '^(pass|observed)$' -and
              $candidate.Ref -match '^(commit|worktree)@[0-9A-Fa-f]{7,40}$' -and
              (Test-RecordCoversAcs $candidate $taskAcsById[$task])) {
            $negativeReviewBeforeSuccess = @($records | Where-Object {
              $_.Task -eq $task -and $_.Phase -eq 'review' -and
              $_.Line -gt $readyImpl.Line -and $_.Line -lt $candidate.Line -and
              $_.Result -match '^(fail|unavailable)$'
            }).Count -gt 0
            if (-not $negativeReviewBeforeSuccess) {
              $doneReviews += $candidate
            }
          }
        }

        $latestReclassificationReview = $null
        foreach ($candidate in @($records | Where-Object {
          $_.Task -eq $task -and $_.Phase -eq 'review' -and
          $_.Result -eq 'not-run' -and $_.Line -gt $readyImpl.Line
        })) {
          $hasDoneReviewBefore = @($doneReviews | Where-Object { $_.Line -lt $candidate.Line }).Count -gt 0
          if ($hasDoneReviewBefore) { $latestReclassificationReview = $candidate }
        }

        if ($null -ne $latestReclassificationReview -and
            -not $latestReclassificationReview.HasValidReclassification) {
          Erro "${evidenceRel}: task $task ready apos review done e review not-run exige Reclassificacao valida no bloco not-run mais recente"
        }
      }
      continue
    }
    if ($state -notmatch '^(verification-pending|blocked|done)$') { continue }

    if ($state -eq 'blocked') {
      $taskRecords = @($records | Where-Object { $_.Task -eq $task })
      if ($taskRecords.Count -eq 0) {
        Erro "${evidenceRel}: task $task blocked exige Registro implement ou review valido"
      } else {
        $latestTaskRecord = $taskRecords[$taskRecords.Count - 1]
        if (-not $latestTaskRecord.Valid -or $latestTaskRecord.Result -notmatch '^(fail|not-run|unavailable)$') {
          Erro "${evidenceRel}: task $task blocked exige Registro valido mais recente com fail, not-run ou unavailable"
        } elseif (-not $latestTaskRecord.HasValidBlocker) {
          Erro "${evidenceRel}: task $task blocked exige Bloqueio valido no mesmo bloco do Registro negativo mais recente"
        }
      }
      continue
    }

    $impl = Latest-Record $records $task 'implement'
    if ($null -eq $impl) {
      Erro "${evidenceRel}: task $task em estado $state sem Registro implement"
      continue
    }

    if (-not $impl.Valid -or $impl.Result -notmatch '^(pass|observed)$' -or
        $impl.Ref -notmatch '^(commit|worktree)@[0-9A-Fa-f]{7,40}$') {
      Erro "${evidenceRel}: task $task em estado $state exige ultimo implement pass/observed com SHA"
    }
    foreach ($declaredAc in @($taskAcsById[$task])) {
      if ($impl.Acs -notcontains $declaredAc) {
        Erro "${evidenceRel}: ultimo implement da task $task nao cobre AC declarado $declaredAc"
      }
    }

    if ($state -eq 'verification-pending') {
      $reviewsAfterImpl = @($records | Where-Object {
        $_.Task -eq $task -and $_.Phase -eq 'review' -and $_.Line -gt $impl.Line
      })
      foreach ($pendingReview in $reviewsAfterImpl) {
        if ($pendingReview.Result -ne 'not-run') {
          Erro "${evidenceRel}: task $task verification-pending tem review posterior ao implement com resultado $($pendingReview.Result); somente not-run e coerente"
        }
      }
    }

    if ($state -eq 'done') {
      $review = Latest-Record $records $task 'review'
      if ($null -eq $review) {
        Erro "${evidenceRel}: task $task done sem Registro review"
      } elseif (-not $review.Valid -or $review.Result -notmatch '^(pass|observed)$' -or
                $review.Ref -notmatch '^(commit|worktree)@[0-9A-Fa-f]{7,40}$') {
        Erro "${evidenceRel}: task $task done exige ultimo review pass/observed com SHA"
      } elseif ($review.Line -le $impl.Line) {
        Erro "${evidenceRel}: task $task done exige review posterior ao implement"
      }
      if ($null -ne $review -and $review.Result -match '^(pass|observed)$' -and
          $review.Line -gt $impl.Line) {
        $negativeReviewsBeforeSuccess = @($records | Where-Object {
          $_.Task -eq $task -and $_.Phase -eq 'review' -and
          $_.Line -gt $impl.Line -and $_.Line -lt $review.Line -and
          $_.Result -match '^(fail|unavailable)$'
        })
        if ($negativeReviewsBeforeSuccess.Count -gt 0) {
          $latestNegativeReview = $negativeReviewsBeforeSuccess[$negativeReviewsBeforeSuccess.Count - 1]
          Erro "${evidenceRel}: task $task done tem review $($latestNegativeReview.Result) apos o ultimo implement e antes do review success; exige novo implement"
        }
      }
      if ($null -ne $review) {
        foreach ($declaredAc in @($taskAcsById[$task])) {
          if ($review.Acs -notcontains $declaredAc) {
            Erro "${evidenceRel}: ultimo review da task $task nao cobre AC declarado $declaredAc"
          }
        }
      }
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
