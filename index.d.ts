/**
 * Smart Commit Hook - TypeScript Type Definitions
 */

export interface ClassificationResult {
  classification: {
    type: CommitType;
    scope: string | null;
    is_breaking: boolean;
    confidence: 'high' | 'medium' | 'low';
    ticket_id: string | null;
    reasons: string;
  };
  message: {
    title: string;
    full: string;
  };
}

export interface MessageResult {
  type: CommitType;
  scope: string | null;
  isBreaking: boolean;
  confidence: 'high' | 'medium' | 'low';
  ticketId: string | null;
  title: string;
  fullMessage: string;
  stats: {
    files: number;
    added: number;
    removed: number;
  };
}

export interface CommitResult {
  success: boolean;
  dryRun: boolean;
  classification: ClassificationResult['classification'];
  message: ClassificationResult['message'];
  commitHash: string | null;
}

export interface GitStatus {
  branch: string;
  staged: string[];
  hasChanges: boolean;
  hasStagedChanges: boolean;
  raw: string;
}

export interface FileStat {
  file: string;
  added: number;
  removed: number;
}

export interface StagedStats {
  stat: string;
  files: string[];
  fileStats: FileStat[];
  totalFiles: number;
  totalAdded: number;
  totalRemoved: number;
}

export interface HooksResult {
  success: boolean;
  hooksDir: string;
  hooks: string[];
}

export interface CommitTypeConfig {
  description: string;
  emoji: string;
  patterns: string[];
  filePatterns: string[];
}

export interface Config {
  version: string;
  types: Record<string, CommitTypeConfig>;
  scopes: {
    autoDetect: boolean;
    commonScopes: string[];
  };
  breakingChangeIndicators: string[];
}

export type CommitType = 'feat' | 'fix' | 'docs' | 'style' | 'refactor' | 'perf' | 'test' | 'build' | 'ci' | 'chore' | 'revert';

export interface Options {
  cwd?: string;
}

export interface CommitOptions extends Options {
  autoStage?: boolean;
  dryRun?: boolean;
}

/**
 * Classify staged changes without committing.
 */
export function classify(options?: Options): Promise<ClassificationResult>;

/**
 * Generate commit message with stats.
 */
export function generateMessage(options?: Options): Promise<MessageResult>;

/**
 * Create an auto-classified commit.
 */
export function commit(options?: CommitOptions): Promise<CommitResult>;

/**
 * Get current git status.
 */
export function getGitStatus(cwd?: string): GitStatus;

/**
 * Get staged diff content.
 */
export function getStagedDiff(cwd?: string): string;

/**
 * Get detailed stats for staged changes.
 */
export function getStagedStats(cwd?: string): StagedStats;

/**
 * Install git hooks in a repository.
 */
export function installHooks(repoPath: string): HooksResult;

/**
 * Load commit types configuration.
 */
export function loadConfig(): Config;

/**
 * Available commit types.
 */
export const COMMIT_TYPES: CommitType[];

/**
 * Emoji mapping for commit types.
 */
export const TYPE_EMOJIS: Record<CommitType, string>;
