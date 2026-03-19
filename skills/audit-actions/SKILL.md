---
name: audit-actions
description: This skill should be used when a user asks to audit GitHub Actions workflows for security issues. Common triggers include "audit workflows", "security review my GitHub Actions", "check CI security", "scan workflows for vulnerabilities", "review workflow security", "harden my CI pipelines", "check for script injection", or "are my GitHub Actions secure".
---

# Audit GitHub Actions Workflows

Perform a security audit of GitHub Actions workflow files, checking for common security issues and best practices.

## Steps

1. Find all workflow files in `.github/workflows/`
2. Check each file against the security checklist:
   - **Unpinned actions**: Actions using tag references instead of SHA pins
   - **Untrusted actions**: Actions from unknown or unverified publishers
   - **Excessive permissions**: Workflows with broad `permissions` grants
   - **Script injection**: Unsafe use of `${{ }}` expressions in `run:` blocks
   - **Secret exposure**: Secrets passed to untrusted actions or logged in output
   - **Risky triggers**: `pull_request_target` with checkout of PR code
   - Additional checks (mutable Docker tags, missing timeouts, missing concurrency) are in the [full checklist](references/security-checklist.md)
3. Report findings with severity (critical / warning / info) and remediation steps

## Output Format

```
## Workflow Audit Report

### critical
- [ ] `deploy.yml:15` — `actions/checkout@v4` is not SHA-pinned
- [ ] `ci.yml:32` — Script injection via `${{ github.event.issue.title }}`

### warning
- [ ] `ci.yml:1` — No `permissions` key (defaults to broad access)
- [ ] `release.yml:8` — Uses `pull_request_target` trigger

### info
- [ ] `ci.yml:20` — `actions/setup-node@v4` can be upgraded to v5
```

## Notes

- This skill identifies and reports issues — it does not fix them automatically
- To remediate unpinned actions, use the **pin-actions** skill
- To upgrade outdated actions, use the **upgrade-actions** skill
- For the full security checklist, see [references/security-checklist.md](references/security-checklist.md)
