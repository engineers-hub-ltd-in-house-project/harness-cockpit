import type { FC, PropsWithChildren } from "hono/jsx";

export const Layout: FC<PropsWithChildren<{ title?: string }>> = ({
  children,
  title = "Harness Cockpit Setup",
}) => (
  <html lang="ja" data-theme="dark">
    <head>
      <meta charset="utf-8" />
      <meta name="viewport" content="width=device-width, initial-scale=1" />
      <title>{title}</title>
      <link
        rel="stylesheet"
        href="https://cdn.jsdelivr.net/npm/@picocss/pico@2/css/pico.min.css"
      />
      <script src="https://unpkg.com/htmx.org@2.0.4"></script>
      <style>{`
        :root { --pico-font-size: 15px; }
        .step-card { margin-bottom: 1rem; padding: 1.5rem; border-radius: 8px; border: 1px solid var(--pico-muted-border-color); }
        .step-card h3 { margin-top: 0; margin-bottom: 0.5rem; }
        .step-idle { opacity: 0.6; }
        .step-running { border-color: var(--pico-primary); }
        .step-done { border-color: #57ab5a; }
        .step-error { border-color: #e5534b; }
        .badge { display: inline-block; padding: 2px 8px; border-radius: 4px; font-size: 0.75rem; font-weight: 600; }
        .badge-idle { background: var(--pico-muted-border-color); color: var(--pico-muted-color); }
        .badge-running { background: var(--pico-primary); color: #fff; }
        .badge-done { background: #57ab5a; color: #fff; }
        .badge-error { background: #e5534b; color: #fff; }
        pre.output { max-height: 200px; overflow-y: auto; font-size: 0.8rem; background: #1a1e24; padding: 0.75rem; border-radius: 4px; white-space: pre-wrap; word-break: break-all; }
        .htmx-indicator { display: none; }
        .htmx-request .htmx-indicator { display: inline-block; }
        .spinner { display: inline-block; width: 1em; height: 1em; border: 2px solid transparent; border-top-color: currentColor; border-radius: 50%; animation: spin 0.6s linear infinite; }
        @keyframes spin { to { transform: rotate(360deg); } }
      `}</style>
    </head>
    <body>
      <main class="container" style="max-width: 720px; padding-top: 2rem;">
        <hgroup>
          <h1>Harness Cockpit Setup</h1>
          <p>Claude Code Hooks permissive-to-enforcing mode control</p>
        </hgroup>
        {children}
      </main>
    </body>
  </html>
);

export const Badge: FC<{ status: string }> = ({ status }) => {
  const labels: Record<string, string> = {
    idle: "Pending",
    running: "Running...",
    done: "Complete",
    error: "Error",
  };
  return (
    <span class={`badge badge-${status}`}>{labels[status] || status}</span>
  );
};

export const OutputBlock: FC<{ text: string }> = ({ text }) =>
  text ? <pre class="output">{text}</pre> : null;
