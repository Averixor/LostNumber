#!/usr/bin/env node
/**
 * Minimal static folder for hosting privacy + account-deletion pages
 * (GitHub Pages, Netlify Drop, Cloudflare Pages).
 */
import { cpSync, mkdirSync, rmSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const outDir = join(root, 'privacy-host');
const pages = ['privacy.html', 'delete-account.html'];

rmSync(outDir, { recursive: true, force: true });
mkdirSync(outDir, { recursive: true });

for (const name of pages) {
  cpSync(join(root, name), join(outDir, name));
}

writeFileSync(
  join(outDir, 'index.html'),
  `<!DOCTYPE html>
<html lang="uk">
  <head>
    <meta charset="utf-8">
    <meta http-equiv="refresh" content="0; url=./privacy.html">
    <title>Lost Number — Privacy</title>
  </head>
  <body>
    <p><a href="./privacy.html">Lost Number — Privacy Policy</a></p>
    <p><a href="./delete-account.html">Lost Number — Delete account</a></p>
  </body>
</html>
`,
);

writeFileSync(
  join(outDir, 'README.txt'),
  `Lost Number — privacy + account deletion host

1. Open https://app.netlify.com/drop
2. Drag this entire folder (privacy-host) onto the page
3. After deploy, open:
   - https://YOUR-SITE.netlify.app/privacy.html
   - https://YOUR-SITE.netlify.app/delete-account.html
4. Use privacy URL in Play Console Store listing + Data safety
5. Use delete-account URL in Account deletion declaration

Or make the GitHub repo public and use GitHub Pages — see docs/PRIVACY_HOSTING.md
`,
);

console.log(`Privacy host package ready: ${outDir}`);
for (const name of pages) {
  console.log(`  - ${name}`);
}
console.log('Next: drag privacy-host/ to https://app.netlify.com/drop');
