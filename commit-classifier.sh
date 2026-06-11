#!/usr/bin/env bash
#
# Smart Commit Classifier
# Standalone script for auto-classifying commits and generating messages
# Can be used by any agent or tool, not just Claude Code
#
# Usage:
#   ./commit-classifier.sh [options]
#
# Options:
#   -d, --dry-run     Show generated message without committing
#   -a, --auto-stage  Automatically stage all changes before commit
#   -j, --json        Output classification as JSON
#   -h, --help        Show this help message
#
# Exit codes:
#   0 - Success
#   1 - Error (no changes, git error, etc.)
#

set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMIT_TYPES_FILE="${SCRIPT_DIR}/commit-types.json"

# Default options
DRY_RUN=false
AUTO_STAGE=false
JSON_OUTPUT=false

# ============================================================================
# Color output
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ============================================================================
# Helper functions
# ============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

show_help() {
    cat << 'EOF'
Smart Commit Classifier
========================

Automatically classifies git commits and generates meaningful commit messages
following the Conventional Commits specification.

Usage:
  ./commit-classifier.sh [options]

Options:
  -d, --dry-run     Show generated message without committing
  -a, --auto-stage  Automatically stage all changes before commit
  -j, --json        Output classification as JSON
  -h, --help        Show this help message

Commit Types:
  feat:     ✨ A new feature
  fix:      🐛 A bug fix
  docs:     📝 Documentation only changes
  style:    💄 Formatting, missing semi colons, etc
  refactor: ♻️  Code change that neither fixes a bug nor adds a feature
  perf:     ⚡ A code change that improves performance
  test:     ✅ Adding missing or correcting existing tests
  build:    📦 Changes to build system or dependencies
  ci:       🔧 Changes to CI configuration
  chore:    🔨 Other changes that don't modify src or test
  revert:   ⏪ Reverts a previous commit

Examples:
  # Auto-classify and commit staged changes
  ./commit-classifier.sh

  # Stage all changes and commit
  ./commit-classifier.sh --auto-stage

  # Preview commit message without committing
  ./commit-classifier.sh --dry-run

  # Get classification as JSON
  ./commit-classifier.sh --json --dry-run

EOF
}

# ============================================================================
# Parse arguments
# ============================================================================

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -a|--auto-stage)
                AUTO_STAGE=true
                shift
                ;;
            -j|--json)
                JSON_OUTPUT=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# ============================================================================
# Git helper functions
# ============================================================================

get_staged_files() {
    git diff --cached --name-only 2>/dev/null || echo ""
}

get_staged_diff_stat() {
    git diff --cached --stat 2>/dev/null || echo ""
}

get_staged_diff() {
    git diff --cached 2>/dev/null || echo ""
}

get_current_branch() {
    git branch --show-current 2>/dev/null || echo ""
}

get_recent_commits() {
    git log --oneline -10 2>/dev/null || echo ""
}

# ============================================================================
# Classification logic
# ============================================================================

