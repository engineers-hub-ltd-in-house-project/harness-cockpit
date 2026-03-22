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

# Quality checks for file editing tools
if [[ "$TOOL_NAME" =~ ^(Write|Edit|MultiEdit)$ ]] && [[ -n "$FILE_PATH" ]]; then
  # Biome lint (fast, if available)
  if command -v biome &>/dev/null; then
    LINT_OUTPUT=$(biome check "$FILE_PATH" 2>&1 || true)
    LINT_VIOLATIONS=$(echo "$LINT_OUTPUT" | grep -c "error\|warning" || true)
  fi

  # TypeScript type check (only if tsconfig.json exists)
  if [[ ("$FILE_PATH" == *.ts || "$FILE_PATH" == *.tsx) ]] && [[ -f "${CLAUDE_PROJECT_DIR:-.}/tsconfig.json" ]]; then
    if command -v tsc &>/dev/null; then
      TYPE_OUTPUT=$(timeout 15 tsc --noEmit "$FILE_PATH" 2>&1 || true)
      TYPE_ERRORS=$(echo "$TYPE_OUTPUT" | grep -c "error TS" || true)
    fi
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
