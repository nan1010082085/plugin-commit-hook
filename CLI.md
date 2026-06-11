# CLI & Integration Guide

## 📦 Node.js Integration

### Installation

```bash
# Clone the repository
git clone git@github.com:nan1010082085/plugin-commit-hook.git
cd plugin-commit-hook

# Install dependencies (none required, but needed for npm link)
npm install

# Link globally for CLI usage
npm link
```

After `npm link`, you can use `smart-commit` command anywhere.

### As npm dependency

```json
{
  "dependencies": {
    "smart-commit-hook": "git@github.com:nan1010082085/plugin-commit-hook.git"
  }
}
```

Or install directly:

```bash
npm install git@github.com:nan1010082085/plugin-commit-hook.git
```

### Programmatic API

```javascript
const {
  classify,
  generateMessage,
  commit,
  getGitStatus,
  getStagedStats,
  installHooks,
  loadConfig,
  COMMIT_TYPES,
  TYPE_EMOJIS
} = require('smart-commit-hook');
```

#### classify(options?)

Classify staged changes without committing.

```javascript
const result = await classify();
console.log(result);
// {
//   classification: {
//     type: 'feat',
//     scope: 'api',
//     is_breaking: false,
//     confidence: 'high',
//     ticket_id: 'PROJ-123',
//     reasons: 'Changes add new functionality'
//   },
//   message: {
//     title: 'feat(api): add user endpoint',
//     full: 'feat(api): add user endpoint\n\n...'
//   }
// }
```

**Options:**
- `cwd` (string): Working directory (default: process.cwd())

#### generateMessage(options?)

Generate commit message with stats.

```javascript
const result = await generateMessage();
console.log(result.type);       // 'feat'
console.log(result.title);      // 'feat(api): add user endpoint'
console.log(result.fullMessage); // Full commit message
console.log(result.stats);      // { files: 3, added: 45, removed: 12 }
```

**Options:**
- `cwd` (string): Working directory (default: process.cwd())

#### commit(options?)

Create an auto-classified commit.

```javascript
// Standard commit
const result = await commit();

// Auto stage all changes
const result = await commit({ autoStage: true });

// Dry run (preview only)
const result = await commit({ dryRun: true });

console.log(result.success);      // true
console.log(result.commitHash);   // 'abc123...'
console.log(result.classification); // { type: 'feat', ... }
```

**Options:**
- `autoStage` (boolean): Stage all changes before commit (default: false)
- `dryRun` (boolean): Preview without committing (default: false)
- `cwd` (string): Working directory (default: process.cwd())

#### getGitStatus(cwd?)

Get current git status.

```javascript
const status = getGitStatus();
console.log(status.branch);          // 'main'
console.log(status.staged);          // ['file1.js', 'file2.js']
console.log(status.hasStagedChanges); // true
```

#### getStagedStats(cwd?)

Get detailed stats for staged changes.

```javascript
const stats = getStagedStats();
console.log(stats.totalFiles);  // 3
console.log(stats.totalAdded);  // 45
console.log(stats.totalRemoved); // 12
console.log(stats.fileStats);   // [{ file: '...', added: 10, removed: 5 }, ...]
```

#### installHooks(repoPath)

Install git hooks in a repository.

```javascript
const result = installHooks('/path/to/repo');
console.log(result.success); // true
console.log(result.hooks);   // ['commit-msg', 'pre-commit']
```

#### loadConfig()

Load commit types configuration.

```javascript
const config = loadConfig();
console.log(config.types.feat); // { description: '...', emoji: '✨', patterns: [...] }
```

### Constants

```javascript
// Available commit types
COMMIT_TYPES = ['feat', 'fix', 'docs', 'style', 'refactor', 'perf', 'test', 'build', 'ci', 'chore', 'revert']

// Emoji mapping
TYPE_EMOJIS = {
  feat: '✨',
  fix: '🐛',
  docs: '📝',
  style: '💄',
  refactor: '♻️',
  perf: '⚡',
  test: '✅',
  build: '📦',
  ci: '🔧',
  chore: '🔨',
  revert: '⏪'
}
```

---

## 🖥️ CLI Usage

After `npm link`:

```bash
# Show help
smart-commit --help

# Show version
smart-commit --version

# Classify staged changes
smart-commit --classify

# Preview commit message
smart-commit --message --dry-run

# Create commit (default action)
smart-commit

# Auto stage and commit
smart-commit --auto-stage

# Dry run (preview only)
smart-commit --dry-run

# JSON output
smart-commit --json --dry-run

# Install git hooks
smart-commit --install
```

### CLI Options

| Option | Alias | Description |
|--------|-------|-------------|
| `--classify` | `-c` | Classify staged changes and show result |
| `--message` | `-m` | Generate commit message without committing |
| `--commit` | | Create commit with auto-classification (default) |
| `--auto-stage` | `-a` | Auto stage all changes before commit |
| `--dry-run` | `-d` | Preview without committing |
| `--json` | `-j` | Output as JSON |
| `--install` | | Install git hooks in current repository |
| `--help` | `-h` | Show help |
| `--version` | `-v` | Show version |

