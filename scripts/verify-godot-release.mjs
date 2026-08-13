#!/usr/bin/env node
/**
 * Godot Android release gate: no secrets in export_presets.cfg, AAB SDK/debug checks.
 */
import { spawnSync } from 'node:child_process';
import { existsSync, mkdtempSync, readFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const failures = [];
const DEBUG_VERSION_NAME = 'dev';
const ANDROID_TARGET_SDK = '36';
const FIREBASE_BOM_VERSION = '34.17.0';
const GOOGLE_SERVICES_PLUGIN_VERSION = '4.5.0';

function fail(msg) {
  failures.push(msg);
}

function ok(msg) {
  console.log(`ok: ${msg}`);
}

function readPresetOptions(content, index) {
  const marker = `[preset.${index}.options]`;
  const start = content.indexOf(marker);
  if (start < 0) {
    fail(`${marker} missing`);
    return '';
  }
  const nextPreset = content.indexOf(`\n[preset.${index + 1}]`, start);
  return content.slice(start + marker.length, nextPreset < 0 ? undefined : nextPreset);
}

function readOption(options, key) {
  const escapedKey = key.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  const match = options.match(new RegExp(`^${escapedKey}=(.+)$`, 'm'));
  return match ? match[1].trim().replace(/^"|"$/g, '') : null;
}

function verifyExportPresetsNoSecrets() {
  const cfgPath = join(root, 'godot/export_presets.cfg');
  if (!existsSync(cfgPath)) {
    fail('godot/export_presets.cfg missing');
    return;
  }

  const content = readFileSync(cfgPath, 'utf8');
  const secretPatterns = [
    /1q2w3e/,
    /keystore\/release_password/i,
    /keystore\/release_user_password/i,
    /store_password/i,
    /key_password/i,
    /keystore_password/i,
  ];

  for (const pattern of secretPatterns) {
    if (pattern.test(content)) {
      fail(`godot/export_presets.cfg contains forbidden secret pattern: ${pattern}`);
    }
  }

  const packageJson = JSON.parse(readFileSync(join(root, 'package.json'), 'utf8'));
  const releaseOptions = readPresetOptions(content, 0);
  const debugOptions = readPresetOptions(content, 1);
  const releaseCode = readOption(releaseOptions, 'version/code');
  const debugCode = readOption(debugOptions, 'version/code');

  const expectedOptions = [
    [releaseOptions, 'package/unique_name', 'com.Averixor.Lost_Number', 'release package'],
    [debugOptions, 'package/unique_name', 'com.Averixor.Lost_Number.dev', 'debug package'],
    [releaseOptions, 'version/name', packageJson.version, 'release versionName'],
    [debugOptions, 'version/name', DEBUG_VERSION_NAME, 'debug versionName'],
    [releaseOptions, 'gradle_build/export_format', '1', 'release AAB format'],
    [debugOptions, 'gradle_build/export_format', '0', 'debug APK format'],
    [releaseOptions, 'package/signed', 'true', 'release signing enabled'],
  ];
  for (const [options, key, expected, label] of expectedOptions) {
    const actual = readOption(options, key);
    if (actual !== expected) {
      fail(`${label} must be ${expected}, got ${actual ?? 'missing'}`);
    }
  }

  if (!releaseCode || releaseCode !== debugCode || !/^[1-9]\d*$/.test(releaseCode)) {
    fail(
      `release/debug versionCode must be the same positive integer, got ${releaseCode}/${debugCode}`,
    );
  } else {
    ok(
      `Android identities: release ${releaseCode} / ${packageJson.version} / ${ANDROID_TARGET_SDK}; ` +
        `debug ${debugCode} / ${DEBUG_VERSION_NAME} / ${ANDROID_TARGET_SDK}`,
    );
  }

  for (const [index, options] of [
    [0, releaseOptions],
    [1, debugOptions],
  ]) {
    const expectedArchitectureOptions = [
      ['architectures/armeabi-v7a', 'false'],
      ['architectures/arm64-v8a', 'true'],
      ['architectures/x86', 'false'],
      ['architectures/x86_64', 'true'],
    ];
    for (const [key, expected] of expectedArchitectureOptions) {
      const actual = readOption(options, key);
      if (actual !== expected) {
        fail(`preset.${index} ${key} must be ${expected}, got ${actual ?? 'missing'}`);
      }
    }
    if (readOption(options, 'permissions/internet') !== 'true') {
      fail(`preset.${index} must set permissions/internet=true for Google Sign-In`);
    }
    for (const mediaKey of [
      'permissions/read_media_images',
      'permissions/read_external_storage',
      'permissions/read_media_visual_user_selected',
    ]) {
      const mediaVal = readOption(options, mediaKey);
      if (mediaVal === 'true') {
        fail(`preset.${index} must not enable ${mediaKey} (system photo picker only)`);
      }
    }
  }
  ok('Android presets enable INTERNET and limit ABIs to arm64-v8a/x86_64');

  const targetSdkPattern = new RegExp(`gradle_build/target_sdk="${ANDROID_TARGET_SDK}"`, 'g');
  const targetSdkMatches = content.match(targetSdkPattern) || [];
  if (targetSdkMatches.length < 2) {
    fail(
      `godot/export_presets.cfg must set target_sdk=${ANDROID_TARGET_SDK} on both Android presets`,
    );
  } else {
    ok(`export_presets target_sdk=${ANDROID_TARGET_SDK} on Android presets`);
  }

  if (!/plugins\/LostNumberFirebase=true/.test(content)) {
    fail('export_presets must enable plugins/LostNumberFirebase=true');
  } else {
    ok('LostNumberFirebase plugin enabled in export presets');
  }

  const excludeFilters = [...content.matchAll(/^exclude_filter="([^"]*)"/gm)].map(
    (match) => match[1],
  );
  if (
    excludeFilters.length < 2 ||
    excludeFilters.some((filter) => !filter.includes('scripts/tests/*'))
  ) {
    fail('all Android presets must exclude scripts/tests/* from packaged builds');
  } else {
    ok('Android presets exclude test and capture scripts');
  }

  ok('export_presets.cfg has no keystore passwords');
}

