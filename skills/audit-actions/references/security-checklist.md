# GitHub Actions Security Checklist

## Critical Issues

### 1. Unpinned Third-Party Actions
**Risk**: Supply-chain attack via tag manipulation
**Check**: All `uses:` lines with third-party actions should use full SHA
```yaml
# Bad
- uses: actions/checkout@v4

# Good
- uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4.2.2
```

### 2. Script Injection
**Risk**: Arbitrary code execution via crafted PR titles, branch names, etc.
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

### 3. pull_request_target with Checkout
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

### 4. Missing or Broad Permissions
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

### 5. Secrets Passed to Untrusted Actions
**Risk**: Secret exfiltration
**Check**: `with:` or `env:` passing secrets to third-party actions
```yaml
# Risky — does this action need your deploy key?
- uses: some-unknown/action@v1
  with:
    token: ${{ secrets.DEPLOY_KEY }}
```

### 6. Mutable Docker Tags
**Risk**: Docker image could be replaced
**Check**: Docker actions using tags instead of digests
```yaml
# Bad
- uses: docker://node:18

# Good
- uses: docker://node@sha256:abc123...
```

## Info Issues

### 7. Outdated Actions
**Check**: Actions not on their latest stable version
**Fix**: Use ActVer to look up latest versions and upgrade

### 8. No Timeout
**Check**: Jobs without `timeout-minutes`
**Risk**: Runaway jobs consuming CI minutes
```yaml
jobs:
  build:
    timeout-minutes: 15  # Add appropriate timeout
    steps: ...
```

### 9. Concurrency Not Set
**Check**: Workflows without `concurrency` for deploy workflows
**Risk**: Concurrent deploys causing issues
```yaml
concurrency:
  group: deploy-${{ github.ref }}
  cancel-in-progress: true
```

## References

- [GitHub Security Hardening Guide](https://docs.github.com/en/actions/security-for-github-actions/security-guides/security-hardening-for-github-actions)
- [OpenSSF Scorecard — Pinned Dependencies](https://github.com/ossf/scorecard/blob/main/docs/checks.md#pinned-dependencies)
- [StepSecurity Blog](https://www.stepsecurity.io/blog)