classify_changes() {
    local staged_files="$1"
    local staged_diff="$2"
    local branch_name="$3"

    local type=""
    local scope=""
    local is_breaking=false
    local confidence="medium"
    local reasons=()

    # Convert staged files to array
    local files=()
    while IFS= read -r line; do
        [[ -n "$line" ]] && files+=("$line")
    done <<< "$staged_files"

    local total_files=${#files[@]}

    # --------------------------------------------------------------------------
    # Check for revert
    # --------------------------------------------------------------------------
    if echo "$staged_diff" | head -5 | grep -qi "revert\|undo\|rollback"; then
        type="revert"
        reasons+=("Changes appear to revert previous commits")
        confidence="high"
    fi

    # --------------------------------------------------------------------------
    # Check for fix
    # --------------------------------------------------------------------------
    if [[ -z "$type" ]]; then
        if echo "$staged_diff" | grep -qiE "fix|bug|issue|error|crash|resolve|patch|broken|incorrect"; then
            type="fix"
            reasons+=("Changes address bugs or errors")
            confidence="high"
        fi
    fi

    # --------------------------------------------------------------------------
    # Check for feat
    # --------------------------------------------------------------------------
    if [[ -z "$type" ]]; then
        if echo "$staged_diff" | grep -qiE "add|implement|create|new|feature|support|introduce"; then
            type="feat"
            reasons+=("Changes add new functionality")
            confidence="high"
        fi
    fi

    # --------------------------------------------------------------------------
    # Check for perf
    # --------------------------------------------------------------------------
    if [[ -z "$type" ]]; then
        if echo "$staged_diff" | grep -qiE "performance|optimize|speed|fast|cache|lazy|memo|efficient"; then
            type="perf"
            reasons+=("Changes improve performance")
            confidence="high"
        fi
    fi

    # --------------------------------------------------------------------------
    # Check for refactor
    # --------------------------------------------------------------------------
    if [[ -z "$type" ]]; then
        if echo "$staged_diff" | grep -qiE "refactor|restructure|reorganize|simplify|extract|rename|move|clean|decouple"; then
            type="refactor"
            reasons+=("Changes restructure code")
            confidence="medium"
        fi
    fi

    # --------------------------------------------------------------------------
    # Check for test
    # --------------------------------------------------------------------------
    if [[ -z "$type" ]]; then
        local test_files=0
        for file in "${files[@]}"; do
            if echo "$file" | grep -qE '\.(test|spec)\.|__tests__|tests/|test/'; then
                ((test_files++)) || true
            fi
        done

        if [[ $test_files -eq $total_files && $total_files -gt 0 ]]; then
            type="test"
            reasons+=("Only test files changed")
            confidence="high"
        elif [[ $test_files -gt 0 ]]; then
            # Mixed files, will be caught by other checks
            :
        fi
    fi

    # --------------------------------------------------------------------------
    # Check for docs
    # --------------------------------------------------------------------------
    if [[ -z "$type" ]]; then
        local doc_files=0
        for file in "${files[@]}"; do
            if echo "$file" | grep -qE '\.(md|txt|rst|adoc)$|^docs/|^README|^CHANGELOG|^LICENSE'; then
                ((doc_files++)) || true
            fi
        done

        if [[ $doc_files -eq $total_files && $total_files -gt 0 ]]; then
            type="docs"
            reasons+=("Only documentation files changed")
            confidence="high"
        fi
    fi

    # --------------------------------------------------------------------------
    # Check for style
    # --------------------------------------------------------------------------
    if [[ -z "$type" ]]; then
        local style_files=0
        for file in "${files[@]}"; do
            if echo "$file" | grep -qE '\.(css|scss|less|sass)$|\.eslintrc|\.prettierrc|\.stylelintrc'; then
                ((style_files++)) || true
            fi
        done

        if [[ $style_files -gt 0 ]]; then
            # Check if changes are formatting-only
            if echo "$staged_diff" | grep -qE '^\+.*[{};]$' && ! echo "$staged_diff" | grep -qiE 'function|class|const|let|var|import|export'; then
                type="style"
                reasons+=("Changes appear to be formatting/style only")
                confidence="medium"
            fi
        fi
    fi

    # --------------------------------------------------------------------------
    # Check for build
    # --------------------------------------------------------------------------
    if [[ -z "$type" ]]; then
        local build_files=0
        for file in "${files[@]}"; do
            if echo "$file" | grep -qE 'package\.json|package-lock\.json|yarn\.lock|pnpm-lock|tsconfig|webpack|vite|rollup|babel|\.cargo|Makefile|CMakeLists|build\.gradle|pom\.xml'; then
                ((build_files++)) || true
            fi
        done

        if [[ $build_files -gt 0 ]]; then
            type="build"
            reasons+=("Changes affect build system or dependencies")
            confidence="high"
        fi
    fi

    # --------------------------------------------------------------------------
    # Check for ci
    # --------------------------------------------------------------------------
    if [[ -z "$type" ]]; then
        local ci_files=0
        for file in "${files[@]}"; do
            if echo "$file" | grep -qE '\.github/|\.gitlab-ci|Jenkinsfile|\.travis|\.circleci|\.azure-pipelines|bitbucket-pipelines'; then
                ((ci_files++)) || true
            fi
        done

        if [[ $ci_files -gt 0 ]]; then
            type="ci"
            reasons+=("Changes to CI/CD configuration")
            confidence="high"
        fi
    fi

    # --------------------------------------------------------------------------
    # Default to chore
    # --------------------------------------------------------------------------
    if [[ -z "$type" ]]; then
        type="chore"
        reasons+=("General maintenance changes")
        confidence="low"
    fi

    # --------------------------------------------------------------------------
    # Detect scope
    # --------------------------------------------------------------------------
    if [[ ${#files[@]} -gt 0 ]]; then
        # Try to extract scope from directory structure
        local first_file="${files[0]}"
        local dir_part=$(dirname "$first_file")

        # Common scope mappings
        case "$dir_part" in
            src/api|api|api/*)
                scope="api"
                ;;
            src/ui|ui|components|src/components)
                scope="ui"
                ;;
            src/auth|auth|authentication)
                scope="auth"
                ;;
            src/db|database|db)
                scope="db"
                ;;
            src/config|config)
                scope="config"
                ;;
            src/utils|utils|helpers)
                scope="utils"
                ;;
            src/hooks|hooks)
                scope="hooks"
                ;;
            src/pages|pages|views)
                scope="pages"
                ;;
            src/services|services)
                scope="services"
                ;;
            src/models|models|schemas)
                scope="models"
                ;;
            src/middleware|middleware)
                scope="middleware"
                ;;
            *)
                # Try to extract from filename
                local base_name=$(basename "$first_file" | sed 's/\..*//')
                if [[ ${#base_name} -lt 15 ]]; then
                    scope="$base_name"
                fi
                ;;
        esac
    fi

    # --------------------------------------------------------------------------
    # Detect breaking changes
    # --------------------------------------------------------------------------
    if echo "$staged_diff" | grep -qE "BREAKING CHANGE|breaking:|!:"; then
        is_breaking=true
        reasons+=("Breaking change detected")
    fi

    # Check for common breaking patterns
    if echo "$staged_diff" | grep -qE "^\-.*public|^\-.*export|^\-.*function.*\(|^\-.*class "; then
        is_breaking=true
        reasons+=("Public API changes detected")
    fi

    # --------------------------------------------------------------------------
    # Extract ticket ID from branch
    # --------------------------------------------------------------------------
    local ticket_id=""
    if [[ -n "$branch_name" ]]; then
        ticket_id=$(echo "$branch_name" | grep -oE '[A-Z]+-[0-9]+' | head -1 || true)
    fi

    # --------------------------------------------------------------------------
    # Output results
    # --------------------------------------------------------------------------
    echo "${type}|${scope}|${is_breaking}|${confidence}|${ticket_id}|$(IFS=,; echo "${reasons[*]}")"
}

# ============================================================================
# Generate commit message
# ============================================================================

generate_commit_message() {
    local type="$1"
    local scope="$2"
    local is_breaking="$3"
    local ticket_id="$4"
    local staged_files="$5"
    local staged_diff="$6"

    # Type emojis
    get_emoji() {
        case "$1" in
            feat) echo "✨" ;;
            fix) echo "🐛" ;;
            docs) echo "📝" ;;
            style) echo "💄" ;;
            refactor) echo "♻️" ;;
            perf) echo "⚡" ;;
            test) echo "✅" ;;
            build) echo "📦" ;;
            ci) echo "🔧" ;;
            chore) echo "🔨" ;;
            revert) echo "⏪" ;;
            *) echo "📝" ;;
        esac
    }

    local emoji
    emoji=$(get_emoji "$type")

    # Build type prefix
    local type_prefix="${type}"
    if [[ -n "$scope" ]]; then
        type_prefix="${type}(${scope})"
    fi
    if [[ "$is_breaking" == "true" ]]; then
        type_prefix="${type_prefix}!"
    fi

    # Generate title based on type and changes
    local title=""
    local body=""

    case "$type" in
        feat)
            title="add new functionality"
            body="Implement new feature based on staged changes."
            ;;
        fix)
            title="resolve issue"
            body="Fix bug identified in staged changes."
            ;;
        docs)
            title="update documentation"
            body="Documentation updates and improvements."
            ;;
        style)
            title="format code"
            body="Code style and formatting adjustments."
            ;;
        refactor)
            title="refactor code"
            body="Restructure code without changing functionality."
            ;;
        perf)
            title="improve performance"
            body="Optimize code for better performance."
            ;;
        test)
            title="update tests"
            body="Add or modify test coverage."
            ;;
        build)
            title="update build configuration"
            body="Changes to build system or dependencies."
            ;;
        ci)
            title="update CI configuration"
            body="CI/CD pipeline adjustments."
            ;;
        chore)
            title="general maintenance"
            body="Routine maintenance and housekeeping."
            ;;
        revert)
            title="revert previous changes"
            body="Undo changes from a previous commit."
            ;;
    esac

    # Analyze diff for more specific title
    local added_lines=$(echo "$staged_diff" | grep -c "^+" || true)
    local removed_lines=$(echo "$staged_diff" | grep -c "^-" || true)
    local file_count=$(echo "$staged_files" | wc -l | tr -d ' ')

    # Generate more descriptive title based on file analysis
    local primary_change=""
    if [[ $file_count -eq 1 ]]; then
        primary_change=$(basename "$(echo "$staged_files" | head -1)")
        title="update ${primary_change}"
    elif [[ $file_count -le 3 ]]; then
        title="update ${file_count} files"
    fi

    # Build commit message
    local message="${type_prefix}: ${title}"

    # Add body
    message="${message}

