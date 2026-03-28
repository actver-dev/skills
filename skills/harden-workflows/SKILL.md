---
name: harden-workflows
description: This skill should be used when the user wants to add static analysis tools (actionlint, ghalint, zizmor) to their GitHub Actions CI for continuous workflow security enforcement. Common triggers include "harden workflows", "harden CI", "add workflow linting", "setup actionlint", "add zizmor", "add ghalint", "secure my GitHub Actions", "workflow security setup", "static analysis for workflows", "lint my workflows", "workflow lint CI", "add workflow security checks", or "enforce workflow policies". This skill sets up tooling in CI — it does not pin individual actions (use pin-actions) or perform one-time audits (use audit-actions).
---

# Harden GitHub Actions Workflows

Set up static analysis tools (actionlint, ghalint, zizmor) in CI to automatically detect workflow security issues, policy violations, and injection vulnerabilities.

## Scope

This skill helps **set up tooling** for continuous workflow security enforcement. It does not perform security audits itself — use the **audit-actions** skill for manual security review.

| Tool | Role | Detects |
|------|------|---------|
| actionlint | Syntax validation | YAML errors, type mismatches, shellcheck issues |
| ghalint | Policy enforcement | Missing timeouts, permissions, credential persistence |
| zizmor | Attack detection | Script injection, excessive permissions, missing concurrency |

## Steps

1. Check if `.github/workflows/` already contains a workflow-lint file (e.g. `workflow-lint.yml`)
2. If not present, create a new workflow file based on the [template](references/workflow-lint-template.md):
   - Look up the latest SHA-pinned versions of `actions/checkout`, `rhysd/actionlint`, and `zizmorcore/zizmor-action` using ActVer (prefer `get_action_version` MCP tool)
   - Look up the latest ghalint release version from GitHub (`gh release view --repo suzuki-shunsuke/ghalint --json tagName`)
   - Generate the workflow with all actions SHA-pinned and ghalint version-pinned
3. Create a `zizmor.yml` config file if the repo uses `secrets` in workflows:
   - Add `secrets-outside-env` ignores for workflows that pass secrets to trusted actions (e.g. claude-code-action, deploy actions)
4. Apply workflow security best practices to existing workflows where missing (confirm with the user before modifying workflows beyond the lint file):
   - `permissions: {}` at workflow level (deny by default) + job-level permissions
   - `persist-credentials: false` on all `actions/checkout`
   - `timeout-minutes` on all jobs
   - `concurrency` groups where appropriate
5. Verify ghalint binary with `gh attestation verify` for supply-chain security

## Notes

- This skill sets up tooling — it does not replicate what the tools check. The tools themselves detect and report issues.
- For action-specific security audits (SHA pinning, checkout config, secrets exposure), use the **audit-actions** skill
- For SHA pinning of actions, use the **pin-actions** skill
- For upgrading action versions, use the **upgrade-actions** skill
- For the workflow template and configuration examples, see [references/workflow-lint-template.md](references/workflow-lint-template.md)
