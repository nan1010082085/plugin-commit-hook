/**
 * Smart Commit Hook - ESM Wrapper
 *
 * Provides ESM import support for the smart commit hook module.
 */

import { createRequire } from 'module';
const require = createRequire(import.meta.url);
const module = require('./index.js');

export const classify = module.classify;
export const generateMessage = module.generateMessage;
export const commit = module.commit;
export const getGitStatus = module.getGitStatus;
export const getStagedDiff = module.getStagedDiff;
export const getStagedStats = module.getStagedStats;
export const installHooks = module.installHooks;
export const loadConfig = module.loadConfig;
export const COMMIT_TYPES = module.COMMIT_TYPES;
export const TYPE_EMOJIS = module.TYPE_EMOJIS;

export default module;
