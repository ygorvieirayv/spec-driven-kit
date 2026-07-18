#!/usr/bin/env bash
# sdk-check.sh — validação determinística dos marcadores de estado do Spec Driven Kit.
# Implementa o contrato de .specify/memory/state-markers.md. Zero token: só grep/awk.
#
# Uso: ./scripts/sdk-check.sh
# Saída: ERRO (viola o contrato — exit 1) · AVISO (incompleto/molde — não bloqueia).
# O /sdk-doctor roda este script como primeira camada (T0), antes de qualquer leitura por LLM.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ERROS=0
AVISOS=0

erro()  { echo "ERRO  $1"; ERROS=$((ERROS + 1)); }
aviso() { echo "AVISO $1"; AVISOS=$((AVISOS + 1)); }

rel() { echo "${1#"$ROOT"/}"; }

# ---------------------------------------------------------------- specs: Status
for spec in "$ROOT"/docs/specs/*/spec.md; do
  [ -e "$spec" ] || continue
  r="$(rel "$spec")"
  line="$(grep -m1 -E '^- \*\*Status:\*\*' "$spec" || true)"
  if [ -z "$line" ]; then
    erro "$r: sem a linha '- **Status:**' (contrato: state-markers.md)"
  elif echo "$line" | grep -q 'rascunho | em revisão | aprovada'; then
    aviso "$r: Status ainda no molde (não preenchido)"
  elif ! echo "$line" | grep -qE '^- \*\*Status:\*\* (rascunho|em revisão|aprovada)\b'; then
    erro "$r: Status fora do vocabulário (rascunho | em revisão | aprovada)"
  fi
done

# ------------------------------------------- planos: Status, Analyze, Review
for plan in "$ROOT"/docs/plans/*/plan.md; do
  [ -e "$plan" ] || continue
  r="$(rel "$plan")"

  line="$(grep -m1 -E '^- \*\*Status:\*\*' "$plan" || true)"
  if [ -z "$line" ]; then
    erro "$r: sem a linha '- **Status:**'"
  elif echo "$line" | grep -q 'rascunho | aprovado'; then
    aviso "$r: Status ainda no molde (não preenchido)"
  elif ! echo "$line" | grep -qE '^- \*\*Status:\*\* (rascunho|aprovado)\b'; then
    erro "$r: Status fora do vocabulário (rascunho | aprovado)"
  fi

  line="$(grep -m1 -E '^- \*\*Analyze:\*\*' "$plan" || true)"
  if [ -z "$line" ]; then
    aviso "$r: sem a linha '- **Analyze:**' (plano anterior ao contrato? adicione-a)"
  elif ! echo "$line" | grep -qE '^- \*\*Analyze:\*\* (pendente|consistente|ajustar|bloqueado)\b'; then
    erro "$r: Analyze fora do vocabulário (pendente | consistente | ajustar | bloqueado)"
  fi

  line="$(grep -m1 -E '^- \*\*Review:\*\*' "$plan" || true)"
  if [ -z "$line" ]; then
    aviso "$r: sem a linha '- **Review:**' (plano anterior ao contrato? adicione-a)"
  elif ! echo "$line" | grep -qE '^- \*\*Review:\*\* (—|aprovado( com ressalvas)?|bloqueado)'; then
    erro "$r: Review fora do vocabulário (— | aprovado | aprovado com ressalvas | bloqueado)"
  fi
done

# -------------------------------- tasks, AC <-> task e evidência (por feature)
# Se tasks.md existe, ele é a fonte autoritativa. A tabela inline do plano só vale na ausência dele.
trim() {
  printf '%s' "$1" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//'
}

