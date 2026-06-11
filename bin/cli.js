#!/usr/bin/env node

/**
 * Smart Commit Hook CLI
 *
 * Command-line interface for the smart commit classifier.
 *
 * Usage:
 *   smart-commit [options]
 *
 * Options:
 *   --classify, -c    Classify staged changes and show result
 *   --message, -m     Generate commit message without committing
 *   --commit          Create commit with auto-classification (default)
 *   --auto-stage, -a  Auto stage all changes before commit
 *   --dry-run, -d     Preview without committing
 *   --json, -j        Output as JSON
 *   --install         Install git hooks in current repository
 *   --help, -h        Show help
 *   --version, -v     Show version
 */

const {
  classify,
  generateMessage,
  commit,
  installHooks,
  getGitStatus,
  getStagedStats,
  COMMIT_TYPES,
  TYPE_EMOJIS
} = require('../index');

const args = process.argv.slice(2);

// Parse arguments
const flags = {
  classify: args.includes('--classify') || args.includes('-c'),
  message: args.includes('--message') || args.includes('-m'),
  commit: args.includes('--commit'),
  autoStage: args.includes('--auto-stage') || args.includes('-a'),
  dryRun: args.includes('--dry-run') || args.includes('-d'),
  json: args.includes('--json') || args.includes('-j'),
  install: args.includes('--install'),
  help: args.includes('--help') || args.includes('-h'),
  version: args.includes('--version') || args.includes('-v')
};

// Default to commit if no action specified
if (!flags.classify && !flags.message && !flags.install && !flags.help && !flags.version) {
  flags.commit = true;
}

// Colors
const colors = {
  reset: '\x1b[0m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m',
  bold: '\x1b[1m'
};

function colorize(color, text) {
  return `${colors[color]}${text}${colors.reset}`;
}

// Show help
function showHelp() {
  console.log(`
${colorize('cyan', 'Smart Commit Hook CLI')}
${colorize('cyan', '═══════════════════════')}

Intelligent commit classifier that follows Conventional Commits.

${colorize('bold', 'Usage:')}
  smart-commit [options]

${colorize('bold', 'Options:')}
  --classify, -c    Classify staged changes and show result
  --message, -m     Generate commit message without committing
  --commit          Create commit with auto-classification (default)
  --auto-stage, -a  Auto stage all changes before commit
  --dry-run, -d     Preview without committing
  --json, -j        Output as JSON
  --install         Install git hooks in current repository
  --help, -h        Show help
  --version, -v     Show version

${colorize('bold', 'Commit Types:')}
${COMMIT_TYPES.map(t => `  ${TYPE_EMOJIS[t]}  ${t}`).join('\n')}

${colorize('bold', 'Examples:')}
  # Classify and show result
  smart-commit --classify

  # Preview commit message
  smart-commit --message --dry-run

  # Auto stage and commit
  smart-commit --auto-stage

  # Get JSON output
  smart-commit --json --dry-run

  # Install git hooks
  smart-commit --install
`);
}

// Show version
function showVersion() {
  const pkg = require('../package.json');
  console.log(pkg.version);
}

// Main execution
async function main() {
  if (flags.help) {
    showHelp();
    return;
  }

  if (flags.version) {
    showVersion();
    return;
  }

  if (flags.install) {
    console.log(colorize('blue', 'Installing git hooks...'));
    const result = installHooks(process.cwd());
    console.log(colorize('green', '✓ Hooks installed successfully'));
    console.log(`  Location: ${result.hooksDir}`);
    console.log(`  Hooks: ${result.hooks.join(', ')}`);
    return;
  }

  try {
    // Check git status
    const status = getGitStatus();
    if (!status.hasStagedChanges && !flags.autoStage) {
      console.error(colorize('red', 'Error: No staged changes to commit'));
      console.log(colorize('yellow', 'Use "git add <files>" to stage changes, or use --auto-stage flag'));
      process.exit(1);
    }

    if (flags.classify) {
      const result = await classify();
      if (flags.json) {
        console.log(JSON.stringify(result, null, 2));
      } else {
        console.log('');
        console.log(colorize('cyan', '═══════════════════════════════════════════════════════════════'));
        console.log(colorize('cyan', '                    📊 Commit Analysis                        '));
        console.log(colorize('cyan', '═══════════════════════════════════════════════════════════════'));
        console.log('');
        console.log(`  ${colorize('blue', 'Type:')}       ${colorize('green', result.classification.type)}`);
        console.log(`  ${colorize('blue', 'Scope:')}      ${result.classification.scope || colorize('yellow', '(none)')}`);
        console.log(`  ${colorize('blue', 'Breaking:')}   ${result.classification.is_breaking}`);
        console.log(`  ${colorize('blue', 'Confidence:')} ${result.classification.confidence}`);
        if (result.classification.ticket_id) {
          console.log(`  ${colorize('blue', 'Ticket:')}     ${result.classification.ticket_id}`);
        }
        console.log('');
      }
    }

    if (flags.message) {
      const result = await generateMessage();
      if (flags.json) {
        console.log(JSON.stringify(result, null, 2));
      } else {
        console.log('');
        console.log(colorize('cyan', '═══════════════════════════════════════════════════════════════'));
        console.log(colorize('cyan', '                    📝 Commit Message                         '));
        console.log(colorize('cyan', '═══════════════════════════════════════════════════════════════'));
        console.log('');
        console.log(result.fullMessage);
        console.log('');
        console.log(colorize('cyan', '═══════════════════════════════════════════════════════════════'));
        console.log('');
        console.log(colorize('blue', '  Stats:'));
        console.log(`    Files: ${result.stats.files} | Added: +${result.stats.added} | Removed: -${result.stats.removed}`);
        console.log('');
      }
    }

    if (flags.commit) {
      const result = await commit({
        autoStage: flags.autoStage,
        dryRun: flags.dryRun
      });

      if (flags.json) {
        console.log(JSON.stringify(result, null, 2));
      } else {
        if (result.dryRun) {
          console.log(colorize('yellow', '\n⚠️  Dry run - no commit created\n'));
        } else {
          console.log(colorize('green', `\n✓ Commit created: ${result.commitHash}\n`));
        }
      }
    }
  } catch (err) {
    console.error(colorize('red', `Error: ${err.message}`));
    process.exit(1);
  }
}

main();
