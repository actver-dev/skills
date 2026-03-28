# Workflow Lint Template

## Workflow File

Create `.github/workflows/workflow-lint.yml`:

```yaml
name: Workflow Lint

on:
  push:
    branches: [main]
    paths:
      - ".github/workflows/**"
      - ".ghalint.yml"
      - "zizmor.yml"
  pull_request:
    branches: [main]
    paths:
      - ".github/workflows/**"
      - ".ghalint.yml"
      - "zizmor.yml"

permissions: {} # deny by default — each job declares its own

concurrency:
  group: workflow-lint-${{ github.ref }}
  cancel-in-progress: true

jobs:
  actionlint:
    name: actionlint
    runs-on: ubuntu-latest
    timeout-minutes: 10
    permissions:
      contents: read # Read workflow files for linting
    steps:
      - uses: actions/checkout@SHA # vX.Y.Z — look up with ActVer
        with:
          persist-credentials: false

      - uses: rhysd/actionlint@SHA # vX.Y.Z — look up with ActVer

  ghalint:
    name: ghalint
    runs-on: ubuntu-latest
    timeout-minutes: 10
    permissions:
      contents: read # Read workflow files for linting
    steps:
      - uses: actions/checkout@SHA # vX.Y.Z
        with:
          persist-credentials: false

      - name: Install ghalint
        env:
          GHALINT_VERSION: "X.Y.Z" # look up latest from GitHub releases
          GH_TOKEN: ${{ github.token }}
        run: |
          # Note: assumes x86_64 runners. For ARM runners, change linux_amd64 to linux_arm64
          gh release download "v${GHALINT_VERSION}" \
            -R suzuki-shunsuke/ghalint \
            -p "ghalint_${GHALINT_VERSION}_linux_amd64.tar.gz"
          gh attestation verify "ghalint_${GHALINT_VERSION}_linux_amd64.tar.gz" \
            -R suzuki-shunsuke/ghalint \
            --signer-workflow suzuki-shunsuke/go-release-workflow/.github/workflows/release.yaml
          tar xzf "ghalint_${GHALINT_VERSION}_linux_amd64.tar.gz" -C /usr/local/bin ghalint

      - name: Run ghalint
        run: ghalint run

  zizmor:
    name: zizmor
    runs-on: ubuntu-latest
    timeout-minutes: 10
    permissions:
      contents: read # Read workflow files for auditing
    steps:
      - uses: actions/checkout@SHA # vX.Y.Z
        with:
          persist-credentials: false

      - uses: zizmorcore/zizmor-action@SHA # vX.Y.Z — look up with ActVer
        with:
          persona: auditor
          advanced-security: false
```

**Important**: Replace all `@SHA # vX.Y.Z` placeholders with actual SHA-pinned versions. Use the ActVer `get_action_version` tool to look up the latest versions.

## Tool Roles

| Tool | Focus | Key Rules |
|------|-------|-----------|
| **actionlint** | Syntax & types | shellcheck integration, expression type checking, runner label validation |
| **ghalint** | Security policy | `job_timeout_minutes_is_required`, `job_permissions`, `checkout_persist_credentials_should_be_false` |
| **zizmor** | Attack patterns | `template-injection`, `concurrency-limits`, `excessive-permissions`, `secrets-outside-env` |

The three tools complement each other — actionlint catches syntax issues, ghalint enforces organizational policies, and zizmor detects security vulnerabilities.

## Configuration Files

### zizmor.yml (optional)

Create `zizmor.yml` at the repository root to suppress expected findings:

```yaml
# Suppress findings for workflows that intentionally use secrets
# outside GitHub Environments (e.g. trusted first-party actions)
rules:
  secrets-outside-env:
    ignore:
      - workflow-name.yml  # only if the workflow passes secrets to trusted actions
  excessive-permissions:
    ignore:
      - workflow-name.yml  # only if write permissions are required (e.g. posting PR comments)
```

Only add ignores for workflows where the finding is intentional and understood. Do not blanket-ignore rules.

### .ghalint.yml (optional)

Create `.ghalint.yml` at the repository root to exclude specific policies:

```yaml
excludes:
  - policy_name: job_timeout_minutes_is_required
    workflow_file_path: .github/workflows/special-case.yml
    job_name: long-running-job
```

## ghalint Binary Verification

ghalint does not provide a GitHub Action. The template uses `gh attestation verify` for SLSA provenance verification:

1. `gh release download` — Download the binary from GitHub Releases
2. `gh attestation verify` — Verify the binary was built by the official release workflow
3. `--signer-workflow` — Restrict to the specific build workflow for maximum security

This is more secure than checksums because it verifies the **build provenance** (who built it, from which repo, using which workflow), not just the file hash.

## Workflow Best Practices Applied

The template incorporates these security best practices:

- **`permissions: {}`** — Deny by default at workflow level; each job declares its own minimal permissions
- **`persist-credentials: false`** — Prevent token persistence in git config
- **`timeout-minutes`** — Prevent runaway jobs
- **`concurrency` + `cancel-in-progress`** — Cancel outdated runs on the same branch
- **`paths` filter** — Only trigger when workflow files or lint configs change
- **SHA-pinned actions** — All actions pinned to full commit SHAs
