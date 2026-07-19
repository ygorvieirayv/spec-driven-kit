#!/usr/bin/env bash
# Safe installer for Spec Driven Kit.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST="$ROOT/scripts/kit-manifest.txt"
VERSION_FILE="$ROOT/VERSION"
STAMP_REL=".specify/spec-driven-kit.version"
PENDING_REL=".specify/spec-driven-kit.pending"

TARGET="."
DRY_RUN=0
FORCE=0
YES=0

COPIED=0
SKIPPED=0
CONFLICTS=0
ENGINE_CONFLICTS=0
MERGE_CONFLICTS=0
PENDING_ENGINE_CONFLICTS=0
BACKUPS=0
SIDECARS=0
PENDING_ENGINE_PATHS=()
CREATE_TARGET=0
INSTALL_TIMESTAMP="$(date +%Y%m%d%H%M%S)"

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

resolve_kit_build() {
  local revision dirty_suffix=""
  KIT_BUILD="$KIT_VERSION-dev+source.unknown"
  command -v git >/dev/null 2>&1 || return
  revision="$(git -C "$ROOT" rev-parse --verify HEAD 2>/dev/null || true)"
  if ! echo "$revision" | grep -qE '^[0-9a-fA-F]{40,64}$'; then
    return
  fi
  revision="$(printf '%s' "$revision" | tr '[:upper:]' '[:lower:]' | cut -c1-12)"
  if ! git -C "$ROOT" status --porcelain --untracked-files=all >/dev/null 2>&1; then
    KIT_BUILD="$KIT_VERSION-dev+g$revision.state-unknown"
    return
  fi
  if [ -n "$(git -C "$ROOT" status --porcelain --untracked-files=all 2>/dev/null)" ]; then
    dirty_suffix=".dirty"
  fi
  KIT_BUILD="$KIT_VERSION-dev+g$revision$dirty_suffix"
}

resolve_kit_build

abs_existing_dir() {
  local dir="$1"
  (cd "$dir" && pwd -P)
}

unsafe_path() {
  local path="$1" reason="$2"
  echo "Unsafe install path: $path ($reason)" >&2
  exit 1
}

# Inspect the path as the caller wrote it before pwd -P/Resolve-Path can erase
# evidence of a redirecting ancestor. This deliberately rejects a target
# reached through a symlink even when the resolved physical directory would be
# writable: containment is defined by the requested project path.
assert_safe_target_lexical_path() {
  local requested="$1" lexical current component
  local -a components

  case "$requested" in
    /*) lexical="$requested" ;;
    *) lexical="${PWD%/}/$requested" ;;
  esac

  current="/"
  IFS='/' read -r -a components <<< "${lexical#/}"
  for component in "${components[@]}"; do
    case "$component" in
      ""|.) continue ;;
      ..)
        if [ "$current" != "/" ]; then
          current="${current%/*}"
          [ -n "$current" ] || current="/"
        fi
        continue
        ;;
    esac

    current="${current%/}/$component"
    if [ -L "$current" ]; then
      unsafe_path "$requested" "target path crosses a symlink/reparse point at $current"
    fi
  done
  return 0
}

path_entry_exists() {
  [ -e "$1" ] || [ -L "$1" ]
}

# Refuse redirects inside the target before any filesystem mutation. The only
# linked leaf that may be read is the documented MERGE lessons file; it is
# never overwritten by the installer.
assert_safe_relative_path() {
  local rel="$1" allow_linked_leaf="${2:-0}"
  local current="$TARGET_ABS" remaining="$rel" component last

  case "$rel" in
    ""|/*) unsafe_path "$rel" "manifest path must be relative" ;;
  esac

  if [ -L "$current" ]; then
    unsafe_path "$current" "target root is a symlink"
  fi
  if [ -e "$current" ] && [ ! -d "$current" ]; then
    unsafe_path "$current" "target root is not a directory"
  fi

  while [ -n "$remaining" ]; do
    case "$remaining" in
      */*)
        component="${remaining%%/*}"
        remaining="${remaining#*/}"
        last=0
        ;;
      *)
        component="$remaining"
        remaining=""
        last=1
        ;;
    esac

    case "$component" in
      ""|.|..) unsafe_path "$rel" "invalid path component '$component'" ;;
    esac

    current="$current/$component"
    if [ -L "$current" ]; then
      if [ "$last" -eq 1 ] && [ "$allow_linked_leaf" -eq 1 ]; then
        if [ ! -e "$current" ] || [ ! -f "$current" ]; then
          unsafe_path "$rel" "allowed MERGE link is dangling or not a file"
        fi
      else
        unsafe_path "$rel" "symlink/reparse point detected"
      fi
    elif [ -e "$current" ]; then
      if [ "$last" -eq 1 ]; then
        [ -f "$current" ] || unsafe_path "$rel" "destination is not a regular file"
      else
        [ -d "$current" ] || unsafe_path "$rel" "parent component is not a directory"
      fi
    fi
  done
}

