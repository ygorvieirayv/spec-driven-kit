#!/usr/bin/env bash
# Integration/negative matrix for the consumer quality-gate runner.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

prepare_project() {
  local name="$1" target gate
  target="$TMP_ROOT/$name with spaces"
  mkdir -p "$target/scripts" "$target/.specify/ci/gates" "$target/.specify/memory" \
    "$target/.github/workflows"
  cp "$ROOT/scripts/sdk-ci.sh" "$target/scripts/"
  cat > "$target/.specify/memory/project-context.md" <<'EOF'
## Contrato de CI
- **Runner de quality:** `ubuntu-24.04`
| Gate | Contrato | Detalhe |
|------|----------|---------|
| install | required | fixture |
| lint | required | fixture |
| typecheck | required | fixture |
| test | required | fixture |
| build | required | fixture |
| dependency-audit | required | fixture |
EOF
  cat > "$target/.github/workflows/sdk-quality.yml" <<'EOF'
name: Fixture
jobs:
  quality:
    runs-on: ubuntu-24.04
    steps: []
EOF
  for gate in install lint typecheck test build dependency-audit; do
    printf '# Gate %s\nprintf "%%s\\n" "$SDK_CI_GATE" >> .gate-order\n' "$gate" \
      > "$target/.specify/ci/gates/$gate.sh"
  done
  printf '%s' "$target"
}

valid="$(prepare_project valid)"
printf 'Projeto JavaScript sem etapa separada de typecheck.' > "$valid/.specify/ci/gates/typecheck.skip"
rm "$valid/.specify/ci/gates/typecheck.sh"
sed -i 's/| typecheck | required |/| typecheck | N\/A |/' "$valid/.specify/memory/project-context.md"
bash "$valid/scripts/sdk-ci.sh" >/dev/null
expected=$'install\nlint\ntest\nbuild\ndependency-audit'
actual="$(cat "$valid/.gate-order")"
[ "$actual" = "$expected" ] || {
  echo "Gate execution order diverged" >&2
  printf 'expected:\n%s\nactual:\n%s\n' "$expected" "$actual" >&2
  exit 1
}
bash "$valid/scripts/sdk-ci.sh" --validate >/dev/null

missing="$(prepare_project missing)"
rm "$missing/.specify/ci/gates/test.sh"
if output="$(bash "$missing/scripts/sdk-ci.sh" 2>&1)"; then
  echo "Missing required gate unexpectedly passed" >&2
  exit 1
fi
grep -Fq 'test sem .sh nem .skip' <<< "$output"
[ ! -e "$missing/.gate-order" ] || {
  echo "Runner executed commands before validating the complete contract" >&2
  exit 1
}

duplicate="$(prepare_project duplicate)"
printf 'Typecheck nao se aplica porque o projeto nao possui tipos.' > \
  "$duplicate/.specify/ci/gates/typecheck.skip"
if output="$(bash "$duplicate/scripts/sdk-ci.sh" --validate 2>&1)"; then
  echo "Duplicate .sh/.skip contract unexpectedly passed" >&2
  exit 1
fi
grep -Fq 'typecheck possui .sh e .skip' <<< "$output"

drift="$(prepare_project context-drift)"
rm "$drift/.specify/ci/gates/test.sh"
printf 'Este produto terceiriza testes ao provedor externo.' > "$drift/.specify/ci/gates/test.skip"
if output="$(bash "$drift/scripts/sdk-ci.sh" --validate 2>&1)"; then
  echo "Gate/context drift unexpectedly passed" >&2
  exit 1
fi
grep -Fq 'test.skip diverge do project-context.md, que declara required' <<< "$output"

runner_drift="$(prepare_project runner-drift)"
sed -i 's/runs-on: ubuntu-24.04/runs-on: windows-2025/' \
  "$runner_drift/.github/workflows/sdk-quality.yml"
if output="$(bash "$runner_drift/scripts/sdk-ci.sh" --validate 2>&1)"; then
  echo "Approved runner/workflow drift unexpectedly passed" >&2
  exit 1
fi
grep -Fq 'runs-on do workflow diverge do Runner de quality aprovado' <<< "$output"

mutable_action="$(prepare_project mutable-action)"
cat > "$mutable_action/.github/workflows/sdk-quality.yml" <<'EOF'
name: Fixture
jobs:
  quality:
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@main
EOF
if output="$(bash "$mutable_action/scripts/sdk-ci.sh" --validate 2>&1)"; then
  echo "$output" >&2
  echo "Mutable generated action reference unexpectedly passed" >&2
  exit 1
fi
grep -Fq "action 'actions/checkout@main' nao esta fixada por SHA completo" <<< "$output"

placeholder="$(prepare_project placeholder)"
rm "$placeholder/.specify/ci/gates/build.sh"
printf '[VERIFICAR] depois' > "$placeholder/.specify/ci/gates/build.skip"
if output="$(bash "$placeholder/scripts/sdk-ci.sh" --validate 2>&1)"; then
  echo "Placeholder skip unexpectedly passed" >&2
  exit 1
fi
grep -Fq 'build.skip contem motivo temporario ou placeholder' <<< "$output"

bypass="$(prepare_project bypass)"
printf 'npm test --if-present || true\n' > "$bypass/.specify/ci/gates/test.sh"
if output="$(bash "$bypass/scripts/sdk-ci.sh" --validate 2>&1)"; then
  echo "Fail-open gate command unexpectedly passed" >&2
  exit 1
fi
grep -Fq 'test.sh contem bypass fail-open proibido' <<< "$output"

failing="$(prepare_project failing)"
printf 'exit 23\n' > "$failing/.specify/ci/gates/test.sh"
set +e
bash "$failing/scripts/sdk-ci.sh" >/dev/null 2>&1
status=$?
set -e
[ "$status" -eq 23 ] || {
  echo "Gate failure exit was not propagated (got $status, expected 23)" >&2
  exit 1
}
actual="$(cat "$failing/.gate-order")"
[ "$actual" = $'install\nlint\ntypecheck' ] || {
  echo "Runner continued after a failed gate" >&2
  exit 1
}

unknown="$(prepare_project unknown)"
printf 'echo typo\n' > "$unknown/.specify/ci/gates/tests.sh"
if output="$(bash "$unknown/scripts/sdk-ci.sh" --validate 2>&1)"; then
  echo "Unknown gate unexpectedly passed" >&2
  exit 1
fi
grep -Fq 'tests.sh nao pertence ao catalogo canonico' <<< "$output"

echo "sdk-ci consumer matrix passed."
