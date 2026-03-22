import { Hono } from "hono";
import { readdirSync, statSync } from "fs";
import { resolve, dirname, basename } from "path";
import { homedir } from "os";
import { t } from "../lib/i18n";

const app = new Hono();

app.get("/", async (c) => {
  const rawPath = c.req.query("path") || homedir();
  const currentPath = resolve(rawPath);

  let dirs: { name: string; path: string; isGit: boolean }[] = [];
  let error = "";

  try {
    const entries = readdirSync(currentPath, { withFileTypes: true });
    dirs = entries
      .filter((e) => e.isDirectory() && !e.name.startsWith("."))
      .sort((a, b) => a.name.localeCompare(b.name))
      .map((e) => {
        const fullPath = resolve(currentPath, e.name);
        let isGit = false;
        try {
          statSync(resolve(fullPath, ".git"));
          isGit = true;
        } catch {}
        return { name: e.name, path: fullPath, isGit };
      });
  } catch (e: any) {
    error = e.message;
  }

  const parentPath = dirname(currentPath);

  return c.html(
    <div>
      <p style="font-size: 0.85rem; color: var(--pico-muted-color); margin-bottom: 0.25rem;">
        {currentPath}
      </p>

      {error && <p style="color: #e5534b; font-size: 0.85rem;">{error}</p>}

      <div style="max-height: 240px; overflow-y: auto; border: 1px solid var(--pico-muted-border-color); border-radius: 4px; margin-bottom: 0.75rem;">
        <table style="margin: 0;">
          <tbody>
            {currentPath !== parentPath && (
              <tr
                style="cursor: pointer;"
                hx-get={`/api/browse?path=${encodeURIComponent(parentPath)}`}
                hx-target="#folder-browser"
                hx-swap="innerHTML"
              >
                <td style="padding: 0.35rem 0.75rem;">
                  <span style="color: var(--pico-muted-color);">.. (parent)</span>
                </td>
              </tr>
            )}
            {dirs.map((d) => (
              <tr
                style="cursor: pointer;"
                hx-get={`/api/browse?path=${encodeURIComponent(d.path)}`}
                hx-target="#folder-browser"
                hx-swap="innerHTML"
              >
                <td style="padding: 0.35rem 0.75rem;">
                  {d.name}
                  {d.isGit && (
                    <span style="margin-left: 0.5rem; font-size: 0.7rem; color: #57ab5a; border: 1px solid #57ab5a; padding: 1px 4px; border-radius: 3px;">
                      git
                    </span>
                  )}
                </td>
              </tr>
            ))}
            {dirs.length === 0 && !error && (
              <tr>
                <td style="padding: 0.35rem 0.75rem; color: var(--pico-muted-color);">
                  ({t("browse.empty")})
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      <button
        hx-post="/api/analyze"
        hx-target="#analysis-result"
        hx-vals={`{"targetProject": "${currentPath}"}`}
        hx-indicator="#analyze-spinner"
        style="width: auto;"
      >
        {t("browse.select")} {basename(currentPath)}
        <span id="analyze-spinner" class="htmx-indicator spinner" />
      </button>
    </div>
  );
});

export default app;