valid_iso8601() {
  local value="$1"
  local year month day hour minute second zone offset_hour offset_minute max_day leap=0
  local iso_re='^([0-9]{4})-([0-9]{2})-([0-9]{2})T([0-9]{2}):([0-9]{2}):([0-9]{2})(\.[0-9]+)?(Z|[+-][0-9]{2}:[0-9]{2})$'
  [[ "$value" =~ $iso_re ]] || return 1

  year=$((10#${BASH_REMATCH[1]}))
  month=$((10#${BASH_REMATCH[2]}))
  day=$((10#${BASH_REMATCH[3]}))
  hour=$((10#${BASH_REMATCH[4]}))
  minute=$((10#${BASH_REMATCH[5]}))
  second=$((10#${BASH_REMATCH[6]}))
  zone="${BASH_REMATCH[8]}"

  [ "$year" -ge 1 ] || return 1
  [ "$month" -ge 1 ] && [ "$month" -le 12 ] || return 1
  [ "$hour" -le 23 ] && [ "$minute" -le 59 ] && [ "$second" -le 59 ] || return 1

  if [ $((year % 400)) -eq 0 ] || \
     { [ $((year % 4)) -eq 0 ] && [ $((year % 100)) -ne 0 ]; }; then
    leap=1
  fi
  case "$month" in
    1|3|5|7|8|10|12) max_day=31 ;;
    4|6|9|11) max_day=30 ;;
    2) max_day=$((28 + leap)) ;;
  esac
  [ "$day" -ge 1 ] && [ "$day" -le "$max_day" ] || return 1

  if [ "$zone" != "Z" ]; then
    offset_hour=$((10#${zone:1:2}))
    offset_minute=$((10#${zone:4:2}))
    [ "$offset_hour" -le 14 ] && [ "$offset_minute" -le 59 ] || return 1
    if [ "$offset_hour" -eq 14 ] && [ "$offset_minute" -ne 0 ]; then
      return 1
    fi
  fi
  return 0
}

latest_record() {
  local evidence="$1" task="$2" phase="$3"
  awk -v target="$task" -v wanted_phase="$phase" '
    function trim_value(value) {
      gsub(/^[ \t]+|[ \t]+$/, "", value)
      return value
    }
    /^- \*\*Registro:\*\*/ {
      line = $0
      sub(/^- \*\*Registro:\*\*[ \t]*/, "", line)
      count = split(line, fields, /\|/)
      for (i = 1; i <= count; i++) fields[i] = trim_value(fields[i])
      if (count == 5 && fields[1] == target && fields[3] == wanted_phase) {
        latest = NR "|" fields[2] "|" fields[4] "|" fields[5]
      }
    }
    END { if (latest != "") print latest }
  ' "$evidence"
}

review_records_after_line() {
  local evidence="$1" task="$2" after_line="$3"
  awk -v target="$task" -v after="$after_line" '
    function trim_value(value) {
      gsub(/^[ \t]+|[ \t]+$/, "", value)
      return value
    }
    NR > after && /^- \*\*Registro:\*\*/ {
      line = $0
      sub(/^- \*\*Registro:\*\*[ \t]*/, "", line)
      count = split(line, fields, /\|/)
      for (i = 1; i <= count; i++) fields[i] = trim_value(fields[i])
      if (count == 5 && fields[1] == target && fields[3] == "review") {
        print NR "|" fields[4]
      }
    }
  ' "$evidence"
}

latest_record_before_line() {
  local evidence="$1" task="$2" phase="$3" before_line="$4"
  awk -v target="$task" -v wanted_phase="$phase" -v before="$before_line" '
    function trim_value(value) {
      gsub(/^[ \t]+|[ \t]+$/, "", value)
      return value
    }
    NR < before && /^- \*\*Registro:\*\*/ {
      line = $0
      sub(/^- \*\*Registro:\*\*[ \t]*/, "", line)
      count = split(line, fields, /\|/)
      for (i = 1; i <= count; i++) fields[i] = trim_value(fields[i])
      if (count == 5 && fields[1] == target && fields[3] == wanted_phase) {
        latest = NR "|" fields[2] "|" fields[4] "|" fields[5]
      }
    }
    END { if (latest != "") print latest }
  ' "$evidence"
}

review_records_between_lines() {
  local evidence="$1" task="$2" after_line="$3" before_line="$4"
  awk -v target="$task" -v after="$after_line" -v before="$before_line" '
    function trim_value(value) {
      gsub(/^[ \t]+|[ \t]+$/, "", value)
      return value
    }
    NR > after && NR < before && /^- \*\*Registro:\*\*/ {
      line = $0
      sub(/^- \*\*Registro:\*\*[ \t]*/, "", line)
      count = split(line, fields, /\|/)
      for (i = 1; i <= count; i++) fields[i] = trim_value(fields[i])
      if (count == 5 && fields[1] == target && fields[3] == "review") {
        print NR "|" fields[2] "|" fields[4] "|" fields[5]
      }
    }
  ' "$evidence"
}

task_records_before_line() {
  local evidence="$1" task="$2" before_line="$3"
  awk -v target="$task" -v before="$before_line" '
    function trim_value(value) {
      gsub(/^[ \t]+|[ \t]+$/, "", value)
      return value
    }
    NR < before && /^- \*\*Registro:\*\*/ {
      line = $0
      sub(/^- \*\*Registro:\*\*[ \t]*/, "", line)
      count = split(line, fields, /\|/)
      for (i = 1; i <= count; i++) fields[i] = trim_value(fields[i])
      if (count == 5 && fields[1] == target) {
        print NR "|" fields[3] "|" fields[2] "|" fields[4] "|" fields[5]
      }
    }
  ' "$evidence"
}

task_implement_records() {
  local evidence="$1" task="$2"
  awk -v target="$task" '
    function trim_value(value) {
      gsub(/^[ \t]+|[ \t]+$/, "", value)
      return value
    }
    /^- \*\*Registro:\*\*/ {
      line = $0
      sub(/^- \*\*Registro:\*\*[ \t]*/, "", line)
      count = split(line, fields, /\|/)
      for (i = 1; i <= count; i++) fields[i] = trim_value(fields[i])
      if (count == 5 && fields[1] == target && fields[3] == "implement") {
        print NR "|" fields[2] "|" fields[4] "|" fields[5]
      }
    }
  ' "$evidence"
}

reclassification_marker_lines() {
  local evidence="$1" task="$2"
  awk -v target="$task" '
    function trim_value(value) {
      gsub(/^[ \t]+|[ \t]+$/, "", value)
      return value
    }
    /^### / {
      active = 0
      header_line = NR
      count = split($0, fields, / - /)
      if (count == 4 && trim_value(fields[3]) == target && trim_value(fields[4]) == "review") active = 1
      next
    }
    active && /^- \*\*Reclassificacao:\*\*/ { print header_line }
  ' "$evidence"
}

latest_task_record() {
  local evidence="$1" task="$2"
  awk -v target="$task" '
    function trim_value(value) {
      gsub(/^[ \t]+|[ \t]+$/, "", value)
      return value
    }
    function meaningful(value) {
      return value != "" && value != "-" && value != "..." && value != "—" && value !~ /^<.*>$/
    }
    function finish_block() {
      if (active && record_task == target) {
        latest = record_line "|" record_phase "|" record_result "|" record_ref "|" blocker_valid
      }
    }
    /^### / {
      finish_block()
      active = 0
      record_task = record_phase = record_result = record_ref = ""
      record_line = blocker_valid = 0
      if ($0 ~ /^### E[0-9]+ - .* - T[0-9]+ - (implement|review)$/) active = 1
      next
    }
    active && /^- \*\*Registro:\*\*/ {
      line = $0
      sub(/^- \*\*Registro:\*\*[ \t]*/, "", line)
      count = split(line, fields, /\|/)
      for (i = 1; i <= count; i++) fields[i] = trim_value(fields[i])
      if (count == 5 && (fields[3] == "implement" || fields[3] == "review")) {
        record_task = fields[1]
        record_phase = fields[3]
        record_result = fields[4]
        record_ref = fields[5]
        record_line = NR
      }
      next
    }
    active && /^- \*\*Bloqueio:\*\*/ {
      line = $0
      sub(/^- \*\*Bloqueio:\*\*[ \t]*/, "", line)
      count = split(line, fields, /\|/)
      for (i = 1; i <= count; i++) fields[i] = trim_value(fields[i])
      if (count == 3 && fields[1] == record_task && meaningful(fields[2]) && meaningful(fields[3])) {
        blocker_valid = 1
      }
    }
    END {
      finish_block()
      if (latest != "") print latest
    }
  ' "$evidence"
}

record_covers_declared_acs() {
  local declared_acs="$1" record_acs="$2" declared_ac
  while IFS= read -r declared_ac; do
    [ -n "$declared_ac" ] || continue
    echo "$record_acs" | grep -oE 'AC[0-9]+' | grep -qx "$declared_ac" || return 1
  done <<< "$declared_acs"
  return 0
}

reclassification_history_valid() {
  local evidence="$1" task="$2" marker_line="$3" declared_acs="$4"
  local implement_record implement_line implement_acs implement_result implement_ref
  local review_line review_acs review_result review_ref review_tainted=0

  implement_record="$(latest_record_before_line "$evidence" "$task" implement "$marker_line")"
  [ -n "$implement_record" ] || return 1
  IFS='|' read -r implement_line implement_acs implement_result implement_ref <<< "$implement_record"
  echo "$implement_result" | grep -qE '^(pass|observed)$' || return 1
  valid_sha_ref "$implement_ref" || return 1
  record_covers_declared_acs "$declared_acs" "$implement_acs" || return 1

  while IFS='|' read -r review_line review_acs review_result review_ref; do
    [ -n "$review_line" ] || continue
    case "$review_result" in
      fail|unavailable)
        review_tainted=1
        continue
        ;;
    esac
    [ "$review_tainted" -eq 0 ] || continue
    echo "$review_result" | grep -qE '^(pass|observed)$' || continue
    valid_sha_ref "$review_ref" || continue
    record_covers_declared_acs "$declared_acs" "$review_acs" || continue
    return 0
  done < <(review_records_between_lines "$evidence" "$task" "$implement_line" "$marker_line")
  return 1
}

latest_valid_review_before_line() {
  local evidence="$1" task="$2" before_line="$3" declared_acs="$4"
  local record_line record_phase record_acs record_result record_ref
  local base_valid=0 review_tainted=0 latest=""

  while IFS='|' read -r record_line record_phase record_acs record_result record_ref; do
    [ -n "$record_line" ] || continue
    if [ "$record_phase" = "implement" ]; then
      if echo "$record_result" | grep -qE '^(pass|observed)$' && \
         valid_sha_ref "$record_ref" && \
         record_covers_declared_acs "$declared_acs" "$record_acs"; then
        base_valid=1
        review_tainted=0
      fi
      continue
    fi
    [ "$record_phase" = "review" ] && [ "$base_valid" -eq 1 ] || continue
    case "$record_result" in
      fail|unavailable)
        review_tainted=1
        continue
        ;;
    esac
    [ "$review_tainted" -eq 0 ] || continue
    echo "$record_result" | grep -qE '^(pass|observed)$' || continue
    valid_sha_ref "$record_ref" || continue
    record_covers_declared_acs "$declared_acs" "$record_acs" || continue
    latest="$record_line"
  done < <(task_records_before_line "$evidence" "$task" "$before_line")
  [ -n "$latest" ] && echo "$latest"
}

ready_reclassification_gap() {
  local evidence="$1" task="$2" implement_line="$3" declared_acs="$4"
  local required_acs
  required_acs="$(printf '%s\n' "$declared_acs" | paste -sd, -)"
  awk -v target="$task" -v latest_implement="$implement_line" -v required_acs="$required_acs" '
    function trim_value(value) {
      gsub(/^[ \t]+|[ \t]+$/, "", value)
      return value
    }
    function covers_required(actual, required, actual_count, required_count, actual_items, required_items, i, j, found) {
      required_count = split(required_acs, required_items, /,/)
      actual_count = split(actual, actual_items, /,/)
      for (i = 1; i <= required_count; i++) {
        if (required_items[i] == "") continue
        found = 0
        for (j = 1; j <= actual_count; j++) {
          if (trim_value(actual_items[j]) == required_items[i]) found = 1
        }
        if (!found) return 0
      }
      return 1
    }
    function finish_block() {
      if (!active || record_task != target) return
      if (record_phase == "review" && record_line > latest_implement &&
          (record_result == "pass" || record_result == "observed") &&
          record_ref ~ /^(commit|worktree)@[0-9a-fA-F]{7,40}$/ &&
          covers_required(record_acs)) {
        done_review_lines[++done_review_count] = record_line
      } else if (record_phase == "review" && record_result == "not-run" && record_line > latest_implement) {
        has_done_review_before = 0
        for (i = 1; i <= done_review_count; i++) {
          if (done_review_lines[i] < record_line) has_done_review_before = 1
        }
        if (has_done_review_before) {
          latest_not_run = header_line
          latest_not_run_has_reclass = has_reclass
        }
      }
    }
    /^### / {
      finish_block()
      active = 0
      header_line = NR
      record_task = record_acs = record_phase = record_result = record_ref = ""
      record_line = has_reclass = 0
      if ($0 ~ /^### E[0-9]+ - .* - T[0-9]+ - (implement|review)$/) active = 1
      next
    }
    active && /^- \*\*Registro:\*\*/ {
      line = $0
      sub(/^- \*\*Registro:\*\*[ \t]*/, "", line)
      count = split(line, fields, /\|/)
      for (i = 1; i <= count; i++) fields[i] = trim_value(fields[i])
      if (count == 5) {
        record_task = fields[1]
        record_acs = fields[2]
        record_phase = fields[3]
        record_result = fields[4]
        record_ref = fields[5]
        record_line = NR
      }
      next
    }
    active && /^- \*\*Reclassificacao:\*\*/ { has_reclass = 1 }
    END {
      finish_block()
      if (latest_not_run > 0 && !latest_not_run_has_reclass) print latest_not_run
    }
  ' "$evidence"
}

valid_sha_ref() {
  echo "$1" | grep -qE '^(commit|worktree)@[0-9a-fA-F]{7,40}$'
}

task_declared_acs() {
  local task_source="$1" task="$2"
  awk -F'|' -v target="$task" '
    function trim_value(value) {
      gsub(/^[ \t]+|[ \t]+$/, "", value)
      return value
    }
    /^\|/ {
      if (ac_column == 0) {
        for (i = 1; i <= NF; i++) {
          if (trim_value($i) == "AC") ac_column = i
        }
      }
      id = trim_value($2)
      if (ac_column > 0 && id == target) {
        value = $ac_column
        while (match(value, /AC[0-9]+/)) {
          print substr(value, RSTART, RLENGTH)
          value = substr(value, RSTART + RLENGTH)
        }
      }
    }
  ' "$task_source" | sort -u
}

check_record_ac_coverage() {
  local task_source_rel="$1" task_id="$2" task_state="$3" phase="$4" declared_acs="$5" record_acs="$6"
  local declared_ac
  while IFS= read -r declared_ac; do
    [ -n "$declared_ac" ] || continue
    echo "$record_acs" | grep -oE 'AC[0-9]+' | grep -qx "$declared_ac" || \
      erro "$task_source_rel: task $task_id em $task_state tem Registro $phase mais recente sem o AC declarado $declared_ac"
  done <<< "$declared_acs"
}

valid_blocker_text() {
  local value; value="$(trim "$1")"
  [ -n "$value" ] && ! echo "$value" | grep -qE '^(-|\.\.\.|<[^>]*>|—)$'
}

task_declared_dependencies() {
  local task_source="$1" task="$2"
  awk -F'|' -v target="$task" '
    function trim_value(value) {
      gsub(/^[ \t]+|[ \t]+$/, "", value)
      return value
    }
    /^\|/ {
      if (dependency_column == 0) {
        for (i = 1; i <= NF; i++) {
          if (trim_value($i) == "Depende de") dependency_column = i
        }
      }
      id = trim_value($2)
      if (dependency_column > 0 && id == target) {
        value = $dependency_column
        while (match(value, /T[0-9]+/)) {
          print substr(value, RSTART, RLENGTH)
          value = substr(value, RSTART + RLENGTH)
        }
      }
    }
  ' "$task_source" | sort -u
}

task_state_for_id() {
  local task_source="$1" task="$2"
  awk -F'|' -v target="$task" '
    /^\| *T[0-9]+ *\|/ {
      id = $2
      state = $(NF-1)
      gsub(/^[ \t]+|[ \t]+$/, "", id)
      gsub(/^[ \t]+|[ \t]+$/, "", state)
      if (id == target) latest = state
    }
    END { if (latest != "") print latest }
  ' "$task_source"
}

reset_evidence_block() {
  EB_ACTIVE=0
  EB_HEADER_LINE=0
  EB_HEADER_TASK=""
  EB_HEADER_PHASE=""
  EB_RECORD_COUNT=0
  EB_RECORD_TASK=""
  EB_RECORD_ACS=""
  EB_RECORD_PHASE=""
  EB_RECORD_RESULT=""
  EB_RECORD_REF=""
  EB_BLOCKER_COUNT=0
  EB_BLOCKER_TASK=""
  EB_BLOCKER_REASON=""
  EB_BLOCKER_CONDITION=""
  EB_RECLASS_COUNT=0
  EB_RECLASS_TASK=""
  EB_RECLASS_FROM=""
  EB_RECLASS_TO=""
  EB_RECLASS_AT=""
  EB_RECLASS_REASON=""
  EB_ACTION_COUNT=0; EB_ACTION=""
  EB_DIRECTORY_COUNT=0; EB_DIRECTORY=""
  EB_SOURCE_COUNT=0; EB_SOURCE=""
  EB_EXIT_COUNT=0; EB_EXIT=""
  EB_OUTPUT_COUNT=0; EB_OUTPUT=""
  EB_BRANCH_COUNT=0; EB_BRANCH=""
  EB_LIMITATIONS_COUNT=0; EB_LIMITATIONS=""
}

finalize_evidence_block() {
  [ "$EB_ACTIVE" -eq 1 ] || return
  local label count value

  if [ "$EB_RECORD_COUNT" -ne 1 ]; then
    erro "$EVIDENCE_REL:$EB_HEADER_LINE: entrada exige exatamente um Registro (encontrados: $EB_RECORD_COUNT)"
  else
    [ "$EB_HEADER_TASK" = "$EB_RECORD_TASK" ] || \
      erro "$EVIDENCE_REL:$EB_HEADER_LINE: task do header $EB_HEADER_TASK diverge do Registro $EB_RECORD_TASK"
    [ "$EB_HEADER_PHASE" = "$EB_RECORD_PHASE" ] || \
      erro "$EVIDENCE_REL:$EB_HEADER_LINE: fase do header $EB_HEADER_PHASE diverge do Registro $EB_RECORD_PHASE"
  fi

  for label in ACTION DIRECTORY SOURCE EXIT OUTPUT BRANCH LIMITATIONS; do
    eval "count=\$EB_${label}_COUNT"
    eval "value=\$EB_${label}"
    if [ "$count" -ne 1 ]; then
      erro "$EVIDENCE_REL:$EB_HEADER_LINE: entrada exige exatamente um campo $label (encontrados: $count)"
    elif ! valid_blocker_text "$value"; then
      erro "$EVIDENCE_REL:$EB_HEADER_LINE: campo $label vazio ou placeholder"
    fi
  done

  if [ "$EB_BLOCKER_COUNT" -gt 1 ]; then
    erro "$EVIDENCE_REL:$EB_HEADER_LINE: entrada tem mais de um Bloqueio"
  elif [ "$EB_BLOCKER_COUNT" -eq 1 ]; then
    [ "$EB_BLOCKER_TASK" = "$EB_RECORD_TASK" ] || \
      erro "$EVIDENCE_REL:$EB_HEADER_LINE: task do Bloqueio $EB_BLOCKER_TASK diverge do Registro $EB_RECORD_TASK"
    valid_blocker_text "$EB_BLOCKER_REASON" || \
      erro "$EVIDENCE_REL:$EB_HEADER_LINE: Bloqueio sem motivo válido"
    valid_blocker_text "$EB_BLOCKER_CONDITION" || \
      erro "$EVIDENCE_REL:$EB_HEADER_LINE: Bloqueio sem condição de desbloqueio válida"
    case "$EB_RECORD_RESULT" in
      fail|not-run|unavailable) ;;
      *) erro "$EVIDENCE_REL:$EB_HEADER_LINE: Bloqueio exige Registro do mesmo bloco com fail/not-run/unavailable" ;;
    esac
  fi

  if [ "$EB_RECLASS_COUNT" -gt 1 ]; then
    erro "$EVIDENCE_REL:$EB_HEADER_LINE: entrada tem mais de uma Reclassificacao"
  elif [ "$EB_RECLASS_COUNT" -eq 1 ]; then
    [ "$EB_RECLASS_TASK" = "$EB_RECORD_TASK" ] || \
      erro "$EVIDENCE_REL:$EB_HEADER_LINE: task da Reclassificacao $EB_RECLASS_TASK diverge do Registro $EB_RECORD_TASK"
    [ "$EB_RECLASS_FROM" = "done" ] || \
      erro "$EVIDENCE_REL:$EB_HEADER_LINE: Reclassificacao exige estado anterior done"
    [ "$EB_RECLASS_TO" = "ready" ] || \
      erro "$EVIDENCE_REL:$EB_HEADER_LINE: Reclassificacao exige estado novo ready"
    valid_iso8601 "$EB_RECLASS_AT" || \
      erro "$EVIDENCE_REL:$EB_HEADER_LINE: Reclassificacao exige data/hora ISO-8601"
    valid_blocker_text "$EB_RECLASS_REASON" || \
      erro "$EVIDENCE_REL:$EB_HEADER_LINE: Reclassificacao sem motivo/referencia valido"
    if [ "$EB_RECORD_COUNT" -eq 1 ] && \
       { [ "$EB_RECORD_PHASE" != "review" ] || [ "$EB_RECORD_RESULT" != "not-run" ]; }; then
      erro "$EVIDENCE_REL:$EB_HEADER_LINE: Reclassificacao exige Registro review | not-run no mesmo bloco"
    fi
  fi

  if [ "$EB_RECORD_COUNT" -eq 1 ] && [ "$EB_EXIT_COUNT" -eq 1 ]; then
    case "$EB_RECORD_RESULT" in
      pass)
        [ "$EB_EXIT" = "0" ] || erro "$EVIDENCE_REL:$EB_HEADER_LINE: resultado pass exige Exit code 0"
        ;;
      fail)
        if ! echo "$EB_EXIT" | grep -qE '^-?[0-9]+$' || echo "$EB_EXIT" | grep -qE '^-?0+$'; then
          erro "$EVIDENCE_REL:$EB_HEADER_LINE: resultado fail exige Exit code inteiro diferente de 0"
        fi
        ;;
      observed|not-run)
        [ "$EB_EXIT" = "not-applicable" ] || \
          erro "$EVIDENCE_REL:$EB_HEADER_LINE: resultado $EB_RECORD_RESULT exige Exit code not-applicable"
        ;;
      unavailable)
        [ "$EB_EXIT" = "unavailable" ] || \
          erro "$EVIDENCE_REL:$EB_HEADER_LINE: resultado unavailable exige Exit code unavailable"
        ;;
    esac
  fi
}

parse_evidence_blocks() {
  local evidence="$1" evidence_rel="$2" known_tasks="$3" known_acs="$4"
  local line line_no=0 header_re field_re record field_count record_ac label value
  local previous_entry_id="" entry_id expected_entry_id canonical_block_count=0
  local header_time header_task header_phase
  EVIDENCE_REL="$evidence_rel"
  header_re='^### E([0-9]+) - ([0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(\.[0-9]+)?(Z|[+-][0-9]{2}:[0-9]{2})) - (T[0-9]+) - (implement|review)$'
  field_re='^- \*\*(Acao/comando|Diretorio|Fonte|Exit code|Saida/referencia|Branch|Limitacoes):\*\*[[:space:]]*(.*)$'
  reset_evidence_block

  while IFS= read -r line || [ -n "$line" ]; do
    line_no=$((line_no + 1))

    if [[ "$line" == "### "* ]]; then
      finalize_evidence_block
      reset_evidence_block
      if [[ "$line" =~ $header_re ]]; then
        entry_id="${BASH_REMATCH[1]}"
        header_time="${BASH_REMATCH[2]}"
        header_task="${BASH_REMATCH[5]}"
        header_phase="${BASH_REMATCH[6]}"
        canonical_block_count=$((canonical_block_count + 1))
        if [ -z "$previous_entry_id" ]; then
          expected_entry_id=1
        else
          expected_entry_id=$((previous_entry_id + 1))
        fi
        if [ "$entry_id" != "$expected_entry_id" ]; then
          erro "$evidence_rel:$line_no: sequencia de entradas invalida; esperado E$expected_entry_id, encontrado E$entry_id"
        fi
        previous_entry_id=$((10#$entry_id))
        valid_iso8601 "$header_time" || \
          erro "$evidence_rel:$line_no: data/hora invalida no cabecalho: '$header_time'"
        EB_ACTIVE=1
        EB_HEADER_LINE="$line_no"
        EB_HEADER_TASK="$header_task"
        EB_HEADER_PHASE="$header_phase"
      else
        erro "$evidence_rel:$line_no: header de entrada inválido; esperado '### E<n> - <ISO-8601> - T<n> - <implement|review>'"
      fi
      continue
    fi

    if [[ "$line" == "- **Registro:"* ]]; then
      if [ "$EB_ACTIVE" -ne 1 ]; then
        erro "$evidence_rel:$line_no: Registro fora de entrada"
        continue
      fi
      EB_RECORD_COUNT=$((EB_RECORD_COUNT + 1))
      record="$(printf '%s' "$line" | sed 's/^- \*\*Registro:\*\*[[:space:]]*//')"
      field_count="$(printf '%s\n' "$record" | awk -F'|' '{ print NF }')"
      if [ "$field_count" -ne 5 ]; then
        erro "$evidence_rel:$line_no: Registro deve ter exatamente 5 campos"
        continue
      fi
      IFS='|' read -r EB_RECORD_TASK EB_RECORD_ACS EB_RECORD_PHASE EB_RECORD_RESULT EB_RECORD_REF <<< "$record"
      EB_RECORD_TASK="$(trim "$EB_RECORD_TASK")"
      EB_RECORD_ACS="$(trim "$EB_RECORD_ACS")"
      EB_RECORD_PHASE="$(trim "$EB_RECORD_PHASE")"
      EB_RECORD_RESULT="$(trim "$EB_RECORD_RESULT")"
      EB_RECORD_REF="$(trim "$EB_RECORD_REF")"

      if ! echo "$EB_RECORD_TASK" | grep -qE '^T[0-9]+$'; then
        erro "$evidence_rel:$line_no: task inválida no Registro: '$EB_RECORD_TASK'"
      elif ! echo "$known_tasks" | grep -qx "$EB_RECORD_TASK"; then
        erro "$evidence_rel:$line_no: Registro referencia task inexistente: '$EB_RECORD_TASK'"
      fi
      if ! echo "$EB_RECORD_ACS" | grep -qE '^AC[0-9]+([[:space:]]*,[[:space:]]*AC[0-9]+)*$'; then
        erro "$evidence_rel:$line_no: AC inválido no Registro: '$EB_RECORD_ACS'"
      else
        while IFS= read -r record_ac; do
          [ -n "$record_ac" ] || continue
          echo "$known_acs" | grep -qx "$record_ac" || \
            erro "$evidence_rel:$line_no: Registro referencia $record_ac, que não existe na spec"
        done < <(echo "$EB_RECORD_ACS" | grep -oE 'AC[0-9]+')
      fi
      case "$EB_RECORD_PHASE" in implement|review) ;; *) erro "$evidence_rel:$line_no: fase inválida no Registro: '$EB_RECORD_PHASE'" ;; esac
      case "$EB_RECORD_RESULT" in pass|fail|observed|not-run|unavailable) ;; *) erro "$evidence_rel:$line_no: resultado inválido no Registro: '$EB_RECORD_RESULT'" ;; esac
      echo "$EB_RECORD_REF" | grep -qE '^((commit|worktree)@[0-9a-fA-F]{7,40}|unavailable)$' || \
        erro "$evidence_rel:$line_no: ref inválida no Registro: '$EB_RECORD_REF'"
      continue
    fi

    if [[ "$line" == "- **Bloqueio:"* ]]; then
      if [ "$EB_ACTIVE" -ne 1 ]; then
        erro "$evidence_rel:$line_no: Bloqueio fora de entrada"
        continue
      fi
      if [ "$EB_RECORD_COUNT" -ne 1 ]; then
        erro "$evidence_rel:$line_no: Bloqueio deve aparecer depois do único Registro da entrada"
      fi
      EB_BLOCKER_COUNT=$((EB_BLOCKER_COUNT + 1))
      record="$(printf '%s' "$line" | sed 's/^- \*\*Bloqueio:\*\*[[:space:]]*//')"
      field_count="$(printf '%s\n' "$record" | awk -F'|' '{ print NF }')"
      if [ "$field_count" -ne 3 ]; then
        erro "$evidence_rel:$line_no: Bloqueio deve ter exatamente 3 campos"
        continue
      fi
      IFS='|' read -r EB_BLOCKER_TASK EB_BLOCKER_REASON EB_BLOCKER_CONDITION <<< "$record"
      EB_BLOCKER_TASK="$(trim "$EB_BLOCKER_TASK")"
      EB_BLOCKER_REASON="$(trim "$EB_BLOCKER_REASON")"
      EB_BLOCKER_CONDITION="$(trim "$EB_BLOCKER_CONDITION")"
      if ! echo "$EB_BLOCKER_TASK" | grep -qE '^T[0-9]+$'; then
        erro "$evidence_rel:$line_no: task inválida no Bloqueio: '$EB_BLOCKER_TASK'"
      elif ! echo "$known_tasks" | grep -qx "$EB_BLOCKER_TASK"; then
        erro "$evidence_rel:$line_no: Bloqueio referencia task inexistente: '$EB_BLOCKER_TASK'"
      fi
      continue
    fi

    if [[ "$line" == "- **Reclassificacao:"* ]]; then
      if [ "$EB_ACTIVE" -ne 1 ]; then
        erro "$evidence_rel:$line_no: Reclassificacao fora de entrada"
        continue
      fi
      if [ "$EB_RECORD_COUNT" -ne 1 ]; then
        erro "$evidence_rel:$line_no: Reclassificacao deve aparecer depois do unico Registro da entrada"
      fi
      EB_RECLASS_COUNT=$((EB_RECLASS_COUNT + 1))
      record="$(printf '%s' "$line" | sed 's/^- \*\*Reclassificacao:\*\*[[:space:]]*//')"
      field_count="$(printf '%s\n' "$record" | awk -F'|' '{ print NF }')"
      if [ "$field_count" -ne 5 ]; then
        erro "$evidence_rel:$line_no: Reclassificacao deve ter exatamente 5 campos"
        continue
      fi
      IFS='|' read -r EB_RECLASS_TASK EB_RECLASS_FROM EB_RECLASS_TO EB_RECLASS_AT EB_RECLASS_REASON <<< "$record"
      EB_RECLASS_TASK="$(trim "$EB_RECLASS_TASK")"
      EB_RECLASS_FROM="$(trim "$EB_RECLASS_FROM")"
      EB_RECLASS_TO="$(trim "$EB_RECLASS_TO")"
      EB_RECLASS_AT="$(trim "$EB_RECLASS_AT")"
      EB_RECLASS_REASON="$(trim "$EB_RECLASS_REASON")"
      if ! echo "$EB_RECLASS_TASK" | grep -qE '^T[0-9]+$'; then
        erro "$evidence_rel:$line_no: task invalida na Reclassificacao: '$EB_RECLASS_TASK'"
      elif ! echo "$known_tasks" | grep -qx "$EB_RECLASS_TASK"; then
        erro "$evidence_rel:$line_no: Reclassificacao referencia task inexistente: '$EB_RECLASS_TASK'"
      fi
      continue
    fi

    if [[ "$line" =~ $field_re ]]; then
      if [ "$EB_ACTIVE" -ne 1 ]; then
        erro "$evidence_rel:$line_no: campo canônico fora de entrada"
        continue
      fi
      if [ "$EB_RECORD_COUNT" -eq 0 ]; then
        erro "$evidence_rel:$line_no: campo canônico deve aparecer depois do Registro"
      fi
      label="${BASH_REMATCH[1]}"
      value="$(trim "${BASH_REMATCH[2]}")"
      case "$label" in
        Acao/comando) EB_ACTION_COUNT=$((EB_ACTION_COUNT + 1)); EB_ACTION="$value" ;;
        Diretorio) EB_DIRECTORY_COUNT=$((EB_DIRECTORY_COUNT + 1)); EB_DIRECTORY="$value" ;;
        Fonte) EB_SOURCE_COUNT=$((EB_SOURCE_COUNT + 1)); EB_SOURCE="$value" ;;
        "Exit code") EB_EXIT_COUNT=$((EB_EXIT_COUNT + 1)); EB_EXIT="$value" ;;
        Saida/referencia) EB_OUTPUT_COUNT=$((EB_OUTPUT_COUNT + 1)); EB_OUTPUT="$value" ;;
        Branch) EB_BRANCH_COUNT=$((EB_BRANCH_COUNT + 1)); EB_BRANCH="$value" ;;
        Limitacoes) EB_LIMITATIONS_COUNT=$((EB_LIMITATIONS_COUNT + 1)); EB_LIMITATIONS="$value" ;;
      esac
    fi
  done < "$evidence"
  finalize_evidence_block
  if [ "$canonical_block_count" -eq 0 ]; then
    erro "$evidence_rel: evidence.md existe, mas não contém nenhum bloco canônico de evidência"
  fi
  reset_evidence_block
}

