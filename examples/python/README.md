# Python Template

Python プロジェクト向けの品質チェックテンプレート。

## 含まれるチェック

| スクリプト | ツール | 対象 |
|-----------|--------|------|
| `lint.sh` | Ruff (or flake8) | .py |
| `typecheck.sh` | mypy (or pyright) | .py |

## 前提条件

```bash
# Ruff (推奨、高速)
pip install ruff

# mypy (型チェック)
pip install mypy

# または pyright
pip install pyright
```

## インストール

```bash
# install-hooks.sh の --template オプションで自動設置
/path/to/harness-cockpit/scripts/install-hooks.sh --template python

# または手動コピー
cp -r /path/to/harness-cockpit/examples/python/harness-checks/ .claude/harness-checks/
chmod +x .claude/harness-checks/*.sh
```
