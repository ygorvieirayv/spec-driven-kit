#!/usr/bin/env bash
# new-feature.sh — cria o esqueleto de uma feature (pasta de spec/plano + branch).
# Uso:  ./scripts/new-feature.sh "nome-da-feature"
# Opcional do Spec Driven Kit (Fase 4). O núcleo do kit funciona sem isto.

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Uso: $0 \"nome-da-feature\"" >&2
  exit 1
fi

# slug: minúsculas, espaços -> hífen, remove o que não for [a-z0-9-]
raw="$*"
slug="$(printf '%s' "$raw" \
  | tr '[:upper:]' '[:lower:]' \
  | sed -E 's/[[:space:]]+/-/g; s/[^a-z0-9-]//g; s/-+/-/g; s/^-//; s/-$//')"

if [ -z "$slug" ]; then
  echo "Nome inválido após normalização: '$raw'" >&2
  exit 1
fi

root="$(cd "$(dirname "$0")/.." && pwd)"
spec_dir="$root/docs/specs/$slug"
plan_dir="$root/docs/plans/$slug"

mkdir -p "$spec_dir" "$plan_dir"

# Copia os moldes se a spec/plano ainda não existirem (não sobrescreve).
[ -f "$spec_dir/spec.md" ] || cp "$root/.specify/templates/spec-template.md" "$spec_dir/spec.md"
[ -f "$plan_dir/plan.md" ] || cp "$root/.specify/templates/plan-template.md" "$plan_dir/plan.md"
[ -f "$plan_dir/tasks.md" ] || cp "$root/.specify/templates/tasks-template.md" "$plan_dir/tasks.md"

echo "Criado:"
echo "  $spec_dir/spec.md"
echo "  $plan_dir/plan.md"
echo "  $plan_dir/tasks.md"

# Cria a branch dedicada, se estivermos num repo git.
if git -C "$root" rev-parse --git-dir >/dev/null 2>&1; then
  branch="feature/$slug"
  if git -C "$root" show-ref --verify --quiet "refs/heads/$branch"; then
    echo "Branch '$branch' já existe — alternando."
    git -C "$root" checkout "$branch"
  else
    git -C "$root" checkout -b "$branch"
    echo "Branch '$branch' criada."
  fi
fi

echo "Pronto. Detalhe a feature com /sdk-spec e depois /sdk-plan."
