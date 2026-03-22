# Ruby / Rails Template

Ruby on Rails プロジェクト向けの品質チェックテンプレート。

## 含まれるチェック

| スクリプト | ツール | 対象 |
|-----------|--------|------|
| `lint.sh` | RuboCop | .rb, .rake, .gemspec, Gemfile, Rakefile |

## 前提条件

```bash
gem install rubocop

# Rails プロジェクトの場合
gem install rubocop-rails rubocop-rspec
```

## インストール

```bash
# install-hooks.sh の --template オプションで自動設置
/path/to/harness-cockpit/scripts/install-hooks.sh --template ruby

# または手動コピー
cp -r /path/to/harness-cockpit/examples/ruby/harness-checks/ .claude/harness-checks/
chmod +x .claude/harness-checks/*.sh
```

## カスタマイズ

Sorbet による型チェックを追加する場合は `.claude/harness-checks/typecheck.sh` を作成する:

```bash
#!/usr/bin/env bash
set -euo pipefail
FILE_PATH="$1"
[[ "$FILE_PATH" =~ \.rb$ ]] || { echo "0"; exit 0; }
if command -v srb &>/dev/null; then
  OUTPUT=$(srb tc "$FILE_PATH" 2>&1 || true)
  COUNT=$(echo "$OUTPUT" | grep -c "error" || true)
  echo "$COUNT"
else
  echo "0"
fi
```
