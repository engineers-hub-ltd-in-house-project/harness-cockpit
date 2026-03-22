import type { FC } from "hono/jsx";
import { getState } from "../lib/state";
import { t } from "../lib/i18n";
import { Badge } from "./layout";

export const SetupWizard: FC = () => {
  const state = getState();

  return (
    <div>
      {/* Project Path Input */}
      <div class="step-card">
        <h3>{t("project.title")}</h3>
        <form
          hx-post="/api/analyze"
          hx-target="#analysis-result"
          hx-indicator="#analyze-spinner"
        >
          <div class="grid">
            <input
              type="text"
              name="targetProject"
              placeholder={t("project.placeholder")}
              value={state.targetProject}
              required
            />
            <button type="submit" style="width: auto;">
              {t("project.analyze")}
              <span id="analyze-spinner" class="htmx-indicator spinner" />
            </button>
          </div>
        </form>
        <div id="analysis-result" />
      </div>

      {/* Step 0 */}
      <div class={`step-card step-${state.steps.prerequisites.status}`}>
        <div style="display: flex; justify-content: space-between; align-items: center;">
          <h3>{t("step0.title")}</h3>
          <button
            hx-post="/api/prerequisites"
            hx-target="#prereq-result"
            hx-indicator="#prereq-spinner"
            class="outline"
            style="width: auto; margin: 0;"
          >
            {t("step0.btn")}
            <span id="prereq-spinner" class="htmx-indicator spinner" />
          </button>
        </div>
        <div id="prereq-result" />
      </div>

      {/* Step 1 */}
      <div class={`step-card step-${state.steps.install.status}`}>
        <div style="display: flex; justify-content: space-between; align-items: center;">
          <h3>{t("step1.title")}</h3>
          <button
            hx-post="/api/install"
            hx-target="#install-result"
            hx-indicator="#install-spinner"
            hx-confirm={t("step1.confirm")}
            style="width: auto; margin: 0;"
          >
            {t("step1.btn")}
            <span id="install-spinner" class="htmx-indicator spinner" />
          </button>
        </div>
        <p style="font-size: 0.85rem; color: var(--pico-muted-color);">
          {t("step1.desc.template")}: <strong>{state.template || "(auto)"}</strong>{" / "}
          {t("step1.desc.projectId")}: <strong>{state.projectId || "(from path)"}</strong>
        </p>
        <div id="install-result" />
      </div>

      {/* Step 2 */}
      <div class={`step-card step-${state.steps.seed.status}`}>
        <div style="display: flex; justify-content: space-between; align-items: center;">
          <h3>{t("step2.title")}</h3>
          <button
            hx-post="/api/seed"
            hx-target="#seed-result"
            hx-indicator="#seed-spinner"
            hx-confirm={t("step2.confirm")}
            class="outline"
            style="width: auto; margin: 0;"
          >
            {t("step2.btn")}
            <span id="seed-spinner" class="htmx-indicator spinner" />
          </button>
        </div>
        <p style="font-size: 0.85rem; color: var(--pico-muted-color);">
          {t("step2.desc")}
        </p>
        <div id="seed-result" />
      </div>

      {/* Step 3 */}
      <div class={`step-card step-${state.steps.generate.status}`}>
        <div style="display: flex; justify-content: space-between; align-items: center;">
          <h3>{t("step3.title")}</h3>
          <button
            hx-post="/api/generate"
            hx-target="#generate-result"
            hx-indicator="#generate-spinner"
            class="outline"
            style="width: auto; margin: 0;"
          >
            {t("step3.btn")}
            <span id="generate-spinner" class="htmx-indicator spinner" />
          </button>
        </div>
        <p style="font-size: 0.85rem; color: var(--pico-muted-color);">
          {t("step3.desc")}
        </p>
        <div id="generate-result" />
      </div>

      {/* Step 4 */}
      <div class={`step-card step-${state.steps.verify.status}`}>
        <div style="display: flex; justify-content: space-between; align-items: center;">
          <h3>{t("step4.title")}</h3>
          <button
            hx-post="/api/verify"
            hx-target="#verify-result"
            hx-indicator="#verify-spinner"
            class="outline"
            style="width: auto; margin: 0;"
          >
            {t("step4.btn")}
            <span id="verify-spinner" class="htmx-indicator spinner" />
          </button>
        </div>
        <div id="verify-result" />
      </div>
    </div>
  );
};
