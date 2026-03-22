#!/usr/bin/env bash
set -euo pipefail

# Harness Cockpit Hook Uninstaller
# 対象プロジェクトからフックスクリプトと関連ファイルを除去する。
#
# 使い方:
#   cd /path/to/target-project
#   /path/to/harness-cockpit/scripts/uninstall-hooks.sh
#
# オプション:
#   --keep-rules    harness-rules.json を残す（デフォルトでは削除）
#   --keep-env      harness-env を残す

TARGET_PROJECT="$(pwd)"

KEEP_RULES=false
KEEP_ENV=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --keep-rules) KEEP_RULES=true; shift ;;
    --keep-env)   KEEP_ENV=true; shift ;;
    *) shift ;;
  esac
done

echo "==> Harness Cockpit アンインストール"
echo "    対象: ${TARGET_PROJECT}"
echo ""

REMOVED=0

# --- フックスクリプトの削除 ---

remove_file() {
  if [[ -f "$1" ]]; then
    rm "$1"
    echo "    removed: $1"
    REMOVED=$((REMOVED + 1))
  fi
}

echo "==> フックスクリプトを削除中..."
remove_file "${TARGET_PROJECT}/.claude/hooks/harness-gate.sh"
remove_file "${TARGET_PROJECT}/.claude/hooks/harness-post.sh"
remove_file "${TARGET_PROJECT}/.claude/hooks/sync-harness-config.sh"

# hooks ディレクトリが空なら削除
if [[ -d "${TARGET_PROJECT}/.claude/hooks" ]]; then
  if [[ -z "$(ls -A "${TARGET_PROJECT}/.claude/hooks" 2>/dev/null)" ]]; then
    rmdir "${TARGET_PROJECT}/.claude/hooks"
    echo "    removed: .claude/hooks/ (empty)"
  fi
fi

# --- 品質チェックプラグインの削除 ---

if [[ -d "${TARGET_PROJECT}/.claude/harness-checks" ]]; then
  echo "==> 品質チェックプラグインを削除中..."
  rm -r "${TARGET_PROJECT}/.claude/harness-checks"
  echo "    removed: .claude/harness-checks/"
  REMOVED=$((REMOVED + 1))
fi

# --- 環境変数ファイルの削除 ---

if [[ "$KEEP_ENV" == "false" ]]; then
  echo "==> 環境変数ファイルを削除中..."
  remove_file "${TARGET_PROJECT}/.claude/harness-env"
fi

# --- ルール設定ファイルの削除 ---

if [[ "$KEEP_RULES" == "false" ]]; then
  echo "==> ルール設定ファイルを削除中..."
  remove_file "${TARGET_PROJECT}/.claude/harness-rules.json"
fi

# --- settings.json からフック登録を除去 ---

SETTINGS_FILE="${TARGET_PROJECT}/.claude/settings.json"
if [[ -f "$SETTINGS_FILE" ]]; then
  echo "==> settings.json からフック登録を除去中..."

  if command -v jq &>/dev/null; then
    UPDATED=$(jq '
      if .hooks then
        .hooks.PreToolUse = [.hooks.PreToolUse[]? | select(.hooks[]?.command | test("harness-gate") | not)] |
        .hooks.PostToolUse = [.hooks.PostToolUse[]? | select(.hooks[]?.command | test("harness-post") | not)] |
        .hooks.SessionStart = [.hooks.SessionStart[]? | select(.hooks[]?.command | test("sync-harness-config") | not)] |
        if (.hooks.PreToolUse | length) == 0 then del(.hooks.PreToolUse) else . end |
        if (.hooks.PostToolUse | length) == 0 then del(.hooks.PostToolUse) else . end |
        if (.hooks.SessionStart | length) == 0 then del(.hooks.SessionStart) else . end |
        if (.hooks | keys | length) == 0 then del(.hooks) else . end
      else . end
    ' "$SETTINGS_FILE")

    echo "$UPDATED" > "$SETTINGS_FILE"
    echo "    updated: .claude/settings.json"

    # settings.json が空オブジェクト ({}) なら削除
    if [[ "$(jq 'keys | length' "$SETTINGS_FILE")" == "0" ]]; then
      rm "$SETTINGS_FILE"
      echo "    removed: .claude/settings.json (empty)"
    fi
  else
    echo "    [WARN] jq が未インストールのため settings.json の自動編集をスキップしました。"
    echo "    手動で .claude/settings.json から harness 関連のフック登録を除去してください。"
  fi
fi

# --- .claude ディレクトリが空なら削除 ---

if [[ -d "${TARGET_PROJECT}/.claude" ]]; then
  if [[ -z "$(ls -A "${TARGET_PROJECT}/.claude" 2>/dev/null)" ]]; then
    rmdir "${TARGET_PROJECT}/.claude"
    echo "    removed: .claude/ (empty)"
  fi
fi

# --- 完了 ---

echo ""
echo "============================================"
echo " Harness Cockpit アンインストール完了"
echo "============================================"
echo ""
echo "  ${REMOVED} 件のファイルを削除しました。"
if [[ "$KEEP_ENV" == "true" ]]; then
  echo "  (harness-env は保持)"
fi
if [[ "$KEEP_RULES" == "true" ]]; then
  echo "  (harness-rules.json は保持)"
fi
echo ""
echo "  注意: DynamoDB のルールデータとCloudWatch Logsのイベントデータは"
echo "  AWS上に残っています。Terraform で管理されるインフラの撤去は"
echo "  cd infra/ && terraform destroy で行えます。"
echo ""
