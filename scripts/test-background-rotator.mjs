#!/usr/bin/env node
/**
 * Smoke tests: automatic and manual visual skin selection with theme-specific backgrounds.
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
    dataset: {},
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

assert(rotator.SKINS.length === 6, 'visual skin registry contains six provided skins');
assert(rotator.DARK_BACKGROUNDS.length === 6, 'dark background registry contains six images');
assert(rotator.LIGHT_BACKGROUNDS.length === 6, 'light background registry contains six images');
assert(!code.includes("artwork: 'mockup'"), 'mockup artwork mode removed from skin registry');

rotator.syncForGameTheme('dusk');
for (let i = 1; i <= 6; i++) {
  const skinId = `skin-${i}`;
  const index = rotator.setPreferenceValue(skinId, 'dusk');
  assert(index === i - 1, `${skinId} maps to its dark image index`);
  assert(rotator.getPreferenceValue('dusk') === skinId, `${skinId} persists for dark theme`);
  assert(
    bgEl.style.backgroundImage.includes(`dark/menu-bg-${i}.png`),
    `${skinId} applies dark/menu-bg-${i}.png`,
  );
  assert(
    !bgEl.style.backgroundImage.includes('light/'),
    `${skinId} dark theme avoids light assets`,
  );
}

rotator.syncForGameTheme('dawn');
rotator.setPreferenceValue('skin-2', 'dawn');
assert(
  bgEl.style.backgroundImage.includes('light/bg-light-02.png'),
  'dawn theme applies light/bg-light-02.png for skin 2',
);
assert(!bgEl.style.backgroundImage.includes('/dark/'), 'dawn theme avoids dark assets');

storage.clear();
bgEl.style = {};
bgEl.dataset = {};
document.documentElement.dataset = {};
document.documentElement.style.props = {};

rotator.init('dusk');
assert(rotator.getPreferenceValue('dusk') === 'auto', 'default dark preference is auto');
let stored = JSON.parse(storage.get(rotator.STORAGE_KEY));
assert(stored.dawn && stored.dusk, 'init stores per-theme branches');
assert(document.documentElement.dataset.visualSkin, 'init sets html visual skin dataset');
assert(
  document.documentElement.dataset.backgroundTheme === 'dark',
  'init tags dark background theme',
);
assert(!document.documentElement.dataset.skinArtwork, 'init does not set mockup artwork dataset');

const manual = rotator.setPreferenceValue('skin-3', 'dusk');
assert(manual === 2, 'manual set returns selected skin index');
assert(bgEl.dataset.bgIndex === '2', 'manual set applies selected skin background');
assert(bgEl.dataset.visualSkin === 'skin-3', 'manual set tags app background with skin id');
assert(
  bgEl.style.backgroundImage.includes('dark/menu-bg-3.png'),
  'manual dark skin 3 uses dark background path',
);
stored = JSON.parse(storage.get(rotator.STORAGE_KEY));
assert(stored.dusk.mode === 'manual', 'manual set stores manual mode on dark branch');
assert(
  stored.selectedDarkBackground === 'skin-3',
  'manual dark selection stored in selectedDarkBackground',
);
assert(stored.dusk.manualIndex === 2, 'manual set stores manual index on dark branch');
assert(stored.dusk.manualSkin === 'skin-3', 'manual set stores manual skin id on dark branch');
assert(rotator.onMainMenuEnter('dusk') === 2, 'manual dark mode does not rotate on menu enter');

rotator.syncForGameTheme('dawn');
assert(
  document.documentElement.dataset.backgroundTheme === 'light',
  'dawn sync switches background theme dataset',
);
rotator.setPreferenceValue('skin-4', 'dawn');
assert(
  bgEl.style.backgroundImage.includes('light/bg-light-04.png'),
  'dawn manual skin 4 uses light background path',
);
stored = JSON.parse(storage.get(rotator.STORAGE_KEY));
assert(stored.dawn.manualSkin === 'skin-4', 'dawn manual skin stored separately');

rotator.syncForGameTheme('dusk');
assert(
  bgEl.style.backgroundImage.includes('dark/menu-bg-3.png'),
  'switching back to dusk restores dark manual background',
);

rotator.setPreferenceValue('synthwave', 'dusk');
assert(rotator.getPreferenceValue('dusk') === 'skin-1', 'legacy synthwave maps to skin 1 on dark');

const autoIndex = rotator.setPreferenceValue('auto', 'dusk');
assert(Number.isInteger(autoIndex), 'auto set returns numeric index');
assert(rotator.getPreferenceValue('dusk') === 'auto', 'auto preference reads auto for dark branch');
stored = JSON.parse(storage.get(rotator.STORAGE_KEY));
assert(stored.dusk.mode === 'auto', 'auto set stores auto mode on dark branch');

const yesterday = '2000-01-01';
storage.set(
  rotator.STORAGE_KEY,
  JSON.stringify({
    version: 2,
    dawn: {
      index: 0,
      lastDay: yesterday,
      mode: 'auto',
      manualIndex: 0,
      manualSkin: 'skin-1',
      selectedBackground: rotator.LIGHT_BACKGROUNDS[0],
    },
    dusk: {
      index: 1,
      lastDay: yesterday,
      mode: 'auto',
      manualIndex: 2,
      manualSkin: 'skin-3',
      selectedBackground: rotator.DARK_BACKGROUNDS[1],
    },
    selectedLightBackground: null,
    selectedDarkBackground: null,
  }),
);
assert(rotator.onMainMenuEnter('dusk') === 2, 'auto dark mode rotates when stored day changes');
stored = JSON.parse(storage.get(rotator.STORAGE_KEY));
assert(stored.dusk.index === 2, 'auto dark rotation stores next index');
assert(stored.dusk.mode === 'auto', 'auto dark rotation keeps auto mode');

console.log(`\n${passed} passed, ${failed} failed`);
process.exit(failed > 0 ? 1 : 0);
