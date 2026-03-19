---
name: upgrade-actions
description: This skill should be used when the user wants to upgrade GitHub Actions in their workflow files to the latest versions. Common triggers include "update actions", "upgrade actions", "bump action versions", "check for outdated actions", "update workflow dependencies", "what actions are out of date", "modernize my CI workflows", or "latest version of GitHub Actions".
---

# Upgrade GitHub Actions

Upgrade GitHub Actions in workflow files to their latest stable versions.

## Steps

1. Find all workflow files in `.github/workflows/`
2. For each `uses:` line (skip local actions `./` and Docker `docker://`):
   - Extract the `owner/repo` and current version
   - Look up the latest version using ActVer (prefer `get_action_version` MCP tool; fall back to `https://actver.dev/v1/actions/{owner}/{repo}` if MCP is unavailable)
   - Compare current version with latest
3. Categorize updates:
   - **Patch upgrades** (same major): apply directly
   - **Major upgrades** (different major): flag for user review before applying — major versions may include breaking changes
4. If the action is SHA-pinned, update both the SHA and the version comment
5. Report which actions were updated and from/to versions

## Example

```yaml
# Tag-based upgrade
- uses: actions/checkout@v3      # outdated
- uses: actions/checkout@v4      # upgraded

# SHA-pinned upgrade
- uses: actions/checkout@old_sha # v3.6.0  (outdated)
- uses: actions/checkout@new_sha # v4.2.2  (upgraded)
```

## Notes

- Use `list_action_versions` to check available major versions when a major upgrade is possible
- Major version upgrades may include breaking changes — always confirm with the user before applying
- Do not suggest prerelease versions unless the user explicitly requests them
- For detailed upgrade patterns, see [references/upgrade-patterns.md](references/upgrade-patterns.md)
