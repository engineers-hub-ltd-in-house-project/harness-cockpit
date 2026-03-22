#!/usr/bin/env bash
set -euo pipefail

# Load environment from project-local config if available
HARNESS_ENV="${CLAUDE_PROJECT_DIR:-.}/.claude/harness-env"
if [[ -f "$HARNESS_ENV" ]]; then
  # shellcheck source=/dev/null
  source "$HARNESS_ENV"
fi

# Abort silently if endpoint is not configured
if [[ -z "${HARNESS_ENDPOINT:-}" || -z "${HARNESS_TOKEN:-}" ]]; then
  exit 0
fi

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id')

LINT_VIOLATIONS=0
TYPE_ERRORS=0
OUTCOME="success"

# Quality checks for file editing tools via plugin directory
if [[ "$TOOL_NAME" =~ ^(Write|Edit|MultiEdit)$ ]] && [[ -n "$FILE_PATH" ]]; then
  CHECKS_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/harness-checks"

  if [[ -d "$CHECKS_DIR" ]]; then
    # Execute each check script in the plugin directory
    for CHECK_SCRIPT in "$CHECKS_DIR"/*.sh; do
      [[ -x "$CHECK_SCRIPT" ]] || continue
      CHECK_NAME=$(basename "$CHECK_SCRIPT" .sh)

      COUNT=$(timeout 15 "$CHECK_SCRIPT" "$FILE_PATH" 2>/dev/null || echo "0")
      COUNT=$(echo "$COUNT" | tail -1 | tr -cd '0-9')
      COUNT="${COUNT:-0}"

      case "$CHECK_NAME" in
        lint*)     LINT_VIOLATIONS=$((LINT_VIOLATIONS + COUNT)) ;;
        type*)     TYPE_ERRORS=$((TYPE_ERRORS + COUNT)) ;;
        *)         LINT_VIOLATIONS=$((LINT_VIOLATIONS + COUNT)) ;;
      esac
    done
  fi

  if [[ $LINT_VIOLATIONS -gt 0 || $TYPE_ERRORS -gt 0 ]]; then
    OUTCOME="quality_issue"
  fi
fi

# Bash exit code check
if [[ "$TOOL_NAME" == "Bash" ]]; then
  EXIT_CODE=$(echo "$INPUT" | jq -r '.tool_response.exit_code // 0')
  if [[ "$EXIT_CODE" != "0" ]]; then
    OUTCOME="execution_failure"
  fi
fi

# Send event in background
curl -sf --max-time 5 -X POST "${HARNESS_ENDPOINT}/events" \
  -H "Authorization: Bearer ${HARNESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "$(jq -n --arg sid "$SESSION_ID" --arg tool "$TOOL_NAME" \
    --arg outcome "$OUTCOME" --argjson lint "$LINT_VIOLATIONS" \
    --argjson types "$TYPE_ERRORS" \
    '{event_type:"post_tool_use",session_id:$sid,tool_name:$tool,
      outcome:$outcome,quality_check:{lint_violations:$lint,type_errors:$types},
      timestamp:(now|todate)}')" &

exit 0
