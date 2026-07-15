#!/usr/bin/env node
/**
 * Minimal static folder for hosting privacy.html outside GitHub Pages
 * (e.g. Netlify Drop, Cloudflare Pages) when the repo is private.
 */
import { cpSync, mkdirSync, rmSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const src = join(root, 'privacy.html');
const outDir = join(root, 'privacy-host');

rmSync(outDir, { recursive: true, force: true });
mkdirSync(outDir, { recursive: true });

cpSync(src, join(outDir, 'privacy.html'));
writeFileSync(
  join(outDir, 'index.html'),
  `<!doctype html>
<html lang="uk">
  <head>
    <meta charset="utf-8" />
    <meta http-equiv="refresh" content="0; url=./privacy.html" />
    <title>Lost Number — Privacy</title>
  </head>
  <body>
    <p><a href="./privacy.html">Lost Number — Privacy Policy</a></p>
  </body>
</html>
`,
);

writeFileSync(
  join(outDir, 'README.txt'),
  `Lost Number — privacy-only host

1. Open https://app.netlify.com/drop
2. Drag this entire folder (privacy-host) onto the page
3. After deploy, open: https://YOUR-SITE.netlify.app/privacy.html
4. Use that URL in Google Play Console (Store listing + Data safety)

Or make the GitHub repo public and use GitHub Pages — see docs/PRIVACY_HOSTING.md
`,
);

console.log(`Privacy host package ready: ${outDir}`);
console.log('Next: drag privacy-host/ to https://app.netlify.com/drop');
