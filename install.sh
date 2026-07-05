#!/usr/bin/env bash
# Safe installer for Spec Driven Kit.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST="$ROOT/scripts/kit-manifest.txt"
VERSION_FILE="$ROOT/VERSION"
STAMP_REL=".specify/spec-driven-kit.version"

TARGET="."
DRY_RUN=0
FORCE=0
YES=0

COPIED=0
SKIPPED=0
CONFLICTS=0
BACKUPS=0
SIDECARS=0

usage() {
  cat <<'EOF'
Usage: ./install.sh [--target <dir>] [--dry-run] [--force] [--yes] [-h]

Options:
  --target <dir>  Destination project directory (default: current directory).
  --dry-run       Print the plan without writing anything.
  --force         Overwrite divergent ENGINE files only, after .sdk-bak timestamp backup.
  --yes           Non-interactive safe defaults; create missing target and skip conflicts.
  -h, --help      Show this help.
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --target)
      [ $# -ge 2 ] || { echo "Missing value for --target" >&2; exit 2; }
      TARGET="$2"
      shift 2
      ;;
    --dry-run) DRY_RUN=1; shift ;;
    --force) FORCE=1; shift ;;
    --yes) YES=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage; exit 2 ;;
  esac
done

[ -f "$MANIFEST" ] || { echo "Missing manifest: $MANIFEST" >&2; exit 1; }
[ -f "$VERSION_FILE" ] || { echo "Missing VERSION file: $VERSION_FILE" >&2; exit 1; }

KIT_VERSION="$(tr -d '\r\n' < "$VERSION_FILE")"
if ! echo "$KIT_VERSION" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
  echo "Invalid VERSION: $KIT_VERSION" >&2
  exit 1
fi

abs_existing_dir() {
  local dir="$1"
  (cd "$dir" && pwd -P)
}

target_parent="$(dirname "$TARGET")"
target_name="$(basename "$TARGET")"
if [ -d "$TARGET" ]; then
  TARGET_ABS="$(abs_existing_dir "$TARGET")"
else
  [ -d "$target_parent" ] || { echo "Target parent does not exist: $target_parent" >&2; exit 1; }
  TARGET_ABS="$(cd "$target_parent" && pwd -P)/$target_name"
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "DRY-RUN would create target directory: $TARGET_ABS"
  elif [ "$YES" -eq 1 ]; then
    mkdir -p "$TARGET_ABS"
    echo "Created target directory: $TARGET_ABS"
  elif [ -t 0 ]; then
    printf "Target does not exist. Create '%s'? [y/N] " "$TARGET_ABS"
    read -r answer
    case "$answer" in
      y|Y|yes|YES) mkdir -p "$TARGET_ABS" ;;
      *) echo "Aborted."; exit 1 ;;
    esac
  else
    echo "Target does not exist and --yes was not provided: $TARGET_ABS" >&2
    exit 1
  fi
fi

