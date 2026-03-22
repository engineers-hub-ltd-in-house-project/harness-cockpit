import { Hono } from "hono";
import { exec, terraformOutput } from "../lib/exec";
import { getState, updateStep } from "../lib/state";
import { Badge, OutputBlock } from "../views/layout";

const app = new Hono();

app.post("/", async (c) => {
  const state = getState();
  updateStep("verify", { status: "running", output: "", grafanaUrl: "" });

  const endpoint = await terraformOutput("api_endpoint");
  const grafanaUrl = (await terraformOutput("grafana_endpoint")) || "";

  let output = "";
  let ok = false;

  if (endpoint) {
    const tokenResult = await exec(
      ["bash", "-c", `grep harness_api_token terraform.tfvars | cut -d'"' -f2`],
      { cwd: `${import.meta.dir}/../../../infra` }
    );
    const token = tokenResult.stdout;

    const curlResult = await exec([
      "curl", "-sf", "--max-time", "10",
      "-X", "POST", `${endpoint}/events`,
      "-H", `Authorization: Bearer ${token}`,
      "-H", "Content-Type: application/json",
      "-d", JSON.stringify({
        event_type: "pre_tool_use",
        session_id: "dashboard-verify",
        tool_name: "Bash",
        tool_input: { command: "dashboard verification" },
        project_id: state.projectId,
        action: "allow",
        timestamp: new Date().toISOString(),
      }),
    ]);

    if (curlResult.exitCode === 0) {
      output = `API OK: ${curlResult.stdout}`;
      ok = true;
    } else {
      output = `API Error: ${curlResult.stderr || curlResult.stdout}`;
    }
  } else {
    output = "Terraform output (api_endpoint) not available.";
  }

  updateStep("verify", {
    status: ok ? "done" : "error",
    output,
    grafanaUrl,
  });

  return c.html(
    <div>
      <Badge status={ok ? "done" : "error"} />
      <OutputBlock text={output} />
      {grafanaUrl && (
        <p>
          Grafana:{" "}
          <a href={grafanaUrl} target="_blank" rel="noopener">
            {grafanaUrl}
          </a>
        </p>
      )}
    </div>
  );
});

export default app;
