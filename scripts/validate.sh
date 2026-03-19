#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
errors=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

pass() { echo -e "  ${GREEN}✓${NC} $1"; }
fail() { echo -e "  ${RED}✗${NC} $1"; errors=$((errors + 1)); }
warn() { echo -e "  ${YELLOW}!${NC} $1"; }

# ─────────────────────────────────────────────
# 1. Required files
# ─────────────────────────────────────────────
echo "=== Required files ==="

required_files=(
  "LICENSE"
  "README.md"
  "CLAUDE.md"
  ".gitignore"
  ".github/FUNDING.yml"
  ".claude-plugin/marketplace.json"
  "plugins/actver/.claude-plugin/plugin.json"
  "plugins/actver/.mcp.json"
  "plugins/actver/agents/actver.md"
)

for f in "${required_files[@]}"; do
  if [[ -f "$REPO_ROOT/$f" ]]; then
    pass "$f"
  else
    fail "$f — missing"
  fi
done

# ─────────────────────────────────────────────
# 2. JSON validation
# ─────────────────────────────────────────────
echo ""
echo "=== JSON validation ==="

json_files=(
  ".claude-plugin/marketplace.json"
  "plugins/actver/.claude-plugin/plugin.json"
  "plugins/actver/.mcp.json"
)

for f in "${json_files[@]}"; do
  filepath="$REPO_ROOT/$f"
  if [[ ! -f "$filepath" ]]; then
    fail "$f — file not found"
    continue
  fi
  if python3 -c "import json, sys; json.load(open(sys.argv[1]))" "$filepath" 2>/dev/null; then
    pass "$f — valid JSON"
  else
    fail "$f — invalid JSON"
  fi
done

# Check plugin.json required fields
echo ""
echo "=== plugin.json schema ==="
plugin_json="$REPO_ROOT/plugins/actver/.claude-plugin/plugin.json"
if [[ -f "$plugin_json" ]]; then
  for field in name description; do
    if python3 -c "import json, sys; d=json.load(open(sys.argv[1])); assert d.get('$field')" "$plugin_json" 2>/dev/null; then
      pass "plugin.json has '$field'"
    else
      fail "plugin.json missing '$field'"
    fi
  done
fi

# Check .mcp.json has a server with url
echo ""
echo "=== .mcp.json schema ==="
mcp_json="$REPO_ROOT/plugins/actver/.mcp.json"
if [[ -f "$mcp_json" ]]; then
  if python3 -c "
import json, sys
d = json.load(open(sys.argv[1]))
servers = list(d.values())
assert len(servers) > 0, 'no servers'
for s in servers:
    assert 'url' in s, 'missing url'
    assert s['url'].startswith('https://'), 'url must be https'
" "$mcp_json" 2>/dev/null; then
    pass ".mcp.json has valid server entry with https URL"
  else
    fail ".mcp.json — invalid server configuration"
  fi
fi

# Check marketplace.json structure
echo ""
echo "=== marketplace.json schema ==="
marketplace_json="$REPO_ROOT/.claude-plugin/marketplace.json"
if [[ -f "$marketplace_json" ]]; then
  for array in plugins skills; do
    if python3 -c "
import json, sys
d = json.load(open(sys.argv[1]))
items = d.get('$array', [])
assert isinstance(items, list) and len(items) > 0, 'empty'
for item in items:
    assert 'name' in item, 'missing name'
    assert 'path' in item, 'missing path'
" "$marketplace_json" 2>/dev/null; then
      pass "marketplace.json '$array' array is valid"
    else
      fail "marketplace.json '$array' — missing or invalid"
    fi
  done
fi

# ─────────────────────────────────────────────
# 3. SKILL.md frontmatter validation
# ─────────────────────────────────────────────
echo ""
echo "=== SKILL.md frontmatter ==="

for skill_dir in "$REPO_ROOT"/skills/*/; do
  skill_name="$(basename "$skill_dir")"
  skill_md="$skill_dir/SKILL.md"

  if [[ ! -f "$skill_md" ]]; then
    fail "skills/$skill_name/SKILL.md — missing"
    continue
  fi

  # Check YAML frontmatter exists and has required fields
  if python3 -c "
import sys, re

content = open(sys.argv[1]).read()
match = re.match(r'^---\n(.*?)\n---', content, re.DOTALL)
assert match, 'no frontmatter'

fm = match.group(1)
assert 'name:' in fm, 'missing name'
assert 'description:' in fm, 'missing description'

# Check description is not empty
for line in fm.splitlines():
    if line.startswith('description:'):
        desc = line.split(':', 1)[1].strip()
        assert len(desc) > 20, 'description too short'
        break
" "$skill_md" 2>/dev/null; then
    pass "skills/$skill_name/SKILL.md — valid frontmatter"
  else
    fail "skills/$skill_name/SKILL.md — invalid or missing frontmatter"
  fi
done

# ─────────────────────────────────────────────
# 4. Relative link validation
# ─────────────────────────────────────────────
echo ""
echo "=== Relative link validation ==="

# Check links in SKILL.md files
for skill_dir in "$REPO_ROOT"/skills/*/; do
  skill_name="$(basename "$skill_dir")"
  skill_md="$skill_dir/SKILL.md"

  if [[ ! -f "$skill_md" ]]; then
    continue
  fi

  # Extract relative links from markdown (handles multiple links per line)
  links=$(python3 -c "
import re, sys
for line in open(sys.argv[1]):
    for m in re.findall(r'\]\(([^)]+)\)', line):
        if not m.startswith('http'):
            print(m)
" "$skill_md" 2>/dev/null || true)
  for link in $links; do
    target="$skill_dir/$link"
    if [[ -f "$target" ]]; then
      pass "skills/$skill_name: $link"
    else
      fail "skills/$skill_name: $link — broken link"
    fi
  done
done

# Check links in agent files
for agent_md in "$REPO_ROOT"/plugins/*/agents/*.md; do
  if [[ ! -f "$agent_md" ]]; then
    continue
  fi
  agent_name="$(basename "$agent_md")"
  links=$(python3 -c "
import re, sys
for line in open(sys.argv[1]):
    for m in re.findall(r'\]\(([^)]+)\)', line):
        if not m.startswith('http'):
            print(m)
" "$agent_md" 2>/dev/null || true)
  for link in $links; do
    target="$(dirname "$agent_md")/$link"
    if [[ -f "$target" ]]; then
      pass "agents/$agent_name: $link"
    else
      warn "agents/$agent_name: $link — link not found (may be intentional)"
    fi
  done
done

# Check marketplace.json paths exist
echo ""
echo "=== Marketplace path validation ==="
if [[ -f "$marketplace_json" ]]; then
  paths=$(python3 -c "
import json, sys
d = json.load(open(sys.argv[1]))
for section in ['plugins', 'skills']:
    for item in d.get(section, []):
        print(item['path'])
" "$marketplace_json" 2>/dev/null || true)
  for p in $paths; do
    if [[ -d "$REPO_ROOT/$p" ]]; then
      pass "marketplace path: $p"
    else
      fail "marketplace path: $p — directory not found"
    fi
  done
fi

# ─────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────
echo ""
if [[ $errors -eq 0 ]]; then
  echo -e "${GREEN}All checks passed!${NC}"
  exit 0
else
  echo -e "${RED}$errors check(s) failed.${NC}"
  exit 1
fi
