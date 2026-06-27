#!/usr/bin/env node
/**
 * Smoke tests: mobile main menu layout (title, panel, tiles, CTA, dock).
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
const uiCss = readFileSync(join(root, 'css/ui.css'), 'utf8');
const menuJs = readFileSync(join(root, 'js/ui/screens/menu.js'), 'utf8');
const screensJs = readFileSync(join(root, 'js/ui/screens/screens.js'), 'utf8');

const mainMenuBlock =
  indexHtml.match(/id="mainMenuScreen"[\s\S]*?id="achievementsScreen"/)?.[0] || '';

function cssRule(selector) {
  const escaped = selector.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  return uiCss.match(new RegExp(`${escaped}\\s*\\{[^}]*\\}`))?.[0] || '';
}

assert(mainMenuBlock.includes('class="main-menu__title"'), 'main menu has visible title');
assert(mainMenuBlock.includes('main-menu__hero'), 'title sits in hero scrim block');
const titleRule = cssRule('.main-menu__title');
assert(titleRule.includes('letter-spacing: 0'), 'title avoids width-scaled letter spacing');
assert(titleRule.includes('max-width: 100%'), 'title uses fluid max-width not fixed clip');
assert(
  uiCss.includes("body[data-active-screen='mainMenu'] .app-background::after"),
  'main menu mutes baked-in background logo with a screen-only scrim',
);
assert(
  uiCss.includes('rgba(12, 5, 25, 0.9)'),
  'main menu scrim darkens right edge where background title can clip',
);

assert(mainMenuBlock.includes('main-menu__panel'), 'main menu has contrast panel container');
const panelRule = cssRule('.main-menu__panel');
assert(panelRule.includes('rgba(43, 23, 70, 0.78)'), 'menu panel uses lighter translucent fill');
assert(panelRule.includes('rgba(116, 235, 255'), 'menu panel has cyan neon edge');

assert(mainMenuBlock.includes('main-menu__quick-row'), 'main menu has horizontal quick row');
assert(
  (mainMenuBlock.match(/menu-quick-btn--tile/g) || []).length === 3,
  'quick row has three equal tile buttons',
);
assert(!mainMenuBlock.includes('main-menu__quick-stack'), 'vertical pill stack removed');

assert(uiCss.includes('.menu-quick-btn--tile'), 'tile button styles defined');
assert(uiCss.includes('grid-template-columns: repeat(3'), 'quick row uses 3-column grid');
const quickLabelRule = cssRule('.menu-quick-btn--tile .menu-quick-btn__label');
assert(quickLabelRule.includes('white-space: normal'), 'quick labels can wrap instead of clipping');
assert(
  quickLabelRule.includes('overflow-wrap: anywhere'),
  'quick labels keep long words inside tiles',
);

assert(mainMenuBlock.includes('main-menu__continue hidden'), 'continue hidden until save exists');
assert(
  menuJs.includes("continueBtn.classList.toggle('hidden', !hasSave)"),
  'menu hides continue without save',
);

assert(
  menuJs.includes("continueBtn.classList.toggle('primary', hasSave)"),
  'continue primary when save exists',
);

for (const id of [
  'dockPremiumBtn',
  'dockTournamentsBtn',
  'dockAchievementsBtn',
  'dockDailyBtn',
  'dockBonusesBtn',
]) {
  assert(mainMenuBlock.includes(`id="${id}"`), `dock item ${id} present`);
}

assert(
  uiCss.includes('.menu-dock-btn') && /font-size:\s*clamp/.test(uiCss),
  'dock label uses clamp font-size',
);

assert(menuJs.includes('applyMainMenuIcons'), 'menu refresh applies icons');
assert(menuJs.includes('LostNumberIcons.applyAll'), 'menu uses LostNumberIcons.applyAll');
assert(
  screensJs.includes('document.body.dataset.activeScreen = name'),
  'screen sets body dataset for layout hooks',
);

console.log(`\n${passed} passed, ${failed} failed`);
process.exit(failed > 0 ? 1 : 0);
