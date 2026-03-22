#!/usr/bin/env bash
# Ruby lint check using RuboCop
# Usage: lint.sh <file_path>
# Output: violation count (integer on last line)
set -euo pipefail

FILE_PATH="$1"

# Skip non-Ruby files
if [[ ! "$FILE_PATH" =~ \.(rb|rake|gemspec)$ ]] && [[ "$(basename "$FILE_PATH")" != "Gemfile" ]] && [[ "$(basename "$FILE_PATH")" != "Rakefile" ]]; then
  echo "0"
  exit 0
fi

if command -v rubocop &>/dev/null; then
  OUTPUT=$(rubocop --format simple "$FILE_PATH" 2>&1 || true)
  # RuboCop outputs "N offenses detected" on the last line
  COUNT=$(echo "$OUTPUT" | grep -oP '\d+ offense' | grep -oP '\d+' || echo "0")
  echo "$COUNT"
else
  echo "0"
fi
