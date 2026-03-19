# CLAUDE.md

## Overview

ActVer plugin & skills for AI coding agents.
GitHub Actions の最新バージョン・SHA 情報の取得、SHA ピン留め、ワークフロー監査を提供する。

## Structure

- `plugins/actver/` — Claude Code プラグイン（MCP + エージェント）
- `skills/` — スキル定義（skills.sh 互換、マルチエージェント対応）

## MCP Server

- **URL**: `https://actver.dev/mcp`
- **Transport**: StreamableHTTP（リモート、ローカルプロセス不要）
- **認証**: 不要

## Tools

| Tool | Description |
|------|-------------|
| `get_action_version` | アクションの最新バージョン・SHA を取得 |
| `list_action_versions` | メジャーバージョン一覧を取得 |

## License

MIT