function verifyPrivacyPolicyMatchesAuthBuild() {
  const privacyPath = join(root, 'privacy.html');
  if (!existsSync(privacyPath)) {
    fail('privacy.html missing');
    return;
  }
  const privacy = readFileSync(privacyPath, 'utf8');
  if (!privacy.includes('<code>user://</code>')) {
    fail('privacy.html must describe local Godot user:// storage');
  }
  if (!/optional.*Google Sign-In/i.test(privacy)) {
    fail('privacy.html English section must describe optional Google Sign-In');
  }
  if (!privacy.includes('<code>INTERNET</code>')) {
    fail('privacy.html must mention INTERNET permission');
  }
  if (/does\s+not\s+request\s+the\s*<code>INTERNET<\/code>\s*permission/i.test(privacy)) {
    fail('privacy.html must not claim INTERNET is absent (Auth-capable build)');
  }
  if (!/Firebase Analytics/i.test(privacy)) {
    fail('privacy.html must state Firebase Analytics is not enabled');
  }
  ok('privacy policy matches Auth-capable INTERNET build (Sign-In only, no Analytics)');
}

function verifyFirebaseGradleWiring() {
  const pluginGradlePath = join(
    root,
    'godot/android/plugins/LostNumberFirebasePlugin/build.gradle',
  );
  const gdapPath = join(root, 'godot/android/plugins/LostNumberFirebase.gdap');
  const exportHookPath = join(root, 'scripts/lib/firebase-android.sh');
  const wiringPaths = [pluginGradlePath, gdapPath, exportHookPath];
  let missing = false;
  for (const path of wiringPaths) {
    if (!existsSync(path)) {
      fail(`Firebase Gradle wiring file missing: ${path}`);
      missing = true;
    }
  }
  if (missing) {
    return;
  }

  const pluginGradle = readFileSync(pluginGradlePath, 'utf8');
  const gdap = readFileSync(gdapPath, 'utf8');
  const exportHook = readFileSync(exportHookPath, 'utf8');
  const bomCoordinate = `com.google.firebase:firebase-bom:${FIREBASE_BOM_VERSION}`;

  if (!pluginGradle.includes(`platform('${bomCoordinate}')`)) {
    fail(`Firebase plugin build.gradle must import BoM ${FIREBASE_BOM_VERSION}`);
  }
  if (!/implementation\s+['"]com\.google\.firebase:firebase-auth['"]/.test(pluginGradle)) {
    fail('Firebase plugin build.gradle must declare versionless firebase-auth via the BoM');
  }
  // Godot .gdap remote[] entries are plain Maven coordinates — Gradle platform() is invalid here.
  const gdapRemote = (gdap.match(/^remote=\[.*\]$/m) || [''])[0];
  if (/platform\s*\(/.test(gdapRemote)) {
    fail('LostNumberFirebase.gdap must not use Gradle platform(...) in remote dependencies');
  }
  if (!/"com\.google\.firebase:firebase-auth:\d+\.\d+\.\d+"/.test(gdapRemote)) {
    fail('LostNumberFirebase.gdap must pin an explicit firebase-auth:x.y.z Maven coordinate');
  }
  if (
    !exportHook.includes(
      `com.google.gms.google-services' version '${GOOGLE_SERVICES_PLUGIN_VERSION}'`,
    )
  ) {
    fail(`Firebase export hook must install google-services ${GOOGLE_SERVICES_PLUGIN_VERSION}`);
  }
  if (/firebase-analytics/.test(`${pluginGradle}\n${gdap}`)) {
    fail('Firebase Analytics must not be added to the Auth-only build');
  }

  ok(
    `Firebase Gradle wiring: BoM ${FIREBASE_BOM_VERSION} (AAR), pinned Auth in .gdap, ` +
      `google-services ${GOOGLE_SERVICES_PLUGIN_VERSION}`,
  );
}

function resolveAapt2() {
  const sdk = process.env.ANDROID_HOME || join(process.env.HOME || '', 'Android/Sdk');
  for (const version of ['35.0.0', '36.1.0', '34.0.0', '37.0.0']) {
    const tool = join(sdk, 'build-tools', version, 'aapt2');
    if (existsSync(tool)) {
      return tool;
    }
  }
  return null;
}

function resolveBundletoolJar() {
  const candidates = [
    process.env.BUNDLETOOL_JAR,
    join(root, 'tools/bundletool-all.jar'),
    join(root, 'bundletool.jar'),
    join(process.env.HOME || '', '.local/share/bundletool/bundletool-all.jar'),
  ].filter(Boolean);
  for (const jar of candidates) {
    if (existsSync(jar)) {
      return jar;
    }
  }
  return null;
}

function extractAabContract(aabPath) {
  const workDir = mkdtempSync(join(tmpdir(), 'ln-aab-contract-'));
  try {
    const unzipManifest = spawnSync('unzip', ['-p', aabPath, 'base/manifest/AndroidManifest.xml'], {
      encoding: 'buffer',
      maxBuffer: 20 * 1024 * 1024,
    });
    if (unzipManifest.status !== 0 || !unzipManifest.stdout || unzipManifest.stdout.length < 32) {
      return { error: 'failed to extract base/manifest/AndroidManifest.xml from AAB' };
    }
    // Binary XML — use strings for contract probes.
    const stringsResult = spawnSync('strings', ['-n', '4'], {
      input: unzipManifest.stdout,
      encoding: 'utf8',
      maxBuffer: 20 * 1024 * 1024,
    });
    const blob = `${stringsResult.stdout || ''}\n${unzipManifest.stdout.toString('latin1')}`;
    const listing = spawnSync('unzip', ['-l', aabPath], { encoding: 'utf8' });
    const listText = listing.stdout || '';
    // Probe Firebase google-services resource strings (plugin marker alone is insufficient).
    const resourceEntries = ['base/resources.pb', 'base/assets/google-services.json'];
    let resourceBlob = '';
    for (const entry of resourceEntries) {
      if (!listText.includes(entry)) {
        continue;
      }
      const extracted = spawnSync('unzip', ['-p', aabPath, entry], {
        encoding: 'buffer',
        maxBuffer: 40 * 1024 * 1024,
      });
      if (extracted.status === 0 && extracted.stdout?.length) {
        const asText = spawnSync('strings', ['-n', '4'], {
          input: extracted.stdout,
          encoding: 'utf8',
          maxBuffer: 40 * 1024 * 1024,
        });
        resourceBlob += `\n${asText.stdout || ''}\n${extracted.stdout.toString('latin1')}`;
      }
    }
    if (!resourceBlob || !/google_app_id/.test(resourceBlob)) {
      // Zip-compressed AAB still exposes many resource name strings to `strings`.
      const aabStrings = spawnSync('strings', ['-n', '8', aabPath], {
        encoding: 'utf8',
        maxBuffer: 80 * 1024 * 1024,
      });
      resourceBlob += `\n${aabStrings.stdout || ''}`;
    }
    return {
      blob,
      listText,
      hasInternet: /android\.permission\.INTERNET/.test(blob),
      hasReadMediaImages: /android\.permission\.READ_MEDIA_IMAGES/.test(blob),
      hasReadExternalStorage: /android\.permission\.READ_EXTERNAL_STORAGE/.test(blob),
      packageName: (blob.match(/com\.Averixor\.Lost_Number(?:\.dev)?/) || [])[0] || null,
      hasFirebasePluginMeta: /LostNumberFirebase/.test(blob) || /LostNumberFirebase/.test(listText),
      hasMigrationOnly: /LostNumberMigration/.test(blob) || /LostNumberMigration/.test(listText),
      hasGoogleAppId: /google_app_id/.test(resourceBlob),
      hasDefaultWebClientId: /default_web_client_id/.test(resourceBlob),
      hasFirebaseProjectId:
        /project_id/.test(resourceBlob) || /gcm_defaultSenderId/.test(resourceBlob),
    };
  } finally {
    rmSync(workDir, { recursive: true, force: true });
  }
}

function verifyAab(aabPath) {
  if (!existsSync(aabPath)) {
    console.log(
      `note: AAB not found at ${aabPath} — skipping AAB artifact checks (presets still gated)`,
    );
    return;
  }

  ok(`AAB present: ${aabPath}`);

  const contract = extractAabContract(aabPath);
  if (contract.error) {
    fail(contract.error);
    return;
  }

  if (contract.packageName !== 'com.Averixor.Lost_Number') {
    fail(`AAB package must be com.Averixor.Lost_Number, got ${contract.packageName ?? 'unknown'}`);
  } else {
    ok('AAB package is com.Averixor.Lost_Number');
  }

  if (!contract.hasInternet) {
    fail('AAB missing android.permission.INTERNET (Auth-capable source contract)');
  } else {
    ok('AAB declares INTERNET');
  }

  if (contract.hasReadMediaImages || contract.hasReadExternalStorage) {
    fail(
      'AAB must not declare broad READ_MEDIA_IMAGES / READ_EXTERNAL_STORAGE (use system picker)',
    );
  } else {
    ok('AAB has no broad photo/storage permissions');
  }

  if (!contract.hasFirebasePluginMeta && !contract.hasMigrationOnly) {
    fail('AAB missing expected Android plugin metadata markers');
  } else if (!contract.hasFirebasePluginMeta) {
    fail('AAB missing LostNumberFirebase plugin (source enables Auth bridge)');
  } else {
    ok('AAB includes LostNumberFirebase plugin marker');
  }

  // Hard-fail Firebase resources only when OWNER already placed prod JSON (rebuild expected).
  // Without JSON in repo, CI/local may still have a stale AAB — warn, do not block merge.
  const prodJson = join(root, 'android/firebase/prod/google-services.json');
  const missingFirebaseResources = [];
  if (!contract.hasGoogleAppId) {
    missingFirebaseResources.push('google_app_id');
  }
  if (!contract.hasDefaultWebClientId) {
    missingFirebaseResources.push('default_web_client_id');
  }
  if (!contract.hasFirebaseProjectId) {
    missingFirebaseResources.push('project_id/gcm_defaultSenderId');
  }
  if (missingFirebaseResources.length) {
    const detail = missingFirebaseResources.join(', ');
    if (existsSync(prodJson)) {
      fail(
        `AAB missing Firebase config resources (${detail}). ` +
          'Rebuild after android/firebase/prod/google-services.json before Closed Testing',
      );
    } else {
      console.log(
        `note: AAB missing Firebase resources (${detail}) — CT NO-GO until OWNER places ` +
          'android/firebase/prod/google-services.json and rebuilds',
      );
    }
  } else {
    ok('AAB includes Firebase google-services resources (app id / web client / project)');
  }

  const aapt2 = resolveAapt2();
  const bundletoolJar = resolveBundletoolJar();
  let manifestXml = null;

  if (bundletoolJar) {
    const workDir = mkdtempSync(join(tmpdir(), 'ln-aab-'));
    try {
      const apksPath = join(workDir, 'out.apks');
      const extractResult = spawnSync(
        'java',
        [
          '-jar',
          bundletoolJar,
          'build-apks',
          '--bundle',
          aabPath,
          '--output',
          apksPath,
          '--mode=universal',
          '--overwrite',
        ],
        { cwd: root, encoding: 'utf8' },
      );
      if (extractResult.status !== 0) {
        fail(`bundletool build-apks failed: ${extractResult.stderr || extractResult.stdout}`);
      } else {
        const unzipDir = join(workDir, 'unzipped');
        const unzipResult = spawnSync('unzip', ['-qo', apksPath, '-d', unzipDir], {
          cwd: root,
          encoding: 'utf8',
        });
        if (unzipResult.status !== 0) {
          fail('failed to unzip universal APK from bundletool output');
        } else {
          const universalApk = join(unzipDir, 'universal.apk');
          if (!existsSync(universalApk)) {
            fail('universal.apk missing from bundletool output');
          } else if (aapt2) {
            const dump = spawnSync(aapt2, ['dump', 'badging', universalApk], {
              cwd: root,
              encoding: 'utf8',
            });
            if (dump.status === 0) {
              manifestXml = dump.stdout;
            }
          }
        }
      }
    } finally {
      rmSync(workDir, { recursive: true, force: true });
    }
  }

  if (manifestXml) {
    const targetSdkMatch = manifestXml.match(/targetSdkVersion:'(\d+)'/);
    if (!targetSdkMatch) {
      fail('could not read targetSdkVersion from release AAB');
    } else {
      const targetSdk = Number(targetSdkMatch[1]);
      if (targetSdk < Number(ANDROID_TARGET_SDK)) {
        fail(`release AAB targetSdkVersion must be >= ${ANDROID_TARGET_SDK}, got ${targetSdk}`);
      } else {
        ok(`release AAB targetSdkVersion=${targetSdk}`);
      }
    }

    if (/application-debuggable/.test(manifestXml)) {
      fail('release AAB must not be debuggable');
    } else {
      ok('release AAB is not debuggable');
    }
    return;
  }

  // Never treat Godot Gradle intermediates as proof of the shipped AAB.
  fail(
    'could not dump AAB badging (install bundletool + aapt2). Refusing false-green from Gradle merged manifest',
  );
}

verifyExportPresetsNoSecrets();
verifyPrivacyPolicyMatchesAuthBuild();
verifyFirebaseGradleWiring();
verifyAab(join(root, 'build/android/lost-number.aab'));

if (failures.length) {
  console.error('\nGodot release verification failed:');
  for (const msg of failures) {
    console.error(`  - ${msg}`);
  }
  process.exit(1);
}

console.log('Godot release verification passed.');
