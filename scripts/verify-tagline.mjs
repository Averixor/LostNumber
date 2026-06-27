#!/usr/bin/env node
/**
 * Fails if the legacy marketing tagline reappears in sources or shipped static assets.
 */
import { existsSync, readdirSync, readFileSync, statSync } from 'node:fs';
import { extname, join, sep } from 'node:path';
import { fileURLToPath } from 'node:url';
import { dirname } from 'node:path';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');

export const NEW_TAGLINE = 'Panta mēn ta gignōskomena arithmon echontikai panta ga man';

const FORBIDDEN_PATTERNS = [
  /спокійна\s+головоломка/i,
  /спокина\s+головоломка/i,
  /\bголоволомка\b/i,
  /\bшифр\b/i,
  /грай\s+у\s+своєму\s+темпі/i,
  /играй\s+в\s+твоем\s+темпе/i,
  /без\s+таймерів/i,
  /без\s+таймеров/i,
  /без\s+підрахунків/i,
  /без\s+подсчётов/i,
  /без\s+подсчетов/i,
  /calm\s+number\s+puzzle/i,
  /play\s+at\s+your\s+own\s+pace/i,
  /no\s+timers/i,
  /no\s+rush/i,
  /no\s+time\s+limits/i,
  /cozy\s+meditative\s+puzzle/i,
  /легка\s+логічна\s+puzzle-гра/i,
  /echonti\./i,
];

const SCAN_ROOTS = [
  'index.html',
  'manifest.json',
  'README.md',
  'PROJECT_STRUCTURE.md',
  'docs',
  'js',
  'css',
  '_site',
  join('android', 'app', 'src', 'main', 'assets', 'public'),
];

const TEXT_EXTENSIONS = new Set(['.html', '.js', '.json', '.md', '.css']);

const SKIP_DIR_NAMES = new Set([
  'node_modules',
  '.git',
  'build',
  'dist',
  '.gradle',
  'capacitor-cordova-android-plugins',
]);

const failures = [];

function fail(message) {
  failures.push(message);
}

function walkScanTarget(targetRel, callback) {
  const full = join(root, targetRel);
  if (!existsSync(full)) return;

  const stat = statSync(full);
  if (stat.isFile()) {
    callback(full, targetRel);
    return;
  }

  if (!stat.isDirectory()) return;

  function walkDir(dirFull, dirRel) {
    for (const entry of readdirSync(dirFull, { withFileTypes: true })) {
      if (entry.isDirectory()) {
        if (SKIP_DIR_NAMES.has(entry.name)) continue;
        walkDir(join(dirFull, entry.name), join(dirRel, entry.name));
        continue;
      }
      if (!entry.isFile()) continue;
      const rel = join(dirRel, entry.name).split(sep).join('/');
      callback(join(dirFull, entry.name), rel);
    }
  }

  walkDir(full, targetRel.split(sep).join('/'));
}

function scanFile(fullPath, relPath) {
  const ext = extname(relPath).toLowerCase();
  if (!TEXT_EXTENSIONS.has(ext)) return;

  const text = readFileSync(fullPath, 'utf8');
  const lines = text.split(/\r?\n/);

  for (const pattern of FORBIDDEN_PATTERNS) {
    for (let index = 0; index < lines.length; index += 1) {
      if (pattern.test(lines[index])) {
        fail(`${relPath}:${index + 1} matches forbidden legacy tagline (${pattern})`);
      }
    }
  }
}

function verifyRequiredTagline() {
  const i18n = readFileSync(join(root, 'js/system/i18n/i18n.js'), 'utf8');
  for (const lang of ['ua', 'ru', 'en']) {
    const block =
      lang === 'ua'
        ? i18n.match(/ua:\s*\{([\s\S]*?)\n\s*ru:\s*\{/)?.[1]
        : lang === 'ru'
          ? i18n.match(/ru:\s*\{([\s\S]*?)\n\s*en:\s*\{/)?.[1]
          : i18n.match(/en:\s*\{([\s\S]*?)\n\s*\},?\s*\n/)?.[1];
    if (!block?.includes(`main_subtitle: '${NEW_TAGLINE}'`)) {
      fail(`js/system/i18n/i18n.js ${lang}.main_subtitle must equal NEW_TAGLINE`);
    }
  }

  const manifest = JSON.parse(readFileSync(join(root, 'manifest.json'), 'utf8'));
  if (manifest.description !== NEW_TAGLINE) {
    fail('manifest.json description must equal NEW_TAGLINE');
  }

  const indexHtml = readFileSync(join(root, 'index.html'), 'utf8');
  if (!indexHtml.includes(`content="${NEW_TAGLINE}"`)) {
    fail('index.html meta/og description must include NEW_TAGLINE');
  }
}

for (const target of SCAN_ROOTS) {
  walkScanTarget(target, scanFile);
}

verifyRequiredTagline();

if (failures.length) {
  console.error('Tagline verification failed:');
  for (const failure of failures) {
    console.error(`- ${failure}`);
  }
  process.exit(1);
}

console.log(`Tagline verification passed (${NEW_TAGLINE}).`);
