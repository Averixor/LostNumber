#!/usr/bin/env node
import { spawnSync } from 'node:child_process';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');

const steps = [
  ['node_modules/prettier/bin/prettier.cjs', ['--check', '.']],
  ['node_modules/eslint/bin/eslint.js', ['.']],
  ['node_modules/typescript/bin/tsc', ['--noEmit', '-p', 'tsconfig.json']],
  ['scripts/verify-static-assets.mjs', []],
  ['scripts/verify-tagline.mjs', []],
  ['scripts/verify-android-release.mjs', []],
  ['scripts/verify-godot-release.mjs', []],
  ['scripts/smoke-tests.mjs', []],
];

for (const [scriptRel, args] of steps) {
  const script = join(root, scriptRel);
  const result = spawnSync(process.execPath, [script, ...args], {
    cwd: root,
    stdio: 'inherit',
    shell: false,
  });

  if (result.status !== 0) {
    process.exit(result.status ?? 1);
  }
}

console.log('Release checks passed.');
