# GitHub Actions Security Checklist

## Scope

Each check is labeled **Core** or **Reference**:

- **Core** — Action-related security. Always checked by this skill.
- **Reference** — General workflow best practice. Included for awareness but can be automatically detected by dedicated tools (actionlint, ghalint, zizmor).

## Critical Issues

### 1. Unpinned Third-Party Actions [Core]

**Risk**: Supply-chain attack via tag manipulation
**Check**: All `uses:` lines with third-party actions should use full SHA

```yaml
# Bad
- uses: actions/checkout@v4

# Good
- uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4.2.2
```

### 2. Script Injection [Reference]

**Risk**: Arbitrary code execution via crafted PR titles, branch names, etc.
**Auto-detection**: zizmor (`template-injection`)
**Check**: `${{ }}` expressions in `run:` blocks

```yaml
# Bad — attacker controls github.event.issue.title
- run: echo "Issue: ${{ github.event.issue.title }}"

# Good — use environment variable
- run: echo "Issue: $TITLE"
  env:
    TITLE: ${{ github.event.issue.title }}
```

Dangerous contexts (user-controlled input):

- `github.event.issue.title` / `github.event.issue.body`
- `github.event.pull_request.title` / `github.event.pull_request.body`
- `github.event.comment.body`
- `github.event.review.body`
- `github.event.head_commit.message`
- `github.head_ref` (branch name)

### 3. pull_request_target with Checkout [Core]

**Risk**: Running untrusted PR code with write permissions and secrets
**Check**: `pull_request_target` trigger + `actions/checkout` with `ref: ${{ github.event.pull_request.head.sha }}`

```yaml
# Dangerous — runs PR code with repo write access
on: pull_request_target
jobs:
  build:
    steps:
      - uses: actions/checkout@v4
        with:
          ref: ${{ github.event.pull_request.head.sha }}
      - run: npm test  # Runs attacker's code with secrets!
```

## Warning Issues

### 4. Missing or Broad Permissions [Core]

**Risk**: Compromised action gets unnecessary access
**Check**: Top-level `permissions` key

```yaml
# Bad — defaults to broad access
on: push
jobs: ...

# Good — principle of least privilege
permissions:
  contents: read

on: push
jobs: ...
```

### 5. Secrets Passed to Untrusted Actions [Core]

**Risk**: Secret exfiltration
**Check**: `with:` or `env:` passing secrets to third-party actions

```yaml
# Risky — does this action need your deploy key?
- uses: some-unknown/action@v1
  with:
    token: ${{ secrets.DEPLOY_KEY }}
```

### 6. Mutable Docker Tags [Core]

**Risk**: Docker image could be replaced
**Check**: Docker actions using tags instead of digests

```yaml
# Bad
- uses: docker://node:18

# Good
- uses: docker://node@sha256:abc123...
```

### 7. Checkout Credential Persistence [Core]

**Risk**: Token persisted in `.git/config` can be stolen by compromised dependencies or scripts in later steps
**Check**: `actions/checkout` without `persist-credentials: false`

```yaml
# Bad — token remains in .git/config for subsequent steps
- uses: actions/checkout@v4  # (SHA pinning omitted for clarity — see check #1)

# Good — credentials removed after checkout
- uses: actions/checkout@v4  # (SHA pinning omitted for clarity — see check #1)
  with:
    persist-credentials: false
```

**Exception**: Workflows that need `git push` (deploy, release, backport) may require persisted credentials. In such cases, scope the credentials tightly — revoke with `git config --unset-all http.<url>.extraheader` after the push step, or use a short-lived token.

### 8. Submodules with Persisted Credentials [Core]

**Risk**: Submodule init scripts can access the persisted token; especially dangerous with custom PATs that have broad scope
**Check**: `submodules: true` (or `recursive`) without `persist-credentials: false`

```yaml
# Bad — token accessible to submodule scripts
- uses: actions/checkout@v4  # (SHA pinning omitted for clarity — see check #1)
  with:
    submodules: true

# Good — no persisted credentials
- uses: actions/checkout@v4  # (SHA pinning omitted for clarity — see check #1)
  with:
    submodules: true
    persist-credentials: false
```

## Info Issues

### 9. Outdated Actions [Core]

**Check**: Actions not on their latest stable version
**Fix**: Use ActVer to look up latest versions and upgrade

### 10. No Timeout [Reference]

**Check**: Jobs without `timeout-minutes`
**Risk**: Runaway jobs consuming CI minutes
**Auto-detection**: ghalint (`job_timeout_minutes_is_required`)

```yaml
jobs:
  build:
    timeout-minutes: 15  # Add appropriate timeout
    steps: ...
```

### 11. Concurrency Not Set [Reference]

**Check**: Workflows without `concurrency` for deploy workflows
**Risk**: Concurrent deploys causing issues
**Auto-detection**: zizmor (`concurrency-limits`)

```yaml
concurrency:
  group: deploy-${{ github.ref }}
  cancel-in-progress: true
```

## Automated Tooling for Reference Checks

Reference checks can be automatically detected and enforced by adding static analysis tools to CI:

| Tool | Detects | Key rules |
|------|---------|-----------|
| [actionlint](https://github.com/rhysd/actionlint) | Syntax errors, type mismatches | shellcheck integration |
| [ghalint](https://github.com/suzuki-shunsuke/ghalint) | Policy violations | `job_timeout_minutes_is_required`, `job_permissions`, `action_ref_should_be_full_length_commit_sha` |
| [zizmor](https://github.com/zizmorcore/zizmor) | Injection, permissions | `template-injection`, `concurrency-limits`, `excessive-permissions` |

Consider adding these tools to your CI pipeline for continuous enforcement.

## References

- [GitHub Security Hardening Guide](https://docs.github.com/en/actions/security-for-github-actions/security-guides/security-hardening-for-github-actions)
- [OpenSSF Scorecard — Pinned Dependencies](https://github.com/ossf/scorecard/blob/main/docs/checks.md#pinned-dependencies)
- [StepSecurity Blog](https://www.stepsecurity.io/blog)
- [actions/checkout — Usage](https://github.com/actions/checkout#usage)
