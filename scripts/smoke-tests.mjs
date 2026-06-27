#!/usr/bin/env node
import { spawnSync } from 'node:child_process';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const tests = [
  'scripts/test-min-tile.mjs',
  'scripts/test-level-config.mjs',
  'scripts/test-storage-fallback.mjs',
  'scripts/test-error-handler-fallback.mjs',
  'scripts/test-grid-dom-sync.mjs',
  'scripts/test-critical-fixes.mjs',
  'scripts/test-package2.mjs',
  'scripts/test-menu-navigation.mjs',
  'scripts/test-build-flags.mjs',
];

for (const test of tests) {
  const result = spawnSync(process.execPath, [join(root, test)], {
    cwd: root,
    stdio: 'inherit',
    shell: false,
  });

  if (result.status !== 0) {
    process.exit(result.status ?? 1);
  }
}

console.log('Smoke tests passed.');
