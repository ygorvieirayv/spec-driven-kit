#!/usr/bin/env bash
# Focused regression tests for installer path containment and macOS-safe feature rendering.
set -euo pipefail

# Git Bash can emulate symlinks without elevated Windows privileges. Relaunch
# once with that mode so the same linked-leaf scenarios run on every CI host.
case "$(uname -s)" in
  MINGW*|MSYS*)
    if [ "${SDK_SYMLINK_REEXEC:-0}" != "1" ]; then
      exec env SDK_SYMLINK_REEXEC=1 MSYS=winsymlinks:sys "$BASH" "$0" "$@"
    fi
    ;;
esac

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# macOS exposes /tmp and /var through system symlinks. The installer rejects
# every redirecting target component by design, so use the physical home tree
# for destination-containment tests instead of weakening that policy.
TMP_ROOT="$(mktemp -d "${HOME%/}/sdk-install-path-safety.XXXXXX")"
trap 'rm -rf "$TMP_ROOT"' EXIT

expect_unsafe_failure() {
  local label="$1" output="$TMP_ROOT/$1.log"
  shift
  if "$@" >"$output" 2>&1; then
    cat "$output"
    echo "$label unexpectedly succeeded" >&2
    exit 1
  fi
  if ! grep -Fq 'Unsafe install path:' "$output"; then
    cat "$output"
    echo "$label failed without the path-safety diagnostic" >&2
    exit 1
  fi
}

assert_only_sentinel() {
  local directory="$1" expected="$2" count
  count="$(find "$directory" -type f -print | wc -l | tr -d '[:space:]')"
  [ "$count" = "1" ] || {
    find "$directory" -print >&2
    echo "outside directory changed" >&2
    exit 1
  }
  [ "$(cat "$directory/sentinel")" = "$expected" ] || {
    echo "outside sentinel changed" >&2
    exit 1
  }
}

install_clean() {
  local parent="$1" target="$2"
  mkdir -p "$parent"
  bash "$ROOT/install.sh" --target "$target" --yes >/dev/null
}

# Dry-run must not create the target or any generated staging path.
dry_parent="$TMP_ROOT/dry-parent"
dry_target="$dry_parent/project"
mkdir -p "$dry_parent"
bash "$ROOT/install.sh" --target "$dry_target" --dry-run --yes >/dev/null
[ ! -e "$dry_target" ] && [ ! -L "$dry_target" ] || {
  echo "dry-run created its target" >&2
  exit 1
}
if find "$dry_parent" ! -path "$dry_parent" -print | grep -q .; then
  echo "dry-run created staging files" >&2
  exit 1
fi

# The normal path also proves new-feature.sh without GNU sed -i semantics.
portable_parent="$TMP_ROOT/portable"
portable_target="$portable_parent/project"
install_clean "$portable_parent" "$portable_target"
bash "$portable_target/scripts/new-feature.sh" "Portable Feature" >/dev/null
portable_spec="$portable_target/docs/specs/portable-feature/spec.md"
[ -f "$portable_spec" ] || { echo "portable spec was not created" >&2; exit 1; }
if grep -Eq '<feature>|<Nome da Feature>' "$portable_spec"; then
  echo "portable renderer left template placeholders" >&2
  exit 1
fi
if find "$portable_target/docs/specs/portable-feature" \
    \( -name '*-e' -o -name '*.tmp.*' \) -print | grep -q .; then
  echo "portable renderer left sed backup or temporary files" >&2
  exit 1
fi

# Conflicting dry-runs may report sidecar/backup plans, but never materialize them.
printf 'custom-engine\n' > "$portable_target/.claude/commands/sdk-next.md"
bash "$ROOT/install.sh" --target "$portable_target" --dry-run --yes >/dev/null
bash "$ROOT/install.sh" --target "$portable_target" --dry-run --yes --force >/dev/null
grep -qx 'custom-engine' "$portable_target/.claude/commands/sdk-next.md"
if find "$portable_target" \( -name '*.sdk-new*' -o -name '*.sdk-bak.*' -o -name 'spec-driven-kit.pending' \) -print | grep -q .; then
  echo "conflicting dry-run created sidecar or backup staging" >&2
  exit 1
