#!/usr/bin/env bash
# TypeScript type check using tsc
# Usage: typecheck.sh <file_path>
# Output: error count (integer on last line)
set -euo pipefail

FILE_PATH="$1"

# Skip non-TS files
if [[ ! "$FILE_PATH" =~ \.(ts|tsx)$ ]]; then
  echo "0"
  exit 0
fi

# Only run if tsconfig.json exists in project root
if [[ ! -f "${CLAUDE_PROJECT_DIR:-.}/tsconfig.json" ]]; then
  echo "0"
  exit 0
fi

if command -v tsc &>/dev/null; then
  OUTPUT=$(tsc --noEmit "$FILE_PATH" 2>&1 || true)
  COUNT=$(echo "$OUTPUT" | grep -c "error TS" || true)
  echo "$COUNT"
else
  echo "0"
fi
