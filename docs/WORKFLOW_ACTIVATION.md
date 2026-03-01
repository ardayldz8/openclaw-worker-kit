# Workflow Activation Runbook

Use this when your current token cannot push `.github/workflows/*`.

## Steps
1. Open `docs/CI_WORKFLOW_TEMPLATE.md`.
2. Copy YAML content into `.github/workflows/smoke-test.yml` in a workflow-scoped session (web UI or scoped PAT).
3. Commit to `main`.
4. Verify Actions run succeeds on latest commit.

## Verification
- At least one successful run on `main`.
- Artifacts upload on failure is visible.
