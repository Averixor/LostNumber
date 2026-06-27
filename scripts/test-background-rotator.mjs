#!/usr/bin/env node
/**
 * Smoke tests: automatic and manual main-menu background selection.
 */
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const code = readFileSync(join(root, 'js/system/platform/background.js'), 'utf8');

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

const storage = new Map();
const localStorage = {
  getItem(key) {
    return storage.has(key) ? storage.get(key) : null;
  },
  setItem(key, value) {
    storage.set(key, String(value));
  },
};
const bgEl = { style: {}, dataset: {} };
const document = {
  baseURI: 'https://example.test/LostNumber/',
  documentElement: {
    style: {
      props: {},
      setProperty(key, value) {
        this.props[key] = value;
      },
    },
  },
  getElementById(id) {
    return id === 'appBackground' ? bgEl : null;
  },
};
const window = {};

const factory = new Function(
  'localStorage',
  'document',
  'window',
  `${code}\nreturn BackgroundRotator;`,
);
const rotator = factory(localStorage, document, window);

rotator.init();
assert(rotator.getPreferenceValue() === 'auto', 'default preference is auto');
let stored = JSON.parse(storage.get(rotator.STORAGE_KEY));
assert(stored.mode === 'auto', 'init stores auto mode');
assert(Number.isInteger(stored.index), 'init stores numeric index');

const manual = rotator.setPreferenceValue('1');
assert(manual === 1, 'manual set returns selected index');
assert(bgEl.dataset.bgIndex === '1', 'manual set applies selected background');
assert(rotator.getPreferenceValue() === '1', 'manual preference reads selected index');
stored = JSON.parse(storage.get(rotator.STORAGE_KEY));
assert(stored.mode === 'manual', 'manual set stores manual mode');
assert(stored.manualIndex === 1, 'manual set stores manual index');
assert(rotator.onMainMenuEnter() === 1, 'manual mode does not rotate on menu enter');

const autoIndex = rotator.setPreferenceValue('auto');
assert(Number.isInteger(autoIndex), 'auto set returns numeric index');
assert(rotator.getPreferenceValue() === 'auto', 'auto preference reads auto');
stored = JSON.parse(storage.get(rotator.STORAGE_KEY));
assert(stored.mode === 'auto', 'auto set stores auto mode');

const yesterday = '2000-01-01';
storage.set(
  rotator.STORAGE_KEY,
  JSON.stringify({ index: 1, lastDay: yesterday, mode: 'auto', manualIndex: 1 }),
);
assert(rotator.onMainMenuEnter() === 2, 'auto mode rotates when stored day changes');
stored = JSON.parse(storage.get(rotator.STORAGE_KEY));
assert(stored.index === 2, 'auto rotation stores next index');
assert(stored.mode === 'auto', 'auto rotation keeps auto mode');

console.log(`\n${passed} passed, ${failed} failed`);
process.exit(failed > 0 ? 1 : 0);