${body}

Summary:
- Files changed: ${file_count}
- Lines added: ${added_lines}
- Lines removed: ${removed_lines}"

    # Add ticket ID if found
    if [[ -n "$ticket_id" ]]; then
        message="${message}
- Ticket: ${ticket_id}"
    fi

    # Add footer
    message="${message}

Co-authored-by: Claude <noreply@anthropic.com>"

    if [[ -n "$ticket_id" ]]; then
        message="${message}
Refs: ${ticket_id}"
    fi

    echo "$message"
}

# ============================================================================
# JSON output
# ============================================================================

# Pure bash JSON string escape (no jq dependency)
json_escape() {
    local s="$1"
    s="${s//\\/\\\\}"     # backslash
    s="${s//\"/\\\"}"     # double quote
    s="${s//$'\n'/\\n}"   # newline
    s="${s//$'\r'/\\r}"   # carriage return
    s="${s//$'\t'/\\t}"   # tab
    echo "$s"
}

output_json() {
    local type="$1"
    local scope="$2"
    local is_breaking="$3"
    local confidence="$4"
    local ticket_id="$5"
    local reasons="$6"
    local title="$7"
    local message="$8"

    local escaped_message
    escaped_message=$(json_escape "$message")
    local escaped_reasons
    escaped_reasons=$(json_escape "$reasons")

    cat << EOF
{
  "classification": {
    "type": "${type}",
    "scope": "${scope:-null}",
    "is_breaking": ${is_breaking},
    "confidence": "${confidence}",
    "ticket_id": "${ticket_id:-null}",
    "reasons": "${escaped_reasons}"
  },
  "message": {
    "title": "${title}",
    "full": "${escaped_message}"
  }
}
EOF
}

