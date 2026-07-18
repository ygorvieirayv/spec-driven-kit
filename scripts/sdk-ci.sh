#!/usr/bin/env bash
# Fail-closed runner for the consumer project's declared quality gates.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GATES_DIR="$ROOT/.specify/ci/gates"
CONTEXT="$ROOT/.specify/memory/project-context.md"
WORKFLOW="$ROOT/.github/workflows/sdk-quality.yml"
MODE="run"
ERRORS=0
CANONICAL_GATES=(install lint typecheck test build dependency-audit)

usage() {
  cat <<'EOF'
Usage: bash scripts/sdk-ci.sh [--validate]

With no argument, validates every gate and then executes required gate scripts in canonical order.
--validate checks the contract without executing project commands.
EOF
}

case "${1:-}" in
  "") ;;
  --validate) MODE="validate" ;;
  -h|--help) usage; exit 0 ;;
  *) echo "sdk-ci: unknown argument: $1" >&2; usage >&2; exit 2 ;;
esac
[ "$#" -le 1 ] || { echo "sdk-ci: too many arguments" >&2; exit 2; }

ci_error() {
  echo "ERRO  CI $1" >&2
  ERRORS=$((ERRORS + 1))
}

is_canonical_gate() {
  local candidate="$1" gate
  for gate in "${CANONICAL_GATES[@]}"; do
    [ "$candidate" = "$gate" ] && return 0
  done
  return 1
}

