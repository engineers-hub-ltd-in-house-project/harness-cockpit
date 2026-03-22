# Harness Cockpit Setup Wizard

対象プロジェクトに Harness Cockpit のフックと初期ルールをセットアップするウィザード。

## Instructions

以下のステップを順番に、ユーザーに確認しながら進めてください。各ステップの実行前にユーザーの承認を取ること。

### Step 0: 前提条件の確認

以下を確認してください:

1. `infra/` で `terraform apply` が完了しているか（`terraform output` で確認）
2. 対象プロジェクトのパスをユーザーに聞く
3. PROJECT_ID をユーザーに聞く（省略時はディレクトリ名を使用）

```bash
cd infra/ && terraform output
```

出力が表示されれば Terraform デプロイ済み。表示されない場合は先に `terraform apply` を案内する。

### Step 1: フックの設置

`scripts/install-hooks.sh` を実行して、対象プロジェクトにフックスクリプト、環境変数、settings.json を設置する。

```bash
cd <対象プロジェクトのパス>
<harness-cockpitリポジトリのパス>/scripts/install-hooks.sh <PROJECT_ID>
```

スクリプトの最後にAPI疎通テストが実行される。成功を確認してから次に進む。

### Step 2: 初期ルールの投入（任意）

ユーザーに初期ルール（5種）を投入するか確認する。投入する場合は `scripts/seed-rules.sh` を実行する。

投入される初期ルール:

| ルールID | 対象 | 検出パターン |
|---------|------|-------------|
| rule_bash_destructive | Bash | rm -rf, drop table, truncate table |
| rule_env_protection | Write/Edit | .env, .secrets, credentials |
| rule_config_protection | Write/Edit | tsconfig.json, biome.json, package.json |
| rule_git_operations | Bash | git push -f, git reset --hard, git clean -f |
| rule_production_access | Bash | psql/mysql/ssh/kubectl with prod |

全ルールは **permissive モード**（ブロックせずログのみ）で投入される。

```bash
<harness-cockpitリポジトリのパス>/scripts/seed-rules.sh <PROJECT_ID>
```

### Step 3: harness-rules.json の生成（任意）

Step 2 でルールを投入した場合、`scripts/generate-config.sh` を実行して harness-rules.json を生成する。

```bash
<harness-cockpitリポジトリのパス>/scripts/generate-config.sh <PROJECT_ID> <対象プロジェクトのパス>
```

これにより:
- S3 に harness-rules.json がアップロードされる
- 対象プロジェクトの `.claude/harness-rules.json` にローカルコピーが配置される

### Step 4: 動作確認

セットアップが完了したことを確認する:

1. Grafana ダッシュボードの URL を表示

```bash
cd <harness-cockpitリポジトリのパス>/infra && terraform output -raw grafana_endpoint
```

2. 対象プロジェクトで Claude Code セッションを開始し、任意のツールを実行
3. Grafana Session Timeline で該当セッションのイベントが表示されることを確認

### 完了メッセージ

セットアップが完了したら、以下を伝える:

- 次回の Claude Code セッション開始時からイベントが自動記録される
- Step 2 でルールを投入した場合、WOULD_BLOCK イベントの蓄積が開始される
- Grafana でイベントを確認できる
- ルールはすべて permissive モード（ブロックしない）で開始されている
