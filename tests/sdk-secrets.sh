#!/usr/bin/env bash
# Real Gitleaks smoke: clean history passes; removed synthetic secret remains detectable in history.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT
export SDK_GITLEAKS_CACHE_DIR="$TMP_ROOT/cache"

init_repo() {
  local target="$1"
  mkdir -p "$target"
  git -C "$target" init -q
  git -C "$target" config user.name "SDK CI fixture"
  git -C "$target" config user.email "sdk-ci@example.invalid"
  printf 'fixture\n' > "$target/README.md"
  git -C "$target" add README.md
  git -C "$target" commit -qm "clean baseline"
}

clean="$TMP_ROOT/clean repo"
init_repo "$clean"
bash "$ROOT/scripts/sdk-secrets.sh" "$clean" >/dev/null

leaky="$TMP_ROOT/leaky repo"
init_repo "$leaky"
token_prefix='ghp_'
fixture_part='7uY3kP9mN2qR8vW4xC6bD1sF5hJ0tLzA'
printf 'api_key = "%s%s"\n' "$token_prefix" "$fixture_part" > "$leaky/config.txt"
git -C "$leaky" add config.txt
git -C "$leaky" commit -qm "add synthetic credential"
rm "$leaky/config.txt"
git -C "$leaky" add -u
git -C "$leaky" commit -qm "remove synthetic credential"
if output="$(bash "$ROOT/scripts/sdk-secrets.sh" "$leaky" 2>&1)"; then
  echo "Synthetic secret removed from HEAD unexpectedly escaped history scan" >&2
  exit 1
fi
grep -Fq 'generic-api-key' <<< "$output" || {
  echo "$output"
  echo "Gitleaks failed without identifying the expected synthetic rule" >&2
  exit 1
}
if grep -Fq "$fixture_part" <<< "$output"; then
  echo "Gitleaks output exposed the synthetic secret despite full redaction" >&2
  exit 1
fi

current="$TMP_ROOT/current tree"
init_repo "$current"
printf 'api_key = "%s%s"\n' "$token_prefix" "$fixture_part" > "$current/untracked-config.txt"
if output="$(bash "$ROOT/scripts/sdk-secrets.sh" "$current" 2>&1)"; then
  echo "Synthetic secret in the current tree unexpectedly escaped directory scan" >&2
  exit 1
fi
grep -Fq 'generic-api-key' <<< "$output" || {
  echo "$output"
  echo "Current-tree scan failed without identifying the expected synthetic rule" >&2
  exit 1
}
if grep -Fq "$fixture_part" <<< "$output"; then
  echo "Current-tree scan exposed the synthetic secret despite full redaction" >&2
  exit 1
fi

custom="$TMP_ROOT/custom config"
init_repo "$custom"
cat > "$custom/.gitleaks.toml" <<'EOF'
[extend]
useDefault = true
disabledRules = ["generic-api-key"]
EOF
if output="$(bash "$ROOT/scripts/sdk-secrets.sh" "$custom" 2>&1)"; then
  echo "Config disabling a default Gitleaks rule unexpectedly passed" >&2
  exit 1
fi
grep -Fq 'disabledRules nao pode remover regras padrao' <<< "$output"

shallow="$TMP_ROOT/shallow repo"
git clone -q --depth 1 --no-local "$leaky" "$shallow"
if output="$(bash "$ROOT/scripts/sdk-secrets.sh" "$shallow" 2>&1)"; then
  echo "Shallow checkout unexpectedly passed secret scan" >&2
  exit 1
fi
grep -Fq 'shallow checkout is forbidden' <<< "$output"

echo "sdk-secrets real scan matrix passed."
