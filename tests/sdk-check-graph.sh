#!/usr/bin/env bash
# Integration matrix for the canonical task dependency graph in sdk-check Bash/PowerShell.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

prepare_case() {
  local name="$1"
  shift
  local target="$TMP_ROOT/$name" row id dependencies

  mkdir -p "$target"
  cp -R "$ROOT/tests/fixtures/valid/." "$target"
  rm -f "$target/docs/plans/sample/evidence.md"
  mkdir -p "$target/scripts"
  cp "$ROOT/scripts/sdk-check.sh" "$ROOT/scripts/sdk-check.ps1" "$target/scripts/"

  {
    printf '%s\n' \
      '# Tasks - Dependency graph fixture' \
      '' \
      '- **Plano de referência:** `docs/plans/sample/plan.md`' \
      '- **Spec de referência:** `docs/specs/sample/spec.md`' \
      '- **Evidence:** `docs/plans/sample/evidence.md`' \
      '' \
      '---' \
      '' \
      '## Tabela de tasks' \
      '' \
      '| ID | Descrição | Depende de | AC | Perfis | Arquivo(s) | Verificação | Estado |' \
      '|----|-----------|------------|----|---------|------------|-------------|--------|'
    for row in "$@"; do
      id="${row%%:*}"
      dependencies="${row#*:}"
      printf '| %s | Task %s | %s | AC1 | logic | `x` | manual | backlog |\n' \
        "$id" "$id" "$dependencies"
    done
    printf '%s\n' \
      '' \
      '## Cobertura de AC e perfis' \
      '- Nenhuma lacuna para este fixture de grafo.'
  } > "$target/docs/plans/sample/tasks.md"

  printf '%s' "$target"
}

run_checker() {
  local checker="$1" target="$2"
  if [ "$checker" = "bash" ]; then
    bash "$target/scripts/sdk-check.sh"
  else
    pwsh -NoProfile -File "$target/scripts/sdk-check.ps1"
  fi
}

expect_pass() {
  local name="$1"
  shift
  local target checker output
  target="$(prepare_case "$name" "$@")"
  for checker in bash powershell; do
    if ! output="$(run_checker "$checker" "$target" 2>&1)"; then
      echo "$output"
      echo "$name unexpectedly failed in $checker" >&2
      exit 1
    fi
  done
}

expect_fail() {
  local name="$1" needle="$2"
  shift 2
  local target checker output
  target="$(prepare_case "$name" "$@")"
  for checker in bash powershell; do
    if output="$(run_checker "$checker" "$target" 2>&1)"; then
      echo "$output"
      echo "$name unexpectedly passed in $checker" >&2
      exit 1
    fi
    if ! grep -Fq -- "$needle" <<< "$output"; then
      echo "$output"
      echo "$name failed in $checker, but not for the expected reason: $needle" >&2
      exit 1
    fi
  done
}

expect_pass valid-empty 'T1:—'
expect_pass valid-diamond 'T1:—' 'T2:T1' 'T3:T1' 'T4:T2, T3'
expect_pass valid-prefix-ids 'T1:—' 'T10:T1' 'T2:T10'

expect_fail self-cycle 'ciclo de dependencias: T1 -> T1' 'T1:T1'
expect_fail long-cycle 'ciclo de dependencias: T1 -> T2 -> T3 -> T1' 'T1:T2' 'T2:T3' 'T3:T1'
expect_fail tail-to-cycle 'ciclo de dependencias: T2 -> T3 -> T2' 'T1:T2' 'T2:T3' 'T3:T2'
expect_fail unknown-reference 'task T1 depende de task inexistente T99' 'T1:T99'
expect_fail malformed-prose 'task T2 tem Depende de' 'T1:—' 'T2:T1 e T3' 'T3:—'
expect_fail mixed-none 'task T1 tem Depende de' 'T1:—, T2' 'T2:—'
expect_fail duplicate-reference 'task T2 repete depend' 'T1:—' 'T2:T1, T1'
expect_fail empty-cell 'task T1 tem Depende de' 'T1:'
expect_fail invalid-id 'ID de task invalido: t1' 't1:—'
expect_fail lowercase-dependency 'task T2 tem Depende de' 'T1:—' 'T2:t1'
expect_fail empty-table 'tabela de tasks nao possui task canonica'

missing_column="$(prepare_case missing-column 'T1:—')"
sed -i 's/ | Depende de//' "$missing_column/docs/plans/sample/tasks.md"
for checker in bash powershell; do
  if output="$(run_checker "$checker" "$missing_column" 2>&1)"; then
    echo "$output"
    echo "missing-column unexpectedly passed in $checker" >&2
    exit 1
  fi
  grep -Fq 'exatamente uma coluna Depende de' <<< "$output" || {
    echo "$output"
    echo "missing-column failed in $checker for the wrong reason" >&2
    exit 1
  }
done

echo "sdk-check dependency graph matrix passed."
