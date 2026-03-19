# SHA Pinning Guide

## Why Pin to SHA?

Tag-based references (`actions/checkout@v4`) are mutable — a compromised repository could move the tag to point to malicious code. SHA pinning ensures you always run the exact code you reviewed.

This is recommended by:
- [GitHub's security hardening guide](https://docs.github.com/en/actions/security-for-github-actions/security-guides/security-hardening-for-github-actions#using-third-party-actions)
- [OpenSSF Scorecard](https://github.com/ossf/scorecard)
- [StepSecurity](https://www.stepsecurity.io/)

## Pinning Rules

### Standard Actions
```yaml
# Pin to full SHA with version comment
- uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4.2.2
```

### Subdirectory Actions
Subdirectory actions share the same SHA as the parent repository:
```yaml
- uses: github/codeql-action/init@ea9e4e37992a54ee68a9f14f4a7fbd07faded6ee # v3.28.0
- uses: github/codeql-action/analyze@ea9e4e37992a54ee68a9f14f4a7fbd07faded6ee # v3.28.0
```

### Reusable Workflows
Reusable workflows should also be pinned:
```yaml
- uses: org/repo/.github/workflows/build.yml@a1b2c3d4e5f6 # v1.2.0
```

### What NOT to Pin
- **Local actions**: `uses: ./.github/actions/my-action` — these are in your own repo
- **Docker actions**: `uses: docker://alpine:3.19` — use image digest instead

## Version Comment Format

Always include the version tag as a trailing comment:
```yaml
# Good — readable and auditable
- uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4.2.2

# Bad — no way to know what version this SHA corresponds to
- uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683
```

## Verifying a SHA

To verify that a SHA matches a specific tag:
```bash
# Using ActVer API
curl -s https://actver.dev/v1/actions/actions/checkout | jq '.sha'

# Using GitHub API directly
gh api repos/actions/checkout/git/refs/tags/v4.2.2 --jq '.object.sha'
```

## Updating Pinned Actions

When updating a pinned action:
1. Look up the new version's SHA using ActVer
2. Update both the SHA and the version comment
3. Never update just the comment — always verify the SHA matches

## Automation

Tools that can automate SHA pinning:
- **ActVer** (`actver.dev`) — version + SHA lookup API and MCP server
- **Dependabot** — can be configured to pin and update SHAs
- **Renovate** — supports SHA pinning via `pinDigests` option
- **StepSecurity Secure Workflows** — automated pinning + additional hardening