for plandir in "$ROOT"/docs/plans/*/; do
  [ -d "$plandir" ] || continue
  feature="$(basename "$plandir")"
  plan="${plandir}plan.md"
  tasks="${plandir}tasks.md"
  evidence="${plandir}evidence.md"
  spec="$ROOT/docs/specs/$feature/spec.md"
  [ -e "$plan" ] || [ -e "$tasks" ] || continue

  if [ -e "$tasks" ]; then
    task_source="$tasks"
  else
    task_source="$plan"
  fi
  task_source_rel="$(rel "$task_source")"

  if [ ! -e "$spec" ]; then
    erro "docs/plans/$feature: existe plano mas não existe docs/specs/$feature/spec.md"
    continue
  fi

  spec_ac_occurrences="$(grep -E '^- \*\*AC[0-9]+\*\*[[:space:]]+—[[:space:]]+.+' "$spec" | \
    grep -oE '\*\*AC[0-9]+\*\*' | tr -d '*' || true)"
  spec_acs="$(printf '%s\n' "$spec_ac_occurrences" | sed '/^$/d' | sort -u)"
  duplicate_spec_acs="$(printf '%s\n' "$spec_ac_occurrences" | sed '/^$/d' | sort | uniq -d)"
  while IFS= read -r duplicate_ac; do
    [ -n "$duplicate_ac" ] || continue
    erro "$(rel "$spec"): ID de criterio de aceite duplicado: $duplicate_ac"
  done <<< "$duplicate_spec_acs"

  task_id_occurrences="$(awk -F'|' '/^\| *T[0-9]+ *\|/ { v = $2; gsub(/^[ \t]+|[ \t]+$/, "", v); print v }' "$task_source")"
  task_ids="$(printf '%s\n' "$task_id_occurrences" | sed '/^$/d' | sort -u)"
  duplicate_task_ids="$(printf '%s\n' "$task_id_occurrences" | sed '/^$/d' | sort | uniq -d)"
  while IFS= read -r duplicate_task; do
    [ -n "$duplicate_task" ] || continue
    erro "$task_source_rel: ID de task duplicado: $duplicate_task"
  done <<< "$duplicate_task_ids"
  task_acs="$(grep -E '^\| *T[0-9]+' "$task_source" | grep -oE 'AC[0-9]+' | sort -u || true)"

  # O marker continua sendo validado como ponte explícita para evidence.md.
  expected_evidence_path="docs/plans/$feature/evidence.md"
  expected_evidence_backticked="\`$expected_evidence_path\`"
  for marker_file in "$plan" "$tasks"; do
    [ -e "$marker_file" ] || continue
    marker_count=0
    while IFS=: read -r marker_line_no marker_line; do
      [ -n "$marker_line_no" ] || continue
      marker_count=$((marker_count + 1))
      marker_value="$(printf '%s' "$marker_line" | sed 's/^- \*\*Evidence:\*\*[[:space:]]*//')"
      marker_value="$(trim "$marker_value")"
      IFS=$' \t' read -r marker_target _ <<< "$marker_value"
      if [ "$marker_target" != "$expected_evidence_path" ] && \
         [ "$marker_target" != "$expected_evidence_backticked" ]; then
        erro "$(rel "$marker_file"):$marker_line_no: Evidence deve apontar para '$expected_evidence_path'"
      fi
    done < <(grep -nE '^- \*\*Evidence:\*\*' "$marker_file" || true)
    if grep -qE '^\|[[:space:]]*ID[[:space:]]*\|' "$marker_file" && [ "$marker_count" -eq 0 ]; then
      erro "$(rel "$marker_file"): tabela de tasks exige marker '- **Evidence:** $expected_evidence_path'"
    fi
  done
  # Valida estrutura e conteúdo de cada entrada antes de relacioná-la aos estados.
  if [ -e "$evidence" ]; then
    evidence_rel="$(rel "$evidence")"
    parse_evidence_blocks "$evidence" "$evidence_rel" "$task_ids" "$spec_acs"
  fi

  # Estado é a última coluna da fonte autoritativa.
  while IFS='|' read -r task_id task_state; do
    declared_acs="$(task_declared_acs "$task_source" "$task_id")"
    declared_dependencies="$(task_declared_dependencies "$task_source" "$task_id")"

    if [ -e "$evidence" ]; then
      reclass_lines="$(reclassification_marker_lines "$evidence" "$task_id")"
      lifecycle_implement_record="$(latest_record "$evidence" "$task_id" implement)"
      lifecycle_implement_line=0
      if [ -n "$lifecycle_implement_record" ]; then
        IFS='|' read -r lifecycle_implement_line lifecycle_implement_acs lifecycle_implement_result lifecycle_implement_ref <<< "$lifecycle_implement_record"
      fi

      while IFS= read -r reclass_line; do
        [ -n "$reclass_line" ] || continue
        if ! reclassification_history_valid "$evidence" "$task_id" "$reclass_line" "$declared_acs"; then
          erro "$(rel "$evidence"):$reclass_line: Reclassificacao de $task_id sem prova valida de done anterior no mesmo ciclo"
        fi
        if [ "$lifecycle_implement_line" -le "$reclass_line" ] && [ "$task_state" != "ready" ]; then
          erro "$task_source_rel: task $task_id tem Reclassificacao sem implement posterior, portanto o estado atual deve ser ready, não '$task_state'"
        fi
      done <<< "$reclass_lines"

      while IFS='|' read -r candidate_implement_line candidate_implement_acs candidate_implement_result candidate_implement_ref; do
        [ -n "$candidate_implement_line" ] || continue
        prior_done_review_line="$(latest_valid_review_before_line "$evidence" "$task_id" "$candidate_implement_line" "$declared_acs")"
        if [ -n "$prior_done_review_line" ]; then
          valid_reclass_before_implement=0
          while IFS= read -r reclass_line; do
            [ -n "$reclass_line" ] || continue
            if [ "$reclass_line" -gt "$prior_done_review_line" ] && \
               [ "$reclass_line" -lt "$candidate_implement_line" ] && \
               reclassification_history_valid "$evidence" "$task_id" "$reclass_line" "$declared_acs"; then
              valid_reclass_before_implement=1
            fi
          done <<< "$reclass_lines"
          if [ "$valid_reclass_before_implement" -ne 1 ]; then
            erro "$task_source_rel: task $task_id recebeu implement na linha $candidate_implement_line após prova de done sem review not-run + Reclassificacao valida entre os dois"
          fi
        fi
      done < <(task_implement_records "$evidence" "$task_id")

      if [ "$task_state" != "done" ]; then
        latest_done_review_line="$(latest_valid_review_before_line "$evidence" "$task_id" 2147483647 "$declared_acs")"
        if [ -n "$latest_done_review_line" ]; then
          valid_reclass_after_done=0
          while IFS= read -r reclass_line; do
            [ -n "$reclass_line" ] || continue
            if [ "$reclass_line" -gt "$latest_done_review_line" ] && \
               reclassification_history_valid "$evidence" "$task_id" "$reclass_line" "$declared_acs"; then
              valid_reclass_after_done=1
            fi
          done <<< "$reclass_lines"
          if [ "$valid_reclass_after_done" -ne 1 ]; then
            erro "$task_source_rel: task $task_id tem prova valida de done na linha $latest_done_review_line, mas estado atual '$task_state' sem Reclassificacao posterior"
          fi
        fi
      fi
    fi

    if echo "$task_state" | grep -qE '^(verification-pending|done)$'; then
      while IFS= read -r dependency_id; do
        [ -n "$dependency_id" ] || continue
        dependency_state="$(task_state_for_id "$task_source" "$dependency_id")"
        if [ -z "$dependency_state" ]; then
          erro "$task_source_rel: task $task_id depende de task inexistente $dependency_id"
        elif [ "$task_state" = "verification-pending" ]; then
          case "$dependency_state" in
            verification-pending|done) ;;
            *) erro "$task_source_rel: task $task_id em $task_state exige dependência $dependency_id em verification-pending/done, não '$dependency_state'; cascata esperada: $task_id volta a ready" ;;
          esac
        elif [ "$dependency_state" != "done" ]; then
          erro "$task_source_rel: task $task_id em done exige dependência $dependency_id em done, não '$dependency_state'"
        fi
      done <<< "$declared_dependencies"
    fi

    if [ "$task_state" = "ready" ] && [ -e "$evidence" ]; then
      ready_implement_record="$(latest_record "$evidence" "$task_id" implement)"
      if [ -n "$ready_implement_record" ]; then
        IFS='|' read -r ready_implement_line ready_implement_acs ready_implement_result ready_implement_ref <<< "$ready_implement_record"
        if echo "$ready_implement_result" | grep -qE '^(pass|observed)$' && \
           valid_sha_ref "$ready_implement_ref" && \
           record_covers_declared_acs "$declared_acs" "$ready_implement_acs"; then
          while IFS= read -r gap_line; do
            [ -n "$gap_line" ] || continue
            erro "$(rel "$evidence"):$gap_line: task $task_id ready apos review done e review not-run exige Reclassificacao valida no bloco not-run mais recente"
          done < <(ready_reclassification_gap "$evidence" "$task_id" "$ready_implement_line" "$declared_acs")
        fi
      fi
    fi

    case "$task_state" in
      backlog|ready|in-progress) ;;
      blocked)
        if [ ! -e "$evidence" ]; then
          erro "$task_source_rel: task $task_id em blocked exige evidence.md"
          continue
        fi
        task_record="$(latest_task_record "$evidence" "$task_id")"
        if [ -z "$task_record" ]; then
          erro "$task_source_rel: task $task_id em blocked exige Registro implement ou review"
        else
          IFS='|' read -r task_line task_phase task_result task_ref task_blocker_valid <<< "$task_record"
          case "$task_result" in
            fail|not-run|unavailable) ;;
            *) erro "$task_source_rel: task $task_id em blocked exige Registro mais recente da task com fail/not-run/unavailable" ;;
          esac
          [ "$task_blocker_valid" = "1" ] || \
            erro "$task_source_rel: task $task_id em blocked exige Bloqueio válido no mesmo bloco do Registro mais recente"
        fi
        ;;
      verification-pending|done)
        if [ -z "$declared_acs" ]; then
          erro "$task_source_rel: task $task_id em $task_state sob contrato estrito exige ao menos um AC declarado na propria linha"
        fi
        if [ ! -e "$evidence" ]; then
          erro "$task_source_rel: task $task_id em $task_state exige evidence.md"
          continue
        fi
        implement_record="$(latest_record "$evidence" "$task_id" implement)"
        if [ -z "$implement_record" ]; then
          erro "$task_source_rel: task $task_id em $task_state exige Registro implement"
          continue
        fi
        IFS='|' read -r implement_line implement_acs implement_result implement_ref <<< "$implement_record"
        if [[ "$implement_result" != "pass" && "$implement_result" != "observed" ]] || ! valid_sha_ref "$implement_ref"; then
          erro "$task_source_rel: task $task_id em $task_state exige Registro implement mais recente com pass/observed e ref commit@SHA/worktree@SHA"
        fi
        check_record_ac_coverage "$task_source_rel" "$task_id" "$task_state" implement "$declared_acs" "$implement_acs"

        review_record="$(latest_record "$evidence" "$task_id" review)"
        if [ "$task_state" = "verification-pending" ]; then
          while IFS='|' read -r pending_review_line pending_review_result; do
            [ -n "$pending_review_line" ] || continue
            case "$pending_review_result" in
              not-run) ;;
              pass|observed) erro "$task_source_rel: task $task_id continua verification-pending após review $pending_review_result na linha $pending_review_line; estado esperado: done" ;;
              fail) erro "$task_source_rel: task $task_id continua verification-pending após review fail na linha $pending_review_line; estado esperado: ready" ;;
              unavailable) erro "$task_source_rel: task $task_id continua verification-pending após review unavailable na linha $pending_review_line; estado esperado: blocked" ;;
            esac
          done < <(review_records_after_line "$evidence" "$task_id" "$implement_line")
        fi

        if [ "$task_state" = "done" ]; then
          if [ -z "$review_record" ]; then
            erro "$task_source_rel: task $task_id em done exige Registro review"
            continue
          fi
          IFS='|' read -r review_line review_acs review_result review_ref <<< "$review_record"
          if [[ "$review_result" != "pass" && "$review_result" != "observed" ]] || ! valid_sha_ref "$review_ref"; then
            erro "$task_source_rel: task $task_id em done exige Registro review mais recente com pass/observed e ref commit@SHA/worktree@SHA"
          elif [ "$review_line" -le "$implement_line" ]; then
            erro "$task_source_rel: task $task_id em done exige review posterior ao último implement"
          fi
          while IFS='|' read -r intervening_review_line intervening_review_result; do
            [ -n "$intervening_review_line" ] || continue
            case "$intervening_review_result" in
              fail|unavailable)
                erro "$task_source_rel: task $task_id em done tem review $intervening_review_result na linha $intervening_review_line após o último implement; exige nova rodada de implement antes de concluir"
                ;;
            esac
          done < <(review_records_after_line "$evidence" "$task_id" "$implement_line")
          check_record_ac_coverage "$task_source_rel" "$task_id" "$task_state" review "$declared_acs" "$review_acs"
        fi
        ;;
      *"<"*|"") ;;  # placeholder de molde — ignora
      *) erro "$task_source_rel: estado de task inválido: '$task_state' (backlog | ready | in-progress | blocked | verification-pending | done)" ;;
    esac
  done < <(awk -F'|' '/^\| *T[0-9]+ *\|/ {
    id = $2; state = $(NF-1)
    gsub(/^[ \t]+|[ \t]+$/, "", id)
    gsub(/^[ \t]+|[ \t]+$/, "", state)
    print id "|" state
  }' "$task_source")

  # task cita AC que não existe na spec -> ERRO
  for ac in $task_acs; do
    echo "$spec_acs" | grep -qx "$ac" || \
      erro "docs/plans/$feature: task referencia $ac, que não existe na spec"
  done

  # AC sem task (só relevante se já há tasks) -> AVISO
  if [ -n "$task_acs" ]; then
    for ac in $spec_acs; do
      echo "$task_acs" | grep -qx "$ac" || \
        aviso "docs/specs/$feature: $ac não tem task que o cubra"
    done
  fi
