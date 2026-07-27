#!/usr/bin/env node
/**
 * Google Play store-listing gate: localized copy limits/sync and graphic assets.
 */
import { existsSync, readFileSync, readdirSync, statSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const failures = [];

function fail(message) {
  failures.push(message);
}

function ok(message) {
  console.log(`ok: ${message}`);
}

function text(path) {
  if (!existsSync(path)) {
    fail(`missing file: ${path}`);
    return '';
  }
  return readFileSync(path, 'utf8').trim();
}

function characterCount(value) {
  return Array.from(value).length;
}

function pngInfo(path) {
  if (!existsSync(path)) {
    fail(`missing PNG: ${path}`);
    return null;
  }
  const data = readFileSync(path);
  const signature = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
  if (data.length < 26 || !data.subarray(0, 8).equals(signature)) {
    fail(`not a valid PNG: ${path}`);
    return null;
  }
  if (data.toString('ascii', 12, 16) !== 'IHDR') {
    fail(`PNG has no IHDR header: ${path}`);
    return null;
  }
  return {
    width: data.readUInt32BE(16),
    height: data.readUInt32BE(20),
    bitDepth: data[24],
    colorType: data[25],
    bytes: statSync(path).size,
  };
}

function verifyPng(relativePath, width, height, options = {}) {
  const path = join(root, relativePath);
  const info = pngInfo(path);
  if (!info) return;

  if (info.width !== width || info.height !== height) {
    fail(`${relativePath} must be ${width}x${height}, got ${info.width}x${info.height}`);
  }
  if (options.noAlpha && ![0, 2].includes(info.colorType)) {
    fail(`${relativePath} must not have an alpha channel`);
  }
  if (options.maxBytes && info.bytes > options.maxBytes) {
    fail(`${relativePath} exceeds ${options.maxBytes} bytes (${info.bytes})`);
  }
  if (info.bitDepth !== 8) {
    fail(`${relativePath} must use 8-bit channels, got ${info.bitDepth}`);
  }

  ok(
    `${relativePath} ${info.width}x${info.height}, ${info.bytes} bytes, PNG color type ${info.colorType}`,
  );
}

const listingPaths = [
  join(root, 'store/PLAY_CONSOLE_LISTING.md'),
  join(root, 'docs/PLAY_CONSOLE_LISTING.md'),
];
const listings = listingPaths.map(text);

for (const locale of ['uk', 'en', 'ru']) {
  const shortPath = join(root, `docs/store-listing/short-description-${locale}.txt`);
  const fullPath = join(root, `docs/store-listing/full-description-${locale}.txt`);
  const shortDescription = text(shortPath);
  const fullDescription = text(fullPath);
  const shortLength = characterCount(shortDescription);
  const fullLength = characterCount(fullDescription);

  if (!shortDescription || shortDescription.includes('\n')) {
    fail(`${shortPath} must contain one non-empty line`);
  }
  if (shortLength > 80) {
    fail(`${shortPath} exceeds 80 characters (${shortLength})`);
  }
  if (!fullDescription) {
    fail(`${fullPath} must not be empty`);
  }
  if (fullLength > 4000) {
    fail(`${fullPath} exceeds 4000 characters (${fullLength})`);
  }

  for (let index = 0; index < listings.length; index += 1) {
    if (shortDescription && !listings[index].includes(shortDescription)) {
      fail(`${listingPaths[index]} is not synced with ${shortPath}`);
    }
    if (fullDescription && !listings[index].includes(fullDescription)) {
      fail(`${listingPaths[index]} is not synced with ${fullPath}`);
    }
  }

  ok(`${locale} store copy: short ${shortLength}/80, full ${fullLength}/4000`);
}

verifyPng('store/play-high-res-icon-512.png', 512, 512);
verifyPng('store/feature-graphic-1024x500.png', 1024, 500, {
  noAlpha: true,
});

const screenshotDir = join(root, 'store/screenshots/phone');
const screenshots = existsSync(screenshotDir)
  ? readdirSync(screenshotDir)
      .filter((name) => name.toLowerCase().endsWith('.png'))
      .sort()
  : [];

if (screenshots.length < 2) {
  fail(`at least 2 phone screenshots are required, got ${screenshots.length}`);
}
for (const screenshot of screenshots) {
  verifyPng(`store/screenshots/phone/${screenshot}`, 1080, 1920, {
    noAlpha: true,
    maxBytes: 8 * 1024 * 1024,
  });
}
if (screenshots.includes('02-menu-light.png')) {
  fail('obsolete 02-menu-light.png falsely advertises a light release theme');
}

const truthfulnessFiles = [
  ...listingPaths,
  join(root, 'docs/store-listing/full-description-uk.txt'),
  join(root, 'docs/store-listing/full-description-en.txt'),
  join(root, 'docs/store-listing/full-description-ru.txt'),
  join(root, 'store/screenshots/phone/README.md'),
  join(root, 'scripts/prepare-play-store-assets.py'),
];
const falseThemeClaim =
  /two\s+(visual\s+)?themes|дві\s+(візуальні\s+)?теми|две\s+темы|темна та світла|темная и светлая/i;
for (const path of truthfulnessFiles) {
  const value = text(path);
  if (falseThemeClaim.test(value)) {
    fail(`${path} advertises two/light themes, but the release is dark-only`);
  }
}

if (failures.length) {
  console.error('\nPlay Store verification failed:');
  for (const message of failures) {
    console.error(`  - ${message}`);
  }
  process.exit(1);
}

console.log(`Play Store verification passed (${screenshots.length} phone screenshots).`);
