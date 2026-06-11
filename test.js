/**
 * Smart Commit Hook - Test Suite
 *
 * Run: node test.js
 */

const {
  classify,
  generateMessage,
  getGitStatus,
  getStagedStats,
  loadConfig,
  COMMIT_TYPES,
  TYPE_EMOJIS
} = require('./index');

const assert = require('assert');

// Test results
let passed = 0;
let failed = 0;

function test(name, fn) {
  try {
    fn();
    console.log(`  ✓ ${name}`);
    passed++;
  } catch (err) {
    console.log(`  ✗ ${name}`);
    console.log(`    ${err.message}`);
    failed++;
  }
}

console.log('\nSmart Commit Hook - Test Suite\n');

// ============================================================================
// Test: COMMIT_TYPES
// ============================================================================
console.log('Commit Types:');

test('should have 11 commit types', () => {
  assert.strictEqual(COMMIT_TYPES.length, 11);
});

test('should have all required types', () => {
  const required = ['feat', 'fix', 'docs', 'style', 'refactor', 'perf', 'test', 'build', 'ci', 'chore', 'revert'];
  required.forEach(type => {
    assert.ok(COMMIT_TYPES.includes(type), `Missing type: ${type}`);
  });
});

test('should have emoji for each type', () => {
  COMMIT_TYPES.forEach(type => {
    assert.ok(TYPE_EMOJIS[type], `Missing emoji for: ${type}`);
  });
});

// ============================================================================
// Test: loadConfig
// ============================================================================
console.log('\nConfig:');

test('should load commit-types.json', () => {
  const config = loadConfig();
  assert.ok(config.version);
  assert.ok(config.types);
});

test('should have types matching COMMIT_TYPES', () => {
  const config = loadConfig();
  COMMIT_TYPES.forEach(type => {
    assert.ok(config.types[type], `Missing config for: ${type}`);
  });
});

test('each type should have required fields', () => {
  const config = loadConfig();
  Object.entries(config.types).forEach(([name, type]) => {
    assert.ok(type.description, `${name} missing description`);
    assert.ok(type.emoji, `${name} missing emoji`);
    assert.ok(Array.isArray(type.patterns), `${name} missing patterns`);
  });
});

// ============================================================================
// Test: getGitStatus
// ============================================================================
console.log('\nGit Status:');

test('should return git status object', () => {
  const status = getGitStatus();
  assert.ok(typeof status.branch === 'string');
  assert.ok(Array.isArray(status.staged));
  assert.ok(typeof status.hasChanges === 'boolean');
  assert.ok(typeof status.hasStagedChanges === 'boolean');
});

// ============================================================================
// Test: getStagedStats
// ============================================================================
console.log('\nStaged Stats:');

test('should return stats object', () => {
  const stats = getStagedStats();
  assert.ok(Array.isArray(stats.files));
  assert.ok(Array.isArray(stats.fileStats));
  assert.ok(typeof stats.totalFiles === 'number');
  assert.ok(typeof stats.totalAdded === 'number');
  assert.ok(typeof stats.totalRemoved === 'number');
});

// ============================================================================
// Summary
// ============================================================================
console.log('\n═══════════════════════════════════════════════════════════════');
console.log(`\nResults: ${passed} passed, ${failed} failed\n`);

if (failed > 0) {
  process.exit(1);
}
