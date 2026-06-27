#!/usr/bin/env node
/**
 * Release APK without cheats: sync release flags → assembleRelease.
 */
import { spawnSync } from 'node:child_process';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const androidDir = join(root, 'android');
const apkPath = join(androidDir, 'app/build/outputs/apk/release/app-release.apk');

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

function runGradle(task) {
  const gradlew = join(androidDir, process.platform === 'win32' ? 'gradlew.bat' : 'gradlew');
  const result = spawnSync(gradlew, [task], {
    cwd: androidDir,
    stdio: 'inherit',
    shell: false,
  });
  if (result.status !== 0) {
    process.exit(result.status ?? 1);
  }
}

console.log('→ android:sync (release flags)');
runNode('scripts/prepare-android.mjs');

console.log('→ assembleRelease');
runGradle('assembleRelease');

console.log(`\nRelease APK: ${apkPath}`);
console.log('Package: com.averixor.lostnumber');
