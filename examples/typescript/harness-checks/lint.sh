#!/usr/bin/env bash
# TypeScript/JavaScript lint check using Biome (or oxlint as fallback)
# Usage: lint.sh <file_path>
# Output: violation count (integer on last line)
set -euo pipefail

FILE_PATH="$1"

# Skip non-JS/TS files
if [[ ! "$FILE_PATH" =~ \.(ts|tsx|js|jsx|mjs|cjs)$ ]]; then
  echo "0"
  exit 0
fi

if command -v biome &>/dev/null; then
  OUTPUT=$(biome check "$FILE_PATH" 2>&1 || true)
  COUNT=$(echo "$OUTPUT" | grep -c "error\|warning" || true)
  echo "$COUNT"
elif command -v oxlint &>/dev/null; then
  OUTPUT=$(oxlint "$FILE_PATH" 2>&1 || true)
  COUNT=$(echo "$OUTPUT" | grep -cE "error|warning" || true)
  echo "$COUNT"
else
  echo "0"
fi
