export type Lang = "ja" | "en";

let currentLang: Lang = "ja";

export function getLang(): Lang {
  return currentLang;
}

export function setLang(lang: Lang): void {
  currentLang = lang;
}

export function t(key: string): string {
  return messages[currentLang][key] ?? messages["en"][key] ?? key;
}

const messages: Record<Lang, Record<string, string>> = {
  ja: {
    "app.title": "Harness Cockpit Setup",
    "app.subtitle": "Claude Code Hooks permissive-to-enforcing mode control",
    "project.title": "Project Path",
    "project.placeholder": "/path/to/your/project",
    "project.analyze": "Analyze",
    "analysis.language": "検出言語",
    "analysis.template": "推薦テンプレート",
    "analysis.indicators": "検出根拠",
    "analysis.tools": "利用可能ツール",
    "analysis.projectId": "Project ID",
    "analysis.apply": "Apply & Continue",
    "step0.title": "Step 0: 前提条件チェック",
    "step0.btn": "Check",
    "step1.title": "Step 1: フック設置",
    "step1.btn": "Run",
    "step1.desc.template": "Template",
    "step1.desc.projectId": "Project ID",
    "step1.confirm": "install-hooks.sh を実行します。続行しますか?",
    "step2.title": "Step 2: 初期ルール投入",
    "step2.btn": "Run",
    "step2.desc": "bash_destructive, env_protection, config_protection, git_operations, production_access",
    "step2.confirm": "5件のスターターールをDynamoDBに投入します。続行しますか?",
    "step3.title": "Step 3: 設定生成",
    "step3.btn": "Run",
    "step3.desc": "DynamoDB -> harness-rules.json -> S3 + local",
    "step4.title": "Step 4: 動作確認",
    "step4.btn": "Test",
    "status.idle": "Pending",
    "status.running": "Running...",
    "status.done": "Complete",
    "status.error": "Error",
    "terraform.missing": "Terraform未デプロイです。先に cd infra/ && terraform apply を実行してください。",
    "browse.btn": "Browse",
    "browse.select": "Select:",
    "browse.empty": "サブディレクトリなし",
    "uninstall.title": "Uninstall",
    "uninstall.btn": "Uninstall",
    "uninstall.desc": "フックスクリプト、環境変数、品質チェックプラグイン、settings.json のフック登録を除去",
    "uninstall.confirm": "フックと関連ファイルをアンインストールします。続行しますか?",
  },
  en: {
    "app.title": "Harness Cockpit Setup",
    "app.subtitle": "Claude Code Hooks permissive-to-enforcing mode control",
    "project.title": "Project Path",
    "project.placeholder": "/path/to/your/project",
    "project.analyze": "Analyze",
    "analysis.language": "Detected Language",
    "analysis.template": "Recommended Template",
    "analysis.indicators": "Indicators",
    "analysis.tools": "Available Tools",
    "analysis.projectId": "Project ID",
    "analysis.apply": "Apply & Continue",
    "step0.title": "Step 0: Prerequisites",
    "step0.btn": "Check",
    "step1.title": "Step 1: Install Hooks",
    "step1.btn": "Run",
    "step1.desc.template": "Template",
    "step1.desc.projectId": "Project ID",
    "step1.confirm": "install-hooks.sh will be executed. Proceed?",
    "step2.title": "Step 2: Seed Starter Rules",
    "step2.btn": "Run",
    "step2.desc": "bash_destructive, env_protection, config_protection, git_operations, production_access",
    "step2.confirm": "5 starter rules will be inserted into DynamoDB. Proceed?",
    "step3.title": "Step 3: Generate Config",
    "step3.btn": "Run",
    "step3.desc": "DynamoDB -> harness-rules.json -> S3 + local",
    "step4.title": "Step 4: Verify",
    "step4.btn": "Test",
    "status.idle": "Pending",
    "status.running": "Running...",
    "status.done": "Complete",
    "status.error": "Error",
    "terraform.missing": "Terraform not deployed. Run cd infra/ && terraform apply first.",
    "browse.btn": "Browse",
    "browse.select": "Select:",
    "browse.empty": "No subdirectories",
    "uninstall.title": "Uninstall",
    "uninstall.btn": "Uninstall",
    "uninstall.desc": "Remove hook scripts, env file, quality check plugins, and settings.json hook entries",
    "uninstall.confirm": "This will uninstall hooks and related files. Proceed?",
  },
};