done

# ----------------------------------------------------- ledger: coluna Estado
EPICS="$ROOT/docs/epics.md"
if [ -e "$EPICS" ]; then
  while IFS= read -r estado; do
    case "$estado" in
      "a fazer"|"em spec"|"em plano"|"em construção"|"em review"|"concluída") ;;
      *"_("*|"") ;;  # placeholder de molde — ignora
      *) erro "docs/epics.md: Estado de ledger inválido: '$estado' (ver state-markers.md)" ;;
    esac
  done < <(awk -F'|' '/^\| *[0-9]+ *\|/ && NF >= 8 { v = $6; gsub(/^[ \t]+|[ \t]+$/, "", v); print v }' "$EPICS")
fi

# ------------------------------------------------ [VERIFICAR] (informativo)
pendencias="$(grep -rc '\[VERIFICAR\]' "$ROOT"/docs "$ROOT"/.specify/memory/project-context.md 2>/dev/null \
  | awk -F: '$NF > 0' || true)"
if [ -n "$pendencias" ]; then
  echo "INFO  pendências [VERIFICAR] por arquivo:"
  echo "$pendencias" | sed "s|$ROOT/|      |"
fi

# -------------------------------------------------------------------- resumo
echo "----------------------------------------"
echo "sdk-check: $ERROS erro(s), $AVISOS aviso(s)."
if [ "$ERROS" -gt 0 ]; then
  echo "Contrato violado — ver .specify/memory/state-markers.md."
  exit 1
fi
exit 0
