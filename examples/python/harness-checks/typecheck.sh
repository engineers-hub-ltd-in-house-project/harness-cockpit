#!/usr/bin/env bash
# Python type check using mypy (or pyright as fallback)
# Usage: typecheck.sh <file_path>
# Output: error count (integer on last line)
set -euo pipefail

FILE_PATH="$1"

# Skip non-Python files
if [[ ! "$FILE_PATH" =~ \.py$ ]]; then
  echo "0"
  exit 0
fi

if command -v mypy &>/dev/null; then
  OUTPUT=$(mypy "$FILE_PATH" --no-error-summary 2>&1 || true)
  COUNT=$(echo "$OUTPUT" | grep -c ": error:" || true)
  echo "$COUNT"
elif command -v pyright &>/dev/null; then
  OUTPUT=$(pyright "$FILE_PATH" 2>&1 || true)
  COUNT=$(echo "$OUTPUT" | grep -c "error:" || true)
  echo "$COUNT"
else
  echo "0"
fi
