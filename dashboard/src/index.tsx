import { Hono } from "hono";
import { existsSync } from "fs";
import { resolve, basename } from "path";
import { Layout } from "./views/layout";
import { SetupWizard } from "./views/setup";
import { checkCommand } from "./lib/exec";
import { updateState, getState } from "./lib/state";
import { setLang, t, type Lang } from "./lib/i18n";
import prerequisites from "./api/prerequisites.tsx";
import install from "./api/install.tsx";
import seed from "./api/seed.tsx";
import generate from "./api/generate.tsx";
import verify from "./api/verify.tsx";
import browse from "./api/browse.tsx";
import uninstall from "./api/uninstall.tsx";

const app = new Hono();

// --- API Routes ---
app.route("/api/prerequisites", prerequisites);
app.route("/api/install", install);
app.route("/api/seed", seed);
app.route("/api/generate", generate);
app.route("/api/verify", verify);
app.route("/api/browse", browse);
app.route("/api/uninstall", uninstall);

// --- Language Toggle ---
app.post("/api/lang", (c) => {
  const lang = c.req.query("lang") as Lang;
  if (lang === "ja" || lang === "en") {
    setLang(lang);
  }
  c.header("HX-Redirect", "/");
  return c.body(null, 200);
});

// --- Project Analysis ---
app.post("/api/analyze", async (c) => {
  const body = await c.req.parseBody();
  const targetProject = (body.targetProject as string).trim();

  if (!existsSync(targetProject)) {
    return c.html(<p style="color: #e5534b;">Path not found: {targetProject}</p>);
  }

  const detected = await analyzeProject(targetProject);
  const suggestedProjectId = basename(targetProject);

  updateState({ targetProject, projectId: suggestedProjectId, template: detected.template });

  return c.html(
    <div>
      <table>
        <tbody>
          <tr>
            <td><strong>{t("analysis.language")}</strong></td>
            <td>{detected.language}</td>
          </tr>
          <tr>
            <td><strong>{t("analysis.template")}</strong></td>
            <td><mark>{detected.template || "none"}</mark></td>
          </tr>
          <tr>
            <td><strong>{t("analysis.indicators")}</strong></td>
            <td>{detected.indicators.join(", ") || "-"}</td>
          </tr>
          <tr>
            <td><strong>{t("analysis.tools")}</strong></td>
            <td>{detected.tools.join(", ") || "-"}</td>
          </tr>
          <tr>
            <td><strong>{t("analysis.projectId")}</strong></td>
            <td><code>{suggestedProjectId}</code></td>
          </tr>
        </tbody>
      </table>
      <form hx-post="/api/apply-analysis" hx-swap="none">
        <input type="hidden" name="template" value={detected.template} />
        <input type="hidden" name="projectId" value={suggestedProjectId} />
        <input type="hidden" name="targetProject" value={targetProject} />
        <button type="submit" style="width: auto;">{t("analysis.apply")}</button>
      </form>
    </div>
  );
});

app.post("/api/apply-analysis", async (c) => {
  const body = await c.req.parseBody();
  updateState({
    template: body.template as string,
    projectId: body.projectId as string,
    targetProject: body.targetProject as string,
  });
  c.header("HX-Redirect", "/");
  return c.body(null, 200);
});

// --- Main Page ---
app.get("/", (c) => {
  return c.html(
    <Layout>
      <SetupWizard />
    </Layout>
  );
});

// --- Project Analyzer ---
async function analyzeProject(dir: string) {
  const indicators: string[] = [];
  const tools: string[] = [];
  let language = "unknown";
  let template = "";

  // TypeScript / JavaScript
  if (existsSync(resolve(dir, "package.json"))) {
    indicators.push("package.json");
    language = "JavaScript";

    if (existsSync(resolve(dir, "tsconfig.json"))) {
      indicators.push("tsconfig.json");
      language = "TypeScript";
      template = "typescript";
    }
    if (existsSync(resolve(dir, "biome.json")) || existsSync(resolve(dir, "biome.jsonc"))) {
      indicators.push("biome.json");
      tools.push("biome");
    }
    if (existsSync(resolve(dir, ".eslintrc.json")) || existsSync(resolve(dir, "eslint.config.js"))) {
      indicators.push("eslint config");
      tools.push("eslint");
    }
    if (!template) template = "typescript"; // JS projects can use the TS template too
  }

  // Ruby
  if (existsSync(resolve(dir, "Gemfile"))) {
    indicators.push("Gemfile");
    language = "Ruby";
    template = "ruby";

    if (existsSync(resolve(dir, "config/application.rb"))) {
      indicators.push("Rails app");
      language = "Ruby on Rails";
    }
    if (existsSync(resolve(dir, ".rubocop.yml"))) {
      indicators.push(".rubocop.yml");
      tools.push("rubocop");
    }
  }

  // Python
  if (
    existsSync(resolve(dir, "pyproject.toml")) ||
    existsSync(resolve(dir, "setup.py")) ||
    existsSync(resolve(dir, "requirements.txt"))
  ) {
    const pyIndicator = existsSync(resolve(dir, "pyproject.toml"))
      ? "pyproject.toml"
      : existsSync(resolve(dir, "setup.py"))
        ? "setup.py"
        : "requirements.txt";
    indicators.push(pyIndicator);
    language = "Python";
    template = "python";

    if (existsSync(resolve(dir, "ruff.toml")) || existsSync(resolve(dir, ".ruff.toml"))) {
      indicators.push("ruff.toml");
      tools.push("ruff");
    }
    if (existsSync(resolve(dir, "mypy.ini")) || existsSync(resolve(dir, ".mypy.ini"))) {
      indicators.push("mypy config");
      tools.push("mypy");
    }
  }

  // Check installed tools
  for (const cmd of ["biome", "oxlint", "tsc", "rubocop", "ruff", "mypy", "pyright", "flake8"]) {
    if (await checkCommand(cmd)) {
      if (!tools.includes(cmd)) tools.push(cmd);
    }
  }

  return { language, template, indicators, tools };
}

// --- Start Server ---
const port = 3456;
console.log(`Harness Cockpit Setup Dashboard: http://localhost:${port}`);

export default {
  port,
  fetch: app.fetch,
};
