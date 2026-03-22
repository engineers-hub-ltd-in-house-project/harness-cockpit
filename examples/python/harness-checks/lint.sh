#!/usr/bin/env bash
# Python lint check using Ruff (or flake8 as fallback)
# Usage: lint.sh <file_path>
# Output: violation count (integer on last line)
set -euo pipefail

FILE_PATH="$1"

# Skip non-Python files
if [[ ! "$FILE_PATH" =~ \.py$ ]]; then
  echo "0"
  exit 0
fi

if command -v ruff &>/dev/null; then
  OUTPUT=$(ruff check "$FILE_PATH" 2>&1 || true)
  COUNT=$(echo "$OUTPUT" | grep -cE "^${FILE_PATH}" || true)
  echo "$COUNT"
elif command -v flake8 &>/dev/null; then
  OUTPUT=$(flake8 "$FILE_PATH" 2>&1 || true)
  COUNT=$(echo "$OUTPUT" | grep -c ":" || true)
  echo "$COUNT"
else
  echo "0"
fi
