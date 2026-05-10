#!/usr/bin/env node
/**
 * Крос-платформенна перевірка: format:check + lint (без shell=true / cmd).
 */
import { spawnSync } from 'node:child_process';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');

function runNode(scriptRel, args) {
  const script = join(root, scriptRel);
  const result = spawnSync(process.execPath, [script, ...args], {
    stdio: 'inherit',
    cwd: root,
    shell: false,
  });
  if (result.status !== 0) {
    process.exit(result.status ?? 1);
  }
}

runNode('node_modules/prettier/bin/prettier.cjs', ['--check', '.']);
runNode('node_modules/eslint/bin/eslint.js', ['.']);
