import { Hono } from "hono";
import { exec, scriptPath } from "../lib/exec";
import { getState, updateStep } from "../lib/state";
import { Badge, OutputBlock } from "../views/layout";

const app = new Hono();

app.post("/", async (c) => {
  const state = getState();
  updateStep("seed", { status: "running", output: "" });

  const result = await exec(
    ["bash", scriptPath("seed-rules.sh"), state.projectId],
    { cwd: state.targetProject }
  );
  const output = result.stdout + (result.stderr ? "\n" + result.stderr : "");
  const ok = result.exitCode === 0;

  updateStep("seed", { status: ok ? "done" : "error", output });

  return c.html(
    <div>
      <Badge status={ok ? "done" : "error"} />
      <OutputBlock text={output} />
    </div>
  );
});

export default app;