---

## 🔌 Claude Code Plugin Installation

### Method 1: Manual Installation

1. Copy plugin to Claude Code plugins directory:

```bash
cp -r /path/to/commit-hook ~/.claude/plugins/smart-commit-hook
```

2. Register in `~/.claude/plugins/installed_plugins.json`:

```json
{
  "version": 2,
  "plugins": {
    "smart-commit-hook@local": [
      {
        "scope": "user",
        "installPath": "~/.claude/plugins/smart-commit-hook",
        "version": "1.0.0"
      }
    ]
  }
}
```

3. Restart Claude Code

4. Use `/smart-commit` command

### Method 2: Symlink (Development)

```bash
# Create symlink to your development copy
ln -s /path/to/commit-hook ~/.claude/plugins/smart-commit-hook

# Register in installed_plugins.json (same as above)
```

### Method 3: Git Clone

```bash
cd ~/.claude/plugins
git clone git@github.com:nan1010082085/plugin-commit-hook.git smart-commit-hook

# Register in installed_plugins.json (same as above)
```

---

## 🤖 Integration with AI Agents

### With Python Agents

```python
import subprocess
import json

class SmartCommit:
    def __init__(self, cwd=None):
        self.cwd = cwd

    def classify(self):
        """Classify staged changes."""
        result = subprocess.run(
            ['node', '-e', "const sc = require('smart-commit-hook'); sc.classify().then(r => console.log(JSON.stringify(r)))"],
            capture_output=True,
            text=True,
            cwd=self.cwd
        )
        return json.loads(result.stdout)

    def commit(self, auto_stage=False, dry_run=False):
        """Create auto-classified commit."""
        opts = []
        if auto_stage:
            opts.append('autoStage: true')
        if dry_run:
            opts.append('dryRun: true')

        result = subprocess.run(
            ['node', '-e', f"const sc = require('smart-commit-hook'); sc.commit({{ {','.join(opts)} }}).then(r => console.log(JSON.stringify(r)))"],
            capture_output=True,
            text=True,
            cwd=self.cwd
        )
        return json.loads(result.stdout)


# Usage
agent = SmartCommit('/path/to/repo')
classification = agent.classify()
print(f"Type: {classification['classification']['type']}")
print(f"Title: {classification['message']['title']}")
```

### With Shell Scripts

```bash
#!/bin/bash
# Auto-commit with classification

# Get classification as JSON
result=$(node -e "require('smart-commit-hook').classify().then(r => console.log(JSON.stringify(r)))")

# Parse result
type=$(echo "$result" | jq -r '.classification.type')
scope=$(echo "$result" | jq -r '.classification.scope')
title=$(echo "$result" | jq -r '.message.title')

echo "Commit Type: $type"
echo "Scope: $scope"
echo "Title: $title"

# Commit
git commit -m "$title"
```

### With GitHub Actions

```yaml
name: Auto Commit

on:
  push:
    branches: [main]

jobs:
  auto-commit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - uses: actions/setup-node@v3
        with:
          node-version: '18'

      - run: npm install git@github.com:nan1010082085/plugin-commit-hook.git

      - name: Auto commit
        run: |
          git add -A
          npx smart-commit --auto-stage
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### With Husky (Git Hooks)

```json
{
  "devDependencies": {
    "husky": "^8.0.0",
    "smart-commit-hook": "git@github.com:nan1010082085/plugin-commit-hook.git"
  },
  "scripts": {
    "prepare": "husky install"
  }
}
```

```bash
# .husky/commit-msg
npx smart-commit --classify
```

---

## 🧪 Testing

```bash
# Run test suite
npm test

# Test classification
node -e "require('.').classify().then(r => console.log(JSON.stringify(r, null, 2)))"

# Test message generation
node -e "require('.').generateMessage().then(r => console.log(r.fullMessage))"

# Test CLI
./bin/cli.js --dry-run
```

---

## 📚 More Examples

### Custom Integration

```javascript
const { classify, generateMessage, getGitStatus } = require('smart-commit-hook');

async function myWorkflow() {
  // Check if there are staged changes
  const status = getGitStatus();
  if (!status.hasStagedChanges) {
    console.log('No changes to commit');
    return;
  }

  // Classify and get message
  const message = await generateMessage();

  // Custom logic based on type
  if (message.type === 'feat') {
    console.log('New feature detected!');
    // Maybe trigger additional tests
  }

  if (message.isBreaking) {
    console.log('Breaking change! Consider version bump.');
  }

  // Use the message
  console.log(message.fullMessage);
}
```

### Batch Processing

```javascript
const { COMMIT_TYPES, TYPE_EMOJIS } = require('smart-commit-hook');

// Generate changelog
function generateChangelog(commits) {
  return commits
    .sort((a, b) => {
      const order = COMMIT_TYPES;
      return order.indexOf(a.type) - order.indexOf(b.type);
    })
    .map(c => `${TYPE_EMOJIS[c.type]} ${c.message}`)
    .join('\n');
}
```
