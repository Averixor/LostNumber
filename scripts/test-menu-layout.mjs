#!/usr/bin/env node
/**
 * Smoke tests: mobile main menu layout (floating title, CTA, chips, dock).
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
const settingsJs = readFileSync(join(root, 'js/ui/overlays/settings.js'), 'utf8');
const i18nJs = readFileSync(join(root, 'js/app/ui/i18n-theme.js'), 'utf8');

const mainMenuBlock =
  indexHtml.match(/id="mainMenuScreen"[\s\S]*?id="achievementsScreen"/)?.[0] || '';
const settingsBlock = indexHtml.match(/id="settingsScreen"[\s\S]*?id="aboutScreen"/)?.[0] || '';

function cssRule(selector) {
  const escaped = selector.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  return uiCss.match(new RegExp(`${escaped}\\s*\\{[^}]*\\}`))?.[0] || '';
}

assert(mainMenuBlock.includes('class="main-menu__title"'), 'main menu has visible title');
assert(mainMenuBlock.includes('data-i18n-split-lines'), 'title renders as split logo lines');
assert(mainMenuBlock.includes('main-menu__hero'), 'title sits in standalone hero block');
const titleRule = cssRule('.main-menu__title');
assert(titleRule.includes('letter-spacing: 0'), 'title avoids width-scaled letter spacing');
assert(titleRule.includes('flex-direction: column'), 'title is stacked like reference mockups');
assert(titleRule.includes('max-width: 100%'), 'title uses fluid max-width not fixed clip');
assert(i18nJs.includes('data-i18n-split-lines'), 'i18n renderer preserves split title markup');
assert(
  uiCss.includes("body[data-active-screen='mainMenu'] .app-background::after"),
  'main menu uses a screen-only background readability scrim',
);
assert(
  !uiCss.includes('rgba(12, 5, 25, 0.9)'),
  'menu no longer needs the heavy right-edge logo mask',
);

assert(mainMenuBlock.includes('main-menu__actions'), 'main menu has floating action group');
assert(!mainMenuBlock.includes('main-menu__panel'), 'main menu no longer uses a central panel');
const actionsRule = cssRule('.main-menu__actions');
assert(actionsRule.includes('background: transparent'), 'floating actions have no card background');
assert(actionsRule.includes('box-shadow: none'), 'floating actions have no card shadow');
assert(actionsRule.includes('border: 0'), 'floating actions have no card border');

assert(mainMenuBlock.includes('main-menu__quick-row'), 'main menu has horizontal quick row');
assert(
  (mainMenuBlock.match(/menu-quick-btn--chip/g) || []).length === 3,
  'quick row has three lightweight chip actions',
);
assert(!mainMenuBlock.includes('main-menu__quick-stack'), 'vertical pill stack removed');
assert(!mainMenuBlock.includes('menu-quick-btn--tile'), 'square quick tiles removed');

const quickRowRule = cssRule('.main-menu__quick-row');
assert(quickRowRule.includes('display: flex'), 'quick row uses flexible inline chips');
assert(!quickRowRule.includes('grid-template-columns'), 'quick row is not a tile grid');
assert(uiCss.includes('.menu-quick-btn--chip'), 'chip action styles defined');
const quickChipRule = cssRule('.menu-quick-btn--chip');
assert(quickChipRule.includes('border-radius: 999px'), 'quick actions are pill chips');
assert(quickChipRule.includes('min-height: 34px'), 'quick chips stay light and compact');
const quickLabelRule = cssRule('.menu-quick-btn--chip .menu-quick-btn__label');
assert(quickLabelRule.includes('white-space: normal'), 'quick labels can wrap instead of clipping');
assert(
  quickLabelRule.includes('overflow-wrap: anywhere'),
  'quick labels keep long words inside chips',
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
assert(
  menuJs.includes("newGameBtn.classList.toggle('ghost', hasSave)"),
  'new game becomes ghost action when save exists',
);
assert(
  menuJs.includes("newGameBtn.classList.toggle('primary', !hasSave)"),
  'new game is primary only when no save exists',
);

assert(settingsBlock.includes('id="backgroundSelect"'), 'settings expose background selector');
for (const value of ['auto', '0', '1', '2']) {
  assert(settingsBlock.includes(`value="${value}"`), `background option ${value} present`);
}
assert(
  settingsJs.includes('BackgroundRotator.setPreferenceValue(backgroundValue)'),
  'settings save applies manual/auto background preference',
);
assert(
  settingsJs.includes('BackgroundRotator.getPreferenceValue()'),
  'settings UI reads current background preference',
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
