#!/usr/bin/env node
import { cpSync, existsSync, mkdirSync, rmSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const outDir = join(root, '_site');
const debugCheats = process.argv.includes('--debug-cheats');
const releaseEntries = ['index.html', 'manifest.json', 'privacy.html', 'assets', 'css', 'js'];

// Dev/cheat JS paths that must NOT ship in release artifacts.
const DEV_PATHS_IN_SITE = [
  'js/app/dev',
  'js/system/dev',
  'js/ui/overlays/DebugOverlay.js',
];

rmSync(outDir, { recursive: true, force: true });
mkdirSync(outDir, { recursive: true });

for (const entry of releaseEntries) {
  cpSync(join(root, entry), join(outDir, entry), { recursive: true });
}

mkdirSync(join(outDir, 'audio'), { recursive: true });
for (const subdir of ['music', 'sfx']) {
  cpSync(join(root, 'public', 'audio', subdir), join(outDir, 'audio', subdir), {
    recursive: true,
  });
}

writeFileSync(join(outDir, '.nojekyll'), 'Disable Jekyll processing for this static app.\n');

if (!debugCheats) {
  for (const rel of DEV_PATHS_IN_SITE) {
    const full = join(outDir, rel);
    if (existsSync(full)) {
      rmSync(full, { recursive: true, force: true });
    }
  }
  console.log('Removed dev/cheat JS from release artifact.');
}

console.log(`Prepared GitHub Pages artifact in ${outDir} (${debugCheats ? 'debug-cheats' : 'release'}).`);
