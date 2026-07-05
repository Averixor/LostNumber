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

  if (!/android:dataExtractionRules\s*=/.test(xml)) {
    fail('AndroidManifest must declare android:dataExtractionRules for API 31+');
  } else {
    ok('AndroidManifest dataExtractionRules present');
  }

  const appIdx = xml.indexOf('<application');
  const permIdx = xml.indexOf('<uses-permission');
  if (permIdx === -1 || appIdx === -1 || permIdx > appIdx) {
    fail('AndroidManifest uses-permission must appear before <application>');
  } else {
    ok('AndroidManifest permissions before application');
  }
}

// Dev/cheat JS paths that must NOT exist in release artifacts.
const DEV_RELEASE_PATHS = [
  { base: '_site', rel: 'js/app/dev' },
  { base: '_site', rel: 'js/system/dev' },
  { base: '_site', rel: 'js/ui/overlays/DebugOverlay.js' },
  { base: 'android/app/src/main/assets/public', rel: 'js/app/dev' },
  { base: 'android/app/src/main/assets/public', rel: 'js/system/dev' },
  { base: 'android/app/src/main/assets/public', rel: 'js/ui/overlays/DebugOverlay.js' },
];

function verifyNoDevFiles() {
  for (const { base, rel } of DEV_RELEASE_PATHS) {
    const full = join(root, base, rel);
    if (existsSync(full)) {
      fail(
        `Dev/cheat file found in release artifact: ${base}/${rel} — run npm run android:sync (release) or npm run build:pages`,
      );
    } else {
      ok(`dev path absent from release artifact: ${base}/${rel}`);
    }
  }
}

function verifyAudioBundle() {
  const forbidden = join(root, '_site/audio/music_original');
  if (existsSync(forbidden)) {
    fail('_site/audio/music_original must not be shipped (use audio-sources/ for masters)');
    return;
  }
  ok('audio bundle excludes music_original');

  const audioRoot = join(root, '_site/audio');
  if (!existsSync(audioRoot)) {
    return;
  }
  for (const sub of ['music', 'sfx']) {
    const dir = join(audioRoot, sub);
    if (!existsSync(dir)) {
      fail(`_site/audio/${sub} missing from release bundle`);
    }
  }
  if (existsSync(join(audioRoot, 'music')) && existsSync(join(audioRoot, 'sfx'))) {
    ok('_site/audio contains only music and sfx');
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

function verifyBundledBuildFlagsRelease() {
  const checks = [
    ['_site/js/system/build-flags.generated.js', '_site release build flags'],
    [
      'android/app/src/main/assets/public/js/system/build-flags.generated.js',
      'Android synced release build flags',
    ],
  ];

  for (const [rel, label] of checks) {
    const full = join(root, rel);
    if (!existsSync(full)) {
      console.log(`note: ${label} missing (${rel})`);
      continue;
    }

    const content = readFileSync(full, 'utf8');
    if (/cheatsEnabled\s*:\s*true/.test(content)) {
      fail(`${label} must have cheatsEnabled:false (${rel}); run npm run android:sync`);
    } else {
      ok(`${label} cheatsEnabled=false`);
    }
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
  const secretPathPatterns = [
    /(^|\/)android\/keystore(\/|$)/i,
    /(^|\/)keystore\.properties$/i,
    /\.jks$/i,
    /\.keystore$/i,
  ];

  const result = spawnSync('git', ['ls-files'], { cwd: root, encoding: 'utf8' });
  if (result.status !== 0) {
    ok('git index absent — archive mode, skipping tracked-secret check');
    return;
  }

  const tracked = result.stdout.split('\n').filter(Boolean);
  const leaks = tracked.filter((path) => secretPathPatterns.some((re) => re.test(path)));

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

  const syncedFlagsPath = join(syncedRoot, 'js/system/build-flags.generated.js');
  if (!existsSync(syncedFlagsPath)) {
    fail('android synced build flags missing (run npm run android:sync before Android release)');
    return;
  }

  const syncedFlags = readFileSync(syncedFlagsPath, 'utf8');
  if (/cheatsEnabled\s*:\s*true/.test(syncedFlags)) {
    fail(
      'android synced assets have cheatsEnabled:true (run npm run android:sync before Android release)',
    );
  } else {
    ok('android synced build flags cheatsEnabled=false');
  }
}

verifyCapacitorSecurity();
verifyAndroidManifest();
verifyBuildFlagsRelease();
verifyNoHardcodedCheats();
verifyGradleReleasePackage();
verifyNoSecretsInGit();
ensureSiteBundle();
verifyNoDevFiles();
verifyBundledBuildFlagsRelease();
verifyAudioBundle();
verifySyncedAssetsOptional();

if (failures.length) {
  console.error('\nAndroid release verification failed:');
  for (const msg of failures) {
    console.error(`  - ${msg}`);
  }
  process.exit(1);
}

console.log('Android release prerequisites passed.');
