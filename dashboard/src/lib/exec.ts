import { resolve } from "path";

const REPO_ROOT = resolve(import.meta.dir, "../../../");

export function scriptPath(name: string): string {
  return resolve(REPO_ROOT, "scripts", name);
}

export function infraDir(): string {
  return resolve(REPO_ROOT, "infra");
}

export async function exec(
  command: string[],
  options?: { cwd?: string }
): Promise<{ stdout: string; stderr: string; exitCode: number }> {
  const proc = Bun.spawn(command, {
    cwd: options?.cwd,
    stdout: "pipe",
    stderr: "pipe",
    env: { ...process.env, FORCE_COLOR: "0" },
  });

  const stdout = await new Response(proc.stdout).text();
  const stderr = await new Response(proc.stderr).text();
  const exitCode = await proc.exited;

  return { stdout: stdout.trim(), stderr: stderr.trim(), exitCode };
}

export async function checkCommand(name: string): Promise<boolean> {
  try {
    const result = await exec(["which", name]);
    return result.exitCode === 0;
  } catch {
    return false;
  }
}

export async function terraformOutput(key: string): Promise<string | null> {
  try {
    const result = await exec(
      ["terraform", "output", "-raw", key],
      { cwd: infraDir() }
    );
    return result.exitCode === 0 ? result.stdout : null;
  } catch {
    return null;
  }
}
