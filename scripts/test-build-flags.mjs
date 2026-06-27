#!/usr/bin/env node
/**
 * Smoke tests: generated build flags, release guard, LN_isDevToolsAllowed gate.
 */
import { readFileSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const flagsPath = join(root, 'js/system/build-flags.generated.js');
const indexHtml = readFileSync(join(root, 'index.html'), 'utf8');

let passed = 0;
let failed = 0;

function fail(msg) {
  console.error(`FAIL: ${msg}`);
  failed++;
}

function ok(msg) {
  console.log(`ok: ${msg}`);
  passed++;
}

function assert(cond, msg) {
  if (cond) ok(msg);
  else fail(msg);
}

function readCheatsEnabled(content) {
  const m = content.match(/cheatsEnabled:\s*(true|false)/);
  return m ? m[1] === 'true' : null;
}

function runBuildFlags(mode) {
  const result = spawnSync(process.execPath, [join(root, 'scripts/build-flags.mjs'), mode], {
    cwd: root,
    encoding: 'utf8',
  });
  assert(result.status === 0, `build-flags ${mode} exits 0`);
}

function loadGateFromIndex() {
  const start = indexHtml.indexOf('window.LN_isDevToolsAllowed');
  const end = indexHtml.indexOf('</script>', start);
  const block = indexHtml.slice(0, end);
  const gateStart = block.lastIndexOf('<script>');
  const script = block.slice(gateStart + '<script>'.length);
  globalThis.window = globalThis.window || {};
  const factory = new Function(
    `${script}\nreturn { LN_isDevToolsAllowed: window.LN_isDevToolsAllowed, LN_isLocalDevEnvironment: window.LN_isLocalDevEnvironment };`,
  );
  return factory();
}

assert(
  readCheatsEnabled(readFileSync(flagsPath, 'utf8')) === false,
  'committed release flags false',
);

runBuildFlags('debug-cheats');
assert(
  readCheatsEnabled(readFileSync(flagsPath, 'utf8')) === true,
  'debug-cheats flags true after generator',
);

runBuildFlags('release');
assert(
  readCheatsEnabled(readFileSync(flagsPath, 'utf8')) === false,
  'release flags restored after generator',
);

const hardcodedTrue =
  /cheatsEnabled\s*:\s*true/.test(indexHtml) &&
  !indexHtml.includes('js/system/build-flags.generated.js');
assert(!hardcodedTrue, 'index.html has no hardcoded cheatsEnabled:true (uses generated file)');

assert(
  indexHtml.includes('js/system/build-flags.generated.js'),
  'index.html loads build-flags.generated.js before gate',
);

const gateScriptPos = indexHtml.indexOf('window.LN_isDevToolsAllowed');
const flagsScriptPos = indexHtml.indexOf('build-flags.generated.js');
assert(
  flagsScriptPos > 0 && flagsScriptPos < gateScriptPos,
  'build flags script is before dev tools gate',
);

{
  globalThis.window = {
    LN_BUILD_FLAGS: { cheatsEnabled: true },
    Capacitor: { isNativePlatform: () => true },
    location: { protocol: 'https:', hostname: 'localhost' },
  };
  const gate = loadGateFromIndex();

  assert(
    gate.LN_isDevToolsAllowed() === true,
    'LN_isDevToolsAllowed true when cheatsEnabled=true on Capacitor native',
  );

  window.LN_BUILD_FLAGS = { cheatsEnabled: false };
  assert(
    gate.LN_isDevToolsAllowed() === false,
    'LN_isDevToolsAllowed false on Capacitor native when cheatsEnabled=false',
  );

  delete globalThis.window;
}

{
  const verifyScript = readFileSync(join(root, 'scripts/verify-android-release.mjs'), 'utf8');
  assert(
    verifyScript.includes('verifyBuildFlagsRelease'),
    'verify-android checks release build flags',
  );
  assert(
    verifyScript.includes('verifyNoHardcodedCheats'),
    'verify-android checks hardcoded cheats',
  );
}

console.log(`\n${passed} passed, ${failed} failed`);
process.exit(failed > 0 ? 1 : 0);
