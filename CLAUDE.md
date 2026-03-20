# CLAUDE.md

## Overview

ActVer plugin & skills for AI coding agents.
GitHub Actions の最新バージョン・SHA 情報の取得、SHA ピン留め、ワークフロー監査を提供する。

## Repository

- **GitHub**: https://github.com/actver-dev/skills
- **Parent**: https://github.com/yk-works/act-ver (非公開、API/MCP サーバー本体)
- **License**: MIT

## Structure

- `plugins/actver/` — Claude Code プラグイン（MCP + エージェント）
  - `.claude-plugin/plugin.json` — プラグインメタデータ
  - `.mcp.json` — リモート MCP サーバー接続設定
  - `agents/actver.md` — エージェント定義
  - `skills/` → `../../skills/` へのシンボリックリンク
- `skills/` — スキル定義（skills.sh 互換、マルチエージェント対応）
  - `pin-actions/`, `upgrade-actions/`, `audit-actions/`
  - 各スキル: `SKILL.md` + `references/`
- `.claude-plugin/marketplace.json` — Claude Code マーケットプレイス登録
- `scripts/validate.sh` — 構造・JSON・frontmatter・リンク・マニフェスト検証
- `scripts/expected-files.txt` — スキルファイルのマニフェスト（CI で一致確認）

## Git Workflow

- **main**: プロダクション（ブランチ保護あり）
- PR 必須、CI（validate + skills-install）パス必須
- Admin は PR レビュー要件をバイパス可能
- squash merge のみ

## Commands

- `./scripts/validate.sh` — 全バリデーション実行
- `task validate` — Taskfile 経由のバリデーション
- `task docker:test` — Docker でクリーン環境の skills add テスト（CI の skills-install job と同等）
- `claude plugin validate .` — Claude Code プラグインバリデーション
- `npx skills add . --yes` — ローカルからスキルインストール（テスト用）

## Validation Checks (scripts/validate.sh)

- 必須ファイル存在確認
- JSON バリデーション（marketplace.json, plugin.json, .mcp.json）
- marketplace.json: name, owner, plugins 必須フィールド、重複チェック、ソート順
- plugin.json: name, description 必須
- .mcp.json: https URL 必須
- SKILL.md frontmatter: name, description（20 文字以上）必須
- Agent frontmatter: name, description 必須
- 相対リンク切れチェック
- expected-files.txt とのマニフェスト一致確認

## Key Patterns

- SKILL.md の description は三人称（"This skill should be used when..."）でトリガーフレーズを豊富に
- スキル間の cross-skill ハンドオフを Notes に明記（audit → pin/upgrade）
- MCP ツールを優先、REST API はフォールバック

## Review Guidelines

- スキル（SKILL.md）を追加・更新したら `skill-creator:skill-creator` エージェントで品質チェック
- プラグイン構造を変更したら `plugin-dev:plugin-validator` エージェントでバリデーション
- エージェント定義を変更したら `plugin-dev:skill-reviewer` エージェントで確認
- PR 前に `./scripts/validate.sh` を実行して全チェックパスを確認

## MCP Server

- **URL**: `https://actver.dev/mcp`
- **Transport**: StreamableHTTP（リモート、ローカルプロセス不要）
- **認証**: 不要

## Tools

| Tool | Description |
|------|-------------|
| `get_action_version` | アクションの最新バージョン・SHA を取得 |
| `list_action_versions` | メジャーバージョン一覧を取得 |
