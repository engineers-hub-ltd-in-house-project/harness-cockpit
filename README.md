# harness-cockpit

SELinux-inspired permissive-to-enforcing mode control for Claude Code Hooks.

Observe all tool executions without blocking (permissive), analyze false-positive patterns via a Grafana dashboard, then promote rules to enforcing mode based on observed data. This feedback loop enables gradual, data-driven tightening of AI coding guardrails.

## Architecture

- **Hook Scripts** — `harness-gate.sh` (PreToolUse) and `harness-post.sh` (PostToolUse) run locally, evaluating rules from a cached `harness-rules.json`
- **AWS Backend** — API Gateway + Lambda + CloudWatch Logs + DynamoDB for event collection and rule management
- **Grafana Dashboard** — Rule Cockpit, Incident Review, Quality Trends, Session Timeline views with actionable buttons for mode transitions
- **Config Pipeline** — DynamoDB -> Lambda (ConfigGenerator) -> S3 -> local sync

## Documentation

- [Original Specification](docs/requirements/00-original-specification.md) — Full design document (Japanese)

## License

[MIT](LICENSE)
