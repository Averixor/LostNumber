#!/usr/bin/env node
/**
 * Готує web-артефакт (_site/) і синхронізує його з Capacitor Android.
 */
import { spawnSync } from 'node:child_process';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');

function runNode(scriptRel, args = []) {
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

function runCap(args) {
  const capBin = join(root, 'node_modules', '@capacitor', 'cli', 'bin', 'capacitor');
  const result = spawnSync(process.execPath, [capBin, ...args], {
    cwd: root,
    stdio: 'inherit',
    shell: false,
  });
  if (result.status !== 0) {
    process.exit(result.status ?? 1);
  }
}

console.log('→ build:pages');
runNode('scripts/build-pages.mjs');

console.log('→ cap sync android');
runCap(['sync', 'android']);

console.log('Android web assets synced. Open Android Studio: npm run android:open');
