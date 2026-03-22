#!/usr/bin/env bash
set -euo pipefail

# Harness Cockpit Starter Rules Seeder
# 初期ルール5種をDynamoDBに投入する。
#
# 使い方:
#   /path/to/harness-cockpit/scripts/seed-rules.sh <PROJECT_ID>
#
# 引数:
#   PROJECT_ID  DynamoDBのPKに使用するプロジェクト識別子（必須）

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HARNESS_REPO="$(cd "${SCRIPT_DIR}/.." && pwd)"
RULES_FILE="${HARNESS_REPO}/config/starter-rules.json"

PROJECT_ID="${1:-}"
if [[ -z "$PROJECT_ID" ]]; then
  echo "[ERROR] PROJECT_ID を指定してください。" >&2
  echo "  使い方: $0 <PROJECT_ID>" >&2
  exit 1
fi

# --- 前提条件チェック ---

for cmd in aws jq; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "[ERROR] $cmd が見つかりません。" >&2
    exit 1
  fi
done

if [[ ! -f "$RULES_FILE" ]]; then
  echo "[ERROR] ${RULES_FILE} が見つかりません。" >&2
  exit 1
fi

# --- Terraform Output からテーブル名を取得 ---

INFRA_DIR="${HARNESS_REPO}/infra"
TABLE_NAME="HarnessRules"

echo "==> DynamoDB テーブル: ${TABLE_NAME}"
echo "==> PROJECT_ID: ${PROJECT_ID}"
echo ""

# --- 既存ルールの確認 ---

EXISTING=$(aws dynamodb query \
  --table-name "$TABLE_NAME" \
  --key-condition-expression "PK = :pk AND begins_with(SK, :sk)" \
  --expression-attribute-values '{":pk":{"S":"PROJECT#'"$PROJECT_ID"'"},":sk":{"S":"RULE#"}}' \
  --select COUNT \
  --profile yusuke.sato \
  --region ap-northeast-1 \
  --output text --query 'Count' 2>/dev/null) || EXISTING=0

if [[ "$EXISTING" -gt 0 ]]; then
  echo "[WARN] PROJECT#${PROJECT_ID} に既に ${EXISTING} 件のルールが存在します。"
  read -rp "上書きしますか？ (y/N): " CONFIRM
  if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    echo "中断しました。"
    exit 0
  fi
fi

# --- ルール投入 ---

RULE_COUNT=$(jq length "$RULES_FILE")
echo "==> ${RULE_COUNT} 件のスターターールを投入中..."

TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

for i in $(seq 0 $((RULE_COUNT - 1))); do
  RULE=$(jq ".[$i]" "$RULES_FILE")
  RULE_ID=$(echo "$RULE" | jq -r '.id')

  # DynamoDB用のアイテムを構築
  ITEM=$(echo "$RULE" | jq --arg pk "PROJECT#${PROJECT_ID}" \
    --arg sk "RULE#${RULE_ID}" \
    --arg ts "$TIMESTAMP" '{
      PK: {S: $pk},
      SK: {S: $sk},
      GSI1PK: {S: ("MODE#" + .mode)},
      GSI1SK: {S: ($pk + "#RULE#" + .id)},
      entity_type: {S: "Rule"},
      id: {S: .id},
      name: {S: .name},
      description: {S: .description},
      version: {N: "1"},
      enabled: {BOOL: .enabled},
      mode: {S: .mode},
      action: {S: .action},
      priority: {N: (.priority | tostring)},
      tool_pattern: {S: .tool_pattern},
      conditions: {S: (.conditions | tojson)},
      stats: {S: ({"total_matches":0,"true_positives":0,"false_positives":0,"unreviewed":0,"fp_rate":0} | tojson)},
      metadata: {S: ({"created_at": $ts, "created_by": "seed-rules.sh", "updated_at": $ts, "source": "starter-kit", "tags": .tags} | tojson)}
    }')

  aws dynamodb put-item \
    --table-name "$TABLE_NAME" \
    --item "$ITEM" \
    --profile yusuke.sato \
    --region ap-northeast-1

  echo "    [${RULE_ID}] $(echo "$RULE" | jq -r '.name') (mode: $(echo "$RULE" | jq -r '.mode'))"
done

echo ""
echo "==> 完了: ${RULE_COUNT} 件のルールを PROJECT#${PROJECT_ID} に投入しました。"
echo ""
echo "次のステップ:"
echo "  harness-rules.json を生成するには:"
echo "    ${HARNESS_REPO}/scripts/generate-config.sh ${PROJECT_ID}"