case "$TARGET_ABS" in
  "$ROOT"|"$ROOT"/*)
    echo "Refusing to install into the kit repository itself: $TARGET_ABS" >&2
    exit 1
    ;;
esac

read_installed_version() {
  local stamp="$1" value
  if [ ! -f "$stamp" ]; then
    printf 'none\n'
    return
  fi
  value="$(tr -d '\r\n' < "$stamp")"
  if echo "$value" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
    printf '%s\n' "$value"
  else
    printf 'none\n'
  fi
}

stamp_version() {
  local stamp="$TARGET_ABS/$STAMP_REL"
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "DRY-RUN would stamp $STAMP_REL: $INSTALLED_VERSION -> $KIT_VERSION"
  else
    mkdir -p "$(dirname "$stamp")"
    printf '%s\n' "$KIT_VERSION" > "$stamp"
    echo "stamped $STAMP_REL: $INSTALLED_VERSION -> $KIT_VERSION"
  fi
}

unique_path() {
  local base="$1"
  if [ ! -e "$base" ]; then
    printf '%s\n' "$base"
    return
  fi
  local i=1
  while [ -e "$base.$i" ]; do
    i=$((i + 1))
  done
  printf '%s.%s\n' "$base" "$i"
}

copy_file() {
  local src="$1" dst="$2"
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "DRY-RUN copy $src -> $dst"
  else
    mkdir -p "$(dirname "$dst")"
    cp -p "$src" "$dst"
  fi
  COPIED=$((COPIED + 1))
}

copy_sidecar() {
  local src="$1" dst="$2" sidecar
  sidecar="$(unique_path "$dst.sdk-new")"
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "DRY-RUN sidecar $src -> $sidecar"
  else
    mkdir -p "$(dirname "$sidecar")"
    cp -p "$src" "$sidecar"
  fi
  SIDECARS=$((SIDECARS + 1))
}

backup_and_overwrite() {
  local src="$1" dst="$2" backup timestamp
  timestamp="$(date +%Y%m%d%H%M%S)"
  backup="$(unique_path "$dst.sdk-bak.$timestamp")"
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "DRY-RUN backup $dst -> $backup"
    echo "DRY-RUN overwrite $dst"
  else
    mkdir -p "$(dirname "$backup")"
    cp -p "$dst" "$backup"
    cp -p "$src" "$dst"
  fi
  BACKUPS=$((BACKUPS + 1))
  COPIED=$((COPIED + 1))
}

INSTALLED_VERSION="$(read_installed_version "$TARGET_ABS/$STAMP_REL")"

echo "Spec Driven Kit v$KIT_VERSION"
echo "Source: $ROOT"
echo "Target: $TARGET_ABS"
echo "installed: $INSTALLED_VERSION -> $KIT_VERSION"
[ "$DRY_RUN" -eq 1 ] && echo "Mode: dry-run (no writes)"

while read -r category path extra; do
  category="${category%$'\r'}"
  path="${path%$'\r'}"
  extra="${extra%$'\r'}"
  case "$category" in
    ""|\#*) continue ;;
  esac
  if [ -n "${extra:-}" ]; then
    echo "Invalid manifest line (too many columns): $category $path $extra" >&2
    exit 1
  fi

  src="$ROOT/$path"
  dst="$TARGET_ABS/$path"

  case "$category" in
    SKIP)
      SKIPPED=$((SKIPPED + 1))
      continue
      ;;
    ENGINE|SEED|MERGE) ;;
    *)
      echo "Invalid category in manifest: $category ($path)" >&2
      exit 1
      ;;
  esac

  [ -f "$src" ] || { echo "Manifest source missing: $path" >&2; exit 1; }

  if [ ! -e "$dst" ]; then
    copy_file "$src" "$dst"
    continue
  fi

  if cmp -s "$src" "$dst"; then
    echo "skip unchanged $path"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  case "$category" in
    ENGINE)
      CONFLICTS=$((CONFLICTS + 1))
      if [ "$FORCE" -eq 1 ]; then
        echo "force update ENGINE $path"
        backup_and_overwrite "$src" "$dst"
      else
        echo "conflict ENGINE $path -> writing .sdk-new sidecar"
        copy_sidecar "$src" "$dst"
      fi
      ;;
    SEED)
      echo "skip existing SEED $path"
      SKIPPED=$((SKIPPED + 1))
      if [ "$path" = ".gitignore" ]; then
        echo "  note: confirm your .gitignore protects .env and secrets"
      fi
      ;;
    MERGE)
      echo "existing MERGE $path -> writing .sdk-new for manual merge"
      CONFLICTS=$((CONFLICTS + 1))
      copy_sidecar "$src" "$dst"
      ;;
  esac
done < "$MANIFEST"

echo "----------------------------------------"
echo "install: copied=$COPIED skipped=$SKIPPED conflicts=$CONFLICTS sidecars=$SIDECARS backups=$BACKUPS"
stamp_version

if [ "$DRY_RUN" -eq 1 ]; then
  echo "Dry-run complete. No files were written."
  echo "After a real install, run: scripts/sdk-check.sh"
  exit 0
fi

if [ -f "$TARGET_ABS/scripts/sdk-check.sh" ]; then
  echo "Running sdk-check..."
  bash "$TARGET_ABS/scripts/sdk-check.sh"
else
  echo "sdk-check not found. Run scripts/sdk-check.sh after install."
fi

echo "Next: open Claude Code in the target project and run /sdk-bootstrap."
