#!/usr/bin/env bash
# Proves that kit-rules rejects a real semantic mutation instead of only accepting the healthy tree.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

bash "$ROOT/scripts/kit-rules.sh"

copy_contract_surface() {
  local target="$1"
  mkdir -p "$target"
  cp -R "$ROOT/.claude" "$ROOT/.specify" "$ROOT/scripts" "$target/"
  cp "$ROOT/CLAUDE.md" "$target/"
}

done_owner="$TMP_ROOT/done-owner"
copy_contract_surface "$done_owner"
sed -i 's/Nunca marque `done`; essa promoção pertence somente a `\/sdk-review`/A implementação pode marcar `done` diretamente/' \
  "$done_owner/.claude/commands/sdk-implement.md"
if output="$(bash "$done_owner/scripts/kit-rules.sh" 2>&1)"; then
  echo "$output"
  echo "Mutating the done owner unexpectedly passed kit-rules" >&2
  exit 1
fi
grep -Fq 'KR-01 .claude/commands/sdk-implement.md' <<< "$output" || {
  echo "$output"
  echo "Done-owner mutation failed without identifying KR-01 and its consumer" >&2
  exit 1
}

legacy_mode="$TMP_ROOT/legacy-mode"
copy_contract_surface "$legacy_mode"
legacy='PROTO'"TYPE"
printf '\n%s\n' "$legacy" >> "$legacy_mode/CLAUDE.md"
if output="$(bash "$legacy_mode/scripts/kit-rules.sh" 2>&1)"; then
  echo "$output"
  echo "Injecting a legacy global mode unexpectedly passed kit-rules" >&2
  exit 1
fi
grep -Fq 'KR-05 CLAUDE.md' <<< "$output" || {
  echo "$output"
  echo "Legacy-mode mutation failed without identifying KR-05 and its file" >&2
  exit 1
}

additive_contradictions="$TMP_ROOT/additive-contradictions"
copy_contract_surface "$additive_contradictions"
printf '\nA implementação pode marcar `done` diretamente.\n' >> \
  "$additive_contradictions/.claude/commands/sdk-implement.md"
printf '\nCrítico e Alto podem ser aprovados com ressalvas.\n' >> \
  "$additive_contradictions/.claude/commands/sdk-review.md"
printf '| KR-11 | Regra sem asserção | fonte | consumidor |\n' >> \
  "$additive_contradictions/scripts/kit-rules.txt"
if output="$(bash "$additive_contradictions/scripts/kit-rules.sh" 2>&1)"; then
  echo "$output"
  echo "Adding contradictory directives unexpectedly passed kit-rules" >&2
  exit 1
fi
grep -Fq 'KR-01 .claude/commands/sdk-implement.md' <<< "$output" || {
  echo "$output"
  echo "Additive done contradiction failed without identifying KR-01 and its consumer" >&2
  exit 1
}
grep -Fq 'KR-02 .claude/commands/sdk-review.md' <<< "$output" || {
  echo "$output"
  echo "Additive severity contradiction failed without identifying KR-02 and its consumer" >&2
  exit 1
}
grep -Fq 'KR-INDEX scripts/kit-rules.txt' <<< "$output" || {
  echo "$output"
  echo "Unknown invariant failed without identifying the rule index" >&2
  exit 1
}

ci_contract="$TMP_ROOT/ci-contract"
copy_contract_surface "$ci_contract"
sed -i 's#run: bash scripts/sdk-secrets.sh#run: echo secret scan disabled#' \
  "$ci_contract/.specify/templates/consumer-ci-template.yml"
if output="$(bash "$ci_contract/scripts/kit-rules.sh" 2>&1)"; then
  echo "$output"
  echo "Removing the consumer secret scan unexpectedly passed kit-rules" >&2
  exit 1
fi
grep -Fq 'KR-10 .specify/templates/consumer-ci-template.yml' <<< "$output" || {
  echo "$output"
  echo "CI mutation failed without identifying KR-10 and its template" >&2
  exit 1
}

mutable_action="$TMP_ROOT/mutable-action"
copy_contract_surface "$mutable_action"
sed -i 's#actions/checkout@[0-9a-f]\{40\}#actions/checkout@main#' \
  "$mutable_action/.specify/templates/consumer-ci-template.yml"
if output="$(bash "$mutable_action/scripts/kit-rules.sh" 2>&1)"; then
  echo "$output"
  echo "Mutable consumer action reference unexpectedly passed kit-rules" >&2
  exit 1
fi
grep -Fq 'KR-10 .specify/templates/consumer-ci-template.yml' <<< "$output" || {
  echo "$output"
  echo "Mutable action failed without identifying KR-10 and its template" >&2
  exit 1
}

missing_tree_scan="$TMP_ROOT/missing-tree-scan"
copy_contract_surface "$missing_tree_scan"
sed -i 's/^"\$binary" dir /echo skipped-dir /' "$missing_tree_scan/scripts/sdk-secrets.sh"
if output="$(bash "$missing_tree_scan/scripts/kit-rules.sh" 2>&1)"; then
  echo "$output"
  echo "Removing the current-tree scan unexpectedly passed kit-rules" >&2
  exit 1
fi
grep -Fq 'KR-10 scripts/sdk-secrets.sh' <<< "$output" || {
  echo "$output"
  echo "Tree-scan mutation failed without identifying KR-10 and its script" >&2
  exit 1
}

echo "kit-rules negative tests passed."
