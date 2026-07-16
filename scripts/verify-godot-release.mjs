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

function fail(msg) {
  failures.push(msg);
}

function ok(msg) {
  console.log(`ok: ${msg}`);
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

  if (!/gradle_build\/target_sdk="35"/.test(content)) {
    fail('godot/export_presets.cfg must set gradle_build/target_sdk="35" on all Android presets');
  } else {
    const targetSdkMatches = content.match(/gradle_build\/target_sdk="35"/g) || [];
    if (targetSdkMatches.length < 2) {
      fail('godot/export_presets.cfg must set target_sdk=35 on both Android presets');
    } else {
      ok('export_presets target_sdk=35 on Android presets');
    }
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

function readMergedReleaseManifest() {
  const manifestPath = join(
    root,
    'godot/android/build/build/intermediates/merged_manifests/standardRelease/processStandardReleaseManifest/AndroidManifest.xml',
  );
  if (!existsSync(manifestPath)) {
    return null;
  }
  return readFileSync(manifestPath, 'utf8');
}

function verifyManifestText(manifestText, sourceLabel) {
  const targetSdkMatch = manifestText.match(/android:targetSdkVersion="(\d+)"/);
  if (!targetSdkMatch) {
    fail(`could not read targetSdkVersion from ${sourceLabel}`);
  } else {
    const targetSdk = Number(targetSdkMatch[1]);
    if (targetSdk < 35) {
      fail(`release manifest targetSdkVersion must be >= 35, got ${targetSdk} (${sourceLabel})`);
    } else {
      ok(`release manifest targetSdkVersion=${targetSdk} (${sourceLabel})`);
    }
  }

  if (/android:debuggable="true"/.test(manifestText)) {
    fail(`release manifest must not be debuggable (${sourceLabel})`);
  } else {
    ok(`release manifest is not debuggable (${sourceLabel})`);
  }
}

function verifyAab(aabPath) {
  if (!existsSync(aabPath)) {
    console.log(`note: AAB not found at ${aabPath} — skipping AAB manifest checks`);
    return;
  }

  ok(`AAB present: ${aabPath}`);

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
        return;
      }

      const unzipDir = join(workDir, 'unzipped');
      const unzipResult = spawnSync('unzip', ['-qo', apksPath, '-d', unzipDir], {
        cwd: root,
        encoding: 'utf8',
      });
      if (unzipResult.status !== 0) {
        fail('failed to unzip universal APK from bundletool output');
        return;
      }

      const universalApk = join(unzipDir, 'universal.apk');
      if (!existsSync(universalApk)) {
        fail('universal.apk missing from bundletool output');
        return;
      }

      if (aapt2) {
        const dump = spawnSync(aapt2, ['dump', 'badging', universalApk], {
          cwd: root,
          encoding: 'utf8',
        });
        if (dump.status === 0) {
          manifestXml = dump.stdout;
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
      if (targetSdk < 35) {
        fail(`release AAB targetSdkVersion must be >= 35, got ${targetSdk}`);
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

  const mergedManifest = readMergedReleaseManifest();
  if (mergedManifest) {
    verifyManifestText(mergedManifest, 'Godot Gradle merged manifest');
    return;
  }

  console.log(
    'note: bundletool/AAB badging unavailable and Gradle manifest missing — skipping AAB SDK checks',
  );
}

verifyExportPresetsNoSecrets();
verifyAab(join(root, 'build/android/lost-number.aab'));

if (failures.length) {
  console.error('\nGodot release verification failed:');
  for (const msg of failures) {
    console.error(`  - ${msg}`);
  }
  process.exit(1);
}

console.log('Godot release verification passed.');
