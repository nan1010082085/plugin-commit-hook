# Smart Commit Hook Plugin

Intelligent commit hook that auto-classifies commits, generates meaningful titles, and creates detailed descriptions following the [Conventional Commits](https://www.conventionalcommits.org/) specification.

> 📖 **New to the plugin?** Check out the [Quick Start Guide](QUICKSTART.md) to get up and running in 3 steps!
>
> 🔧 **Need CLI or Node.js integration?** See the [CLI & Integration Guide](CLI.md)

## Overview

This plugin provides:

1. **Claude Code Plugin** - `/smart-commit` slash command for Claude Code
2. **Node.js Module** - Programmatic API for any Node.js application
3. **CLI Tool** - `smart-commit` command for terminal usage
4. **Standalone Script** - `commit-classifier.sh` for use by any agent or tool
5. **Classification Rules** - Configurable `commit-types.json` for custom types

## Features

- 🎯 **Auto-Classification** - Automatically detects commit type based on changes
- 📝 **Smart Titles** - Generates concise, imperative-mood titles
- 📋 **Detailed Descriptions** - Creates comprehensive commit bodies
- 🔍 **Scope Detection** - Identifies affected areas of the codebase
- ⚠️ **Breaking Change Detection** - Flags breaking changes automatically
- 🎫 **Ticket ID Extraction** - Extracts JIRA/ticket IDs from branch names
- 🌈 **Emoji Support** - Adds appropriate emojis to commit types

## Commit Types

| Type | Emoji | Description |
|------|-------|-------------|
| `feat` | ✨ | A new feature |
| `fix` | 🐛 | A bug fix |
| `docs` | 📝 | Documentation only changes |
| `style` | 💄 | Formatting, missing semi colons, etc |
| `refactor` | ♻️ | Code change that neither fixes a bug nor adds a feature |
| `perf` | ⚡ | A code change that improves performance |
| `test` | ✅ | Adding missing or correcting existing tests |
| `build` | 📦 | Changes to build system or dependencies |
| `ci` | 🔧 | Changes to CI configuration |
| `chore` | 🔨 | Other changes that don't modify src or test |
| `revert` | ⏪ | Reverts a previous commit |

## Installation

### As Claude Code Plugin

1. Copy the plugin to your Claude Code plugins directory:
   ```bash
   cp -r /path/to/commit-hook ~/.claude/plugins/
   ```

2. Add to your installed plugins:
   ```json
   {
     "smart-commit-hook@local": [
       {
         "scope": "user",
         "installPath": "~/.claude/plugins/commit-hook",
         "version": "1.0.0"
       }
     ]
   }
   ```

3. Restart Claude Code

4. Use the `/smart-commit` command

### As Node.js CLI

1. Clone and link:
   ```bash
   git clone git@github.com:nan1010082085/plugin-commit-hook.git
   cd plugin-commit-hook
   npm link
   ```

2. Use the `smart-commit` command:
   ```bash
   smart-commit --help
   smart-commit --classify
   smart-commit --dry-run
   ```

### As Standalone Script

1. Make the script executable:
   ```bash
   chmod +x commit-classifier.sh
   ```

2. Run it:
   ```bash
   ./commit-classifier.sh [options]
   ```

3. (Optional) Add to PATH:
   ```bash
   echo 'export PATH="$PATH:/path/to/commit-hook"' >> ~/.bashrc
   source ~/.bashrc
   ```

### As npm Dependency

```bash
npm install git@github.com:nan1010082085/plugin-commit-hook.git
```

```json
{
  "dependencies": {
    "smart-commit-hook": "git@github.com:nan1010082085/plugin-commit-hook.git"
  }
}
```

## Usage

### Claude Code Plugin

```bash
# In Claude Code, use the slash command:
/smart-commit

# The plugin will:
# 1. Analyze your staged changes
# 2. Classify the commit type
# 3. Generate a commit message
# 4. Create the commit
```

### Standalone Script

```bash
# Basic usage - classify and commit staged changes
./commit-classifier.sh

# Stage all changes and commit
./commit-classifier.sh --auto-stage

# Preview without committing
./commit-classifier.sh --dry-run

# Get JSON output
./commit-classifier.sh --json --dry-run

# Combine options
./commit-classifier.sh --auto-stage --dry-run --json
```

### Integration with Other Agents

The standalone script can be integrated with any agent or tool:

```bash
# In your agent's code:
result=$(./commit-classifier.sh --json --dry-run)
type=$(echo "$result" | jq -r '.classification.type')
title=$(echo "$result" | jq -r '.message.title')
```

## How It Works

### 1. Analysis Phase

The classifier examines:
- **Staged files** - File types and locations
- **Diff content** - Code changes and patterns
- **Branch name** - For ticket IDs and context
- **Commit history** - For style consistency

### 2. Classification Logic

Priority-based classification:
1. Check for `revert` patterns
2. Check for `fix` patterns (bugs, errors, issues)
3. Check for `feat` patterns (new functionality)
4. Check for `perf` patterns (optimization)
5. Check for `refactor` patterns (restructuring)
6. Check for `test` patterns (test files only)
7. Check for `docs` patterns (documentation only)
8. Check for `style` patterns (formatting only)
9. Check for `build` patterns (dependencies)
10. Check for `ci` patterns (CI/CD config)
11. Default to `chore`

### 3. Message Generation

Following Conventional Commits:
```
<type>(<scope>): <title>

<body>

<footer>
```

## Configuration

### commit-types.json

Customize commit types and detection patterns:

```json
{
  "types": {
    "custom-type": {
      "description": "Your custom type",
      "emoji": "🎯",
      "patterns": ["pattern1", "pattern2"],
      "filePatterns": ["*.custom"]
    }
  }
}
```

### Scope Detection

The plugin automatically detects scopes from:
- Directory structure (`src/api/` → `api`)
- Component names (`UserProfile.tsx` → `user`)
- Common patterns (`auth/`, `ui/`, `db/`)

### Breaking Changes

Automatically detected when:
- `BREAKING CHANGE:` appears in diff
- Public API signatures change
- Database schema changes
- Configuration format changes

## Examples

### Example 1: New Feature

**Staged changes:**
```typescript
// src/components/UserProfile.tsx
export function UserProfile({ user }: Props) {
  return <div>{user.name}</div>;
}
```

**Generated commit:**
```
feat(components): add UserProfile component

Implement new user profile display component.

Summary:
- Files changed: 1
- Lines added: 4
- Lines removed: 0

Co-authored-by: Claude <noreply@anthropic.com>
```

### Example 2: Bug Fix

**Staged changes:**
```typescript
// src/utils/auth.ts
- const isValid = token.length > 0;
+ const isValid = token && token.length > 0;
```

**Generated commit:**
```
fix(auth): resolve token validation issue

Fix bug where null token caused validation error.

Summary:
- Files changed: 1
- Lines added: 1
- Lines removed: 1

Co-authored-by: Claude <noreply@anthropic.com>
```

### Example 3: Documentation Update

**Staged changes:**
```markdown
// README.md
# Updated installation instructions
```

**Generated commit:**
```
docs: update README

Update documentation with new installation instructions.

Summary:
- Files changed: 1
- Lines added: 1
- Lines removed: 0

Co-authored-by: Claude <noreply@anthropic.com>
```

## Integration Guide

### With CI/CD Pipelines

```yaml
# .github/workflows/commit-check.yml
- name: Validate commit message
  run: |
    MSG=$(git log -1 --pretty=%B)
    if ! echo "$MSG" | grep -qE '^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\(.+\))?:'; then
      echo "Invalid commit message format"
      exit 1
    fi
```

### With Git Hooks

```bash
# .git/hooks/commit-msg
#!/bin/bash
# Validate commit message format
MSG=$(cat "$1")
if ! echo "$MSG" | grep -qE '^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\(.+\))?:'; then
  echo "Invalid commit message format. Use: type(scope): description"
  exit 1
fi
```

### With Node.js

```javascript
const { classify, generateMessage, commit } = require('smart-commit-hook');

// Classify staged changes
const classification = await classify();
console.log(`Type: ${classification.classification.type}`);
console.log(`Title: ${classification.message.title}`);

// Generate message with stats
const message = await generateMessage();
console.log(message.fullMessage);

// Auto commit
const result = await commit({ autoStage: true });
console.log(`Committed: ${result.commitHash}`);
```

See [CLI.md](CLI.md) for full Node.js API documentation.

### With Other AI Agents

```python
import subprocess
import json

def classify_commit():
    result = subprocess.run(
        ['node', '-e', "require('smart-commit-hook').classify().then(r => console.log(JSON.stringify(r)))"],
        capture_output=True,
        text=True
    )
    return json.loads(result.stdout)

# Use in your agent
classification = classify_commit()
print(f"Type: {classification['classification']['type']}")
print(f"Title: {classification['message']['title']}")
```

## Troubleshooting

### No staged changes

**Error:** `No staged changes to commit`

**Solution:** Stage files first:
```bash
git add <files>
# or
git add -A
```

### Not a git repository

**Error:** `Not a git repository`

**Solution:** Initialize git or navigate to a git repository:
```bash
git init
# or
cd /path/to/git/repo
```

### Permission denied

**Error:** `Permission denied`

**Solution:** Make script executable:
```bash
chmod +x commit-classifier.sh
```

## Development

### Adding New Commit Types

1. Edit `commit-types.json`
2. Add type definition with patterns
3. Update `classify_changes()` in script
4. Update `generate_commit_message()` in script

### Testing

```bash
# Test classification
./commit-classifier.sh --dry-run --json

# Test with specific changes
echo "test" > test.txt
git add test.txt
./commit-classifier.sh --dry-run
```

## Requirements

- **Git** must be installed and configured
- **Node.js** >= 14.0.0 (for CLI and Node.js API only)
- No external dependencies required (pure implementation)

### Optional Dependencies

- **GitHub CLI (`gh`)** - For creating pull requests with `/commit-push-pr`
- **Claude Code** - For using the `/smart-commit` slash command

## License

MIT License

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes (using this tool!)
4. Push to the branch
5. Create a Pull Request

## Author

Custom Development

## Version

1.0.0
