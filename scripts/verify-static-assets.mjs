#!/usr/bin/env node
import { existsSync, readdirSync, readFileSync, statSync } from 'node:fs';
import { extname, join, normalize, sep } from 'node:path';
import { fileURLToPath } from 'node:url';
import { dirname } from 'node:path';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const failures = [];
const references = new Map();
const expectedImageSizes = new Map();

const REQUIRED_ASSETS = [
  'assets/images/menu-skin-1.png',
  'assets/images/menu-skin-2.png',
  'assets/images/menu-skin-3.png',
  'assets/images/menu-skin-4.png',
  'assets/images/menu-skin-5.png',
  'assets/images/menu-skin-6.png',
  'css/lostnumber-icons.css',
  'js/ui/icons.js',
  'assets/icons/neon/sprite/lostnumber-icons.svg',
];

function verifyRequiredAssets() {
  for (const rel of REQUIRED_ASSETS) {
    const full = join(root, rel);
    if (!existsSync(full) || !statSync(full).isFile()) {
      fail(`Required asset missing: ${rel}`);
    }
  }

  const iconsJsonPath = join(root, 'assets/icons/neon/icons.json');
  if (!existsSync(iconsJsonPath)) {
    fail('Required asset missing: assets/icons/neon/icons.json');
    return;
  }

  let iconsCatalog;
  try {
    iconsCatalog = JSON.parse(readFileSync(iconsJsonPath, 'utf8'));
  } catch (error) {
    fail(`Invalid JSON in assets/icons/neon/icons.json: ${error.message}`);
    return;
  }

  for (const slug of Object.keys(iconsCatalog)) {
    const rel = `assets/icons/neon/icons/${slug}.svg`;
    const full = join(root, rel);
    if (!existsSync(full) || !statSync(full).isFile()) {
      fail(`Neon icon missing: ${rel} (listed in icons.json)`);
    }
  }
}

function addReference(source, rawUrl) {
  const cleaned = normalizeLocalUrl(rawUrl);
  if (!cleaned) return null;

  if (!references.has(cleaned)) {
    references.set(cleaned, new Set());
  }
  references.get(cleaned).add(source);
  return cleaned;
}

function fail(message) {
  failures.push(message);
}

