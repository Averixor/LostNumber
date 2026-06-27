#!/usr/bin/env node
/**
 * Smoke tests: mobile main menu layout (title, quick row, disabled CTA, dock).
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

assert(mainMenuBlock.includes('class="main-menu__title"'), 'main menu has visible title');
const titleRule = uiCss.match(/\.main-menu__title\s*\{[^}]*\}/)?.[0] || '';
assert(titleRule.includes('clamp('), 'title uses responsive clamp font-size');
assert(titleRule.includes('max-width: 100%'), 'title uses fluid max-width not fixed clip');
assert(titleRule.includes('letter-spacing: clamp'), 'title uses responsive letter-spacing');

assert(mainMenuBlock.includes('main-menu__quick-row'), 'main menu has quick action row');
assert(
  (mainMenuBlock.match(/class="menu-quick-btn"/g) || []).length === 3,
  'quick row has three equal quick buttons',
);
assert(!mainMenuBlock.includes('menu-btn--compact'), 'legacy uneven compact menu buttons removed');

assert(uiCss.includes('.menu-quick-btn'), 'quick button styles defined');
assert(uiCss.includes('grid-template-columns: repeat(3'), 'quick row uses 3-column grid');

assert(uiCss.includes('.menu-btn--muted-disabled'), 'disabled continue muted style exists');
assert(menuJs.includes("'menu-btn--muted-disabled'"), 'menu toggles muted disabled on continue');

assert(
  menuJs.includes("continueBtn.classList.toggle('primary', hasSave)"),
  'continue primary only when save exists',
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
