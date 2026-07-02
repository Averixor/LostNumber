#!/usr/bin/env node
/**
 * Debug APK with cheats: sync debug flags → assembleDebug → restore release flags.
 */
import { spawnSync } from 'node:child_process';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const androidDir = join(root, 'android');
const apkPath = join(androidDir, 'app/build/outputs/apk/debug/app-debug.apk');

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
  const gradleCmd =
    process.platform === 'win32'
      ? gradlew
      : process.platform === 'linux' || process.platform === 'darwin'
        ? 'bash'
        : gradlew;
  const gradleArgs =
    process.platform === 'win32' || (process.platform !== 'linux' && process.platform !== 'darwin')
      ? [task]
      : [gradlew, task];
  const result = spawnSync(gradleCmd, gradleArgs, {
    cwd: androidDir,
    stdio: 'inherit',
    shell: false,
  });
  if (result.status !== 0) {
    process.exit(result.status ?? 1);
  }
}

console.log('→ android:sync:debug-cheats');
runNode('scripts/prepare-android.mjs', ['--debug-cheats']);

console.log('→ assembleDebug');
runGradle('assembleDebug');

console.log('→ build:flags:release (restore working tree)');
runNode('scripts/build-flags.mjs', ['release']);

console.log(`\nDebug cheats APK: ${apkPath}`);
console.log('Package: com.averixor.lostnumber.dev');
console.log('Install: adb install -r android/app/build/outputs/apk/debug/app-debug.apk');
