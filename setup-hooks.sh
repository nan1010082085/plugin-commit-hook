#!/usr/bin/env bash
#
# Setup Git Hooks for Smart Commit
# This script installs the commit-msg hook to validate commit messages
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_DIR="$(git rev-parse --git-dir)/hooks"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Installing Smart Commit Git Hooks...${NC}"

# Create hooks directory if it doesn't exist
mkdir -p "$HOOKS_DIR"

# Create commit-msg hook
cat > "$HOOKS_DIR/commit-msg" << 'EOF'
#!/usr/bin/env bash
#
# Commit message validation hook
# Validates that commit messages follow Conventional Commits format
#

commit_msg_file="$1"
commit_msg=$(cat "$commit_msg_file")

# Skip merge commits
if echo "$commit_msg" | grep -q "^Merge"; then
    exit 0
fi

# Conventional Commits pattern
pattern='^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\([a-zA-Z0-9_-]+\))?!?: .{1,72}'

if ! echo "$commit_msg" | head -1 | grep -qE "$pattern"; then
    echo ""
    echo "❌ Invalid commit message format!"
    echo ""
    echo "Expected: type(scope): description"
    echo ""
    echo "Types: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert"
    echo ""
    echo "Examples:"
    echo "  feat(auth): add login functionality"
    echo "  fix: resolve null pointer exception"
    echo "  docs(api): update endpoint documentation"
    echo ""
    echo "Your message:"
    echo "  $(echo "$commit_msg" | head -1)"
    echo ""
    exit 1
fi

# Check title length
title=$(echo "$commit_msg" | head -1)
if [[ ${#title} -gt 72 ]]; then
    echo ""
    echo "⚠️  Commit title is too long (${#title} chars, max 72)"
    echo "  $title"
    echo ""
    exit 1
fi

# Check for ticket ID (optional warning)
branch=$(git branch --show-current 2>/dev/null || echo "")
if [[ -n "$branch" ]]; then
    ticket=$(echo "$branch" | grep -oE '[A-Z]+-[0-9]+' | head -1 || true)
    if [[ -n "$ticket" ]]; then
        if ! echo "$commit_msg" | grep -q "$ticket"; then
            echo ""
            echo "💡 Tip: Branch contains ticket $ticket, consider adding it to commit message"
            echo ""
        fi
    fi
fi

exit 0
EOF

chmod +x "$HOOKS_DIR/commit-msg"

echo -e "${GREEN}✅ commit-msg hook installed${NC}"

# Create pre-commit hook (optional)
cat > "$HOOKS_DIR/pre-commit" << 'EOF'
#!/usr/bin/env bash
#
# Pre-commit hook
# Runs checks before allowing commit
#

echo "🔍 Running pre-commit checks..."

# Check for secrets
if git diff --cached --name-only | xargs grep -l "PRIVATE_KEY\|SECRET\|PASSWORD\|API_KEY" 2>/dev/null; then
    echo ""
    echo "❌ Potential secrets detected in staged files!"
    echo "Please review and remove any sensitive data before committing."
    echo ""
    exit 1
fi

# Check for common issues
if git diff --cached --name-only | grep -qE '\.env$|credentials\.json$|secrets\.yaml$'; then
    echo ""
    echo "⚠️  Warning: Sensitive file detected in staged changes"
    echo "Files: $(git diff --cached --name-only | grep -E '\.env$|credentials\.json$|secrets\.yaml$')"
    echo ""
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo "✅ Pre-commit checks passed"
exit 0
EOF

chmod +x "$HOOKS_DIR/pre-commit"

echo -e "${GREEN}✅ pre-commit hook installed${NC}"

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}                    Setup Complete!                        ${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}Git hooks installed successfully!${NC}"
echo ""
echo "Hooks installed:"
echo "  • commit-msg: Validates commit message format"
echo "  • pre-commit: Checks for secrets and sensitive files"
echo ""
echo "Usage:"
echo "  • Use conventional commits format: type(scope): description"
echo "  • Or run: ${YELLOW}./commit-classifier.sh${NC} for auto-classification"
echo ""
echo "Commit types: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert"
echo ""
