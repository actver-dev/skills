---
name: pin-actions
description: This skill should be used when the user asks to pin GitHub Actions to commit SHAs, secure workflows against supply-chain attacks, replace action tags with SHAs, harden GitHub Actions, fix Scorecard pinned-dependencies findings, or lock action versions. Triggers on phrases like "pin actions", "SHA pin", "secure workflows", "harden workflows", "lock action versions", "replace tags with SHAs".
---

# Pin GitHub Actions to SHA

Pin all GitHub Actions in workflow files to full commit SHAs for supply-chain security.

## Steps

1. Find all workflow files in `.github/workflows/`
2. For each `uses:` line with a tag reference (e.g. `actions/checkout@v4`):
   - Extract the `owner/repo` and current version tag
   - Look up the SHA for the **currently referenced tag** using ActVer (prefer `get_action_version` MCP tool; fall back to `https://actver.dev/v1/actions/{owner}/{repo}` if MCP is unavailable)
   - Replace the tag with the full 40-character commit SHA
   - Add a trailing comment with the version tag for readability
   - **Do not upgrade versions** — pin to the SHA matching the tag already in the workflow. Version upgrades are handled by the `upgrade-actions` skill
3. For subdirectory actions (e.g. `github/codeql-action/init`), look up the parent repository — all subdirectories share the same SHA
4. For reusable workflows (`org/repo/.github/workflows/build.yml@ref`), pin these too using the same SHA pattern

## Format

```yaml
# Before
- uses: actions/checkout@v4
- uses: actions/setup-node@v4

# After
- uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4.2.2
- uses: actions/setup-node@39370e3970a6d050c480ffad4ff0ed4d3fdee5af # v4.1.0
```

## Notes

- Always preserve the version as a `# vX.Y.Z` comment after the SHA
- Skip local actions (`uses: ./.github/actions/...` or `uses: ./`) — these are in the user's own repo
- Skip Docker-based actions (`docker://`) — use image digests instead
- For details, see [references/sha-pinning-guide.md](references/sha-pinning-guide.md)
