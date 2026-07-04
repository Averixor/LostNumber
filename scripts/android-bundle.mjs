#!/usr/bin/env node
/**
 * Release AAB for Google Play: sync release flags → bundleRelease.
 */
import { spawnSync } from 'node:child_process';
import { copyFileSync, existsSync, mkdirSync, statSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const androidDir = join(root, 'android');
const aabPath = join(androidDir, 'app/build/outputs/bundle/release/app-release.aab');
const releaseDir = join(root, 'build', 'releases');

function makeStamp() {
  const now = new Date();
  const yyyy = String(now.getFullYear());
  const mm = String(now.getMonth() + 1).padStart(2, '0');
  const dd = String(now.getDate()).padStart(2, '0');
  const hh = String(now.getHours()).padStart(2, '0');
  const mi = String(now.getMinutes()).padStart(2, '0');
  const ss = String(now.getSeconds()).padStart(2, '0');
  return `${yyyy}${mm}${dd}-${hh}${mi}${ss}`;
}

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

const keystoreProps = join(androidDir, 'keystore.properties');
if (!existsSync(keystoreProps)) {
  console.error(
    'Missing android/keystore.properties — create a release keystore and properties file before bundleRelease.',
  );
  console.error('See docs/PLAY_STORE.md → «Підпис release».');
  process.exit(1);
}

console.log('→ android:sync (release flags)');
runNode('scripts/prepare-android.mjs');

console.log('→ bundleRelease');
runGradle('bundleRelease');

if (!existsSync(aabPath)) {
  console.error(`AAB not found at ${aabPath}`);
  process.exit(1);
}

mkdirSync(releaseDir, { recursive: true });
const stampedAabPath = join(releaseDir, `lostnumber-release-${makeStamp()}.aab`);
copyFileSync(aabPath, stampedAabPath);
const stampedStats = statSync(stampedAabPath);

console.log(`\nRelease AAB: ${aabPath}`);
console.log(`Saved copy: ${stampedAabPath}`);
console.log(`Size: ${(stampedStats.size / (1024 * 1024)).toFixed(1)} MB`);
console.log('Package: com.averixor.lostnumber');
console.log('Upload this file in Play Console → Testing → Closed testing → Create release.');
