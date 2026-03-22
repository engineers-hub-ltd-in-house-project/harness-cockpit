import { Hono } from "hono";
import { exec, scriptPath } from "../lib/exec";
import { getState, updateStep } from "../lib/state";
import { Badge, OutputBlock } from "../views/layout";

const app = new Hono();

app.post("/", async (c) => {
  const state = getState();
  const targetDir = state.targetProject;

  if (!targetDir) {
    return c.html(
      <div>
        <Badge status="error" />
        <p style="color: #e5534b;">Project path not set.</p>
      </div>
    );
  }

  const result = await exec(
    ["bash", scriptPath("uninstall-hooks.sh")],
    { cwd: targetDir }
  );
  const output = result.stdout + (result.stderr ? "\n" + result.stderr : "");
  const ok = result.exitCode === 0;

  return c.html(
    <div>
      <Badge status={ok ? "done" : "error"} />
      <OutputBlock text={output} />
    </div>
  );
});

export default app;
