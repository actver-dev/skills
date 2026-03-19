# ActVer Skills

[English](README.md)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![ActVer](https://img.shields.io/badge/ActVer-actver.dev-blue)](https://actver.dev)
[![Buy Me a Coffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-support-orange?logo=buy-me-a-coffee&logoColor=white)](https://buymeacoffee.com/yetanother_yk)

[ActVer](https://actver.dev) の AI コーディングエージェント向けプラグイン＆スキル — GitHub Actions のバージョン取得、SHA ピン留め、ワークフローセキュリティ監査。

**Claude Code**、**Cursor**、**Copilot** など、[skills.sh 経由で 20 以上のエージェント](https://skills.sh)に対応。

## インストール

### A) Claude Code プラグイン（推奨）

```bash
claude plugin install actver-dev/skills
```

MCP サーバー、エージェント、全スキルが含まれます。

### B) スキルのみ（skills.sh 経由）

```bash
npx skills add actver-dev/skills
```

Claude Code、Cursor、Copilot など対応エージェントで利用可能。

### C) MCP サーバーのみ（手動追加）

`.mcp.json` に追加:

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

ローカルプロセスや API キーは不要です。

## スキル

| スキル | 説明 | プロンプト例 |
|--------|------|-------------|
| **pin-actions** | Actions を SHA にピン留め | 「ワークフローの Actions を SHA ピン留めして」 |
| **upgrade-actions** | 最新版にアップグレード | 「GitHub Actions を更新して」 |
| **audit-actions** | セキュリティ監査 | 「CI ワークフローを監査して」 |

## MCP ツール

| ツール | 説明 |
|--------|------|
| `get_action_version` | 最新バージョン、SHA、プリリリース情報を取得 |
| `list_action_versions` | 全メジャーバージョンと SHA を一覧表示 |

### 使用例

```
> actions/checkout の最新バージョンは？

actions/checkout v4.2.2 (sha: 11bd71901bbe5b1630ceea73d27597364c9af683)
Major: v4
Released: 2024-10-23T15:22:07Z
```

## サポート

ActVer は無料サービスです。もしお役に立てたら、ぜひご支援ください:

- [Buy Me a Coffee](https://buymeacoffee.com/yetanother_yk)
- [GitHub Sponsors](https://github.com/sponsors/actver-dev)

## ライセンス

[MIT](LICENSE)
