import type { FC } from "hono/jsx";
import { getState, type SetupState } from "../lib/state";
import { Badge } from "./layout";

interface ProjectAnalysis {
  path: string;
  detected: {
    language: string;
    template: string;
    indicators: string[];
    tools: string[];
  };
  suggestedProjectId: string;
}

export const SetupWizard: FC<{ analysis?: ProjectAnalysis }> = ({
  analysis,
}) => {
  const state = getState();

  return (
    <div>
      {/* Project Path Input */}
      <div class="step-card">
        <h3>Project Path</h3>
        <form
          hx-post="/api/analyze"
          hx-target="#analysis-result"
          hx-indicator="#analyze-spinner"
        >
          <div class="grid">
            <input
              type="text"
              name="targetProject"
              placeholder="/path/to/your/project"
              value={state.targetProject}
              required
            />
            <button type="submit" style="width: auto;">
              Analyze
              <span id="analyze-spinner" class="htmx-indicator spinner" />
            </button>
          </div>
        </form>
        <div id="analysis-result">
          {analysis && <AnalysisResult analysis={analysis} />}
        </div>
      </div>

      {/* Step 0: Prerequisites */}
      <div class={`step-card step-${state.steps.prerequisites.status}`}>
        <div style="display: flex; justify-content: space-between; align-items: center;">
          <h3>Step 0: Prerequisites</h3>
          <button
            hx-post="/api/prerequisites"
            hx-target="#prereq-result"
            hx-indicator="#prereq-spinner"
            class="outline"
            style="width: auto; margin: 0;"
          >
            Check
            <span id="prereq-spinner" class="htmx-indicator spinner" />
          </button>
        </div>
        <div id="prereq-result" />
      </div>

      {/* Step 1: Install Hooks */}
      <div class={`step-card step-${state.steps.install.status}`}>
        <div style="display: flex; justify-content: space-between; align-items: center;">
          <h3>Step 1: Install Hooks</h3>
          <button
            hx-post="/api/install"
            hx-target="#install-result"
            hx-indicator="#install-spinner"
            hx-confirm="install-hooks.sh will be executed. Proceed?"
            style="width: auto; margin: 0;"
          >
            Run
            <span id="install-spinner" class="htmx-indicator spinner" />
          </button>
        </div>
        <p style="font-size: 0.85rem; color: var(--pico-muted-color);">
          Template: <strong>{state.template || "(auto-detected)"}</strong> / Project ID:{" "}
          <strong>{state.projectId || "(from path)"}</strong>
        </p>
        <div id="install-result" />
      </div>

      {/* Step 2: Seed Rules */}
      <div class={`step-card step-${state.steps.seed.status}`}>
        <div style="display: flex; justify-content: space-between; align-items: center;">
          <h3>Step 2: Seed Starter Rules</h3>
          <button
            hx-post="/api/seed"
            hx-target="#seed-result"
            hx-indicator="#seed-spinner"
            hx-confirm="5 starter rules will be inserted into DynamoDB. Proceed?"
            class="outline"
            style="width: auto; margin: 0;"
          >
            Run
            <span id="seed-spinner" class="htmx-indicator spinner" />
          </button>
        </div>
        <p style="font-size: 0.85rem; color: var(--pico-muted-color);">
          bash_destructive, env_protection, config_protection, git_operations, production_access
        </p>
        <div id="seed-result" />
      </div>

      {/* Step 3: Generate Config */}
      <div class={`step-card step-${state.steps.generate.status}`}>
        <div style="display: flex; justify-content: space-between; align-items: center;">
          <h3>Step 3: Generate Config</h3>
          <button
            hx-post="/api/generate"
            hx-target="#generate-result"
            hx-indicator="#generate-spinner"
            class="outline"
            style="width: auto; margin: 0;"
          >
            Run
            <span id="generate-spinner" class="htmx-indicator spinner" />
          </button>
        </div>
        <p style="font-size: 0.85rem; color: var(--pico-muted-color);">
          DynamoDB → harness-rules.json → S3 + local
        </p>
        <div id="generate-result" />
      </div>

      {/* Step 4: Verify */}
      <div class={`step-card step-${state.steps.verify.status}`}>
        <div style="display: flex; justify-content: space-between; align-items: center;">
          <h3>Step 4: Verify</h3>
          <button
            hx-post="/api/verify"
            hx-target="#verify-result"
            hx-indicator="#verify-spinner"
            class="outline"
            style="width: auto; margin: 0;"
          >
            Test
            <span id="verify-spinner" class="htmx-indicator spinner" />
          </button>
        </div>
        <div id="verify-result" />
      </div>
    </div>
  );
};

const AnalysisResult: FC<{ analysis: ProjectAnalysis }> = ({ analysis }) => (
  <div style="margin-top: 0.75rem; padding: 1rem; background: #1a1e24; border-radius: 4px;">
    <table>
      <tbody>
        <tr>
          <td><strong>Detected Language</strong></td>
          <td>{analysis.detected.language}</td>
        </tr>
        <tr>
          <td><strong>Recommended Template</strong></td>
          <td>
            <mark>{analysis.detected.template || "none"}</mark>
          </td>
        </tr>
        <tr>
          <td><strong>Indicators</strong></td>
          <td>{analysis.detected.indicators.join(", ") || "-"}</td>
        </tr>
        <tr>
          <td><strong>Available Tools</strong></td>
          <td>{analysis.detected.tools.join(", ") || "-"}</td>
        </tr>
        <tr>
          <td><strong>Suggested Project ID</strong></td>
          <td><code>{analysis.suggestedProjectId}</code></td>
        </tr>
      </tbody>
    </table>
    <form hx-post="/api/apply-analysis" hx-target="#analysis-result" hx-swap="none">
      <input type="hidden" name="template" value={analysis.detected.template} />
      <input type="hidden" name="projectId" value={analysis.suggestedProjectId} />
      <input type="hidden" name="targetProject" value={analysis.path} />
      <button type="submit" style="width: auto;">
        Apply Settings
      </button>
    </form>
  </div>
);