fi

# File symlinks require Developer Mode/admin on some Windows hosts. Run every
# link scenario when the host can create a real link; PowerShell separately
# covers junctions without that requirement.
probe_target="$TMP_ROOT/link-probe-target"
probe_link="$TMP_ROOT/link-probe"
printf 'probe\n' > "$probe_target"
if ln -s "$probe_target" "$probe_link" 2>/dev/null && [ -L "$probe_link" ]; then
  rm "$probe_link"

  target_path_outside="$TMP_ROOT/target-path-outside"
  target_path_alias="$TMP_ROOT/target-path-alias"
  mkdir -p "$target_path_outside"
  printf 'target-path-safe' > "$target_path_outside/sentinel"
  ln -s "$target_path_outside" "$target_path_alias"
  expect_unsafe_failure target-path-ancestor-link \
    bash "$ROOT/install.sh" --target "$target_path_alias/project" --yes
  assert_only_sentinel "$target_path_outside" target-path-safe
  [ ! -e "$target_path_outside/project" ] || {
    echo "target path ancestor link redirected the installation" >&2
    exit 1
  }

  ancestor_target="$TMP_ROOT/ancestor-target"
  ancestor_outside="$TMP_ROOT/ancestor-outside"
  mkdir -p "$ancestor_target" "$ancestor_outside"
  printf 'ancestor-safe' > "$ancestor_outside/sentinel"
  ln -s "$ancestor_outside" "$ancestor_target/.claude"
  expect_unsafe_failure ancestor-link \
    bash "$ROOT/install.sh" --target "$ancestor_target" --yes --force
  assert_only_sentinel "$ancestor_outside" ancestor-safe
  [ ! -e "$ancestor_target/.specify" ] || {
    echo "ancestor-link failure wrote before completing preflight" >&2
    exit 1
  }

  leaf_target="$TMP_ROOT/leaf-target"
  leaf_outside="$TMP_ROOT/leaf-outside"
  mkdir -p "$leaf_target/.claude/commands" "$leaf_outside"
  printf 'leaf-safe' > "$leaf_outside/sentinel"
  ln -s "$leaf_outside/sentinel" "$leaf_target/.claude/commands/sdk-next.md"
  expect_unsafe_failure engine-leaf-link \
    bash "$ROOT/install.sh" --target "$leaf_target" --yes --force
  assert_only_sentinel "$leaf_outside" leaf-safe
  [ ! -e "$leaf_target/.specify" ] || {
    echo "leaf-link failure wrote before completing preflight" >&2
    exit 1
  }

  stamp_target="$TMP_ROOT/stamp-target"
  stamp_outside="$TMP_ROOT/stamp-outside"
  mkdir -p "$stamp_target/.specify" "$stamp_outside"
  printf 'stamp-safe' > "$stamp_outside/sentinel"
  ln -s "$stamp_outside/missing-version" \
    "$stamp_target/.specify/spec-driven-kit.version"
  expect_unsafe_failure dangling-stamp-link \
    bash "$ROOT/install.sh" --target "$stamp_target" --yes
  assert_only_sentinel "$stamp_outside" stamp-safe
  [ ! -e "$stamp_outside/missing-version" ] || {
    echo "dangling stamp link was followed" >&2
    exit 1
  }
  [ ! -e "$stamp_target/.claude" ] || {
    echo "stamp-link failure wrote before completing preflight" >&2
    exit 1
  }

  pending_target="$TMP_ROOT/pending-target"
  pending_outside="$TMP_ROOT/pending-outside"
  mkdir -p "$pending_target/.specify" "$pending_outside"
  printf 'pending-safe' > "$pending_outside/sentinel"
  ln -s "$pending_outside/missing-pending" \
    "$pending_target/.specify/spec-driven-kit.pending"
  expect_unsafe_failure dangling-pending-link \
    bash "$ROOT/install.sh" --target "$pending_target" --yes
  assert_only_sentinel "$pending_outside" pending-safe
  [ ! -e "$pending_outside/missing-pending" ] || {
    echo "dangling pending link was followed" >&2
    exit 1
  }
  [ ! -e "$pending_target/.claude" ] || {
    echo "pending-link failure wrote before completing preflight" >&2
    exit 1
  }

  sidecar_parent="$TMP_ROOT/sidecar-parent"
  sidecar_target="$sidecar_parent/project"
  sidecar_outside="$TMP_ROOT/sidecar-outside"
  install_clean "$sidecar_parent" "$sidecar_target"
  mkdir -p "$sidecar_outside"
  printf 'sidecar-safe' > "$sidecar_outside/sentinel"
  printf 'custom-engine\n' > "$sidecar_target/.claude/commands/sdk-next.md"
  ln -s "$sidecar_outside/missing-sidecar" \
    "$sidecar_target/.claude/commands/sdk-next.md.sdk-new"
  expect_unsafe_failure sidecar-link \
    bash "$ROOT/install.sh" --target "$sidecar_target" --yes
  assert_only_sentinel "$sidecar_outside" sidecar-safe
  grep -qx 'custom-engine' "$sidecar_target/.claude/commands/sdk-next.md"
  [ ! -e "$sidecar_outside/missing-sidecar" ] || {
    echo "sidecar link was followed" >&2
    exit 1
  }

  backup_parent="$TMP_ROOT/backup-parent"
  backup_target="$backup_parent/project"
  backup_outside="$TMP_ROOT/backup-outside"
  fake_bin="$TMP_ROOT/fake-bin"
  install_clean "$backup_parent" "$backup_target"
  mkdir -p "$backup_outside" "$fake_bin"
  printf 'backup-safe' > "$backup_outside/sentinel"
  printf 'custom-engine\n' > "$backup_target/.claude/commands/sdk-next.md"
  printf '%s\n' '#!/usr/bin/env sh' 'printf 20000101000000' > "$fake_bin/date"
  chmod +x "$fake_bin/date"
  ln -s "$backup_outside/missing-backup" \
    "$backup_target/.claude/commands/sdk-next.md.sdk-bak.20000101000000"
  expect_unsafe_failure backup-link \
    env PATH="$fake_bin:$PATH" bash "$ROOT/install.sh" \
      --target "$backup_target" --yes --force
  assert_only_sentinel "$backup_outside" backup-safe
  grep -qx 'custom-engine' "$backup_target/.claude/commands/sdk-next.md"
  [ ! -e "$backup_outside/missing-backup" ] || {
    echo "backup link was followed" >&2
    exit 1
  }

  merge_parent="$TMP_ROOT/merge-parent"
  merge_target="$merge_parent/project"
  merge_outside="$TMP_ROOT/merge-outside"
  install_clean "$merge_parent" "$merge_target"
  mkdir -p "$merge_outside"
  printf '# shared lessons\n' > "$merge_outside/lessons.md"
  rm "$merge_target/.specify/memory/lessons.md"
  ln -s "$merge_outside/lessons.md" "$merge_target/.specify/memory/lessons.md"
  before="$(cksum "$merge_outside/lessons.md")"
  bash "$ROOT/install.sh" --target "$merge_target" --yes >/dev/null
  after="$(cksum "$merge_outside/lessons.md")"
  [ "$before" = "$after" ] || { echo "linked MERGE data was overwritten" >&2; exit 1; }
  [ -L "$merge_target/.specify/memory/lessons.md" ] || {
    echo "linked MERGE data was replaced" >&2
    exit 1
  }
  [ -f "$merge_target/.specify/memory/lessons.md.sdk-new" ] || {
    echo "linked MERGE data did not receive a safe sidecar" >&2
    exit 1
  }
else
  rm -f "$probe_link"
  echo "SKIP file-symlink cases: host cannot create symbolic links"
fi

echo "install path safety (Bash): ok"
