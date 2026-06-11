/**
 * Smart Commit Hook - Node.js Integration
 *
 * Provides programmatic access to commit classification and message generation.
 * Can be used by any Node.js tool, agent, or script.
 *
 * Usage:
 *   const { classify, generateMessage, commit } = require('smart-commit-hook');
 *
 *   // Classify staged changes
 *   const classification = await classify();
 *
 *   // Generate commit message
 *   const message = await generateMessage();
 *
 *   // Auto commit
 *   await commit({ autoStage: false, dryRun: false });
 */

const { execSync, exec } = require('child_process');
const path = require('path');
const fs = require('fs');

const SCRIPT_PATH = path.join(__dirname, 'commit-classifier.sh');

/**
 * Execute shell command and return output
 */
function execCommand(cmd, options = {}) {
  try {
    return execSync(cmd, {
      encoding: 'utf-8',
      cwd: options.cwd || process.cwd(),
      ...options
    }).trim();
  } catch (err) {
    throw new Error(`Command failed: ${cmd}\n${err.stderr || err.message}`);
  }
}

/**
 * Execute shell command asynchronously
 */
function execCommandAsync(cmd, options = {}) {
  return new Promise((resolve, reject) => {
    exec(cmd, {
      encoding: 'utf-8',
      cwd: options.cwd || process.cwd(),
      ...options
    }, (err, stdout, stderr) => {
      if (err) {
        reject(new Error(`Command failed: ${cmd}\n${stderr || err.message}`));
      } else {
        resolve(stdout.trim());
      }
    });
  });
}

/**
 * Get current git status
 */
function getGitStatus(cwd) {
  const status = execCommand('git status --porcelain', { cwd });
  const branch = execCommand('git branch --show-current', { cwd });
  const staged = execCommand('git diff --cached --name-only', { cwd });

  return {
    branch,
    staged: staged ? staged.split('\n') : [],
    hasChanges: status.length > 0,
    hasStagedChanges: staged.length > 0,
    raw: status
  };
}

/**
 * Get staged diff
 */
function getStagedDiff(cwd) {
  return execCommand('git diff --cached', { cwd });
}

/**
 * Get staged files with stats
 */
function getStagedStats(cwd) {
  const stat = execCommand('git diff --cached --stat', { cwd });
  const files = execCommand('git diff --cached --name-only', { cwd });
  const numstat = execCommand('git diff --cached --numstat', { cwd });

  const fileStats = numstat ? numstat.split('\n').map(line => {
    const [added, removed, file] = line.split('\t');
    return {
      file,
      added: parseInt(added, 10) || 0,
      removed: parseInt(removed, 10) || 0
    };
  }) : [];

  return {
    stat,
    files: files ? files.split('\n') : [],
    fileStats,
    totalFiles: fileStats.length,
    totalAdded: fileStats.reduce((sum, f) => sum + f.added, 0),
    totalRemoved: fileStats.reduce((sum, f) => sum + f.removed, 0)
  };
}

/**
 * Classify the current staged changes
 *
 * @param {Object} options
 * @param {string} options.cwd - Working directory
 * @returns {Object} Classification result
 */
async function classify(options = {}) {
  const cwd = options.cwd || process.cwd();
  const output = await execCommandAsync(`${SCRIPT_PATH} --json --dry-run`, { cwd });

  // Extract JSON from output using robust line-by-line parsing
  // The JSON block starts with '{' on its own line and ends with '}'
  const lines = output.split('\n');
  let jsonStart = -1;
  let jsonEnd = -1;

  for (let i = 0; i < lines.length; i++) {
    const trimmed = lines[i].trim();
    if (trimmed === '{' && jsonStart === -1) {
      jsonStart = i;
    }
    if (trimmed === '}' && jsonStart !== -1) {
      jsonEnd = i;
    }
  }

  if (jsonStart === -1 || jsonEnd === -1) {
    throw new Error('Failed to parse classification output: no JSON block found');
  }

  const jsonStr = lines.slice(jsonStart, jsonEnd + 1).join('\n');
  return JSON.parse(jsonStr);
}

/**
 * Generate commit message without committing
 *
 * @param {Object} options
 * @param {string} options.cwd - Working directory
 * @returns {Object} Commit message details
 */
async function generateMessage(options = {}) {
  const classification = await classify(options);
  const stats = getStagedStats(options.cwd);

  return {
    type: classification.classification.type,
    scope: classification.classification.scope,
    isBreaking: classification.classification.is_breaking,
    confidence: classification.classification.confidence,
    ticketId: classification.classification.ticket_id,
    title: classification.message.title,
    fullMessage: classification.message.full,
    stats: {
      files: stats.totalFiles,
      added: stats.totalAdded,
      removed: stats.totalRemoved
    }
  };
}

/**
 * Create a commit with auto-classification
 *
 * @param {Object} options
 * @param {boolean} options.autoStage - Auto stage all changes
 * @param {boolean} options.dryRun - Preview without committing
 * @param {string} options.cwd - Working directory
 * @returns {Object} Commit result
 */
async function commit(options = {}) {
  const { autoStage = false, dryRun = false, cwd = process.cwd() } = options;

  // Check for staged changes
  const status = getGitStatus(cwd);
  if (!status.hasStagedChanges && !autoStage) {
    throw new Error('No staged changes to commit. Use autoStage option or stage files manually.');
  }

  // Build command
  let cmd = SCRIPT_PATH;
  if (autoStage) cmd += ' --auto-stage';
  if (dryRun) cmd += ' --dry-run';
  cmd += ' --json';

  const output = await execCommandAsync(cmd, { cwd });

  // Extract JSON from output
  const jsonMatch = output.match(/\{[\s\S]*\}/);
  if (!jsonMatch) {
    throw new Error('Failed to parse commit output');
  }

  const result = JSON.parse(jsonMatch[0]);

  return {
    success: !dryRun,
    dryRun,
    classification: result.classification,
    message: result.message,
    commitHash: dryRun ? null : execCommand('git rev-parse HEAD', { cwd })
  };
}

/**
 * Install git hooks in a repository
 *
 * @param {string} repoPath - Path to git repository
 * @returns {Object} Installation result
 */
function installHooks(repoPath) {
  const hooksDir = path.join(repoPath, '.git', 'hooks');
  const setupScript = path.join(__dirname, 'setup-hooks.sh');

  if (!fs.existsSync(path.join(repoPath, '.git'))) {
    throw new Error('Not a git repository');
  }

  try {
    execSync(`bash "${setupScript}"`, {
      cwd: repoPath,
      encoding: 'utf-8',
      stdio: 'pipe'
    });

    return {
      success: true,
      hooksDir,
      hooks: ['commit-msg', 'pre-commit']
    };
  } catch (err) {
    throw new Error(`Failed to install hooks: ${err.message}`);
  }
}

/**
 * Load commit types configuration
 */
function loadConfig() {
  const configPath = path.join(__dirname, 'commit-types.json');
  return JSON.parse(fs.readFileSync(configPath, 'utf-8'));
}

// Export public API
module.exports = {
  // Core functions
  classify,
  generateMessage,
  commit,

  // Utility functions
  getGitStatus,
  getStagedDiff,
  getStagedStats,

  // Setup
  installHooks,
  loadConfig,

  // Constants
  COMMIT_TYPES: [
    'feat', 'fix', 'docs', 'style', 'refactor',
    'perf', 'test', 'build', 'ci', 'chore', 'revert'
  ],

  TYPE_EMOJIS: {
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
};