function normalizeLocalUrl(rawUrl) {
  if (!rawUrl || typeof rawUrl !== 'string') return null;

  let value = rawUrl.trim();
  if (!value || value.startsWith('#')) return null;
  if (/^(?:https?:|data:|mailto:|tel:|javascript:|blob:)/i.test(value)) return null;

  if (value.includes(',')) {
    value = value.split(',')[0].trim();
  }

  value = value.split(/\s+/)[0];
  value = value.replace(/[?#].*$/, '');
  if (!value || value === '.' || value === './') return null;

  if (value.startsWith('/')) {
    fail(`Root-absolute URL is not portable for GitHub Pages project paths: ${rawUrl}`);
    return null;
  }

  value = value.replace(/^\.\//, '');
  if (!value || value === '.') return null;

  const looksLikeLocalFile =
    /^(?:assets|audio|css|js)\//.test(value) ||
    /^[^/]+\.(?:css|html|ico|js|json|jpe?g|mp3|png|svg|txt|webmanifest|webp)$/i.test(value);
  if (!looksLikeLocalFile) {
    return null;
  }

  const normalized = normalize(value);
  if (normalized.startsWith('..') || normalized.includes(`${sep}..${sep}`)) {
    fail(`Path escapes project root: ${rawUrl}`);
    return null;
  }

  return normalized.split(sep).join('/');
}

function scanHtmlAttributes(file, text) {
  const attrPattern = /\b(?:src|href|content|srcset)\s*=\s*(["'])(.*?)\1/gi;
  let match;

  while ((match = attrPattern.exec(text))) {
    const raw = match[2];
    if (!raw) continue;

    if (match[0].toLowerCase().includes('srcset')) {
      raw.split(',').forEach((part) => addReference(file, part.trim().split(/\s+/)[0]));
    } else {
      addReference(file, raw);
    }
  }
}

function scanStringReferences(file, text) {
  const quotedPathPattern = /(["'`])((?:\.\/)?(?:assets|audio|css|js)\/[^"'`\s)<]+)\1/g;
  let match;
  while ((match = quotedPathPattern.exec(text))) {
    addReference(file, match[2]);
  }

  const cssUrlPattern = /url\(\s*(["']?)([^"')]+)\1\s*\)/g;
  while ((match = cssUrlPattern.exec(text))) {
    addReference(file, match[2]);
  }
}

function walk(dir, callback) {
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    const full = join(dir, entry.name);
    if (entry.isDirectory()) {
      walk(full, callback);
    } else if (entry.isFile()) {
      callback(full);
    }
  }
}

function scanManifest() {
  const file = 'manifest.json';
  const manifest = JSON.parse(readFileSync(join(root, file), 'utf8'));

  function visit(value, path = file) {
    if (Array.isArray(value)) {
      value.forEach((item, index) => visit(item, `${path}[${index}]`));
      return;
    }
    if (!value || typeof value !== 'object') return;

    if (typeof value.src === 'string' && typeof value.sizes === 'string') {
      const ref = addReference(`${path}.src`, value.src);
      if (ref) {
        expectedImageSizes.set(ref, value.sizes);
      }
    }

    for (const [key, child] of Object.entries(value)) {
      const childPath = `${path}.${key}`;
      if (typeof child === 'string' && ['src', 'url', 'start_url', 'scope', 'id'].includes(key)) {
        addReference(childPath, child);
      } else {
        visit(child, childPath);
      }
    }
  }

  visit(manifest);

  const themeColor = getMetaContent('theme-color');
  const backgroundColor = getMetaContent('background-color');
  if (manifest.theme_color !== themeColor) {
    fail(
      `manifest theme_color ${manifest.theme_color} does not match index theme-color ${themeColor}`,
    );
  }
  if (manifest.background_color !== backgroundColor) {
    fail(
      `manifest background_color ${manifest.background_color} does not match index background-color ${backgroundColor}`,
    );
  }

  const variables = readFileSync(join(root, 'css/variables.css'), 'utf8');
  for (const [name, expected] of [
    ['--pwa-theme-color', manifest.theme_color],
    ['--pwa-background-color', manifest.background_color],
  ]) {
    const matches = [...variables.matchAll(new RegExp(`${name}\\s*:\\s*([^;]+);`, 'g'))].map((m) =>
      m[1].trim().toLowerCase(),
    );
    if (!matches.length || matches.some((value) => value !== expected.toLowerCase())) {
      fail(`${name} in css/variables.css must consistently equal ${expected}`);
    }
  }
}

function getMetaContent(name) {
  const html = readFileSync(join(root, 'index.html'), 'utf8');
  const escaped = name.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  const pattern = new RegExp(
    `<meta\\s+name=["']${escaped}["']\\s+content=["']([^"']+)["']\\s*/?>`,
    'i',
  );
  return pattern.exec(html)?.[1] || null;
}

function hasPrefix(buffer, bytes) {
  return bytes.every((byte, index) => buffer[index] === byte);
}

function readPngSize(buffer) {
  if (buffer.length < 24 || !hasPrefix(buffer, [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a])) {
    return null;
  }

  return {
    width: buffer.readUInt32BE(16),
    height: buffer.readUInt32BE(20),
  };
}

function verifyBinaryAsset(ref, full, sources) {
  if (!statSync(full).isFile()) return;

  const ext = extname(ref).toLowerCase();
  const buffer = readFileSync(full);
  const sourceText = [...sources].sort().join(', ');

  if (buffer.subarray(0, 42).toString('utf8') === 'version https://git-lfs.github.com/spec/v1') {
    fail(`${ref} referenced by ${sourceText} is a Git LFS pointer, not a release asset`);
    return;
  }

  if (ext === '.png') {
    const size = readPngSize(buffer);
    if (!size) {
      fail(`${ref} referenced by ${sourceText} is not a valid PNG`);
      return;
    }

    const expected = expectedImageSizes.get(ref);
    if (expected) {
      const actual = `${size.width}x${size.height}`;
      if (!expected.split(/\s+/).includes(actual)) {
        fail(`${ref} has size ${actual}, but manifest expects ${expected}`);
      }
    }
    return;
  }

  if (
    ext === '.webp' &&
    !(buffer.toString('ascii', 0, 4) === 'RIFF' && buffer.toString('ascii', 8, 12) === 'WEBP')
  ) {
    fail(`${ref} referenced by ${sourceText} is not a valid WebP`);
    return;
  }

  if (ext === '.ico' && !hasPrefix(buffer, [0x00, 0x00, 0x01, 0x00])) {
    fail(`${ref} referenced by ${sourceText} is not a valid ICO`);
    return;
  }

  if (
    ext === '.mp3' &&
    !(
      buffer.toString('ascii', 0, 3) === 'ID3' ||
      (buffer[0] === 0xff && (buffer[1] & 0xe0) === 0xe0)
    )
  ) {
    fail(`${ref} referenced by ${sourceText} is not a valid MP3`);
  }
}

const indexHtml = readFileSync(join(root, 'index.html'), 'utf8');
scanHtmlAttributes('index.html', indexHtml);
scanStringReferences('index.html', indexHtml);
scanManifest();

for (const dir of ['css', 'js']) {
  walk(join(root, dir), (full) => {
    const rel = full
      .slice(root.length + 1)
      .split(sep)
      .join('/');
    if (!['.css', '.js'].includes(extname(rel))) return;
    scanStringReferences(rel, readFileSync(full, 'utf8'));
  });
}

for (const [ref, sources] of [...references.entries()].sort(([a], [b]) => a.localeCompare(b))) {
  const candidates = [join(root, ref)];
  if (ref.startsWith('audio/')) {
    candidates.push(join(root, 'public', ref));
  }

  const full = candidates.find((path) => existsSync(path));
  if (!full) {
    fail(`${ref} referenced by ${[...sources].sort().join(', ')} does not exist`);
    continue;
  }
  if (!statSync(full).isFile() && !statSync(full).isDirectory()) {
    fail(`${ref} referenced by ${[...sources].sort().join(', ')} is not a file or directory`);
    continue;
  }
  verifyBinaryAsset(ref, full, sources);
}

verifyRequiredAssets();

if (failures.length) {
  console.error('Static asset verification failed:');
  for (const failure of failures) {
    console.error(`- ${failure}`);
  }
  process.exit(1);
}

console.log(`Static asset verification passed (${references.size} local references).`);
