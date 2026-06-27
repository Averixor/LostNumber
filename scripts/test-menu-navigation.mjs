#!/usr/bin/env node
/**
 * Smoke tests: main menu navigation, login/exit, premium dock, icon remount.
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

const indexHtml = readFileSync(join(root, 'index.html'), 'utf8');
const menuJs = readFileSync(join(root, 'js/ui/screens/menu.js'), 'utf8');

assert(indexHtml.includes('id="loginBtn"'), 'login button exists separately in main menu');
assert(
  indexHtml.includes('id="exitAppBtn"'),
  'exit button exists in main menu (not settings-only)',
);

const settingsBlock = indexHtml.match(/id="settingsScreen"[\s\S]*?id="aboutScreen"/)?.[0] || '';
assert(!settingsBlock.includes('id="exitAppBtn"'), 'exit button is not hidden inside settings');

assert(indexHtml.includes('id="mainMenuDock"'), 'premium dock navigation container exists');
assert(indexHtml.includes('id="dockPremiumBtn"'), 'dock premium icon button exists');
assert(indexHtml.includes('id="dockTournamentsBtn"'), 'dock tournaments icon button exists');
assert(indexHtml.includes('id="dockAchievementsBtn"'), 'dock achievements icon button exists');
assert(indexHtml.includes('id="dockDailyBtn"'), 'dock daily icon button exists');
assert(indexHtml.includes('id="dockBonusesBtn"'), 'dock bonuses icon button exists');

for (const id of [
  'dockPremiumBtn',
  'dockTournamentsBtn',
  'dockAchievementsBtn',
  'dockDailyBtn',
  'dockBonusesBtn',
]) {
  const re = new RegExp(`id="${id}"[\\s\\S]*?data-ln-icon="[^"]+"`);
  assert(re.test(indexHtml), `${id} uses neon data-ln-icon`);
}

assert(menuJs.includes('refreshMainMenuUI'), 'menu manager exposes refreshMainMenuUI');
assert(menuJs.includes('applyMainMenuIcons'), 'menu manager remounts icons');
assert(menuJs.includes('LostNumberIcons.applyAll'), 'menu render calls LostNumberIcons.applyAll');

assert(menuJs.includes('showFeatureStub'), 'feature stub modal for premium/tournaments');
assert(menuJs.includes('feature_premium_title'), 'premium stub wired');
assert(menuJs.includes('feature_tournaments_title'), 'tournaments stub wired');

// Safe stub when overlay nodes missing
assert(
  menuJs.includes('this.game.showMessage(this.game.t(textKey || titleKey))'),
  'feature stub falls back to showMessage without crashing',
);

// MenuManager can be instantiated with minimal game mock
{
  const factory = new Function(`${menuJs}\nreturn MenuManager;`);
  const MenuManager = factory();
  let applyAllCalls = 0;
  globalThis.LostNumberIcons = {
    applyAll() {
      applyAllCalls++;
    },
  };
  globalThis.document = {
    getElementById(id) {
      if (id === 'mainMenuScreen') {
        return { classList: { contains: () => false, toggle: () => {} } };
      }
      if (id === 'featureStubOverlay') return null;
      if (id === 'newGameBtnLabel') return { textContent: '' };
      if (id === 'continueBtn' || id === 'newGameBtn') {
        return { classList: { toggle: () => {} } };
      }
      return null;
    },
  };
  globalThis.ErrorHandler = { warn() {} };

  const game = {
    hasSave: false,
    t: (k) => k,
    showMessage() {},
    audioManager: { playTap() {} },
  };
  const menu = new MenuManager(game);
  menu.refreshMainMenuUI();
  assert(applyAllCalls >= 1, 'refreshMainMenuUI calls LostNumberIcons.applyAll');

  let stubMessage = null;
  game.showMessage = (msg) => {
    stubMessage = msg;
  };
  menu.showFeatureStub('feature_premium_title', 'feature_premium_text');
  assert(
    stubMessage === 'feature_premium_text',
    'premium navigation stub does not crash without overlay DOM',
  );

  delete globalThis.LostNumberIcons;
  delete globalThis.document;
  delete globalThis.ErrorHandler;
}

console.log(`\n${passed} passed, ${failed} failed`);
process.exit(failed > 0 ? 1 : 0);
