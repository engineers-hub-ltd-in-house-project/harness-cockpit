import { Hono } from "hono";
import { checkCommand, terraformOutput } from "../lib/exec";
import { updateStep } from "../lib/state";
import { Badge } from "../views/layout";
import { t } from "../lib/i18n";

const app = new Hono();

app.post("/", async (c) => {
  updateStep("prerequisites", { status: "running", details: {} });

  const checks: Record<string, boolean> = {};
  for (const cmd of ["terraform", "jq", "curl", "aws", "bun"]) {
    checks[cmd] = await checkCommand(cmd);
  }

  const tfDeployed = (await terraformOutput("api_endpoint")) !== null;
  checks["terraform_deployed"] = tfDeployed;

  const allOk = Object.values(checks).every(Boolean);
  updateStep("prerequisites", {
    status: allOk ? "done" : "error",
    details: checks,
  });

  return c.html(
    <div>
      <Badge status={allOk ? "done" : "error"} />
      <table style="margin-top: 0.5rem;">
        <tbody>
          {Object.entries(checks).map(([name, ok]) => (
            <tr>
              <td>{name}</td>
              <td style={`color: ${ok ? "#57ab5a" : "#e5534b"}`}>
                {ok ? "OK" : "Missing"}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
      {!checks["terraform_deployed"] && (
        <p style="color: #e5534b;">
          {t("terraform.missing")}
        </p>
      )}
    </div>
  );
});

export default app;
