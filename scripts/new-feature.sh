#!/usr/bin/env bash
# new-feature.sh — inicia a spec de uma feature e cria a branch dedicada.
# Uso:  ./scripts/new-feature.sh "nome-da-feature"
# Atalho opcional do Spec Driven Kit. O núcleo do kit funciona sem isto.

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

mkdir -p "$spec_dir"

# Copia e materializa os moldes somente na primeira criação (não sobrescreve).
create_from_template() {
  local source="$1" target="$2" rendered
  [ -f "$target" ] && return
  rendered="$(mktemp "$target.tmp.XXXXXX")"
  if ! sed \
    -e "s#<feature>#$slug#g" \
    -e "s#<Nome da Feature>#$slug#g" \
    "$source" > "$rendered"; then
    rm -f "$rendered"
    return 1
  fi
  chmod 0644 "$rendered"
  mv "$rendered" "$target"
}

create_from_template "$root/.specify/templates/spec-template.md" "$spec_dir/spec.md"

echo "Criado:"
echo "  $spec_dir/spec.md"

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

echo "Pronto. Detalhe a feature com /sdk-spec; depois use /sdk-next para seguir o estado gravado."
