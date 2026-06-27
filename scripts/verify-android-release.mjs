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
    '_site/assets/images/background.png',
    '_site/assets/images/background-alt.png',
    '_site/assets/images/background-alt2.png',
    '_site/assets/icons/neon/icons.json',
    '_site/assets/icons/neon/sprite/lostnumber-icons.svg',
    '_site/css/lostnumber-icons.css',
    '_site/js/ui/icons.js',
  ];

  const missing = required.filter((rel) => !existsSync(join(root, rel)));
  if (missing.length === 0) return;

  console.log('→ build:pages (refresh _site for Android bundle check)');
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
    'assets/images/background.png',
    'assets/icons/neon/sprite/lostnumber-icons.svg',
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
