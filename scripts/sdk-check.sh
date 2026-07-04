#!/usr/bin/env bash
# sdk-check.sh — validação determinística dos marcadores de estado do Spec Driven Kit.
# Implementa o contrato de .specify/memory/state-markers.md. Zero token: só grep/awk.
#
# Uso: ./scripts/sdk-check.sh
# Saída: ERRO (viola o contrato — exit 1) · AVISO (incompleto/molde — não bloqueia).
# O /sdk-doctor roda este script como primeira camada (T0), antes de qualquer leitura por LLM.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ERROS=0
AVISOS=0

erro()  { echo "ERRO  $1"; ERROS=$((ERROS + 1)); }
aviso() { echo "AVISO $1"; AVISOS=$((AVISOS + 1)); }

rel() { echo "${1#"$ROOT"/}"; }

# ---------------------------------------------------------------- specs: Status
for spec in "$ROOT"/docs/specs/*/spec.md; do
  [ -e "$spec" ] || continue
  r="$(rel "$spec")"
  line="$(grep -m1 -E '^- \*\*Status:\*\*' "$spec" || true)"
  if [ -z "$line" ]; then
    erro "$r: sem a linha '- **Status:**' (contrato: state-markers.md)"
  elif echo "$line" | grep -q 'rascunho | em revisão | aprovada'; then
    aviso "$r: Status ainda no molde (não preenchido)"
  elif ! echo "$line" | grep -qE '^- \*\*Status:\*\* (rascunho|em revisão|aprovada)\b'; then
    erro "$r: Status fora do vocabulário (rascunho | em revisão | aprovada)"
  fi
done

# ------------------------------------------- planos: Status, Analyze, Review
for plan in "$ROOT"/docs/plans/*/plan.md; do
  [ -e "$plan" ] || continue
  r="$(rel "$plan")"

  line="$(grep -m1 -E '^- \*\*Status:\*\*' "$plan" || true)"
  if [ -z "$line" ]; then
    erro "$r: sem a linha '- **Status:**'"
  elif echo "$line" | grep -q 'rascunho | aprovado'; then
    aviso "$r: Status ainda no molde (não preenchido)"
  elif ! echo "$line" | grep -qE '^- \*\*Status:\*\* (rascunho|aprovado)\b'; then
    erro "$r: Status fora do vocabulário (rascunho | aprovado)"
  fi

  line="$(grep -m1 -E '^- \*\*Analyze:\*\*' "$plan" || true)"
  if [ -z "$line" ]; then
    aviso "$r: sem a linha '- **Analyze:**' (plano anterior ao contrato? adicione-a)"
  elif ! echo "$line" | grep -qE '^- \*\*Analyze:\*\* (pendente|consistente|ajustar|bloqueado)\b'; then
    erro "$r: Analyze fora do vocabulário (pendente | consistente | ajustar | bloqueado)"
  fi

  line="$(grep -m1 -E '^- \*\*Review:\*\*' "$plan" || true)"
  if [ -z "$line" ]; then
    aviso "$r: sem a linha '- **Review:**' (plano anterior ao contrato? adicione-a)"
  elif ! echo "$line" | grep -qE '^- \*\*Review:\*\* (—|aprovado( com ressalvas)?|bloqueado)'; then
    erro "$r: Review fora do vocabulário (— | aprovado | aprovado com ressalvas | bloqueado)"
  fi
done

# ------------------------------------------------------- tasks: estados válidos
# Linhas de task começam com '| T<n> |'; a coluna Estado é a última.
check_task_states() {
  local file="$1" r; r="$(rel "$file")"
  while IFS= read -r estado; do
    case "$estado" in
      backlog|ready|in-progress|done) ;;
      *"<"*|"") ;;  # placeholder de molde — ignora
      *) erro "$r: estado de task inválido: '$estado' (backlog | ready | in-progress | done)" ;;
    esac
  done < <(awk -F'|' '/^\| *T[0-9]+ *\|/ { v = $(NF-1); gsub(/^[ \t]+|[ \t]+$/, "", v); print v }' "$file")
}
for f in "$ROOT"/docs/plans/*/plan.md "$ROOT"/docs/plans/*/tasks.md; do
  [ -e "$f" ] || continue
  check_task_states "$f"
done

# ------------------------------------------------- AC <-> task (por feature)
for plandir in "$ROOT"/docs/plans/*/; do
  [ -d "$plandir" ] || continue
  feature="$(basename "$plandir")"
  plan="$plandir/plan.md"
  tasks="$plandir/tasks.md"
  spec="$ROOT/docs/specs/$feature/spec.md"
  [ -e "$plan" ] || [ -e "$tasks" ] || continue

  if [ ! -e "$spec" ]; then
    erro "docs/plans/$feature: existe plano mas não existe docs/specs/$feature/spec.md"
    continue
  fi

  spec_acs="$(grep -oE '\*\*AC[0-9]+\*\*' "$spec" | tr -d '*' | sort -u)"
  task_acs="$(cat "$plan" "$tasks" 2>/dev/null | grep -E '^\| *T[0-9]+' | grep -oE 'AC[0-9]+' | sort -u || true)"

  # task cita AC que não existe na spec -> ERRO
  for ac in $task_acs; do
    echo "$spec_acs" | grep -qx "$ac" || \
      erro "docs/plans/$feature: task referencia $ac, que não existe na spec"
  done

  # AC sem task (só relevante se já há tasks) -> AVISO
  if [ -n "$task_acs" ]; then
    for ac in $spec_acs; do
      echo "$task_acs" | grep -qx "$ac" || \
        aviso "docs/specs/$feature: $ac não tem task que o cubra"
    done
  fi
done

# ----------------------------------------------------- ledger: coluna Estado
EPICS="$ROOT/docs/epics.md"
if [ -e "$EPICS" ]; then
  while IFS= read -r estado; do
    case "$estado" in
      "a fazer"|"em spec"|"em plano"|"em construção"|"em review"|"concluída") ;;
      *"_("*|"") ;;  # placeholder de molde — ignora
      *) erro "docs/epics.md: Estado de ledger inválido: '$estado' (ver state-markers.md)" ;;
    esac
  done < <(awk -F'|' '/^\| *[0-9]+ *\|/ && NF >= 8 { v = $6; gsub(/^[ \t]+|[ \t]+$/, "", v); print v }' "$EPICS")
fi

# ------------------------------------------------ [VERIFICAR] (informativo)
pendencias="$(grep -rc '\[VERIFICAR\]' "$ROOT"/docs "$ROOT"/.specify/memory/project-context.md 2>/dev/null \
  | awk -F: '$NF > 0' || true)"
if [ -n "$pendencias" ]; then
  echo "INFO  pendências [VERIFICAR] por arquivo:"
  echo "$pendencias" | sed "s|$ROOT/|      |"
fi

# -------------------------------------------------------------------- resumo
echo "----------------------------------------"
echo "sdk-check: $ERROS erro(s), $AVISOS aviso(s)."
if [ "$ERROS" -gt 0 ]; then
  echo "Contrato violado — ver .specify/memory/state-markers.md."
  exit 1
fi
exit 0
