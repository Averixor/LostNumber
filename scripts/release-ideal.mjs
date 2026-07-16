#!/usr/bin/env node
/**
 * Production release gate: repo checks + Godot rules/save tests (if godot4 on PATH).
 */
import { spawnSync } from 'node:child_process';
import { existsSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');

function run(cmd, args, label) {
  console.log(`\n→ ${label}`);
  const result = spawnSync(cmd, args, { cwd: root, stdio: 'inherit', shell: false });
  if (result.status !== 0) {
    process.exit(result.status ?? 1);
  }
}

run(process.execPath, [join(root, 'scripts/release-check.mjs')], 'release:check');

run(process.execPath, [join(root, 'scripts/verify-godot-release.mjs')], 'verify:godot-release');

const godot = process.env.GODOT_BIN || 'godot4';
const hasGodot = spawnSync('which', [godot], { shell: false }).status === 0;

if (hasGodot) {
  run(
    godot,
    ['--path', 'godot', '--headless', '--script', 'res://scripts/tests/run_rules_tests.gd'],
    'godot:test (rules)',
  );
  run(
    godot,
    ['--path', 'godot', '--headless', '--script', 'res://scripts/tests/run_save_tests.gd'],
    'godot:test:save',
  );
} else {
  console.warn('\n⚠ godot4 not found — skipping Godot tests (install Godot 4.3+ for full gate)');
}

const aab = join(root, 'build/android/lost-number.aab');
if (existsSync(aab)) {
  console.log(`\n✓ Godot AAB present: ${aab}`);
} else {
  console.log(
    '\nℹ No prebuilt AAB at build/android/lost-number.aab (run npm run godot:android:release)',
  );
}

console.log('\nRelease ideal checks passed.');
