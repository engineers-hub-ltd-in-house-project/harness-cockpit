# TypeScript Template

TypeScript / JavaScript プロジェクト向けの品質チェックテンプレート。

## 含まれるチェック

| スクリプト | ツール | 対象 |
|-----------|--------|------|
| `lint.sh` | Biome (or oxlint) | .ts, .tsx, .js, .jsx, .mjs, .cjs |
| `typecheck.sh` | tsc | .ts, .tsx (tsconfig.json 必要) |

## 前提条件

以下のいずれかがインストール済みであること:

```bash
# Biome (推奨)
npm install -g @biomejs/biome

# または oxlint
npm install -g oxlint

# TypeScript (型チェック用)
npm install -g typescript
```

## インストール

```bash
# install-hooks.sh の --template オプションで自動設置
/path/to/harness-cockpit/scripts/install-hooks.sh --template typescript

# または手動コピー
cp -r /path/to/harness-cockpit/examples/typescript/harness-checks/ .claude/harness-checks/
chmod +x .claude/harness-checks/*.sh
```
