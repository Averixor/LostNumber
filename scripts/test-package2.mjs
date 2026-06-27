#!/usr/bin/env node
/**
 * Smoke tests: bonus post-effects, freeze pressure, required static assets.
 */
import { existsSync, readFileSync } from 'node:fs';
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
      classList: new ClassList(),
      appendChild(child) {
        child.parentNode = this;
        this.children.push(child);
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

  return {
    document: {
      documentElement: createElement('html'),
      getElementById(id) {
        if (id === 'grid') return grid;
        return null;
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
    },
    grid,
  };
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

function createGame() {
  const game = {
    GRID_W: 5,
    GRID_H: 8,
    grid: [],
    selected: [],
    currentLevel: 0,
    carryNumber: null,
    animationEnabled: false,
    frozenCells: new Map(),
    gamePhase: 'playing',
    levels: [{ target: 64, numbers: [2, 4, 8], newNumbers: [8, 16, 32] }],
    freezeSystem: null,
    getLevelConfig(i) {
      return this.levels[i] || this.levels[0];
    },
    formatNumber(n) {
      return n == null ? '' : String(n);
    },
    nextRandomInt(_n) {
      return 0;
    },
    generateCellNumber() {
      return 2;
    },
    setGamePhase(p) {
      this.gamePhase = p;
    },
    activeBonus: null,
    isCellFrozen() {
      return false;
    },
    getFrozenTurns() {
      return 0;
    },
  };

  for (let x = 0; x < game.GRID_W; x++) {
    game.grid[x] = [];
    for (let y = 0; y < game.GRID_H; y++) {
      game.grid[x][y] = {
        number: 4,
        merged: false,
        frozen: false,
        freezeTurns: 0,
        freezeMaxTurns: 0,
      };
    }
  }

  return game;
}

function countNulls(game) {
  let c = 0;
  for (let x = 0; x < game.GRID_W; x++) {
    for (let y = 0; y < game.GRID_H; y++) {
      if (game.grid[x][y].number == null) c++;
    }
  }
  return c;
}

function runPostMergeSettle(game, gm, removedCells) {
  for (const c of removedCells) {
    game.grid[c.x][c.y].number = null;
    game.grid[c.x][c.y].merged = false;
  }
  let done = false;
  gm.runPostMergeEffects(removedCells, () => {
    done = true;
  });
  assert(done, 'runPostMergeEffects callback invoked (shared bonus/merge pipeline)');
  assertEq(countNulls(game), 0, 'post-merge pipeline leaves no null holes');
}

// --- destroy-style single cell ---
{
  const { document } = createMockDOM();
  const GridManager = loadGridStack(document);
  const game = createGame();
  const gm = new GridManager(game);
  gm.performFullRender();
  runPostMergeSettle(game, gm, [{ x: 2, y: 3 }]);
  assertEq(gm.countEmptyCells(), 0, 'destroy-style removal settles grid');
}

// --- explosion-style 3x3 ---
{
  const { document } = createMockDOM();
  const GridManager = loadGridStack(document);
  const game = createGame();
  const gm = new GridManager(game);
  gm.performFullRender();
  const removed = [];
  for (let dx = -1; dx <= 1; dx++) {
    for (let dy = -1; dy <= 1; dy++) {
      removed.push({ x: 2 + dx, y: 4 + dy });
    }
  }
  runPostMergeSettle(game, gm, removed);
  assertEq(gm.countEmptyCells(), 0, 'explosion-style removal settles grid');
}

// --- post-merge pending flag (failsafe path) ---
{
  const { document } = createMockDOM();
  const GridManager = loadGridStack(document);
  const game = createGame();
  game._postMergeEffectsPending = false;
  const gm = new GridManager(game);
  gm.performFullRender();
  game.grid[0][0].number = null;
  let pendingDuringSettle = false;
  const origSettle = gm._settleAllColumns.bind(gm);
  gm._settleAllColumns = function () {
    pendingDuringSettle = !!game._postMergeEffectsPending;
    return origSettle();
  };
  gm.runPostMergeEffects([{ x: 0, y: 0 }], () => {});
  assert(pendingDuringSettle, 'runPostMergeEffects sets _postMergeEffectsPending during settle');
  assert(!game._postMergeEffectsPending, 'runPostMergeEffects clears _postMergeEffectsPending');
}

// --- pressure respects FreezeSystem ---
{
  const { document } = createMockDOM();
  const GridManager = loadGridStack(document);
  const game = createGame();
  const gm = new GridManager(game);
  gm.performFullRender();

  for (let x = 0; x < game.GRID_W; x++) {
    for (let y = 4; y < game.GRID_H; y++) {
      if (x !== 2) game.grid[x][y].number = null;
    }
  }
  game.grid[2][4].number = 16;
  game.grid[2][4].frozen = false;
  for (let y = 5; y < game.GRID_H; y++) {
    game.grid[1][y].number = null;
  }
  game.grid[1][4].number = null;

  const frozenIdx = 4 * game.GRID_W + 2;
  game.freezeSystem = {
    getFreezeData(idx) {
      return idx === frozenIdx ? { turns: 5, maxTurns: 5, type: 'wheel' } : null;
    },
  };

  gm.applyPressureTransfer(2, 8);
  assertEq(game.grid[2][4].number, 16, 'pressure does not move FreezeSystem-frozen tile');
  assertEq(game.grid[1][4].number, null, 'pressure did not transfer frozen tile sideways');
}

// --- required static assets ---
{
  const required = [
    'assets/images/background.png',
    'assets/images/background-alt.png',
    'assets/images/background-alt2.png',
    'css/lostnumber-icons.css',
    'js/ui/icons.js',
    'assets/icons/neon/icons.json',
    'assets/icons/neon/sprite/lostnumber-icons.svg',
  ];
  for (const rel of required) {
    assert(existsSync(join(root, rel)), `required asset exists: ${rel}`);
  }

  const catalog = JSON.parse(readFileSync(join(root, 'assets/icons/neon/icons.json'), 'utf8'));
  let iconsOk = true;
  for (const slug of Object.keys(catalog)) {
    if (!existsSync(join(root, `assets/icons/neon/icons/${slug}.svg`))) {
      iconsOk = false;
      fail(`neon icon svg missing for slug: ${slug}`);
    }
  }
  if (iconsOk) ok('all neon icons from icons.json exist on disk');
}

console.log(`\n${passed} passed, ${failed} failed`);
process.exit(failed > 0 ? 1 : 0);
