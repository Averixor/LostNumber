#!/usr/bin/env node
/**
 * Fails if forbidden legacy marketing taglines reappear in game i18n or privacy page.
 */
import { existsSync, readdirSync, readFileSync, statSync } from 'node:fs';
import { extname, join, sep } from 'node:path';
import { fileURLToPath } from 'node:url';
import { dirname } from 'node:path';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');

const FORBIDDEN_PATTERNS = [
  /спокійна\s+головоломка/i,
  /спокина\s+головоломка/i,
  /легка\s+логічна\s+puzzle-гра/i,
  /calm\s+number\s+puzzle/i,
  /cozy\s+meditative\s+puzzle/i,
  /echonti\./i,
];

const SCAN_ROOTS = ['privacy.html', 'godot/assets/i18n'];

const TEXT_EXTENSIONS = new Set(['.html', '.json']);

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

function verifyMainSubtitlePresent() {
  for (const lang of ['uk', 'ru', 'en']) {
    const path = join(root, 'godot/assets/i18n', `${lang}.json`);
    if (!existsSync(path)) {
      fail(`Missing i18n file: godot/assets/i18n/${lang}.json`);
      continue;
    }
    const data = JSON.parse(readFileSync(path, 'utf8'));
    if (typeof data.main_subtitle !== 'string' || !data.main_subtitle.trim()) {
      fail(`godot/assets/i18n/${lang}.json must define non-empty main_subtitle`);
    }
    // Require a space after sentence-ending periods (e.g. EN: "numbers. Become").
    if (/\.[^\s."']/.test(data.main_subtitle)) {
      fail(`godot/assets/i18n/${lang}.json main_subtitle must space after period`);
    }
  }
  const enPath = join(root, 'godot/assets/i18n', 'en.json');
  if (existsSync(enPath)) {
    const en = JSON.parse(readFileSync(enPath, 'utf8'));
    if (en.main_subtitle !== 'Connect numbers. Become stronger.') {
      fail('en.json main_subtitle must be exactly "Connect numbers. Become stronger."');
    }
  }
}

for (const target of SCAN_ROOTS) {
  walkScanTarget(target, scanFile);
}

verifyMainSubtitlePresent();

if (failures.length) {
  console.error('Tagline verification failed:');
  for (const failure of failures) {
    console.error(`- ${failure}`);
  }
  process.exit(1);
}

console.log('Tagline verification passed.');
