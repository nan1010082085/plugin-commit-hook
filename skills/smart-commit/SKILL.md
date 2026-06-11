---
name: smart-commit
description: Intelligent git commit with auto-classification, title, and detailed description following Conventional Commits. Use this skill whenever the user wants to commit changes, says "commit", "smart commit", "auto commit", or when wrapping up work on a feature/fix/task. Also use when the user asks to generate a commit message or classify their changes.
---

# Smart Commit

Analyze staged git changes and create a well-structured commit following Conventional Commits format.

## When to use

- User says "commit", "smart commit", "auto commit", "提交"
- User finishes a feature/fix and wants to commit
- User asks to generate a commit message
- User says "wrap up" or "ship it" after making changes

## Workflow

1. **Gather context** — run these commands to understand the changes:
   - `git status` — see what's staged/unstaged
   - `git diff --cached --stat` — staged file summary
   - `git diff --cached` — full staged diff
   - `git diff --stat` — unstaged changes (note but don't commit these)
   - `git branch --show-current` — current branch
   - `git log --oneline -15` — recent commit style
   - `git diff --cached --name-only | sed 's/.*\.//' | sort | uniq -c | sort -rn` — changed file types

2. **Classify the commit** into ONE type, in priority order:

   | Priority | Type | When to use |
   |----------|------|-------------|
   | 1 | `revert` | Changes undo previous commits |
   | 2 | `fix` | Resolves bugs, errors, or issues |
   | 3 | `feat` | Adds new functionality or features |
   | 4 | `perf` | Specifically improves performance |
   | 5 | `refactor` | Restructures code without changing behavior |
   | 6 | `docs` | Only documentation files changed |
   | 7 | `style` | Formatting-only changes |
   | 8 | `test` | Only test files changed |
   | 9 | `build` | Build config or dependencies changed |
   | 10 | `ci` | CI/CD config changes |
   | 11 | `chore` | Maintenance that doesn't fit above |

3. **Detect scope** from changed files:
   - Directory structure (e.g., `src/api/` → scope: `api`)
   - Component names (e.g., `UserProfile.tsx` → scope: `user`)
   - Use the primary area of change; omit if unclear

4. **Detect breaking changes**:
   - Public API signature changes
   - Configuration format changes
   - Database schema changes
   - Behavior changes that could break existing usage
   - Use `!` suffix: `feat!:` or `fix!:`

5. **Generate commit message** in this exact format:

   ```
   <type>(<scope>): <concise title in imperative mood, max 72 chars>

   <body with detailed description>
   - What changed and why
   - Key modifications listed
   - Any important notes for reviewers

   <footer with metadata>
   ```

   **Title rules:**
   - `type(scope): description` format
   - Imperative mood ("add" not "added")
   - Max 72 characters, lowercase after colon, no period

   **Body rules:**
   - Explain WHAT and WHY, not HOW
   - Bullet points for key changes
   - Reference issues/tickets from branch name if present

   **Footer rules:**
   - `BREAKING CHANGE:` if applicable
   - `Co-authored-by: Claude <noreply@anthropic.com>`

6. **Show analysis and execute**:

   ```
   📊 Commit Analysis:
   - Type: <detected type>
   - Scope: <detected scope>
   - Breaking: <yes/no>
   - Confidence: <high/medium/low>
   ```

   Then run:
   ```bash
   git add -A && git commit -m "<type>(<scope>): <title>

   <body>

   Co-authored-by: Claude <noreply@anthropic.com>"
   ```

   Finally: `git log -1 --stat`

## Important

- Do NOT commit files containing secrets (.env, credentials, keys)
- Note incomplete changes in the commit body
- Match the repo's language for commit messages
- Include ticket IDs from branch names in the footer
- If nothing is staged, ask the user what to stage first
