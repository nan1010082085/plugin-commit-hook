---
allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git commit:*), Bash(git branch:*), Read, Grep
description: Intelligent commit with auto-classification, title, and detailed description
---

## Context

- Current git status: !`git status`
- Staged changes: !`git diff --cached --stat`
- Detailed staged diff: !`git diff --cached`
- Unstaged changes: !`git diff --stat`
- Current branch: !`git branch --show-current`
- Recent commits (last 15): !`git log --oneline -15`
- Changed file types: !`git diff --cached --name-only | sed 's/.*\.//' | sort | uniq -c | sort -rn`

## Commit Classification Rules

You MUST classify the commit into ONE of the following types based on the analysis:

### Type Classification Priority

1. **revert** - If changes undo previous commits
2. **fix** - If changes resolve bugs, errors, or issues
3. **feat** - If changes add new functionality, features, or capabilities
4. **perf** - If changes specifically improve performance
5. **refactor** - If changes restructure code without changing behavior
6. **docs** - If only documentation files are changed (*.md, docs/*, README)
7. **style** - If changes are formatting-only (whitespace, semicolons, CSS)
8. **test** - If only test files are changed (*.test.*, *.spec.*, __tests__/*)
9. **build** - If build config or dependencies change (package.json, webpack, etc.)
10. **ci** - If CI/CD config changes (.github/*, Jenkinsfile, etc.)
11. **chore** - For maintenance tasks that don't fit above categories

### Scope Detection

Analyze the changed files to determine the scope:
- Look at directory structure (e.g., `src/api/` → scope: `api`)
- Look at component names (e.g., `UserProfile.tsx` → scope: `user`)
- Use the primary area of change as scope
- If changes span multiple areas, use the most significant one
- If unclear, omit the scope

### Breaking Changes

Mark as breaking change if:
- Public API signatures change
- Configuration format changes
- Database schema changes
- Behavior changes that could break existing usage

Use `!` suffix on type (e.g., `feat!:`) for breaking changes

## Your Task

Analyze the staged changes and create a commit following this EXACT format:

### Commit Message Structure

```
<type>(<scope>): <concise title in imperative mood, max 72 chars>

<body with detailed description>
- What changed and why
- Key modifications listed
- Any important notes for reviewers

<footer with metadata>
```

### Title Rules (First Line)
- Format: `type(scope): description`
- Use imperative mood ("add" not "added", "fix" not "fixed")
- Max 72 characters
- Lowercase first letter after colon
- No period at end
- Be specific but concise

### Body Rules (After blank line)
- Explain WHAT changed and WHY (not HOW)
- List key modifications as bullet points
- Reference related issues/tickets if mentioned in branch name or changes
- Note any breaking changes prominently

### Footer Rules
- Add `BREAKING CHANGE:` if applicable
- Add `Co-authored-by: Claude <noreply@anthropic.com>` for attribution

## Output

1. First, show the classification analysis:
   ```
   📊 Commit Analysis:
   - Type: <detected type>
   - Scope: <detected scope>
   - Breaking: <yes/no>
   - Confidence: <high/medium/low>
   ```

2. Then execute the commit with the generated message:
   ```bash
   git commit -m "<type>(<scope>): <title>

   <body>

   Co-authored-by: Claude <noreply@anthropic.com>"
   ```

3. Show the result with `git log -1 --stat`

## Important Notes

- Do NOT commit files that appear to contain secrets (.env, credentials, keys)
- If changes seem incomplete (partial feature), note this in the commit body
- Match the coding style/language of the repository
- If the branch name contains a ticket ID (e.g., PROJ-123), include it in the footer
- Prefer English for commit messages unless the repo consistently uses another language
