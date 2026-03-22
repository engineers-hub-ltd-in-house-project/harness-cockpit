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
TOOL_INPUT=$(echo "$INPUT" | jq -c '.tool_input')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id')

# Check for local rules cache
CONFIG_FILE="${CLAUDE_PROJECT_DIR:-.}/.claude/harness-rules.json"
if [[ ! -f "$CONFIG_FILE" ]]; then
  # No rules file: log event and allow
  curl -sf --max-time 5 -X POST "${HARNESS_ENDPOINT}/events" \
    -H "Authorization: Bearer ${HARNESS_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "$(jq -n --arg sid "$SESSION_ID" --arg tool "$TOOL_NAME" \
      --argjson input "$TOOL_INPUT" \
      '{event_type:"pre_tool_use",session_id:$sid,tool_name:$tool,
        tool_input:$input,matched_rule:null,rule_mode:null,
        action:"allow",timestamp:(now|todate)}')" &
  exit 0
fi

# --- Rule matching (Phase 2+) ---

MATCH_RESULT=$(echo "$INPUT" | jq -r --slurpfile rules "$CONFIG_FILE" '
  . as $event |
  [$rules[0].rules[] | select(.enabled == true) |
   select(.tool_pattern | test($event.tool_name)) |
   if .conditions then
     select(
       (.conditions.file_pattern == null or
        ($event.tool_input.file_path // "" | test(.conditions.file_pattern))) and
       (.conditions.command_pattern == null or
        ($event.tool_input.command // "" | test(.conditions.command_pattern)))
     )
   else . end
  ] | first // empty
')

if [[ -z "$MATCH_RESULT" ]]; then
  curl -sf --max-time 5 -X POST "${HARNESS_ENDPOINT}/events" \
    -H "Authorization: Bearer ${HARNESS_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "$(jq -n --arg sid "$SESSION_ID" --arg tool "$TOOL_NAME" \
      --argjson input "$TOOL_INPUT" \
      '{event_type:"pre_tool_use",session_id:$sid,tool_name:$tool,
        tool_input:$input,matched_rule:null,rule_mode:null,
        action:"allow",timestamp:(now|todate)}')" &
  exit 0
fi

RULE_ID=$(echo "$MATCH_RESULT" | jq -r '.id')
RULE_MODE=$(echo "$MATCH_RESULT" | jq -r '.mode')
RULE_ACTION=$(echo "$MATCH_RESULT" | jq -r '.action')

EVENT_ACTION="allow"
if [[ "$RULE_MODE" == "enforcing" && "$RULE_ACTION" == "deny" ]]; then
  EVENT_ACTION="blocked"
elif [[ "$RULE_MODE" == "permissive" && "$RULE_ACTION" == "deny" ]]; then
  EVENT_ACTION="would_block"
fi

curl -sf --max-time 5 -X POST "${HARNESS_ENDPOINT}/events" \
  -H "Authorization: Bearer ${HARNESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "$(jq -n --arg sid "$SESSION_ID" --arg tool "$TOOL_NAME" \
    --argjson input "$TOOL_INPUT" --arg rid "$RULE_ID" \
    --arg mode "$RULE_MODE" --arg action "$EVENT_ACTION" \
    '{event_type:"pre_tool_use",session_id:$sid,tool_name:$tool,
      tool_input:$input,matched_rule:$rid,rule_mode:$mode,
      action:$action,timestamp:(now|todate)}')" &

if [[ "$RULE_MODE" == "enforcing" && "$RULE_ACTION" == "deny" ]]; then
  jq -n --arg rid "$RULE_ID" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: ("Blocked by harness rule: " + $rid)
    }
  }'
  exit 0
fi

exit 0
