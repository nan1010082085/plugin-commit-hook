# Quick Start Guide

## 🚀 Get Started in 3 Steps

### Step 1: Setup Git Hooks (Optional)

```bash
cd /path/to/your/project
/path/to/commit-hook/setup-hooks.sh
```

This installs validation hooks to ensure commit messages follow Conventional Commits.

### Step 2: Use the Smart Commit Classifier

#### Option A: Standalone Script (Works with any agent)

```bash
# Stage your changes
git add <files>

# Auto-classify and commit
./commit-classifier.sh

# Or preview without committing
./commit-classifier.sh --dry-run

# Stage everything and commit
./commit-classifier.sh --auto-stage

# Get JSON output for integration
./commit-classifier.sh --json --dry-run
```

#### Option B: Claude Code Plugin

```bash
# In Claude Code, use the slash command:
/smart-commit
```

### Step 3: Review the Commit

The tool will:
1. Analyze your staged changes
2. Detect the commit type (feat, fix, docs, etc.)
3. Generate a formatted commit message
4. Create the commit (unless --dry-run)

## 📋 Example Workflow

```bash
# 1. Make changes to your code
vim src/api/users.ts

# 2. Stage the changes
git add src/api/users.ts

# 3. Run the classifier
./commit-classifier.sh

# Output:
# ═══════════════════════════════════════════════════════════════
#                     📊 Commit Analysis
# ═══════════════════════════════════════════════════════════════
#
#   Type:       feat
#   Scope:      api
#   Breaking:   false
#   Confidence: high
#
# ═══════════════════════════════════════════════════════════════
#                     📝 Commit Message
# ═══════════════════════════════════════════════════════════════
#
# feat(api): add new functionality
#
# Implement new feature based on staged changes.
#
# Summary:
# - Files changed: 1
# - Lines added: 25
# - Lines removed: 0
#
# Co-authored-by: Claude <noreply@anthropic.com>
```

## 🔧 Integration with Other Tools

### With Python

```python
import subprocess
import json

def smart_commit():
    result = subprocess.run(
        ['./commit-classifier.sh', '--json', '--dry-run'],
        capture_output=True,
        text=True
    )
    return json.loads(result.stdout)

# Use in your agent
info = smart_commit()
print(f"Type: {info['classification']['type']}")
print(f"Title: {info['message']['title']}")
```

### With Node.js

```javascript
const { execSync } = require('child_process');

function smartCommit() {
    const result = execSync('./commit-classifier.sh --json --dry-run', {
        encoding: 'utf-8'
    });
    return JSON.parse(result);
}

const info = smartCommit();
console.log(`Type: ${info.classification.type}`);
console.log(`Title: ${info.message.title}`);
```

### With Shell Scripts

```bash
# Get classification only
classification=$(./commit-classifier.sh --json --dry-run | jq -r '.classification.type')

# Get title only
title=$(./commit-classifier.sh --json --dry-run | jq -r '.message.title')
```

## 📚 Commit Types Reference

| Type | When to Use | Example |
|------|-------------|---------|
| `feat` | New feature | `feat(auth): add OAuth2 support` |
| `fix` | Bug fix | `fix(api): handle null response` |
| `docs` | Documentation | `docs(readme): update installation` |
| `style` | Formatting | `style: fix indentation` |
| `refactor` | Code restructure | `refactor(utils): extract helpers` |
| `perf` | Performance | `perf(query): add database index` |
| `test` | Tests | `test(auth): add login tests` |
| `build` | Build system | `build(deps): upgrade React` |
| `ci` | CI/CD | `ci(actions): add deploy workflow` |
| `chore` | Maintenance | `chore: update gitignore` |
| `revert` | Revert changes | `revert: undo breaking change` |

## ❓ FAQ

**Q: Can I customize commit types?**
A: Yes! Edit `commit-types.json` to add or modify types.

**Q: Does it work with existing git hooks?**
A: Yes, the hooks are designed to work alongside existing ones.

**Q: What if I want to override the classification?**
A: Commit manually with your own message, or use `--dry-run` to preview and adjust.

**Q: Is it safe for production use?**
A: Yes, it only reads staged changes and never modifies your code.

## 🐛 Troubleshooting

**"No staged changes"**
- Stage files first: `git add <files>`
- Or use `--auto-stage` flag

**"Not a git repository"**
- Navigate to a git repo: `cd /path/to/repo`
- Or initialize: `git init`

**"Permission denied"**
- Make executable: `chmod +x commit-classifier.sh`

## 📖 More Information

- See [README.md](README.md) for full documentation
- See [commit-types.json](commit-types.json) for type definitions
- See [commands/smart-commit.md](commands/smart-commit.md) for Claude Code plugin details
