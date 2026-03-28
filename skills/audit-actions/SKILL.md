---
name: audit-actions
description: This skill should be used when a user asks to audit GitHub Actions workflows for security issues. Common triggers include "audit workflows", "security review my GitHub Actions", "check CI security", "scan workflows for vulnerabilities", "review workflow security", "supply chain security audit", "check for script injection", "are my GitHub Actions secure", "persist-credentials", "checkout security", "credential leakage", "OpenSSF Scorecard findings", or "harden checkout steps".
---

# Audit GitHub Actions Workflows

Perform a security audit of GitHub Actions workflow files, checking for common security issues and best practices.

## Scope

This skill focuses on **Action-related security** (Core checks):
- Action ref format (SHA pinning, tag references, Docker tags)
- `actions/checkout` configuration (persist-credentials, submodules)
- Dangerous trigger patterns involving checkout (`pull_request_target`)
- Secrets passed to actions
- Permissions affecting action execution

General workflow security items (script injection, timeouts, concurrency) are included as **Reference checks** for awareness, but can be automatically detected and enforced by dedicated linting tools.

## Steps

1. Find all workflow files in `.github/workflows/`
2. Check each file against the security checklist:
   - **Unpinned actions**: Actions using tag references instead of SHA pins
   - **Untrusted actions**: Actions from unknown or unverified publishers
   - **Excessive permissions**: Workflows with broad `permissions` grants
   - **Script injection**: Unsafe use of `${{ }}` expressions in `run:` blocks
   - **Secret exposure**: Secrets passed to untrusted actions or logged in output
   - **Risky triggers**: `pull_request_target` with checkout of PR code
   - **Checkout credential leakage**: `actions/checkout` without `persist-credentials: false` (including submodule checkouts)
   - Additional checks (mutable Docker tags, missing timeouts, missing concurrency) are in the [full checklist](references/security-checklist.md)
3. Report findings with severity (critical / warning / info) and remediation steps

## Output Format

```
## Workflow Audit Report

### Critical
- [ ] `deploy.yml:15` — `actions/checkout@v4` is not SHA-pinned
- [ ] `ci.yml:32` — Script injection via `${{ github.event.issue.title }}`
- [ ] `release.yml:8` — `pull_request_target` with checkout of PR code

### Warning
- [ ] `ci.yml:1` — No `permissions` key (defaults to broad access)
- [ ] `ci.yml:5` — `actions/checkout` without `persist-credentials: false`

### Info
- [ ] `ci.yml:20` — `actions/setup-node@v4` can be upgraded to v5
```

## Notes

- This skill identifies and reports issues — it does not fix them automatically
- To remediate unpinned actions, use the **pin-actions** skill
- To upgrade outdated actions, use the **upgrade-actions** skill
- For the full security checklist, see [references/security-checklist.md](references/security-checklist.md)

### Workflow-wide security tooling

For comprehensive workflow security beyond action-specific checks, recommend adding static analysis tools to CI:
- **actionlint** — Workflow syntax validation and shellcheck integration
- **ghalint** — Security policy enforcement (permissions, timeouts)
- **zizmor** — Injection detection and excessive permissions audit

Use the **harden-workflows** skill to set up these tools in CI.
