#!/usr/bin/env bash
# Pinned, fail-closed secret scan for the consumer CI (Linux x64 only).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE="$ROOT"
GITLEAKS_VERSION="8.30.1"
GITLEAKS_SHA256="551f6fc83ea457d62a0d98237cbad105af8d557003051f41f3e7ca7b3f2470eb"
GITLEAKS_URL="https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz"

usage() {
  echo "Usage: bash scripts/sdk-secrets.sh [repository]"
}

case "${1:-}" in
  "") ;;
  -h|--help) usage; exit 0 ;;
  *) SOURCE="$1" ;;
esac
[ "$#" -le 1 ] || { echo "sdk-secrets: too many arguments" >&2; exit 2; }

[ "$(uname -s)" = "Linux" ] || {
  echo "sdk-secrets: scanner is CI-only and requires Linux x64" >&2
  exit 2
}
case "$(uname -m)" in
  x86_64|amd64) ;;
  *) echo "sdk-secrets: unsupported architecture: $(uname -m)" >&2; exit 2 ;;
esac

[ -d "$SOURCE" ] || { echo "sdk-secrets: repository not found: $SOURCE" >&2; exit 2; }
SOURCE="$(cd "$SOURCE" && pwd -P)"
git -C "$SOURCE" rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
  echo "sdk-secrets: source is not a git repository: $SOURCE" >&2
  exit 2
}
if [ "$(git -C "$SOURCE" rev-parse --is-shallow-repository)" = "true" ]; then
  echo "sdk-secrets: shallow checkout is forbidden; use fetch-depth: 0" >&2
  exit 1
fi

config="$SOURCE/.gitleaks.toml"
if [ -f "$config" ]; then
  if ! awk '
    /^\[extend\][ \t\r]*$/ { in_extend = 1; next }
    /^\[/ { in_extend = 0 }
    in_extend && /^[ \t]*useDefault[ \t]*=[ \t]*true([ \t]*#.*)?[ \t\r]*$/ { found = 1 }
    END { exit(found ? 0 : 1) }
  ' "$config"; then
    echo "sdk-secrets: .gitleaks.toml precisa de [extend] useDefault = true" >&2
    exit 1
  fi
  if awk '
    /^\[extend\][ \t\r]*$/ { in_extend = 1; next }
    /^\[/ { in_extend = 0 }
    in_extend && /^[ \t]*disabledRules[ \t]*=/ { found = 1 }
    END { exit(found ? 0 : 1) }
  ' "$config"; then
    echo "sdk-secrets: disabledRules nao pode remover regras padrao do Gitleaks" >&2
    exit 1
  fi
fi

cache_root="${SDK_GITLEAKS_CACHE_DIR:-${RUNNER_TEMP:-${TMPDIR:-/tmp}}/spec-driven-kit-gitleaks}"
archive="$cache_root/gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz"
mkdir -p "$cache_root"

archive_valid() {
  [ -f "$archive" ] && printf '%s  %s\n' "$GITLEAKS_SHA256" "$archive" | sha256sum -c - >/dev/null 2>&1
}

if ! archive_valid; then
  tmp_archive="$(mktemp "$cache_root/.gitleaks-download.XXXXXX")"
  trap 'rm -f "${tmp_archive:-}"' EXIT
  curl --proto '=https' --tlsv1.2 --fail --location --show-error --retry 3 --retry-all-errors \
    --output "$tmp_archive" "$GITLEAKS_URL"
  printf '%s  %s\n' "$GITLEAKS_SHA256" "$tmp_archive" | sha256sum -c -
  mv "$tmp_archive" "$archive"
  trap - EXIT
fi
printf '%s  %s\n' "$GITLEAKS_SHA256" "$archive" | sha256sum -c -

extract_dir="$(mktemp -d)"
trap 'rm -rf "${extract_dir:-}"' EXIT
verified_archive="$extract_dir/gitleaks.tar.gz"
cp -- "$archive" "$verified_archive"
printf '%s  %s\n' "$GITLEAKS_SHA256" "$verified_archive" | sha256sum -c -
tar -xzf "$verified_archive" -C "$extract_dir" gitleaks
binary="$extract_dir/gitleaks"
chmod 0755 "$binary"
[ "$("$binary" version)" = "$GITLEAKS_VERSION" ] || {
  echo "sdk-secrets: installed Gitleaks version does not match $GITLEAKS_VERSION" >&2
  exit 1
}

echo "sdk-secrets: scanning complete git history with Gitleaks $GITLEAKS_VERSION"
"$binary" git --redact=100 --no-banner --no-color --verbose --timeout=300 \
  --log-opts="--all HEAD" "$SOURCE"
echo "sdk-secrets: scanning current tree"
"$binary" dir --redact=100 --no-banner --no-color --verbose --timeout=300 "$SOURCE"
echo "sdk-secrets: no leaks found."
