#!/usr/bin/env node
/**
 * Verifies _site and synced Android public assets include CSS, JS, and audio.
 */
import { existsSync, readdirSync, statSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');

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

function countFiles(dir, ext) {
  if (!existsSync(dir)) return 0;
  let n = 0;
  for (const name of readdirSync(dir)) {
    const p = join(dir, name);
    const st = statSync(p);
    if (st.isDirectory()) n += countFiles(p, ext);
    else if (!ext || name.endsWith(ext)) n++;
  }
  return n;
}

function checkBundle(baseLabel, basePath) {
  const cssDir = join(basePath, 'css');
  const jsDir = join(basePath, 'js');
  const audioDir = join(basePath, 'audio');
  const indexHtml = join(basePath, 'index.html');

  assert(existsSync(indexHtml), `${baseLabel}: index.html present`);
  assert(countFiles(cssDir, '.css') > 0, `${baseLabel}: CSS files present`);
  assert(countFiles(jsDir, '.js') > 0, `${baseLabel}: JS files present`);
  assert(countFiles(audioDir, '.mp3') > 0, `${baseLabel}: audio mp3 files present`);
}

console.log('→ build:pages');
const build = spawnSync(process.execPath, [join(root, 'scripts/build-pages.mjs')], {
  cwd: root,
  stdio: 'inherit',
});
if (build.status !== 0) process.exit(build.status ?? 1);

const siteDir = join(root, '_site');
checkBundle('_site', siteDir);

console.log('→ cap sync android (assets only check follows)');
const cap = spawnSync(
  process.execPath,
  [join(root, 'node_modules/@capacitor/cli/bin/capacitor'), 'sync', 'android'],
  { cwd: root, stdio: 'inherit' },
);
if (cap.status !== 0) process.exit(cap.status ?? 1);

const androidPublic = join(root, 'android/app/src/main/assets/public');
checkBundle('android public', androidPublic);

console.log(`\n${passed} passed, ${failed} failed`);
process.exit(failed > 0 ? 1 : 0);
