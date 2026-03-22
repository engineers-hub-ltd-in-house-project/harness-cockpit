#!/usr/bin/env bash
set -euo pipefail

# Harness Cockpit Hook Installer
# 対象プロジェクトにフックスクリプトと環境変数を設置する。
#
# 使い方:
#   cd /path/to/target-project
#   /path/to/harness-cockpit/scripts/install-hooks.sh [OPTIONS] [PROJECT_ID]
#
# オプション:
#   --template <name>  品質チェックテンプレートを設置 (typescript, ruby, python)
#
# 引数:
#   PROJECT_ID  省略時はディレクトリ名を使用

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HARNESS_REPO="$(cd "${SCRIPT_DIR}/.." && pwd)"
TARGET_PROJECT="$(pwd)"

# Parse options
TEMPLATE=""
POSITIONAL_ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --template)
      TEMPLATE="$2"
      shift 2
      ;;
    *)
      POSITIONAL_ARGS+=("$1")
      shift
      ;;
  esac
done
PROJECT_ID="${POSITIONAL_ARGS[0]:-$(basename "$TARGET_PROJECT")}"

# --- 前提条件チェック ---

check_command() {
  if ! command -v "$1" &>/dev/null; then
    echo "[ERROR] $1 が見つかりません。インストールしてください。" >&2
    exit 1
  fi
}

check_command jq
check_command curl
check_command aws
check_command terraform

if [[ "$TARGET_PROJECT" == "$HARNESS_REPO" ]]; then
  echo "[ERROR] harness-cockpitリポジトリ自体には設置できません。対象プロジェクトのディレクトリで実行してください。" >&2
  exit 1
fi

# --- Terraform Output 取得 ---

echo "==> Terraform Outputを取得中..."
INFRA_DIR="${HARNESS_REPO}/infra"

if [[ ! -f "${INFRA_DIR}/terraform.tfstate" ]] && [[ ! -d "${INFRA_DIR}/.terraform" ]]; then
  echo "[ERROR] Terraformが初期化されていません。先に infra/ で terraform apply を実行してください。" >&2
  exit 1
fi

ENDPOINT=$(cd "$INFRA_DIR" && terraform output -raw api_endpoint 2>/dev/null) || {
  echo "[ERROR] terraform output の取得に失敗しました。infra/ で terraform apply が完了しているか確認してください。" >&2
  exit 1
}
BUCKET=$(cd "$INFRA_DIR" && terraform output -raw s3_bucket_name)
TOKEN=$(grep harness_api_token "${INFRA_DIR}/terraform.tfvars" 2>/dev/null | cut -d'"' -f2) || {
  echo "[ERROR] terraform.tfvars から harness_api_token を読み取れません。" >&2
  exit 1
}

if [[ -z "$ENDPOINT" || -z "$BUCKET" || -z "$TOKEN" ]]; then
  echo "[ERROR] 必要な値が取得できませんでした。" >&2
  exit 1
fi

echo "    API Endpoint: ${ENDPOINT}"
echo "    S3 Bucket:    ${BUCKET}"
echo "    Project ID:   ${PROJECT_ID}"

# --- フックスクリプトのコピー ---

echo "==> フックスクリプトをコピー中..."
HOOKS_DIR="${TARGET_PROJECT}/.claude/hooks"
mkdir -p "$HOOKS_DIR"

