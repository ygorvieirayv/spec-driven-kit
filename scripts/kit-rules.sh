#!/usr/bin/env bash
# Guarda determinística das invariantes transversais do motor do Spec Driven Kit.
# Responsabilidade diferente de sdk-check: este script valida o repositório do kit;
# sdk-check valida os artefatos de um projeto consumidor.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ERRORS=0

rule_error() {
  local id="$1" message="$2"
  echo "ERRO  $id $message"
  ERRORS=$((ERRORS + 1))
}

require_file() {
  local id="$1" path="$2"
  [ -f "$ROOT/$path" ] || rule_error "$id" "$path: arquivo obrigatório ausente"
}

require_match() {
  local id="$1" path="$2" pattern="$3" message="$4"
  if [ ! -f "$ROOT/$path" ]; then
    rule_error "$id" "$path: arquivo obrigatório ausente"
  elif ! grep -Eq "$pattern" "$ROOT/$path"; then
    rule_error "$id" "$path: $message"
  fi
}

reject_match() {
  local id="$1" path="$2" pattern="$3" message="$4"
  if [ ! -f "$ROOT/$path" ]; then
    rule_error "$id" "$path: arquivo obrigatório ausente"
  elif grep -Eq "$pattern" "$ROOT/$path"; then
    rule_error "$id" "$path: $message"
  fi
}

