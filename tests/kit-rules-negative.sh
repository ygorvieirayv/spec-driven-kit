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

additive_contradictions="$TMP_ROOT/additive-contradictions"
copy_contract_surface "$additive_contradictions"
printf '\nA implementação pode marcar `done` diretamente.\n' >> \
  "$additive_contradictions/.claude/commands/sdk-implement.md"
printf '\nCrítico e Alto podem ser aprovados com ressalvas.\n' >> \
  "$additive_contradictions/.claude/commands/sdk-review.md"
printf '| KR-12 | Regra sem asserção | fonte | consumidor |\n' >> \
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

cycle_route="$TMP_ROOT/cycle-route"
copy_contract_surface "$cycle_route"
sed -i 's/^SDK-CYCLE-ALLOWED=sdk-tasks,sdk-analyze$/SDK-CYCLE-ALLOWED=sdk-tasks,sdk-analyze,sdk-implement/' \
  "$cycle_route/.claude/commands/sdk-cycle.md"
if output="$(bash "$cycle_route/scripts/kit-rules.sh" 2>&1)"; then
  echo "$output"
  echo "Allowing sdk-implement inside sdk-cycle unexpectedly passed kit-rules" >&2
  exit 1
fi
grep -Fq 'KR-11 .claude/commands/sdk-cycle.md' <<< "$output" || {
  echo "$output"
  echo "Cycle-route mutation failed without identifying KR-11 and sdk-cycle" >&2
  exit 1
}

cycle_owner="$TMP_ROOT/cycle-owner"
copy_contract_surface "$cycle_owner"
sed -i 's/^SDK-CYCLE-OWNS-MARKERS=false$/SDK-CYCLE-OWNS-MARKERS=true/' \
  "$cycle_owner/.claude/commands/sdk-cycle.md"
if output="$(bash "$cycle_owner/scripts/kit-rules.sh" 2>&1)"; then
  echo "$output"
  echo "Giving marker ownership to sdk-cycle unexpectedly passed kit-rules" >&2
  exit 1
fi
grep -Fq 'KR-11 .claude/commands/sdk-cycle.md' <<< "$output" || {
  echo "$output"
  echo "Cycle-owner mutation failed without identifying KR-11 and sdk-cycle" >&2
  exit 1
}

analyze_route="$TMP_ROOT/analyze-route"
copy_contract_surface "$analyze_route"
sed -i '/Analyze:/ { /bloqueado/ s/Não avance/Implemente agora/; }' \
  "$analyze_route/.claude/commands/sdk-next.md"
if output="$(bash "$analyze_route/scripts/kit-rules.sh" 2>&1)"; then
  echo "$output"
  echo "Routing Analyze bloqueado to implementation unexpectedly passed kit-rules" >&2
  exit 1
fi
grep -Fq 'KR-11 .claude/commands/sdk-next.md' <<< "$output" || {
  echo "$output"
  echo "Analyze-route mutation failed without identifying KR-11 and sdk-next" >&2
  exit 1
}

review_route="$TMP_ROOT/review-route"
copy_contract_surface "$review_route"
sed -i '/Review:/ { /task.*blocked.*não resolvida/ s/Não avance/\/sdk-implement/; }' \
  "$review_route/.claude/commands/sdk-next.md"
if output="$(bash "$review_route/scripts/kit-rules.sh" 2>&1)"; then
  echo "$output"
  echo "Ignoring an unresolved blocked task after review unexpectedly passed kit-rules" >&2
  exit 1
fi
grep -Fq 'KR-11 .claude/commands/sdk-next.md' <<< "$output" || {
  echo "$output"
  echo "Review-route mutation failed without identifying KR-11 and sdk-next" >&2
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