assert_safe_target_lexical_path "$TARGET"

target_parent="$(dirname "$TARGET")"
target_name="$(basename "$TARGET")"
if [ -L "$TARGET" ]; then
  unsafe_path "$TARGET" "target root is a symlink"
elif [ -d "$TARGET" ]; then
  TARGET_ABS="$(abs_existing_dir "$TARGET")"
elif [ -e "$TARGET" ]; then
  unsafe_path "$TARGET" "target exists and is not a directory"
else
  [ -d "$target_parent" ] || { echo "Target parent does not exist: $target_parent" >&2; exit 1; }
  TARGET_ABS="$(cd "$target_parent" && pwd -P)/$target_name"
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "DRY-RUN would create target directory: $TARGET_ABS"
    CREATE_TARGET=1
  elif [ "$YES" -eq 1 ]; then
    CREATE_TARGET=1
  elif [ -t 0 ]; then
    printf "Target does not exist. Create '%s'? [y/N] " "$TARGET_ABS"
    read -r answer
    case "$answer" in
      y|Y|yes|YES) CREATE_TARGET=1 ;;
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
  if echo "$value" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+(-dev\+(g[0-9a-f]{12}(\.dirty|\.state-unknown)?|source\.unknown))?$'; then
    printf '%s\n' "$value"
  else
    printf 'none\n'
  fi
}

stamp_version() {
  local stamp="$TARGET_ABS/$STAMP_REL"
  assert_safe_relative_path "$STAMP_REL" 0
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "DRY-RUN would stamp $STAMP_REL: $INSTALLED_VERSION -> $KIT_BUILD"
  else
    mkdir -p "$(dirname "$stamp")"
    printf '%s\n' "$KIT_BUILD" > "$stamp"
    echo "stamped $STAMP_REL: $INSTALLED_VERSION -> $KIT_BUILD"
  fi
}

record_pending_install() {
  local pending="$TARGET_ABS/$PENDING_REL" path
  assert_safe_relative_path "$PENDING_REL" 0
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "DRY-RUN would preserve $STAMP_REL at: $INSTALLED_VERSION"
    echo "DRY-RUN would record pending kit update in $PENDING_REL for: $KIT_BUILD"
    return
  fi

  mkdir -p "$(dirname "$pending")"
  {
    printf 'status: pending-engine-reconciliation\n'
    printf 'installed: %s\n' "$INSTALLED_VERSION"
    printf 'target: %s\n' "$KIT_BUILD"
    printf 'engine-conflicts: %s\n' "$PENDING_ENGINE_CONFLICTS"
    printf 'files:\n'
    for path in "${PENDING_ENGINE_PATHS[@]}"; do
      printf -- '- %s\n' "$path"
    done
  } > "$pending"
  echo "version stamp preserved at: $INSTALLED_VERSION"
  echo "pending kit update recorded in $PENDING_REL for: $KIT_BUILD"
}

clear_pending_install() {
  local pending="$TARGET_ABS/$PENDING_REL"
  assert_safe_relative_path "$PENDING_REL" 0
  if ! path_entry_exists "$pending"; then
    return
  fi
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "DRY-RUN would clear resolved pending marker: $PENDING_REL"
  else
    rm -f "$pending"
    echo "cleared resolved pending marker: $PENDING_REL"
  fi
}

finalize_install_state() {
  if [ "$PENDING_ENGINE_CONFLICTS" -gt 0 ]; then
    record_pending_install
    return
  fi
  stamp_version
  clear_pending_install
}

unique_path() {
  local base="$1" kind="${2:-generated file}" candidate
  if [ -L "$base" ]; then
    unsafe_path "$base" "$kind is a symlink/reparse point"
  fi
  if [ ! -e "$base" ]; then
    printf '%s\n' "$base"
    return
  fi
  local i=1
  while :; do
    candidate="$base.$i"
    if [ -L "$candidate" ]; then
      unsafe_path "$candidate" "$kind is a symlink/reparse point"
    fi
    if [ ! -e "$candidate" ]; then
      printf '%s\n' "$candidate"
      return
    fi
    i=$((i + 1))
  done
}

copy_file() {
  local src="$1" dst="$2" rel="$3"
  assert_safe_relative_path "$rel" 0
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "DRY-RUN copy $src -> $dst"
  else
    mkdir -p "$(dirname "$dst")"
    cp -p "$src" "$dst"
  fi
  COPIED=$((COPIED + 1))
}

copy_sidecar() {
  local src="$1" dst="$2" rel="$3" allow_linked_leaf="$4" sidecar
  assert_safe_relative_path "$rel" "$allow_linked_leaf"
  sidecar="$(unique_path "$dst.sdk-new" "sidecar")"
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "DRY-RUN sidecar $src -> $sidecar"
  else
    mkdir -p "$(dirname "$sidecar")"
    cp -p "$src" "$sidecar"
  fi
  SIDECARS=$((SIDECARS + 1))
}

