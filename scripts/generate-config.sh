#!/usr/bin/env bash
set -euo pipefail

# Harness Cockpit Config Generator
# DynamoDBから有効ルールを取得し、harness-rules.json を生成する。
# S3にアップロードし、オプションでローカルにもコピーする。
#
# 使い方:
#   /path/to/harness-cockpit/scripts/generate-config.sh <PROJECT_ID> [TARGET_PROJECT_DIR]
#
# 引数:
#   PROJECT_ID          DynamoDBのPKに使用するプロジェクト識別子（必須）
#   TARGET_PROJECT_DIR  ローカルコピー先（省略時はS3のみ）

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HARNESS_REPO="$(cd "${SCRIPT_DIR}/.." && pwd)"
INFRA_DIR="${HARNESS_REPO}/infra"

PROJECT_ID="${1:-}"
TARGET_DIR="${2:-}"

if [[ -z "$PROJECT_ID" ]]; then
  echo "[ERROR] PROJECT_ID を指定してください。" >&2
  echo "  使い方: $0 <PROJECT_ID> [TARGET_PROJECT_DIR]" >&2
  exit 1
fi

# --- 前提条件チェック ---

for cmd in aws jq terraform; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "[ERROR] $cmd が見つかりません。" >&2
    exit 1
  fi
done

# --- 値の取得 ---

TABLE_NAME="HarnessRules"
BUCKET=$(cd "$INFRA_DIR" && terraform output -raw s3_bucket_name 2>/dev/null) || {
  echo "[ERROR] terraform output の取得に失敗しました。" >&2
  exit 1
}

echo "==> DynamoDB テーブル: ${TABLE_NAME}"
echo "==> S3 バケット: ${BUCKET}"
echo "==> PROJECT_ID: ${PROJECT_ID}"

# --- DynamoDBからルール取得 ---

echo "==> DynamoDBから有効ルールを取得中..."

ITEMS=$(aws dynamodb query \
  --table-name "$TABLE_NAME" \
  --key-condition-expression "PK = :pk AND begins_with(SK, :sk)" \
  --filter-expression "entity_type = :et AND enabled = :en" \
  --expression-attribute-values '{
    ":pk":{"S":"PROJECT#'"$PROJECT_ID"'"},
    ":sk":{"S":"RULE#"},
    ":et":{"S":"Rule"},
    ":en":{"BOOL":true}
  }' \
  --profile yusuke.sato \
  --region ap-northeast-1 \
  --output json 2>/dev/null)

RULE_COUNT=$(echo "$ITEMS" | jq '.Count')
echo "    ${RULE_COUNT} 件の有効ルールを取得"

if [[ "$RULE_COUNT" -eq 0 ]]; then
  echo "[WARN] 有効なルールがありません。空の harness-rules.json を生成します。"
fi

# --- harness-rules.json 生成 ---

TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

CONFIG=$(echo "$ITEMS" | jq --arg pid "$PROJECT_ID" --arg ts "$TIMESTAMP" '{
  version: (now | floor),
  generated_at: $ts,
  project_id: $pid,
  rules: [
    .Items[]
    | {
        id: .id.S,
        name: .name.S,
        enabled: .enabled.BOOL,
        mode: .mode.S,
        action: .action.S,
        priority: (.priority.N | tonumber),
        tool_pattern: .tool_pattern.S,
        conditions: (.conditions.S | fromjson)
      }
  ] | sort_by(-.priority)
}')

# --- S3にアップロード ---

echo "==> S3にアップロード中..."
echo "$CONFIG" | aws s3 cp - \
  "s3://${BUCKET}/${PROJECT_ID}/harness-rules.json" \
  --content-type "application/json" \
  --profile yusuke.sato \
  --region ap-northeast-1

echo "    s3://${BUCKET}/${PROJECT_ID}/harness-rules.json"

# --- ローカルコピー（オプション） ---

if [[ -n "$TARGET_DIR" ]]; then
  LOCAL_PATH="${TARGET_DIR}/.claude/harness-rules.json"
  mkdir -p "$(dirname "$LOCAL_PATH")"
  echo "$CONFIG" | jq '.' > "$LOCAL_PATH"
  echo "==> ローカルにコピー: ${LOCAL_PATH}"
fi

# --- 完了 ---

echo ""
echo "==> 完了: harness-rules.json を生成しました（${RULE_COUNT} ルール）。"
echo ""
echo "内容確認:"
echo "$CONFIG" | jq '.rules[] | {id, mode, priority, tool_pattern}'