cp "${HARNESS_REPO}/src/hooks/harness-gate.sh"       "$HOOKS_DIR/"
cp "${HARNESS_REPO}/src/hooks/harness-post.sh"        "$HOOKS_DIR/"
cp "${HARNESS_REPO}/src/hooks/sync-harness-config.sh" "$HOOKS_DIR/"
chmod +x "$HOOKS_DIR"/*.sh

echo "    ${HOOKS_DIR}/harness-gate.sh"
echo "    ${HOOKS_DIR}/harness-post.sh"
echo "    ${HOOKS_DIR}/sync-harness-config.sh"

# --- 環境変数ファイルの作成 ---

echo "==> 環境変数ファイルを作成中..."
ENV_FILE="${TARGET_PROJECT}/.claude/harness-env"

cat > "$ENV_FILE" << EOF
HARNESS_ENDPOINT=${ENDPOINT}
HARNESS_TOKEN=${TOKEN}
HARNESS_CONFIG_BUCKET=${BUCKET}
HARNESS_PROJECT_ID=${PROJECT_ID}
EOF

echo "    ${ENV_FILE}"

# --- settings.json のフック登録 ---

echo "==> settings.json にフックを登録中..."
SETTINGS_FILE="${TARGET_PROJECT}/.claude/settings.json"

if [[ -f "$SETTINGS_FILE" ]]; then
  # 既存のsettings.jsonがある場合、hooksキーをマージ
  HOOKS_JSON=$(cat "${HARNESS_REPO}/config/hooks-settings.json")
  EXISTING=$(cat "$SETTINGS_FILE")

  MERGED=$(echo "$EXISTING" | jq --argjson hooks "$(echo "$HOOKS_JSON" | jq '.hooks')" '
    .hooks.PreToolUse = (.hooks.PreToolUse // []) + $hooks.PreToolUse |
    .hooks.PostToolUse = (.hooks.PostToolUse // []) + $hooks.PostToolUse |
    .hooks.SessionStart = (.hooks.SessionStart // []) + $hooks.SessionStart
  ')

  echo "$MERGED" > "$SETTINGS_FILE"
  echo "    既存の settings.json にフック設定をマージしました"
else
  cp "${HARNESS_REPO}/config/hooks-settings.json" "$SETTINGS_FILE"
  echo "    ${SETTINGS_FILE} を新規作成しました"
fi

# --- 品質チェックテンプレートの設置 ---

if [[ -n "$TEMPLATE" ]]; then
  TEMPLATE_DIR="${HARNESS_REPO}/examples/${TEMPLATE}/harness-checks"
  if [[ -d "$TEMPLATE_DIR" ]]; then
    echo "==> 品質チェックテンプレートを設置中 (${TEMPLATE})..."
    CHECKS_DIR="${TARGET_PROJECT}/.claude/harness-checks"
    mkdir -p "$CHECKS_DIR"
    cp "${TEMPLATE_DIR}"/*.sh "$CHECKS_DIR/"
    chmod +x "$CHECKS_DIR"/*.sh
    for f in "$CHECKS_DIR"/*.sh; do
      echo "    $(basename "$f")"
    done
  else
    echo "    [WARN] テンプレート '${TEMPLATE}' が見つかりません。" >&2
    echo "    利用可能: $(ls -1 "${HARNESS_REPO}/examples/" 2>/dev/null | tr '\n' ' ')" >&2
  fi
fi

# --- .gitignore への追加 ---

echo "==> .gitignore を更新中..."
GITIGNORE="${TARGET_PROJECT}/.gitignore"
touch "$GITIGNORE"

add_to_gitignore() {
  if ! grep -qxF "$1" "$GITIGNORE" 2>/dev/null; then
    echo "$1" >> "$GITIGNORE"
    echo "    追加: $1"
  fi
}

add_to_gitignore ".claude/harness-env"
add_to_gitignore ".claude/harness-rules.json"

# --- 動作確認 ---

echo ""
echo "==> 動作確認中..."
TEST_RESULT=$(curl -sf --max-time 10 -X POST "${ENDPOINT}/events" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d "$(jq -n \
    --arg pid "$PROJECT_ID" \
    '{event_type:"pre_tool_use",session_id:"install-test",tool_name:"Bash",
      tool_input:{command:"install-hooks.sh verification"},
      project_id:$pid,action:"allow",timestamp:(now|todate)}')" 2>&1) || true

if echo "$TEST_RESULT" | jq -e '.event_id' &>/dev/null; then
  EVENT_ID=$(echo "$TEST_RESULT" | jq -r '.event_id')
  echo "    API疎通テスト成功 (event_id: ${EVENT_ID})"
else
  echo "    [WARN] API疎通テストに失敗しました。エンドポイントとトークンを確認してください。" >&2
  echo "    レスポンス: ${TEST_RESULT}" >&2
fi

# --- 完了 ---

echo ""
echo "============================================"
echo " Harness Cockpit フック設置完了"
echo "============================================"
echo ""
echo "  対象:      ${TARGET_PROJECT}"
echo "  Project ID: ${PROJECT_ID}"
echo "  Endpoint:   ${ENDPOINT}"
echo ""
echo "  次回の Claude Code セッション開始時からイベントが記録されます。"
echo "  Grafana で確認: cd ${HARNESS_REPO}/infra && terraform output -raw grafana_endpoint"
echo ""
