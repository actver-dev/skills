# Upgrade Patterns

## Upgrade Types

### Patch Upgrade (Safe)
Same major version, just a newer patch. No breaking changes expected.
```yaml
# v4.1.0 → v4.2.2
- uses: actions/checkout@v4.1.0
- uses: actions/checkout@v4.2.2
```

### Major Upgrade (Review Required)
New major version — may include breaking changes.
```yaml
# v3 → v4 (major upgrade)
- uses: actions/checkout@v3
- uses: actions/checkout@v4
```

Always check the action's release notes or changelog for breaking changes in major upgrades.

## Common Major Upgrade Notes

### actions/checkout
- **v3 → v4**: Node.js 16 → 20, `set-safe-directory` default changed
- **v4 → v5**: Minimal breaking changes

### actions/setup-node
- **v3 → v4**: Node.js 16 → 20, `node-version-file` behavior changed
- **v4 → v5**: `cache` input requires explicit package manager

### actions/upload-artifact / actions/download-artifact
- **v3 → v4**: Artifact immutability enforced, `overwrite` input added, breaking changes in merge behavior

## Upgrade Workflow

1. **List current versions**: Scan all `uses:` lines in `.github/workflows/`
2. **Check for updates**: Query ActVer for each action
3. **Categorize updates**:
   - Patch updates → apply directly
   - Major updates → flag for review
4. **Update files**: Replace version references (tag or SHA + comment)
5. **Verify**: Run `git diff` to review all changes

## SHA-Pinned Upgrades

When upgrading SHA-pinned actions, update both the SHA and the comment:
```yaml
# Before
- uses: actions/checkout@old_sha_here # v3.6.0

# After
- uses: actions/checkout@new_sha_here # v4.2.2
```

Never update just the version comment without changing the SHA.

## Prerelease Versions

ActVer reports prerelease versions separately. By default:
- Upgrade to the latest **stable** version
- Only suggest prerelease versions if the user explicitly asks or is already on a prerelease track
