#!/usr/bin/env bash
#
# Claude Code Plugin Installer
# Installs smart-commit-hook as a Claude Code marketplace plugin
#

set -euo pipefail

PLUGIN_NAME="smart-commit-hook"
MARKETPLACE_NAME="plugin-commit-hook"
GITHUB_OWNER="nan1010082085"
PLUGIN_SOURCE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_PLUGINS_DIR="$HOME/.claude/plugins"
INSTALLED_FILE="$CLAUDE_PLUGINS_DIR/installed_plugins.json"
KNOWN_FILE="$CLAUDE_PLUGINS_DIR/known_marketplaces.json"
MARKETPLACE_DIR="$CLAUDE_PLUGINS_DIR/marketplaces/${GITHUB_OWNER}-${MARKETPLACE_NAME}"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║       Smart Commit Hook - Claude Code Plugin Installer    ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if Claude Code plugins directory exists
if [[ ! -d "$CLAUDE_PLUGINS_DIR" ]]; then
    echo -e "${YELLOW}Creating Claude Code plugins directory...${NC}"
    mkdir -p "$CLAUDE_PLUGINS_DIR"
fi

# Get git commit SHA for versioning
PLUGIN_VERSION="$(cd "$PLUGIN_SOURCE" && git rev-parse --short HEAD 2>/dev/null || echo "1.0.0")"
CACHE_DIR="$CLAUDE_PLUGINS_DIR/cache/$MARKETPLACE_NAME/$PLUGIN_NAME/$PLUGIN_VERSION"

echo -e "${BLUE}Plugin version:${NC} $PLUGIN_VERSION"
echo -e "${BLUE}Installing to:${NC} $CACHE_DIR"
echo ""

# Step 1: Register marketplace in known_marketplaces.json
echo -e "${BLUE}[1/4] Registering marketplace...${NC}"

if [[ ! -f "$KNOWN_FILE" ]]; then
    echo -e "${RED}Error: known_marketplaces.json not found. Is Claude Code installed?${NC}"
    exit 1
fi

node -e "
const fs = require('fs');
const data = JSON.parse(fs.readFileSync('$KNOWN_FILE', 'utf8'));
data['$MARKETPLACE_NAME'] = {
    source: { source: 'github', repo: 'nan1010082085/plugin-commit-hook' },
    installLocation: '$MARKETPLACE_DIR',
    lastUpdated: new Date().toISOString()
};
fs.writeFileSync('$KNOWN_FILE', JSON.stringify(data, null, 2) + '\n');
console.log('Marketplace registered');
"

echo -e "${GREEN}✓ Marketplace registered${NC}"

# Step 2: Clone or update marketplace repo
echo -e "${BLUE}[2/4] Setting up marketplace...${NC}"

if [[ -d "$MARKETPLACE_DIR/.git" ]]; then
    echo -e "${YELLOW}Marketplace exists, updating...${NC}"
    (cd "$MARKETPLACE_DIR" && git pull --quiet 2>/dev/null) || true
else
    echo -e "${YELLOW}Cloning marketplace...${NC}"
    rm -rf "$MARKETPLACE_DIR"
    git clone --quiet https://github.com/nan1010082085/plugin-commit-hook.git "$MARKETPLACE_DIR"
fi

echo -e "${GREEN}✓ Marketplace ready${NC}"

# Step 3: Copy plugin to cache
echo -e "${BLUE}[3/4] Installing plugin files...${NC}"

mkdir -p "$CACHE_DIR"
cp -r "$PLUGIN_SOURCE/.claude-plugin" "$CACHE_DIR/"
cp -r "$PLUGIN_SOURCE/commands" "$CACHE_DIR/"
cp -r "$PLUGIN_SOURCE/skills" "$CACHE_DIR/"
cp "$PLUGIN_SOURCE/commit-classifier.sh" "$CACHE_DIR/"
cp "$PLUGIN_SOURCE/commit-types.json" "$CACHE_DIR/"
cp "$PLUGIN_SOURCE/LICENSE" "$CACHE_DIR/"
cp "$PLUGIN_SOURCE/README.md" "$CACHE_DIR/"
mkdir -p "$CACHE_DIR/.in_use"
chmod +x "$CACHE_DIR/commit-classifier.sh"

echo -e "${GREEN}✓ Plugin files installed${NC}"

# Step 4: Register in installed_plugins.json
echo -e "${BLUE}[4/4] Registering plugin...${NC}"

PLUGIN_KEY="${PLUGIN_NAME}@${MARKETPLACE_NAME}"

if grep -q "$PLUGIN_KEY" "$INSTALLED_FILE" 2>/dev/null; then
    echo -e "${YELLOW}Plugin already registered, updating...${NC}"
fi

node -e "
const fs = require('fs');
const data = JSON.parse(fs.readFileSync('$INSTALLED_FILE', 'utf8'));
data.plugins['$PLUGIN_KEY'] = [{
    scope: 'user',
    installPath: '$CACHE_DIR',
    version: '$PLUGIN_VERSION',
    installedAt: new Date().toISOString(),
    lastUpdated: new Date().toISOString(),
    gitCommitSha: '$PLUGIN_VERSION'
}];
fs.writeFileSync('$INSTALLED_FILE', JSON.stringify(data, null, 2) + '\n');
console.log('Plugin registered');
"

echo -e "${GREEN}✓ Plugin registered${NC}"

# Verify installation
echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                  Installation Complete!                    ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "Plugin:     ${BLUE}$PLUGIN_KEY${NC}"
echo -e "Version:    ${BLUE}$PLUGIN_VERSION${NC}"
echo -e "Cache:      ${BLUE}$CACHE_DIR${NC}"
echo -e "Marketplace: ${BLUE}$MARKETPLACE_DIR${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo -e "  1. ${BLUE}Restart Claude Code${NC} to load the plugin"
echo -e "  2. Use ${GREEN}/smart-commit${NC} command to auto-classify commits"
echo ""
echo -e "${YELLOW}Available commands:${NC}"
echo -e "  ${GREEN}/smart-commit${NC}        - Auto-classify and commit with smart message"
echo ""
