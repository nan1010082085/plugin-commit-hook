#!/usr/bin/env bash
#
# Claude Code Plugin Installer
# Installs smart-commit-hook as a Claude Code plugin
#

set -euo pipefail

PLUGIN_NAME="smart-commit-hook"
PLUGIN_SOURCE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_PLUGINS_DIR="$HOME/.claude/plugins"
INSTALLED_FILE="$CLAUDE_PLUGINS_DIR/installed_plugins.json"

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

# Create cache directory for our plugin
PLUGIN_INSTALL_DIR="$CLAUDE_PLUGINS_DIR/cache/custom/$PLUGIN_NAME/1.0.0"
echo -e "${BLUE}Installing plugin to:${NC} $PLUGIN_INSTALL_DIR"

# Create directory
mkdir -p "$PLUGIN_INSTALL_DIR"

# Copy plugin files
echo -e "${BLUE}Copying plugin files...${NC}"
cp -r "$PLUGIN_SOURCE/.claude-plugin" "$PLUGIN_INSTALL_DIR/"
cp -r "$PLUGIN_SOURCE/commands" "$PLUGIN_INSTALL_DIR/"
cp -r "$PLUGIN_SOURCE/skills" "$PLUGIN_INSTALL_DIR/"
cp "$PLUGIN_SOURCE/commit-classifier.sh" "$PLUGIN_INSTALL_DIR/"
cp "$PLUGIN_SOURCE/commit-types.json" "$PLUGIN_INSTALL_DIR/"
cp "$PLUGIN_SOURCE/LICENSE" "$PLUGIN_INSTALL_DIR/"
cp "$PLUGIN_SOURCE/README.md" "$PLUGIN_INSTALL_DIR/"

# Create .in_use directory (required by Claude Code plugin system)
mkdir -p "$PLUGIN_INSTALL_DIR/.in_use"

# Make scripts executable
chmod +x "$PLUGIN_INSTALL_DIR/commit-classifier.sh"

echo -e "${GREEN}✓ Plugin files copied${NC}"

# Update installed_plugins.json
echo -e "${BLUE}Updating installed plugins registry...${NC}"

if [[ ! -f "$INSTALLED_FILE" ]]; then
    # Create new file
    cat > "$INSTALLED_FILE" << EOF
{
  "version": 2,
  "plugins": {
    "${PLUGIN_NAME}@custom": [
      {
        "scope": "user",
        "installPath": "$PLUGIN_INSTALL_DIR",
        "version": "1.0.0",
        "installedAt": "$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")",
        "lastUpdated": "$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")"
      }
    ]
  }
}
EOF
else
    # Check if plugin already exists
    if grep -q "${PLUGIN_NAME}@custom" "$INSTALLED_FILE"; then
        echo -e "${YELLOW}Plugin already registered, updating...${NC}"
        # Use node to update JSON properly
        node -e "
const fs = require('fs');
const data = JSON.parse(fs.readFileSync('$INSTALLED_FILE', 'utf8'));
data.plugins['${PLUGIN_NAME}@custom'] = [{
    scope: 'user',
    installPath: '$PLUGIN_INSTALL_DIR',
    version: '1.0.0',
    installedAt: new Date().toISOString(),
    lastUpdated: new Date().toISOString()
}];
fs.writeFileSync('$INSTALLED_FILE', JSON.stringify(data, null, 2) + '\n');
"
    else
        # Add new plugin entry
        node -e "
const fs = require('fs');
const data = JSON.parse(fs.readFileSync('$INSTALLED_FILE', 'utf8'));
data.plugins['${PLUGIN_NAME}@custom'] = [{
    scope: 'user',
    installPath: '$PLUGIN_INSTALL_DIR',
    version: '1.0.0',
    installedAt: new Date().toISOString(),
    lastUpdated: new Date().toISOString()
}];
fs.writeFileSync('$INSTALLED_FILE', JSON.stringify(data, null, 2) + '\n');
"
    fi
fi

echo -e "${GREEN}✓ Plugin registered${NC}"

# Verify installation
echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                  Installation Complete!                    ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "Plugin installed to: ${BLUE}$PLUGIN_INSTALL_DIR${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo -e "  1. ${BLUE}Restart Claude Code${NC} to load the plugin"
echo -e "  2. Use ${GREEN}/smart-commit${NC} command to auto-classify commits"
echo ""
echo -e "${YELLOW}Available commands:${NC}"
echo -e "  ${GREEN}/smart-commit${NC}        - Auto-classify and commit with smart message"
echo ""
echo -e "${YELLOW}Test installation:${NC}"
echo -e "  cd $PLUGIN_INSTALL_DIR"
echo -e "  ./commit-classifier.sh --help"
echo ""
