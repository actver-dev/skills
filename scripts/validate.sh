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
  if python3 -c "
import json, sys
d = json.load(open(sys.argv[1]))
assert isinstance(d.get('name'), str) and len(d['name']) > 0, 'missing name'
assert isinstance(d.get('owner'), dict), 'missing owner'
assert isinstance(d['owner'].get('name'), str), 'missing owner.name'
" "$marketplace_json" 2>/dev/null; then
    pass "marketplace.json has valid name and owner"
  else
    fail "marketplace.json — missing name or owner"
  fi

  if python3 -c "
import json, sys
d = json.load(open(sys.argv[1]))
plugins = d.get('plugins', [])
assert isinstance(plugins, list) and len(plugins) > 0, 'empty'
for p in plugins:
    assert 'name' in p, 'missing name'
    assert 'description' in p, 'missing description'
    assert 'source' in p, 'missing source'
" "$marketplace_json" 2>/dev/null; then
    pass "marketplace.json plugins have required fields (name, description, source)"
  else
    fail "marketplace.json plugins — missing required fields"
  fi

  # Check for duplicate plugin names
  if python3 -c "
import json, sys
d = json.load(open(sys.argv[1]))
names = [p['name'] for p in d.get('plugins', [])]
assert len(names) == len(set(names)), f'duplicate names: {[n for n in names if names.count(n) > 1]}'
" "$marketplace_json" 2>/dev/null; then
    pass "marketplace.json no duplicate plugin names"
  else
    fail "marketplace.json has duplicate plugin names"
  fi

  # Check plugins are sorted alphabetically
  if python3 -c "
import json, sys
d = json.load(open(sys.argv[1]))
names = [p['name'] for p in d.get('plugins', [])]
assert names == sorted(names), f'plugins not sorted: {names}'
" "$marketplace_json" 2>/dev/null; then
    pass "marketplace.json plugins are sorted"
  else
    fail "marketplace.json plugins are not sorted alphabetically"
  fi
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
# 3b. Agent frontmatter validation
# ─────────────────────────────────────────────
echo ""
echo "=== Agent frontmatter ==="

for agent_md in "$REPO_ROOT"/plugins/*/agents/*.md; do
  if [[ ! -f "$agent_md" ]]; then
    continue
  fi

  plugin_name="$(basename "$(dirname "$(dirname "$agent_md")")")"
  agent_name="$(basename "$agent_md" .md)"

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
" "$agent_md" 2>/dev/null; then
    pass "plugins/$plugin_name/agents/$agent_name.md — valid frontmatter"
  else
    fail "plugins/$plugin_name/agents/$agent_name.md — invalid or missing frontmatter"
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
      fail "agents/$agent_name: $link — broken link"
    fi
  done
done

# Check marketplace.json plugin source paths exist
echo ""
echo "=== Marketplace source validation ==="
if [[ -f "$marketplace_json" ]]; then
  paths=$(python3 -c "
import json, sys
d = json.load(open(sys.argv[1]))
for p in d.get('plugins', []):
    src = p.get('source', '')
    if isinstance(src, str) and src.startswith('./'):
        print(src.lstrip('./'))
" "$marketplace_json" 2>/dev/null || true)
  for p in $paths; do
    if [[ -d "$REPO_ROOT/$p" ]]; then
      pass "marketplace source: $p"
    else
      fail "marketplace source: $p — directory not found"
    fi
  done
fi

# ─────────────────────────────────────────────
# 5. Skills file manifest (for install verification)
# ─────────────────────────────────────────────
echo ""
echo "=== Skills file manifest ==="

manifest_file="$REPO_ROOT/scripts/expected-files.txt"
actual_files=$(cd "$REPO_ROOT" && find skills -type f | sort)

if [[ -f "$manifest_file" ]]; then
  expected_files=$(sort "$manifest_file")
  if [[ "$actual_files" == "$expected_files" ]]; then
    pass "Skills files match expected manifest"
  else
    fail "Skills files do not match expected manifest"
    diff <(echo "$expected_files") <(echo "$actual_files") || true
  fi
else
  fail "scripts/expected-files.txt not found — run './scripts/validate.sh' locally to generate it, then commit"
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
