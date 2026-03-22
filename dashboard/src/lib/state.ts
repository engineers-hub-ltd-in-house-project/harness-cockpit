export type StepStatus = "idle" | "running" | "done" | "error";

export interface SetupState {
  targetProject: string;
  projectId: string;
  template: string;
  steps: {
    prerequisites: { status: StepStatus; details: Record<string, boolean> };
    install: { status: StepStatus; output: string };
    seed: { status: StepStatus; output: string };
    generate: { status: StepStatus; output: string };
    verify: { status: StepStatus; output: string; grafanaUrl: string };
  };
}

const state: SetupState = {
  targetProject: "",
  projectId: "",
  template: "",
  steps: {
    prerequisites: { status: "idle", details: {} },
    install: { status: "idle", output: "" },
    seed: { status: "idle", output: "" },
    generate: { status: "idle", output: "" },
    verify: { status: "idle", output: "", grafanaUrl: "" },
  },
};

export function getState(): SetupState {
  return state;
}

export function updateState(patch: Partial<SetupState>): void {
  Object.assign(state, patch);
}

export function updateStep<K extends keyof SetupState["steps"]>(
  step: K,
  patch: Partial<SetupState["steps"][K]>
): void {
  Object.assign(state.steps[step], patch);
}
