#!/usr/bin/env node
import { cpSync, mkdirSync, rmSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const outDir = join(root, '_site');
const releaseEntries = ['index.html', 'manifest.json', 'assets', 'audio', 'css', 'js'];

rmSync(outDir, { recursive: true, force: true });
mkdirSync(outDir, { recursive: true });

for (const entry of releaseEntries) {
  cpSync(join(root, entry), join(outDir, entry), { recursive: true });
}

writeFileSync(join(outDir, '.nojekyll'), 'Disable Jekyll processing for this static app.\n');

console.log(`Prepared GitHub Pages artifact in ${outDir}`);
