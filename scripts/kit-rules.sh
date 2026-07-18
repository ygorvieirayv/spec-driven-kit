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
  expected="$(printf '%s\n' KR-01 KR-02 KR-03 KR-04 KR-05 KR-06 KR-07 KR-08 KR-09)"
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
  for id in KR-01 KR-02 KR-03 KR-04 KR-05 KR-06 KR-07 KR-08 KR-09; do
    count="$(grep -cE "^\\| $id \\|" "$ROOT/scripts/kit-rules.txt" || true)"
    [ "$count" -eq 1 ] || rule_error "KR-INDEX" "scripts/kit-rules.txt: $id deve aparecer exatamente uma vez"
  done
}

check_legacy_modes() {
  local legacy_a legacy_b legacy_marker path rel
  legacy_a='PROTO'"TYPE"
  legacy_b='PRODUC'"TION"
  legacy_marker='- **'"Modo:"'**'

  if git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    while IFS= read -r -d '' rel; do
      path="$ROOT/$rel"
      [ -f "$path" ] || continue
      grep -Iq . "$path" || continue
      if grep -Eq "(^|[^[:alnum:]_])($legacy_a|$legacy_b)([^[:alnum:]_]|$)" "$path" || \
         grep -Fq -- "$legacy_marker" "$path"; then
        rule_error "KR-05" "$rel: modo global legado encontrado"
      fi
    done < <(git -C "$ROOT" ls-files -z)
  else
    while IFS= read -r -d '' path; do
      rel="${path#"$ROOT"/}"
      grep -Iq . "$path" || continue
      if grep -Eq "(^|[^[:alnum:]_])($legacy_a|$legacy_b)([^[:alnum:]_]|$)" "$path" || \
         grep -Fq -- "$legacy_marker" "$path"; then
        rule_error "KR-05" "$rel: modo global legado encontrado"
      fi
    done < <(find "$ROOT" -path "$ROOT/.git" -prune -o -type f -print0)
  fi
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
check_legacy_modes
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
require_match "KR-07" ".specify/memory/project-context.md" '^## Princípios específicos deste projeto' "contexto não possui princípios do projeto"
require_match "KR-07" "CLAUDE.md" 'project-context.md' "inventário instalado omite project-context"
require_match "KR-07" "CLAUDE.md" 'lessons.md.*não são motor|lessons.md.*nao sao motor' "inventário instalado não separa dados do projeto"
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

echo "----------------------------------------"
echo "kit-rules: $ERRORS erro(s)."
if [ "$ERRORS" -gt 0 ]; then
  echo "Invariantes divergentes — ver scripts/kit-rules.txt."
  exit 1
fi
exit 0