backup_and_overwrite() {
  local src="$1" dst="$2" rel="$3" backup
  assert_safe_relative_path "$rel" 0
  backup="$(unique_path "$dst.sdk-bak.$INSTALL_TIMESTAMP" "backup")"
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

preflight_install() {
  local category path extra src dst allow_linked_leaf

  assert_safe_relative_path "$STAMP_REL" 0
  assert_safe_relative_path "$PENDING_REL" 0

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

    case "$category" in
      SKIP) continue ;;
      ENGINE|SEED|MERGE) ;;
      *) echo "Invalid category in manifest: $category ($path)" >&2; exit 1 ;;
    esac

    src="$ROOT/$path"
    dst="$TARGET_ABS/$path"
    [ -f "$src" ] || { echo "Manifest source missing: $path" >&2; exit 1; }

    allow_linked_leaf=0
    if [ "$category" = "MERGE" ] && [ "$path" = ".specify/memory/lessons.md" ]; then
      allow_linked_leaf=1
    fi
    assert_safe_relative_path "$path" "$allow_linked_leaf"

    path_entry_exists "$dst" || continue
    cmp -s "$src" "$dst" && continue

    case "$category" in
      ENGINE)
        if [ "$FORCE" -eq 1 ]; then
          unique_path "$dst.sdk-bak.$INSTALL_TIMESTAMP" "backup" >/dev/null
        else
          unique_path "$dst.sdk-new" "sidecar" >/dev/null
        fi
        ;;
      MERGE) unique_path "$dst.sdk-new" "sidecar" >/dev/null ;;
      SEED) ;;
    esac
  done < "$MANIFEST"
}

preflight_install

INSTALLED_VERSION="$(read_installed_version "$TARGET_ABS/$STAMP_REL")"

if [ "$CREATE_TARGET" -eq 1 ] && [ "$DRY_RUN" -eq 0 ]; then
  if path_entry_exists "$TARGET_ABS"; then
    unsafe_path "$TARGET_ABS" "target appeared after preflight"
  fi
  mkdir -p "$TARGET_ABS"
  echo "Created target directory: $TARGET_ABS"
fi

echo "Spec Driven Kit $KIT_BUILD (base $KIT_VERSION)"
echo "Source: $ROOT"
echo "Target: $TARGET_ABS"
echo "installed: $INSTALLED_VERSION"
echo "source build: $KIT_BUILD"
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

  allow_linked_leaf=0
  if [ "$category" = "MERGE" ] && [ "$path" = ".specify/memory/lessons.md" ]; then
    allow_linked_leaf=1
  fi

  if ! path_entry_exists "$dst"; then
    copy_file "$src" "$dst" "$path"
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
      ENGINE_CONFLICTS=$((ENGINE_CONFLICTS + 1))
      if [ "$FORCE" -eq 1 ]; then
        echo "force update ENGINE $path"
        backup_and_overwrite "$src" "$dst" "$path"
      else
        PENDING_ENGINE_CONFLICTS=$((PENDING_ENGINE_CONFLICTS + 1))
        PENDING_ENGINE_PATHS+=("$path")
        echo "conflict ENGINE $path -> writing .sdk-new sidecar"
        copy_sidecar "$src" "$dst" "$path" 0
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
      MERGE_CONFLICTS=$((MERGE_CONFLICTS + 1))
      copy_sidecar "$src" "$dst" "$path" "$allow_linked_leaf"
      ;;
  esac
done < "$MANIFEST"

echo "----------------------------------------"
echo "install: copied=$COPIED skipped=$SKIPPED conflicts=$CONFLICTS engine_conflicts=$ENGINE_CONFLICTS merge_conflicts=$MERGE_CONFLICTS pending_engine=$PENDING_ENGINE_CONFLICTS sidecars=$SIDECARS backups=$BACKUPS"

if [ "$DRY_RUN" -eq 1 ]; then
  finalize_install_state
  echo "Dry-run complete. No files were written."
  echo "After a real install, run: scripts/sdk-check.sh"
  exit 0
fi

if [ "$PENDING_ENGINE_CONFLICTS" -gt 0 ]; then
  record_pending_install
fi

if [ -f "$TARGET_ABS/scripts/sdk-check.sh" ]; then
  echo "Running sdk-check..."
  if ! bash "$TARGET_ABS/scripts/sdk-check.sh"; then
    echo "sdk-check failed; version stamp was not advanced." >&2
    exit 1
  fi
else
  echo "sdk-check not found; version stamp was not advanced." >&2
  exit 1
fi

if [ "$PENDING_ENGINE_CONFLICTS" -eq 0 ]; then
  finalize_install_state
  if [ "$INSTALLED_VERSION" = "none" ]; then
    echo "Next: open Claude Code in the target project and run /sdk-bootstrap."
  else
    echo "Kit update complete."
  fi
else
  echo "Kit update remains pending; version stamp was not advanced."
  echo "Next: reconcile the files listed in $PENDING_REL and run the installer again."
fi
