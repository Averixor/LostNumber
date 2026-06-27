#!/usr/bin/env node
/**
 * Android release prerequisites: Capacitor security, manifest, secrets, web bundle assets.
 * Safe for local dev — runs build:pages only when _site is missing required files.
 */
import { spawnSync } from 'node:child_process';
import { existsSync, readFileSync, statSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const failures = [];

function fail(msg) {
  failures.push(msg);
}

function ok(msg) {
  console.log(`ok: ${msg}`);
}

function readJson(rel) {
  const full = join(root, rel);
  if (!existsSync(full)) {
    fail(`Missing file: ${rel}`);
    return null;
  }
  try {
    return JSON.parse(readFileSync(full, 'utf8'));
  } catch (error) {
    fail(`Invalid JSON in ${rel}: ${error.message}`);
    return null;
  }
}

function assertFile(rel) {
  const full = join(root, rel);
  if (!existsSync(full) || !statSync(full).isFile()) {
    fail(`Missing file: ${rel}`);
    return false;
  }
  ok(`file exists: ${rel}`);
  return true;
}

function verifyCapacitorSecurity() {
  const config = readJson('capacitor.config.json');
  if (!config) return;

  if (config.webDir !== '_site') {
    fail(`capacitor.config.json webDir must be "_site", got "${config.webDir}"`);
  } else {
    ok('capacitor webDir is _site');
  }

  const android = config.android || {};
  if (android.allowMixedContent !== false) {
    fail('capacitor android.allowMixedContent must be false');
  } else {
    ok('capacitor allowMixedContent=false');
  }

  if (android.webContentsDebuggingEnabled !== false) {
    fail('capacitor android.webContentsDebuggingEnabled must be false for release');
  } else {
    ok('capacitor webContentsDebuggingEnabled=false');
  }
}

function verifyAndroidManifest() {
  const manifestPath = join(root, 'android/app/src/main/AndroidManifest.xml');
  if (!existsSync(manifestPath)) {
    fail('AndroidManifest.xml not found');
    return;
  }

  const xml = readFileSync(manifestPath, 'utf8');
  if (!/android:allowBackup\s*=\s*"false"/.test(xml)) {
    fail('AndroidManifest must set android:allowBackup="false"');
  } else {
    ok('AndroidManifest allowBackup=false');
  }
}

function verifyBuildFlagsRelease() {
  const flagsPath = join(root, 'js/system/build-flags.generated.js');
  if (!existsSync(flagsPath)) {
    ok('build flags file absent — gate falls back to cheatsEnabled=false');
    return;
  }

  const content = readFileSync(flagsPath, 'utf8');
  if (/cheatsEnabled\s*:\s*true/.test(content)) {
    fail(
      'js/system/build-flags.generated.js must have cheatsEnabled:false for release (run npm run build:flags:release)',
    );
  } else {
    ok('generated build flags cheatsEnabled=false');
  }
}

function verifyNoHardcodedCheats() {
  const indexPath = join(root, 'index.html');
  if (!existsSync(indexPath)) {
    fail('index.html not found');
    return;
  }

  const html = readFileSync(indexPath, 'utf8');
  if (!html.includes('js/system/build-flags.generated.js')) {
    fail('index.html must load js/system/build-flags.generated.js before dev tools gate');
  } else {
    ok('index.html loads generated build flags');
  }

  const stripped = html.replace(/build-flags\.generated\.js[\s\S]*?<\/script>/g, '');
  if (/cheatsEnabled\s*:\s*true/.test(stripped)) {
    fail('index.html must not hardcode cheatsEnabled:true outside generated flags');
  } else {
    ok('index.html has no hardcoded cheatsEnabled:true');
  }
}

function verifyGradleReleasePackage() {
  const gradlePath = join(root, 'android/app/build.gradle');
  if (!existsSync(gradlePath)) {
    fail('android/app/build.gradle not found');
    return;
  }

  const gradle = readFileSync(gradlePath, 'utf8');
  const releaseBlock = gradle.match(/release\s*\{[\s\S]*?\n\s*\}/);
  if (releaseBlock && /applicationIdSuffix\s*["']\.dev["']/.test(releaseBlock[0])) {
    fail('release buildType must not use applicationIdSuffix .dev');
  } else {
    ok('release buildType has no .dev applicationIdSuffix');
  }

  if (!/debug\s*\{[\s\S]*applicationIdSuffix\s*["']\.dev["']/.test(gradle)) {
    fail('debug buildType should use applicationIdSuffix .dev');
  } else {
    ok('debug buildType uses applicationIdSuffix .dev');
  }
}

function verifyNoSecretsInGit() {
  const patterns = [/keystore/i, /\.jks$/i, /\.keystore$/i, /keystore\.properties$/i];
  const result = spawnSync('git', ['ls-files'], { cwd: root, encoding: 'utf8' });
  if (result.status !== 0) {
    fail('git ls-files failed — cannot verify secrets are not tracked');
    return;
  }

  const tracked = result.stdout.split('\n').filter(Boolean);
  const leaks = tracked.filter((path) => patterns.some((re) => re.test(path)));

  if (leaks.length) {
    for (const path of leaks) {
      fail(`Secret/signing file tracked in git: ${path}`);
    }
  } else {
    ok('no keystore/password files tracked in git');
  }

  const publicImages = tracked.filter((path) => path.startsWith('public/images/'));
  if (publicImages.length) {
    for (const path of publicImages) {
      fail(`Duplicate public/images export tracked in git: ${path}`);
    }
  } else {
    ok('no public/images duplicates tracked in git');
  }
}

function ensureSiteBundle() {
  const required = [
    '_site/assets/images/dark/menu-bg-1.png',
    '_site/assets/images/dark/menu-bg-2.png',
    '_site/assets/images/dark/menu-bg-3.png',
    '_site/assets/images/dark/menu-bg-4.png',
    '_site/assets/images/dark/menu-bg-5.png',
    '_site/assets/images/dark/menu-bg-6.png',
    '_site/assets/images/light/bg-light-01.png',
    '_site/assets/images/light/bg-light-02.png',
    '_site/assets/images/light/bg-light-03.png',
    '_site/assets/images/light/bg-light-04.png',
    '_site/assets/images/light/bg-light-05.png',
    '_site/assets/images/light/bg-light-06.png',
    '_site/assets/icons/neon/icons.json',
    '_site/assets/icons/neon/sprite/lostnumber-icons.svg',
    '_site/css/lostnumber-icons.css',
    '_site/js/ui/icons.js',
    '_site/js/system/build-flags.generated.js',
  ];

  const missing = required.filter((rel) => !existsSync(join(root, rel)));
  if (missing.length === 0) return;

  console.log('→ build:pages (refresh _site for Android bundle check)');
  spawnSync(process.execPath, [join(root, 'scripts/build-flags.mjs'), 'release'], {
    cwd: root,
    stdio: 'inherit',
    shell: false,
  });
  const build = spawnSync(process.execPath, [join(root, 'scripts/build-pages.mjs')], {
    cwd: root,
    stdio: 'inherit',
    shell: false,
  });
  if (build.status !== 0) {
    fail('build:pages failed');
    return;
  }

  for (const rel of required) {
    assertFile(rel);
  }
}

function verifySyncedAssetsOptional() {
  const syncedRoot = join(root, 'android/app/src/main/assets/public');
  if (!existsSync(syncedRoot)) {
    console.log(
      'note: android synced assets not present (run npm run android:sync before APK build)',
    );
    return;
  }

  const syncedChecks = [
    'assets/images/dark/menu-bg-1.png',
    'assets/images/dark/menu-bg-2.png',
    'assets/images/dark/menu-bg-3.png',
    'assets/images/dark/menu-bg-4.png',
    'assets/images/dark/menu-bg-5.png',
    'assets/images/dark/menu-bg-6.png',
    'assets/images/light/bg-light-01.png',
    'assets/images/light/bg-light-02.png',
    'assets/images/light/bg-light-03.png',
    'assets/images/light/bg-light-04.png',
    'assets/images/light/bg-light-05.png',
    'assets/images/light/bg-light-06.png',
    'assets/icons/neon/sprite/lostnumber-icons.svg',
    'js/system/build-flags.generated.js',
  ];
  for (const rel of syncedChecks) {
    const full = join(syncedRoot, rel);
    if (existsSync(full) && statSync(full).isFile()) {
      ok(`synced asset present: android/.../public/${rel}`);
    }
  }
}

verifyCapacitorSecurity();
verifyAndroidManifest();
verifyBuildFlagsRelease();
verifyNoHardcodedCheats();
verifyGradleReleasePackage();
verifyNoSecretsInGit();
ensureSiteBundle();
verifySyncedAssetsOptional();

if (failures.length) {
  console.error('\nAndroid release verification failed:');
  for (const msg of failures) {
    console.error(`  - ${msg}`);
  }
  process.exit(1);
}

console.log('Android release prerequisites passed.');