# ============================================================================
# Main execution
# ============================================================================

main() {
    parse_args "$@"

    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        log_error "Not a git repository"
        exit 1
    fi

    # Auto-stage if requested
    if [[ "$AUTO_STAGE" == "true" ]]; then
        log_info "Auto-staging all changes..."
        git add -A
    fi

    # Get staged changes
    local staged_files
    staged_files=$(get_staged_files)

    if [[ -z "$staged_files" ]]; then
        log_error "No staged changes to commit"
        log_info "Use 'git add <files>' to stage changes, or use --auto-stage flag"
        exit 1
    fi

    local staged_diff
    staged_diff=$(get_staged_diff)

    local branch_name
    branch_name=$(get_current_branch)

    # Classify the changes
    log_info "Analyzing staged changes..."
    local classification
    classification=$(classify_changes "$staged_files" "$staged_diff" "$branch_name")

    # Parse classification result
    IFS='|' read -r type scope is_breaking confidence ticket_id reasons <<< "$classification"

    # Generate commit message
    local commit_message
    commit_message=$(generate_commit_message "$type" "$scope" "$is_breaking" "$ticket_id" "$staged_files" "$staged_diff")

    # Extract title
    local title
    title=$(echo "$commit_message" | head -1)

    # Output results
    if [[ "$JSON_OUTPUT" == "true" ]]; then
        output_json "$type" "$scope" "$is_breaking" "$confidence" "$ticket_id" "$reasons" "$title" "$commit_message"
    else
        echo ""
        echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
        echo -e "${CYAN}                    📊 Commit Analysis                        ${NC}"
        echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
        echo ""
        echo -e "  ${BLUE}Type:${NC}       ${GREEN}${type}${NC}"
        echo -e "  ${BLUE}Scope:${NC}      ${scope:-${YELLOW}(none)${NC}}"
        echo -e "  ${BLUE}Breaking:${NC}   ${is_breaking}"
        echo -e "  ${BLUE}Confidence:${NC} ${confidence}"
        if [[ -n "$ticket_id" ]]; then
            echo -e "  ${BLUE}Ticket:${NC}     ${ticket_id}"
        fi
        echo -e "  ${BLUE}Reasons:${NC}    ${reasons}"
        echo ""
        echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
        echo -e "${CYAN}                    📝 Commit Message                         ${NC}"
        echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
        echo ""
        echo "$commit_message"
        echo ""
        echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    fi

    # Commit or dry-run
    if [[ "$DRY_RUN" == "true" ]]; then
        log_warn "Dry run - no commit created"
    else
        log_info "Creating commit..."
        git commit -m "$commit_message"
        log_success "Commit created successfully"
        echo ""
        git log -1 --stat
    fi
}

# Run main function
main "$@"
