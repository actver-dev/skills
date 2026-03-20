# ActVer Skills

[日本語](README.ja.md)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![ActVer](https://img.shields.io/badge/ActVer-actver.dev-blue)](https://actver.dev)
[![Buy Me a Coffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-support-orange?logo=buy-me-a-coffee&logoColor=white)](https://buymeacoffee.com/yetanother_yk)

[ActVer](https://actver.dev) plugin & skills for AI coding agents — GitHub Actions version lookup, SHA pinning, and workflow security auditing.

Works with **Claude Code**, **Cursor**, **Copilot**, and [20+ other agents via skills.sh](https://skills.sh).

## Install

### A) Claude Code Plugin (recommended)

```bash
claude plugin marketplace add actver-dev/skills
claude plugin install actver
```

Includes MCP server, agent, and all skills.

### B) Skills only (via skills.sh)

```bash
npx skills add actver-dev/skills
```

Works with Claude Code, Cursor, Copilot, and other supported agents.

### C) MCP server only (manual)

Add to your `.mcp.json`:

```json
{
  "mcpServers": {
    "actver": {
      "type": "http",
      "url": "https://actver.dev/mcp"
    }
  }
}
```

No local process or API key required.

## Skills

| Skill | Description | Example prompts |
|-------|-------------|-----------------|
| **pin-actions** | Pin actions to SHA | "Pin my workflow actions to SHA" |
| **upgrade-actions** | Upgrade to latest | "Update my GitHub Actions" |
| **audit-actions** | Security audit | "Audit my CI workflows" |

## MCP Tools

| Tool | Description |
|------|-------------|
| `get_action_version` | Get latest version, SHA, and prerelease info |
| `list_action_versions` | List all major versions with SHAs |

### Example

```
> What's the latest version of actions/checkout?

actions/checkout v4.2.2 (sha: 11bd71901bbe5b1630ceea73d27597364c9af683)
Major: v4
Released: 2024-10-23T15:22:07Z
```

## Support

ActVer is a free service. If you find it useful, consider supporting us:

- [Buy Me a Coffee](https://buymeacoffee.com/yetanother_yk)
- [GitHub Sponsors](https://github.com/sponsors/actver-dev)

## License

[MIT](LICENSE)
