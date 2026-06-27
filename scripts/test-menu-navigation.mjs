#!/usr/bin/env node
/**
 * Smoke tests: main menu navigation, feature stubs, icons, Ukrainian copy.
 */
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');

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

const EMOJI_RE = /[\u{1F300}-\u{1FAFF}\u2600-\u27BF]/u;

function hasEmoji(text) {
  return EMOJI_RE.test(text);
}

const indexHtml = readFileSync(join(root, 'index.html'), 'utf8');
const menuJs = readFileSync(join(root, 'js/ui/screens/menu.js'), 'utf8');
const i18nJs = readFileSync(join(root, 'js/system/i18n/i18n.js'), 'utf8');

assert(indexHtml.includes('id="loginBtn"'), 'login button exists separately in main menu');
assert(indexHtml.includes('menu-account-btn--login'), 'login button has active accent styling');
assert(indexHtml.includes('id="exitAppBtn"'), 'exit button exists in main menu');

const settingsBlock = indexHtml.match(/id="settingsScreen"[\s\S]*?id="aboutScreen"/)?.[0] || '';
assert(!settingsBlock.includes('id="exitAppBtn"'), 'exit button is not hidden inside settings');

assert(indexHtml.includes('id="featureStubIcon"'), 'feature stub modal has neon icon slot');
assert(indexHtml.includes('id="featureStubList"'), 'feature stub modal has bullet list');
assert(indexHtml.includes('id="featureStubNote"'), 'feature stub modal has optional note');

for (const id of [
  'dockPremiumBtn',
  'dockTournamentsBtn',
  'dockAchievementsBtn',
  'dockDailyBtn',
  'dockBonusesBtn',
]) {
  assert(indexHtml.includes(`id="${id}"`), `${id} exists in premium dock`);
}

assert(menuJs.includes('getFeatureStubSpec'), 'unified feature stub specs');
assert(menuJs.includes("'login'"), 'login stub spec defined');
assert(menuJs.includes("'premium'"), 'premium stub spec defined');
assert(menuJs.includes("'tournaments'"), 'tournaments stub spec defined');
assert(menuJs.includes("'bonuses'"), 'bonuses stub spec defined');

assert(menuJs.includes("showFeatureStub('premium')"), 'dock premium opens stub');
assert(menuJs.includes("showFeatureStub('tournaments')"), 'dock tournaments opens stub');
assert(menuJs.includes('showAchievementsScreen'), 'dock achievements opens screen');
assert(menuJs.includes("showScreen('dailyQuests')"), 'dock daily opens screen');
assert(menuJs.includes("showFeatureStub('bonuses')"), 'dock bonuses opens stub');

assert(menuJs.includes('dismissFeatureStubFromBack'), 'back handler closes feature stub');
assert(menuJs.includes('applyFeatureStubIcons'), 'stub render remounts icons safely');

assert(
  !hasEmoji(indexHtml.match(/id="mainMenuScreen"[\s\S]*?id="achievementsScreen"/)?.[0] || ''),
  'main menu block has no emoji',
);
assert(
  !hasEmoji(indexHtml.match(/id="featureStubOverlay"[\s\S]*?id="mainMenuScreen"/)?.[0] || ''),
  'feature stub block has no emoji',
);

const uaBlock = i18nJs.match(/ua:\s*\{([\s\S]*?)\n\s*ru:\s*\{/)?.[1] || '';
const uaFeatureKeys = [
  'feature_login_title',
  'feature_login_text',
  'feature_premium_intro',
  'feature_premium_bullet_ad',
  'feature_tournaments_bullet_weekly',
  'feature_tournaments_bullet_records',
  'feature_tournaments_bullet_rewards',
  'feature_bonuses_text',
  'feature_stub_ok',
];
for (const key of uaFeatureKeys) {
  const m = uaBlock.match(new RegExp(`${key}:\\s*'([^']*(?:\\\\'[^']*)*)'`));
  const m2 = uaBlock.match(new RegExp(`${key}:\\s*\\n\\s*'([^']*(?:\\\\'[^']*)*)'`));
  const value = m?.[1] || m2?.[1] || '';
  assert(value.length > 0, `ua i18n key ${key} is defined`);
  if (value) {
    assert(!hasEmoji(value), `ua i18n ${key} has no emoji`);
  }
}

{
  const factory = new Function(`${menuJs}\nreturn MenuManager;`);
  const MenuManager = factory();

  let stubHidden = true;
  const overlay = {
    classList: {
      add(cls) {
        if (cls === 'hidden') stubHidden = true;
      },
      remove(cls) {
        if (cls === 'hidden') stubHidden = false;
      },
      contains(cls) {
        return cls === 'hidden' ? stubHidden : false;
      },
    },
  };
  const iconHost = { setAttribute() {} };
  const title = { textContent: '' };
  const text = { textContent: '' };
  const list = { innerHTML: '', classList: { add() {}, remove() {} }, appendChild() {} };
  const note = { textContent: '', classList: { add() {}, remove() {} } };
  const closeBtn = { focus() {} };

  globalThis.document = {
    getElementById(id) {
      if (id === 'featureStubOverlay') return overlay;
      if (id === 'featureStubIcon') return iconHost;
      if (id === 'featureStubTitle') return title;
      if (id === 'featureStubText') return text;
      if (id === 'featureStubList') return list;
      if (id === 'featureStubNote') return note;
      if (id === 'featureStubClose') return closeBtn;
      if (id === 'mainMenuScreen') return { classList: { toggle() {} } };
      if (id === 'newGameBtnLabel') return { textContent: '' };
      if (id === 'continueBtn' || id === 'newGameBtn') return { classList: { toggle() {} } };
      return null;
    },
    createElement() {
      return { textContent: '', appendChild() {} };
    },
    addEventListener() {},
    removeEventListener() {},
  };
  globalThis.ErrorHandler = { warn() {} };

  const game = {
    hasSave: false,
    t: (k) => k,
    showMessage() {},
    audioManager: { playTap() {} },
  };
  const menu = new MenuManager(game);

  let threw = false;
  try {
    menu.showFeatureStub('premium');
  } catch {
    threw = true;
  }
  assert(!threw, 'premium stub does not throw without LostNumberIcons');
  assert(title.textContent === 'feature_premium_title', 'premium stub sets title');
  assert(!stubHidden, 'premium stub opens overlay');

  const backClosed = menu.dismissFeatureStubFromBack();
  assert(backClosed, 'back closes open feature stub');
  assert(stubHidden, 'back hides feature stub overlay');

  delete globalThis.document;
  delete globalThis.ErrorHandler;
}

console.log(`\n${passed} passed, ${failed} failed`);
process.exit(failed > 0 ? 1 : 0);