has_real_command() {
  awk '
    {
      sub(/\r$/, "")
      line = $0
      gsub(/^[ \t]+|[ \t]+$/, "", line)
      if (line != "" && line !~ /^#/) found = 1
    }
    END { exit(found ? 0 : 1) }
  ' "$1"
}

skip_reason() {
  awk '
    {
      sub(/\r$/, "")
      line = $0
      gsub(/^[ \t]+|[ \t]+$/, "", line)
      if (line != "" && line !~ /^#/) {
        if (reason != "") reason = reason " "
        reason = reason line
      }
    }
    END { print reason }
  ' "$1"
}

context_contract() {
  local wanted="$1"
  awk -F'|' -v wanted="$wanted" '
    function trim(value) {
      gsub(/^[ \t]+|[ \t\r]+$/, "", value)
      gsub(/[`*_]/, "", value)
      return value
    }
    /^## Contrato de CI[ \t\r]*$/ { in_ci = 1; next }
    in_ci && /^## / { exit }
    in_ci && /^\|/ {
      gate = trim($2)
      if (gate != wanted) next
      count++
      contract = trim($3)
    }
    END {
      if (count != 1) exit 3
      if (contract == "obrigatório" || contract == "obrigatorio" || contract == "required") {
        print "required"
        exit 0
      }
      if (contract == "N/A") {
        print "skip"
        exit 0
      }
      exit 4
    }
  ' "$CONTEXT"
}

context_quality_runner() {
  awk '
    /^- \*\*Runner de quality:\*\*/ {
      count++
      value = $0
      sub(/^- \*\*Runner de quality:\*\*[ \t]*/, "", value)
      gsub(/^[ \t`]+|[ \t`\r]+$/, "", value)
    }
    END {
      if (count != 1 || value == "" || value ~ /[<>()]/ || value ~ /a confirmar/) exit 3
      print value
    }
  ' "$CONTEXT"
}

workflow_quality_runner() {
  awk '
    /^  quality:[ \t\r]*$/ { in_quality = 1; next }
    in_quality && /^  [^ ]/ { exit }
    in_quality && /^    runs-on:[ \t]*/ {
      count++
      value = $0
      sub(/^    runs-on:[ \t]*/, "", value)
      gsub(/^[ \t"'\''`]+|[ \t"'\''`\r]+$/, "", value)
    }
    END {
      if (count != 1 || value == "") exit 3
      print value
    }
  ' "$WORKFLOW"
}

if [ ! -f "$CONTEXT" ]; then
  ci_error ".specify/memory/project-context.md ausente; matriz aprovada de CI nao existe"
fi
if [ ! -f "$WORKFLOW" ]; then
  ci_error ".github/workflows/sdk-quality.yml ausente; workflow aprovado nao foi renderizado"
else
  approved_runner="$(context_quality_runner 2>/dev/null)"
  approved_runner_status=$?
  rendered_runner="$(workflow_quality_runner 2>/dev/null)"
  rendered_runner_status=$?
  if [ "$approved_runner_status" -ne 0 ]; then
    ci_error "Runner de quality ausente ou pendente no project-context.md"
  elif [ "$rendered_runner_status" -ne 0 ]; then
    ci_error "job quality sem runs-on canonico no workflow"
  elif [ "$approved_runner" != "$rendered_runner" ]; then
    ci_error "runs-on do workflow diverge do Runner de quality aprovado"
  fi
  if grep -Eq '__SDK_[A-Z_]+__|SDK-SETUP-(START|END)' "$WORKFLOW"; then
    ci_error "workflow ainda contem marcador nao renderizado do template"
  fi
  while IFS= read -r action; do
    action="$(printf '%s\n' "$action" | sed -E 's/^[[:space:]]*(-[[:space:]]*)?uses:[[:space:]]*//; s/[[:space:]]+#.*$//')"
    if [[ "$action" == ./* ]]; then
      continue
    fi
    if [[ "$action" =~ ^docker://.+@sha256:[0-9a-fA-F]{64}$ ]]; then
      continue
    fi
    if [[ "$action" =~ ^[^@[:space:]]+/[^@[:space:]]+@[0-9a-fA-F]{40}$ ]]; then
      continue
    fi
    ci_error "action '$action' nao esta fixada por SHA completo"
  done < <(grep -E '^[[:space:]]*(-[[:space:]]*)?uses:' "$WORKFLOW" || true)
fi

if [ ! -d "$GATES_DIR" ]; then
  ci_error ".specify/ci/gates ausente; bootstrap precisa declarar os seis gates"
else
  shopt -s nullglob
  for path in "$GATES_DIR"/*.sh "$GATES_DIR"/*.skip; do
    name="$(basename "$path")"
    gate="${name%.sh}"
    gate="${gate%.skip}"
    if ! is_canonical_gate "$gate"; then
      ci_error "$name nao pertence ao catalogo canonico de gates"
    fi
  done
  shopt -u nullglob

  for gate in "${CANONICAL_GATES[@]}"; do
    script="$GATES_DIR/$gate.sh"
    skip="$GATES_DIR/$gate.skip"
    has_script=0
    has_skip=0
    [ -f "$script" ] && has_script=1
    [ -f "$skip" ] && has_skip=1

    contract="$(context_contract "$gate" 2>/dev/null)"
    contract_status=$?
    if [ "$contract_status" -ne 0 ]; then
      ci_error "$gate sem contrato canonico required/N/A no project-context.md"
    elif [ "$has_script" -eq 1 ] && [ "$contract" != "required" ]; then
      ci_error "$gate.sh diverge do project-context.md, que declara N/A"
    elif [ "$has_skip" -eq 1 ] && [ "$contract" != "skip" ]; then
      ci_error "$gate.skip diverge do project-context.md, que declara required"
    fi

    if [ "$has_script" -eq 1 ] && [ "$has_skip" -eq 1 ]; then
      ci_error "$gate possui .sh e .skip; mantenha exatamente um contrato"
      continue
    fi
    if [ "$has_script" -eq 0 ] && [ "$has_skip" -eq 0 ]; then
      ci_error "$gate sem .sh nem .skip; ausencia nunca significa sucesso"
      continue
    fi

    if [ "$has_script" -eq 1 ]; then
      if ! has_real_command "$script"; then
        ci_error "$gate.sh nao contem comando executavel"
      fi
      if grep -Eiq -- '--if-present|\|\|[[:space:]]*true|(^|[;&[:space:]])set[[:space:]]+\+e([;&[:space:]]|$)' "$script"; then
        ci_error "$gate.sh contem bypass fail-open proibido"
      fi
      if grep -Eiq -- '<[^>]+>|\[VERIFICAR\]|\b(TODO|PENDING)\b' "$script"; then
        ci_error "$gate.sh contem placeholder pendente"
      fi
      continue
    fi

    reason="$(skip_reason "$skip")"
    if [ "${#reason}" -lt 12 ]; then
      ci_error "$gate.skip exige motivo concreto com pelo menos 12 caracteres"
    fi
    if printf '%s\n' "$reason" | grep -Eiq -- '<[^>]+>|\[VERIFICAR\]|\b(TODO|PENDING)\b|\b(ainda|futur[oa]|por implementar)\b'; then
      ci_error "$gate.skip contem motivo temporario ou placeholder; N/A precisa ser estrutural"
    fi
  done
fi

if [ "$ERRORS" -gt 0 ]; then
  echo "----------------------------------------" >&2
  echo "sdk-ci: contrato invalido ($ERRORS erro(s)); nenhum gate foi executado." >&2
  exit 1
fi

if [ "$MODE" = "validate" ]; then
  echo "sdk-ci: contrato valido; seis gates declarados."
  exit 0
fi

for gate in "${CANONICAL_GATES[@]}"; do
  script="$GATES_DIR/$gate.sh"
  skip="$GATES_DIR/$gate.skip"
  if [ -f "$skip" ]; then
    echo "SKIP  $gate: $(skip_reason "$skip")"
    continue
  fi

  [ "${GITHUB_ACTIONS:-}" = "true" ] && echo "::group::Gate $gate"
  echo "RUN   $gate"
  (
    cd "$ROOT"
    SDK_CI_GATE="$gate" bash -euo pipefail "$script"
  )
  status=$?
  [ "${GITHUB_ACTIONS:-}" = "true" ] && echo "::endgroup::"
  if [ "$status" -ne 0 ]; then
    echo "ERRO  CI gate $gate falhou com exit $status" >&2
    exit "$status"
  fi
done

echo "----------------------------------------"
echo "sdk-ci: todos os gates obrigatorios passaram."
