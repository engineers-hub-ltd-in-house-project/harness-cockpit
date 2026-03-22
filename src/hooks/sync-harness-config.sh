#!/usr/bin/env bash
set -euo pipefail

# Load environment from project-local config if available
HARNESS_ENV="${CLAUDE_PROJECT_DIR:-.}/.claude/harness-env"
if [[ -f "$HARNESS_ENV" ]]; then
  # shellcheck source=/dev/null
  source "$HARNESS_ENV"
fi

# Abort silently if not configured
if [[ -z "${HARNESS_CONFIG_BUCKET:-}" || -z "${HARNESS_PROJECT_ID:-}" ]]; then
  exit 0
fi

TARGET_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude"
mkdir -p "$TARGET_DIR"

aws s3 cp \
  "s3://${HARNESS_CONFIG_BUCKET}/${HARNESS_PROJECT_ID}/harness-rules.json" \
  "${TARGET_DIR}/harness-rules.json" \
  --quiet 2>/dev/null || true