profile_rows() {
  local path="$1"
  awk -F'|' '
    function trim(value) {
      gsub(/^[ \t]+|[ \t\r]+$/, "", value)
      return value
    }
    /^## Perfis de prova[ \t\r]*$/ { in_section = 1; next }
    in_section && /^## / { exit }
    in_section && /^\|/ {
      cell = trim($2)
      gsub(/`/, "", cell)
      if (cell == "Perfil" || cell ~ /^-+$/ || cell == "") next
      print cell
    }
  ' "$ROOT/$path"
}

check_profiles() {
  local id="$1" path="$2"
  local expected actual
  expected="$(printf '%s\n' visual logic journey data-security operational delivery)"
  if [ ! -f "$ROOT/$path" ]; then
    rule_error "$id" "$path: arquivo obrigatório ausente"
    return
  fi
  actual="$(profile_rows "$path")"
  if [ "$actual" != "$expected" ]; then
    rule_error "$id" "$path: deve declarar exatamente visual, logic, journey, data-security, operational e delivery, nesta ordem"
  fi
}

check_rule_index() {
  local id count expected actual
  require_file "KR-INDEX" "scripts/kit-rules.txt"
  [ -f "$ROOT/scripts/kit-rules.txt" ] || return
  expected="$(printf '%s\n' KR-01 KR-02 KR-03 KR-04 KR-05 KR-06 KR-07 KR-08 KR-09 KR-10 KR-11)"
  actual="$(awk -F'|' '
    /^\| KR-[0-9]+ \|/ {
      id = $2
      gsub(/^[ \t]+|[ \t]+$/, "", id)
      print id
    }
  ' "$ROOT/scripts/kit-rules.txt" | sort -u)"
  if [ "$actual" != "$expected" ]; then
    rule_error "KR-INDEX" "scripts/kit-rules.txt: conjunto de IDs diverge das asserções implementadas"
  fi
  for id in KR-01 KR-02 KR-03 KR-04 KR-05 KR-06 KR-07 KR-08 KR-09 KR-10 KR-11; do
    count="$(grep -cE "^\\| $id \\|" "$ROOT/scripts/kit-rules.txt" || true)"
    [ "$count" -eq 1 ] || rule_error "KR-INDEX" "scripts/kit-rules.txt: $id deve aparecer exatamente uma vez"
  done
}

check_rule_index

# KR-01 - promoção para done pertence ao review.
require_match "KR-01" ".specify/memory/state-markers.md" '/sdk-implement.*nunca escreve.*done.*/sdk-review.*único dono' "dono da promoção para done não está explícito"
require_match "KR-01" ".specify/memory/constitution.md" 'Somente `/sdk-review`.*done|Somente `/sdk-review`.*reexecutar' "review não está declarado como único promotor"
require_match "KR-01" ".claude/commands/sdk-implement.md" 'Nunca marque `done`.*somente a `/sdk-review`' "implement pode aparentar promover done"
require_match "KR-01" ".claude/commands/sdk-review.md" 'Só esta etapa promove.*done' "review não assume a promoção para done"
require_match "KR-01" ".claude/agents/sdk-reviewer.md" 'não recomende `done`|Só recomende `done`' "reviewer não protege a conclusão"
require_match "KR-01" ".specify/templates/plan-template.md" 'somente `/sdk-review` promove para `done`' "template de plano perdeu o dono de done"
require_match "KR-01" ".specify/templates/tasks-template.md" 'promovida.*somente.*`/sdk-review`' "template de tasks perdeu o dono de done"
reject_match "KR-01" ".claude/commands/sdk-implement.md" 'A implementação pode marcar `done` diretamente' "implement contradiz o dono exclusivo de done"

# KR-02 - severidades que bloqueiam.
require_match "KR-02" ".specify/memory/constitution.md" 'Crítico e Alto bloqueiam sempre' "barra de bloqueio ausente"
require_match "KR-02" ".claude/commands/sdk-analyze.md" 'Crítico e Alto bloqueiam' "analyze pode liberar achado alto"
require_match "KR-02" ".claude/commands/sdk-review.md" 'Crítico e Alto bloqueiam sempre|Crítico/Alto bloqueiam sempre' "review pode aprovar bloqueador"
require_match "KR-02" ".claude/agents/sdk-reviewer.md" 'Crítico e Alto bloqueiam sempre' "reviewer pode aprovar bloqueador"
require_match "KR-02" ".specify/templates/agents-md-template.md" 'Crítico.*Alto.*bloqueiam sempre' "adaptador perdeu a barra de bloqueio"
reject_match "KR-02" ".claude/commands/sdk-review.md" 'Crítico e Alto podem ser aprovados com ressalvas' "review contradiz a barra de bloqueio"

# KR-03 - uma única fonte formal de tasks.
require_match "KR-03" ".specify/memory/state-markers.md" 'Tabela inline no plano não é fonte de task' "fonte canônica de tasks ausente"
require_match "KR-03" ".claude/commands/sdk-plan.md" '`tasks.md` será a única fonte canônica' "plan pode criar fonte concorrente"
require_match "KR-03" ".claude/commands/sdk-analyze.md" '`tasks.md` é a fonte canônica' "analyze não usa a fonte canônica"
require_match "KR-03" ".claude/commands/sdk-next.md" 'sem `tasks.md`.*`/sdk-tasks`|fonte única de tasks' "next pode pular sdk-tasks"
reject_match "KR-03" ".specify/templates/plan-template.md" '^## Tasks[[:space:]]*$' "template de plano contém tasks inline"
require_match "KR-03" ".specify/templates/tasks-template.md" '^\| ID \| Descrição \| Depende de \| AC \| Perfis \|' "cabeçalho canônico de tasks ausente"

# KR-04 - evidence real, append-only e com proveniência.
require_match "KR-04" ".specify/memory/state-markers.md" 'Entradas são.*append-only' "contrato append-only ausente"
require_match "KR-04" ".specify/memory/state-markers.md" 'ref guarda apenas proveniência|ref registra só proveniência' "proveniência da ref ausente"
require_match "KR-04" ".specify/templates/evidence-template.md" 'entradas são.*append-only|Entradas são.*append-only' "template permite reescrever evidence"
require_match "KR-04" ".claude/commands/sdk-implement.md" 'novo bloco append-only' "implement não exige nova entrada"
require_match "KR-04" ".claude/commands/sdk-review.md" 'novo bloco append-only' "review não exige nova entrada"

# KR-05 - barra única e fidelidade local.
require_match "KR-05" ".specify/memory/constitution.md" 'uma única barra de integridade' "barra única ausente"
require_match "KR-05" ".specify/templates/spec-template.md" '^- \*\*Risco:\*\*' "template de spec sem risco"
require_match "KR-05" ".specify/templates/spec-template.md" '^## Limites de fidelidade' "template de spec sem fidelidade"
require_match "KR-05" ".specify/templates/spec-template.md" '^- \*\*Limites intencionais:\*\* (nenhum|declarados abaixo)' "marcador de fidelidade inválido"

# KR-06 - catálogo de perfis.
check_profiles "KR-06" ".specify/memory/engineering-standards.md"
check_profiles "KR-06" ".specify/templates/plan-template.md"
require_match "KR-06" ".specify/memory/constitution.md" 'visual.*logic.*journey.*data-security.*operational.*delivery' "constituição perdeu o catálogo de perfis"

# KR-07 - fronteira motor x produto e propriedade dos arquivos.
require_match "KR-07" "scripts/kit-manifest.txt" '^SEED \.specify/memory/project-context\.md$' "project-context deve ser SEED"
require_match "KR-07" "scripts/kit-manifest.txt" '^MERGE \.specify/memory/lessons\.md$' "lessons deve ser MERGE"
require_match "KR-07" "scripts/kit-manifest.txt" '^ENGINE \.specify/memory/constitution\.md$' "constituição deve ser ENGINE puro"
reject_match "KR-07" ".specify/memory/constitution.md" '^## Princípios específicos deste projeto' "constituição ENGINE contém dados do projeto"
reject_match "KR-07" ".specify/memory/engineering-standards.md" '^## Padrões específicos deste projeto' "engineering-standards ENGINE contém dados do projeto"
require_match "KR-07" ".specify/memory/project-context.md" '^## Princípios específicos deste projeto' "contexto não possui princípios do projeto"
require_match "KR-07" "CLAUDE.md" 'project-context.md' "inventário instalado omite project-context"
require_match "KR-07" "CLAUDE.md" 'lessons.md.*são dados|lessons.md.*sao dados' "inventário instalado não classifica lessons como dado do projeto"
require_match "KR-07" "CLAUDE.md" 'não são motor|nao sao motor' "inventário instalado não separa dados do motor"
for consumer in .claude/commands/sdk-implement.md .claude/commands/sdk-review.md .claude/commands/sdk-doctor.md .claude/agents/sdk-reviewer.md; do
  require_match "KR-07" "$consumer" 'Motor × produto.*CLAUDE.md|motor × produto.*CLAUDE.md|fronteira.*CLAUDE.md' "consumidor não referencia a fronteira canônica"
done

# KR-08 - disjuntor anti-loop.
for consumer in .specify/memory/constitution.md CLAUDE.md .claude/commands/sdk-implement.md .claude/commands/sdk-review.md .claude/commands/sdk-doctor.md .claude/agents/sdk-reviewer.md; do
  require_match "KR-08" "$consumer" '[Dd]uas tentativas consecutivas|duas tentativas consecutivas' "disjuntor de duas tentativas ausente"
done
require_match "KR-08" ".specify/memory/constitution.md" 'terceira tentativa automática' "constituição permite terceira tentativa automática"

# KR-09 - toda mudança contratual invalida Analyze.
require_match "KR-09" ".specify/memory/state-markers.md" 'Análise velha não vale para contrato novo' "regra de invalidação ausente"
for consumer in .claude/commands/sdk-spec.md .claude/commands/sdk-clarify.md .claude/commands/sdk-decide.md .claude/commands/sdk-plan.md .claude/commands/sdk-tasks.md; do
  require_match "KR-09" "$consumer" 'Analyze.*pendente|pendente.*Analyze' "comando não invalida Analyze quando altera contrato"
done

# KR-10 - CI do consumidor falha fechado e atesta apenas o snapshot executado.
require_match "KR-10" ".specify/memory/engineering-standards.md" '^## CI do consumidor \(fail-closed\)' "fonte normativa de CI ausente"
for gate in install lint typecheck test build dependency-audit; do
  require_match "KR-10" ".specify/memory/engineering-standards.md" "\`$gate\`" "gate $gate ausente da fonte normativa"
done
require_match "KR-10" ".claude/commands/sdk-bootstrap.md" 'consumer-ci-template.yml.*sdk-quality.yml' "bootstrap não gera o workflow aprovado"
require_match "KR-10" ".claude/commands/sdk-bootstrap.md" 'sdk-ci.sh --validate' "bootstrap não valida o contrato antes de seguir"
for engine in scripts/sdk-ci.sh scripts/sdk-ci.ps1 scripts/sdk-secrets.sh .specify/templates/consumer-ci-template.yml; do
  require_match "KR-10" "scripts/kit-manifest.txt" "^ENGINE ${engine//./\\.}$" "$engine precisa viajar como ENGINE"
done
require_match "KR-10" "scripts/sdk-ci.sh" 'CANONICAL_GATES=\(install lint typecheck test build dependency-audit\)' "runner perdeu o catálogo canônico"
require_match "KR-10" "scripts/sdk-ci.sh" 'nenhum gate foi executado' "runner não valida tudo antes de executar"
require_match "KR-10" "scripts/sdk-ci.sh" 'project-context.md' "runner não compara gates com o contrato aprovado"
require_match "KR-10" "scripts/sdk-ci.ps1" 'sdk-ci.sh' "entrada PowerShell não delega à fonte canônica"
require_match "KR-10" "scripts/sdk-secrets.sh" 'GITLEAKS_VERSION="8\.30\.1"' "versão do scanner não está fixada"
require_match "KR-10" "scripts/sdk-secrets.sh" 'GITLEAKS_SHA256="551f6fc83ea457d62a0d98237cbad105af8d557003051f41f3e7ca7b3f2470eb"' "checksum oficial do scanner divergiu"
require_match "KR-10" "scripts/sdk-secrets.sh" 'shallow checkout is forbidden' "scanner aceita histórico parcial"
require_match "KR-10" "scripts/sdk-secrets.sh" 'disabledRules nao pode remover regras padrao' "scanner permite desativar defaults"
require_match "KR-10" "scripts/sdk-secrets.sh" '^"\$binary" git ' "scanner deixou de varrer o histórico"
require_match "KR-10" "scripts/sdk-secrets.sh" '^"\$binary" dir ' "scanner deixou de varrer a árvore atual"
require_match "KR-10" ".specify/templates/consumer-ci-template.yml" 'runs-on: __SDK_QUALITY_RUNNER__' "workflow não permite runner aprovado por stack"
require_match "KR-10" ".specify/templates/consumer-ci-template.yml" 'SDK-SETUP-START' "workflow perdeu o ponto de setup aprovado por stack"
require_match "KR-10" ".specify/templates/consumer-ci-template.yml" 'run: \./scripts/sdk-check.ps1' "workflow não valida estado"
require_match "KR-10" ".specify/templates/consumer-ci-template.yml" 'run: \./scripts/sdk-ci.ps1' "workflow não executa os gates"
require_match "KR-10" ".specify/templates/consumer-ci-template.yml" 'fetch-depth: 0' "secret scan não recebe histórico completo"
require_match "KR-10" ".specify/templates/consumer-ci-template.yml" 'run: bash scripts/sdk-secrets.sh' "workflow não executa secret scan"
reject_match "KR-10" ".specify/templates/consumer-ci-template.yml" 'continue-on-error|pull_request_target' "workflow contém bypass ou evento privilegiado"
if grep -E '^[[:space:]]*(-[[:space:]]*)?uses:' "$ROOT/.specify/templates/consumer-ci-template.yml" | \
   grep -Ev '@[0-9a-f]{40}([[:space:]]*#.*)?$' >/dev/null; then
  rule_error "KR-10" ".specify/templates/consumer-ci-template.yml: action sem SHA completo"
fi
require_match "KR-10" ".claude/commands/sdk-review.md" 'head_sha.*exatamente o commit' "review pode reutilizar CI de outro SHA"
require_match "KR-10" ".claude/agents/sdk-reviewer.md" 'project-context.md' "reviewer não recebe a matriz aprovada"
require_match "KR-10" ".claude/commands/sdk-review.md" 'gate.*externo.*não anexe novo recibo|gate.*externo.*nao anexe novo recibo' "review cria ciclo de atestação por SHA"
require_match "KR-10" ".claude/commands/sdk-doctor.md" 'sdk-ci.sh --validate' "doctor não valida o contrato de CI"

# KR-11 - cycle possui somente o trecho mecânico tasks -> analyze e next roteia os bloqueios sem ambiguidade.
require_match "KR-11" ".specify/memory/state-markers.md" '/sdk-cycle.*somente.*/sdk-tasks' "fonte normativa não limita o cycle a tasks"
require_match "KR-11" ".specify/memory/state-markers.md" '/sdk-analyze.*no máximo uma vez cada' "fonte normativa não limita cada etapa a uma execução"
require_match "KR-11" ".specify/memory/state-markers.md" 'para antes de checkpoint.*decisão' "fonte normativa permite cruzar checkpoint"
require_match "KR-11" ".specify/memory/state-markers.md" 'não escreve artefato nem marcador próprio' "fonte normativa permite estado próprio"
require_match "KR-11" ".claude/commands/sdk-cycle.md" '^SDK-CYCLE-ALLOWED=sdk-tasks,sdk-analyze$' "lista permitida do cycle divergiu"
require_match "KR-11" ".claude/commands/sdk-cycle.md" '^SDK-CYCLE-ORDER=sdk-tasks>sdk-analyze$' "ordem mecânica do cycle divergiu"
require_match "KR-11" ".claude/commands/sdk-cycle.md" '^SDK-CYCLE-MAX-RUNS-PER-STEP=1$' "cycle pode repetir etapa"
require_match "KR-11" ".claude/commands/sdk-cycle.md" '^SDK-CYCLE-OWNS-MARKERS=false$' "cycle passou a possuir markers"
require_match "KR-11" ".claude/commands/sdk-cycle.md" '^SDK-CYCLE-CROSSES-CHECKPOINTS=false$' "cycle pode cruzar checkpoint"
require_match "KR-11" ".claude/commands/sdk-cycle.md" '\.claude/commands/sdk-tasks\.md.*\.claude/commands/sdk-analyze\.md' "cycle não carrega os procedimentos canônicos"
reject_match "KR-11" ".claude/commands/sdk-cycle.md" '^SDK-CYCLE-ALLOWED=.*(roadmap|implement|review)' "cycle autorizou etapa não mecânica"
reject_match "KR-11" ".claude/commands/sdk-cycle.md" '^SDK-CYCLE-(OWNS-MARKERS|CROSSES-CHECKPOINTS)=true$' "cycle ampliou autonomia"
require_match "KR-11" ".claude/commands/sdk-next.md" 'Analyze:.*ajustar.*Não implemente' "next não bloqueia implementação após Analyze ajustar"
require_match "KR-11" ".claude/commands/sdk-next.md" 'Analyze:.*bloqueado.*Não avance' "next não roteia Analyze bloqueado"
require_match "KR-11" ".claude/commands/sdk-next.md" 'Review:.*bloqueado.*task.*blocked.*não resolvida.*Não avance' "next não prioriza task bloqueada sobre Review bloqueado"
require_match "KR-11" ".claude/commands/sdk-next.md" 'Precedência:.*Analyze: ajustar/bloqueado.*impede implementação' "precedência dos gates não está explícita"

echo "----------------------------------------"
echo "kit-rules: $ERRORS erro(s)."
if [ "$ERRORS" -gt 0 ]; then
  echo "Invariantes divergentes — ver scripts/kit-rules.txt."
  exit 1
fi
exit 0
