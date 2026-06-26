#!/usr/bin/env node
/**
 * Smoke tests: save guard, merge repair, achievements, daily icons.
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

function assertEq(actual, expected, msg) {
  if (actual === expected) ok(msg);
  else fail(`${msg} (expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)})`);
}

function loadSaveGuardGame() {
  const ErrorHandler = { info() {}, warn() {}, debug() {}, handle() {} };
  function LostNumberGame() {
    this.GRID_W = 5;
    this.GRID_H = 8;
    this.grid = [];
    this.gamePhase = 'playing';
    this.screenState = 'game';
    this._postMergeEffectsPending = false;
    this._deferredSaveRequested = false;
    this._deferredNavigateScreen = null;
    this._deferredSaveToast = false;
    this._saved = false;
    this.currentLevel = 0;
    this.xp = 0;
    this.xpMultiplier = 1;
    this.xpMultiplierTurns = 0;
    this.bonusInventory = { destroy: 0, shuffle: 0, explosion: 0 };
    this.pendingTransition = null;
    this.maxReachedNumber = 8;
    this.carryNumber = null;
    this.frozenCells = new Map();
    this.stats = {};
    this.achievements = {};
    this.wheelSpinsToday = 0;
    this.lastWheelDay = '2026-01-01';
    this.freezeSystem = null;
    this.storageManager = {
      saveGameState: () => {
        this._saved = true;
        return true;
      },
      isStorageDegraded: () => false,
    };
    this.hasSave = false;
    this.updateContinueButton = () => {};
    this.checkStorageHealth = () => {};
    this.t = (k) => k;
    this.showMessage = () => {};
    this.showScreen = (name) => {
      this._navigated = name;
    };
    this.setGamePhase = (p) => {
      this.gamePhase = p;
    };
    for (let x = 0; x < this.GRID_W; x++) {
      this.grid[x] = [];
      for (let y = 0; y < this.GRID_H; y++) {
        this.grid[x][y] = {
          number: 4,
          merged: false,
          frozen: false,
          freezeTurns: 0,
          freezeMaxTurns: 0,
        };
      }
    }
  }
  const code = readFileSync(join(root, 'js/app/persistence/save-load.js'), 'utf8');
  const factory = new Function('LostNumberGame', 'ErrorHandler', `${code}\nreturn LostNumberGame;`);
  factory(LostNumberGame, ErrorHandler);
  return new LostNumberGame();
}

function loadGridStack(document) {
  const ErrorHandler = { info() {}, warn() {}, debug() {}, handle() {} };
  const Chain = {
    numbers: [],
    get sum() {
      return Chain.numbers.reduce((t, n) => t + (Number(n) || 0), 0);
    },
    set sum(_v) {},
  };
  const files = [
    'js/game/grid/GridManager.js',
    'js/game/grid/grid-render.js',
    'js/game/grid/grid-physics.js',
    'js/game/grid/grid-init.js',
    'js/game/grid/grid-animations.js',
  ];
  const code = files.map((f) => readFileSync(join(root, f), 'utf8')).join('\n\n');
  const factory = new Function('document', 'ErrorHandler', 'Chain', `${code}\nreturn GridManager;`);
  return factory(document, ErrorHandler, Chain);
}

function createMockDOM() {
  class ClassList {
    constructor() {
      this._set = new Set();
    }
    add(...names) {
      names.forEach((n) => this._set.add(n));
    }
    remove(...names) {
      names.forEach((n) => this._set.delete(n));
    }
    contains(name) {
      return this._set.has(name);
    }
  }

  function createElement(tag) {
    const el = {
      tagName: tag.toUpperCase(),
      id: '',
      dataset: {},
      style: {},
      children: [],
      childNodes: [],
      childElementCount: 0,
      firstChild: null,
      parentNode: null,
      classList: new ClassList(),
      appendChild(child) {
        child.parentNode = this;
        this.children.push(child);
        this.childNodes.push(child);
        this.childElementCount = this.children.length;
        this.firstChild = this.children[0] || null;
        return child;
      },
      querySelectorAll() {
        return [];
      },
    };
    Object.defineProperty(el, 'className', {
      get() {
        return [...el.classList._set].join(' ');
      },
      set(v) {
        el.classList._set = new Set(
          String(v || '')
            .split(/\s+/)
            .filter(Boolean),
        );
      },
    });
    return el;
  }

  const grid = createElement('div');
  grid.id = 'grid';
  grid.querySelectorAll = () => [];

  const document = {
    documentElement: createElement('html'),
    getElementById(id) {
      if (id === 'grid') return grid;
      if (id === 'dailyQuestsList') return this._dailyList || null;
    },
    createElement,
    createDocumentFragment() {
      return {
        children: [],
        appendChild(c) {
          this.children.push(c);
          return c;
        },
      };
    },
    querySelectorAll: () => [],
    _dailyList: null,
  };

  return { document, grid };
}

function loadAchievementManager() {
  const code = readFileSync(join(root, 'js/game/meta/achievements.js'), 'utf8');
  const factory = new Function(`${code}\nreturn AchievementManager;`);
  return factory();
}

function loadDailyQuestManager() {
  const code = readFileSync(join(root, 'js/game/meta/daily.js'), 'utf8');
  const factory = new Function(`${code}\nreturn DailyQuestManager;`);
  return factory();
}

// --- save guard ---
{
  const game = loadSaveGuardGame();
  game.gamePhase = 'animating';
  game.saveGameState();
  assert(!game._saved, 'save does not write snapshot during animating');
  assert(game._deferredSaveRequested, 'save defers during animating');
}

{
  const game = loadSaveGuardGame();
  game.gamePhase = 'playing';
  game._postMergeEffectsPending = true;
  game.saveGameState();
  assert(!game._saved, 'save does not write snapshot during post-merge effects');
  assert(game._deferredSaveRequested, 'save defers during post-merge effects');
}

{
  const game = loadSaveGuardGame();
  game._postMergeEffectsPending = true;
  game.requestSaveGameState();
  assert(!game._saved, 'requestSaveGameState defers while post-merge pending');
  game._postMergeEffectsPending = false;
  game.flushDeferredSaveActions();
  assert(game._saved, 'deferred save executes after post-merge completes');
}

{
  const game = loadSaveGuardGame();
  game.gamePhase = 'animating';
  game._deferredSaveRequested = false;
  game.requestSaveAndExitToMenu();
  assertEq(
    game._deferredNavigateScreen,
    'mainMenu',
    'home/back defers navigation during animating',
  );
  game.gamePhase = 'playing';
  game._postMergeEffectsPending = false;
  game.flushDeferredSaveActions();
  assertEq(game._navigated, 'mainMenu', 'deferred home navigation runs after unblock');
}

// --- merge repair ---
{
  const { document } = createMockDOM();
  const GridManager = loadGridStack(document);
  const game = loadSaveGuardGame();
  game.animationEnabled = false;
  game.levels = [{ target: 64, numbers: [2, 4, 8], newNumbers: [8, 16, 32] }];
  game.getLevelConfig = (i) => game.levels[i] || game.levels[0];
  game.formatNumber = (n) => String(n);
  game.nextRandomInt = () => 0;
  game.generateCellNumber = () => 2;
  game.isCellFrozen = () => false;
  game.getFrozenTurns = () => 0;
  const gm = new GridManager(game);
  game.gridManager = gm;
  gm.performFullRender();

  game.grid[2][0].number = null;
  game.grid[2][1].number = null;
  game.grid[2][2].number = 8;
  game.grid[2][3].number = 16;
  game.grid[2][4].number = 32;

  const removed = [
    { x: 2, y: 0 },
    { x: 2, y: 1 },
  ];
  game.repairMergeGridState(removed);

  let nulls = 0;
  for (let y = 0; y < game.GRID_H; y++) {
    if (game.grid[2][y].number == null) nulls++;
  }
  assertEq(nulls, 0, 'mergeChain repair clears null holes in grid');
}

// --- achievements ---
{
  const AchievementManager = loadAchievementManager();
  const game = {
    achievements: {
      chain5: { unlocked: false, progress: 0, max: 1 },
      chain10: { unlocked: false, progress: 0, max: 1 },
      useAllBonuses: { unlocked: false, progress: 0, max: 3, typesUsed: [] },
    },
    getAchievement(key) {
      return this.achievements[key];
    },
    showMessage() {},
    formatTemplate(s) {
      return s;
    },
    t(k) {
      return k;
    },
  };
  const mgr = new AchievementManager(game);

  mgr.updateAchievementProgress('chain10', 1);
  assert(game.achievements.chain10.unlocked, 'chain10 unlocks from one chain >= 10');
  assertEq(game.achievements.chain10.progress, 1, 'chain10 progress is 1 after unlock');
  mgr.updateAchievementProgress('chain10', 1);
  assertEq(game.achievements.chain10.progress, 1, 'chain10 does not stack beyond max 1');

  mgr.updateAchievementProgress('chain5', 0);
  assert(!game.achievements.chain5.unlocked, 'chain5 stays locked when chain < 5');
  mgr.updateAchievementProgress('chain5', 1);
  assert(game.achievements.chain5.unlocked, 'chain5 unlocks from one chain >= 5');

  game.achievements.useAllBonuses = {
    unlocked: false,
    progress: 1,
    max: 3,
    typesUsed: ['destroy'],
  };
  const mgrReloaded = new AchievementManager(game);
  mgrReloaded.trackBonusTypeUsed('destroy');
  assertEq(
    game.achievements.useAllBonuses.progress,
    1,
    'useAllBonuses does not increment after reload',
  );
  mgrReloaded.trackBonusTypeUsed('shuffle');
  assertEq(
    game.achievements.useAllBonuses.progress,
    2,
    'useAllBonuses counts new bonus type after reload',
  );
}

// --- daily icons remount ---
{
  const DailyQuestManager = loadDailyQuestManager();
  const { document } = createMockDOM();
  globalThis.document = document;
  const list = document.createElement('div');
  list.id = 'dailyQuestsList';
  document._dailyList = list;

  let applyAllCalls = 0;
  globalThis.LostNumberIcons = {
    applyAll(scope) {
      applyAllCalls++;
      assert(scope === list, 'daily icons applyAll receives quest container');
    },
  };

  const game = {
    getTodayKey: () => '2026-06-23',
    t: (k) => k,
    dailyQuests: null,
    storageManager: {
      loadDailyQuests: () => null,
      saveDailyQuests: () => {},
    },
  };
  const daily = new DailyQuestManager(game);
  daily.renderDailyQuests();
  assert(applyAllCalls >= 1, 'daily icons remount after re-render');

  delete globalThis.LostNumberIcons;
  delete globalThis.document;
}

console.log(`\n${passed} passed, ${failed} failed`);
process.exit(failed > 0 ? 1 : 0);
