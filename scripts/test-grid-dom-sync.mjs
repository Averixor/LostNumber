#!/usr/bin/env node
/**
 * Smoke tests: grid model ↔ DOM sync (syncGridDOMFromModel, gravity, selection, save).
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
    toggle(name, force) {
      if (force === true) this._set.add(name);
      else if (force === false) this._set.delete(name);
      else if (this._set.has(name)) this._set.delete(name);
      else this._set.add(name);
      return this._set.has(name);
    }
    contains(name) {
      return this._set.has(name);
    }
  }

  function matchesSelector(el, sel) {
    if (sel === '.cell') return el.classList.contains('cell');
    if (sel === '.snowflake') return el.classList.contains('snowflake');
    if (sel === '.freeze-counter') return el.classList.contains('freeze-counter');
    if (sel === '.cell-inner') return el.classList.contains('cell-inner');
    if (sel === '.tile-crown') return el.classList.contains('tile-crown');
    const m = sel.match(/^\.cell\[data-x="(\d+)"\]\[data-y="(\d+)"\]$/);
    if (m) {
      return el.classList.contains('cell') && el.dataset.x === m[1] && el.dataset.y === m[2];
    }
    return false;
  }

  function querySelectorAll(rootEl, sel) {
    const out = [];
    const parts = sel.split(',').map((s) => s.trim());
    const walk = (node) => {
      for (const part of parts) {
        if (part === '.cell.selected') {
          if (node.classList?.contains('cell') && node.classList.contains('selected'))
            out.push(node);
        } else if (part === '.cell.highlight') {
          if (node.classList?.contains('cell') && node.classList.contains('highlight'))
            out.push(node);
        } else if (matchesSelector(node, part)) {
          out.push(node);
        }
      }
      for (const ch of node.children || []) walk(ch);
    };
    walk(rootEl);
    return [...new Set(out)];
  }

  function createElement(tag) {
    const el = {
      tagName: tag.toUpperCase(),
      dataset: {},
      style: {},
      children: [],
      childNodes: [],
      parentNode: null,
      firstChild: null,
      innerHTML: '',
      textContent: '',
      classList: new ClassList(),
      appendChild(child) {
        child.parentNode = this;
        this.children.push(child);
        this.childNodes.push(child);
        this.childElementCount = this.children.length;
        this.firstChild = this.children[0] || null;
        return child;
      },
      insertBefore(child, ref) {
        if (!ref) return this.appendChild(child);
        const idx = this.children.indexOf(ref);
        if (idx < 0) return this.appendChild(child);
        child.parentNode = this;
        this.children.splice(idx, 0, child);
        this.childNodes = [...this.children];
        this.childElementCount = this.children.length;
        this.firstChild = this.children[0] || null;
        return child;
      },
      querySelector(sel) {
        if (matchesSelector(this, sel)) return this;
        for (const ch of this.children) {
          const hit = ch.querySelector?.(sel);
          if (hit) return hit;
        }
        return null;
      },
      remove() {
        if (!this.parentNode) return;
        const p = this.parentNode;
        p.children = p.children.filter((c) => c !== this);
        p.childNodes = [...p.children];
        p.childElementCount = p.children.length;
        p.firstChild = p.children[0] || null;
        this.parentNode = null;
      },
      closest(sel) {
        let node = this;
        while (node) {
          if (node.classList && matchesSelector(node, sel)) return node;
          node = node.parentNode;
        }
        return null;
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
  grid.querySelectorAll = function (sel) {
    return querySelectorAll(this, sel);
  };

  const html = createElement('html');

  const document = {
    documentElement: html,
    getElementById(id) {
      if (id === 'grid') return grid;
      return null;
    },
    createElement,
    createDocumentFragment() {
      const frag = {
        children: [],
        appendChild(child) {
          this.children.push(child);
          return child;
        },
      };
      return frag;
    },
    querySelectorAll(sel) {
      const combined = [];
      const parts = sel.split(',').map((s) => s.trim());
      for (const part of parts) {
        if (part === '.cell.selected' || part === '.cell.highlight') {
          const base = part.split('.')[1];
          querySelectorAll(grid, '.cell').forEach((el) => {
            if (el.classList.contains(base)) combined.push(el);
          });
        }
      }
      return combined;
    },
  };

  const origAppend = grid.appendChild.bind(grid);
  grid.appendChild = function (child) {
    if (child && child.children && !child.tagName) {
      for (const c of [...child.children]) origAppend(c);
      return child;
    }
    return origAppend(child);
  };

  return { document, grid, html };
}

function loadGridStack(document) {
  const ErrorHandler = {
    info() {},
    warn() {},
    debug() {},
    handle() {},
  };
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
  const GridManager = factory(document, ErrorHandler, Chain);
  return { GridManager, ErrorHandler, Chain };
}

function createMockGame() {
  return {
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
}

function fillGrid(game, fn) {
  for (let x = 0; x < game.GRID_W; x++) {
    game.grid[x] = [];
    for (let y = 0; y < game.GRID_H; y++) {
      const number = fn(x, y);
      game.grid[x][y] = {
        number,
        merged: false,
        frozen: false,
        freezeTurns: 0,
        freezeMaxTurns: 0,
      };
    }
  }
}

function expectedInnerText(game, gm, num) {
  if (num == null) return '';
  return gm.formatCarryVisual(num);
}

function assertGridDOMMatchesModel(game, gm, label) {
  let okAll = true;
  for (let x = 0; x < game.GRID_W; x++) {
    for (let y = 0; y < game.GRID_H; y++) {
      const cellData = game.grid[x][y];
      const num = cellData?.number;
      const cellEl = gm.cellCache?.[x]?.[y];
      if (!cellEl) {
        fail(`${label}: missing cellCache[${x}][${y}]`);
        okAll = false;
        continue;
      }
      const numStr = num == null ? '' : String(num);
      if (cellEl.dataset.number !== numStr) {
        fail(
          `${label}: dataset.number at (${x},${y}) expected ${numStr}, got ${cellEl.dataset.number}`,
        );
        okAll = false;
      }
      const inner = cellEl.querySelector('.cell-inner');
      const expected = expectedInnerText(game, gm, num);
      if (!inner || inner.textContent !== expected) {
        fail(
          `${label}: inner text at (${x},${y}) expected ${JSON.stringify(expected)}, got ${JSON.stringify(inner?.textContent)}`,
        );
        okAll = false;
      }
      const isSel = (game.selected || []).some((s) => s.x === x && s.y === y);
      if (cellEl.classList.contains('selected') !== isSel) {
        fail(`${label}: selected class at (${x},${y}) mismatch (model=${isSel})`);
        okAll = false;
      }
      if (cellEl.classList.contains('merged') !== !!cellData.merged) {
        fail(`${label}: merged class at (${x},${y}) mismatch`);
        okAll = false;
      }
    }
  }
  if (okAll) ok(`${label}: DOM matches model`);
}

function loadSaveGridHelpers() {
  const ErrorHandler = { info() {}, warn() {}, debug() {}, handle() {} };
  function LostNumberGame() {
    this.GRID_W = 5;
    this.GRID_H = 8;
    this.grid = [];
  }
  const code = readFileSync(join(root, 'js/app/persistence/save-load.js'), 'utf8');
  const factory = new Function('LostNumberGame', 'ErrorHandler', `${code}\nreturn LostNumberGame;`);
  factory(LostNumberGame, ErrorHandler);
  return new LostNumberGame();
}

function loadCheckWin() {
  const ErrorHandler = { info() {}, warn() {}, debug() {}, handle() {} };
  function LostNumberGame() {}
  const code = readFileSync(join(root, 'js/app/flow/game-flow.js'), 'utf8');
  const checkWinBlock = code.match(
    /LostNumberGame\.prototype\.checkWin = function \(\) \{[\s\S]*?\n\};/,
  );
  if (!checkWinBlock) throw new Error('checkWin block not found');
  const factory = new Function(
    'LostNumberGame',
    'ErrorHandler',
    `${checkWinBlock[0]}\nreturn LostNumberGame.prototype.checkWin;`,
  );
  return factory(LostNumberGame, ErrorHandler);
}

// --- tests ---
const { document, grid, html } = createMockDOM();
const { GridManager } = loadGridStack(document);
const game = createMockGame();
const gm = new GridManager(game);

fillGrid(game, (x, y) => 2 ** (((x + y) % 5) + 1));
gm.performFullRender();
assertEq(grid.childElementCount, game.GRID_W * game.GRID_H, 'performFullRender creates all cells');
assertGridDOMMatchesModel(game, gm, 'after performFullRender');
const largestCell = gm.cellCache.flat().find((cell) => cell.classList.contains('tile--largest'));
assert(!!largestCell, 'performFullRender marks largest tile with crown class');
assert(!!largestCell?.querySelector('.tile-crown'), 'largest tile renders crown icon');

game.grid[2][3].number = 16;
game.grid[2][3].merged = true;
assert(gm.syncGridDOMFromModel(), 'syncGridDOMFromModel returns true');
assertGridDOMMatchesModel(game, gm, 'after syncGridDOMFromModel');

const rendersBefore = gm.renderCount;
game.grid[0][0].number = 32;
gm.render();
assertGridDOMMatchesModel(game, gm, 'after render() incremental sync');
assert(gm.renderCount === rendersBefore, 'render() reused sync path without full rebuild');

game.selected = [
  { x: 1, y: 1 },
  { x: 1, y: 2 },
];
gm.syncGridDOMFromModel();
assert(grid.querySelectorAll('.cell.selected').length === 2, 'selection highlights two cells');
game.selected = [];
gm.syncGridDOMFromModel();
assertEq(
  grid.querySelectorAll('.cell.selected').length,
  0,
  'selection cleared in DOM after model reset',
);

for (let y = 0; y < game.GRID_H; y++) {
  game.grid[2][y].number = y < 3 ? null : 4 * (y - 2);
}
const removedCells = [
  { x: 2, y: 0 },
  { x: 2, y: 1 },
  { x: 2, y: 2 },
];
assert(gm.applyLocalGravity(removedCells), 'applyLocalGravity succeeds');
for (let y = 0; y < game.GRID_H; y++) {
  const n = game.grid[2][y].number;
  if (n == null) {
    fail(`gravity model: null at column 2 row ${y}`);
  }
}
assertGridDOMMatchesModel(game, gm, 'after applyLocalGravity + preferSyncOrFullRender');

game.grid[1][3].number = null;
game.grid[1][4].number = null;
game.grid[0][3].number = 16;
gm.applyPressureTransfer(2, 8);
gm._settleAllColumns();
assertEq(gm.countEmptyCells(), 0, 'settle fills pressure-transfer gaps');
for (let y = 0; y < game.GRID_H; y++) {
  if (game.grid[1][y].number == null) {
    fail(`pressure settle: null at column 1 row ${y}`);
  }
}

let postMergeDone = false;
game.grid[1][0].number = null;
game.grid[1][1].number = null;
game.grid[1][2].number = 8;
const cellAbove = gm.cellCache[1][0];
cellAbove.style.transform = 'translateY(200%)';
cellAbove.classList.add('popping');
gm.runPostMergeEffects(
  [
    { x: 1, y: 0 },
    { x: 1, y: 1 },
  ],
  () => {
    postMergeDone = true;
  },
);
assert(postMergeDone, 'runPostMergeEffects invokes callback');
assertEq(cellAbove.style.transform, '', 'runPostMergeEffects clears stuck transform');
for (let y = 0; y < game.GRID_H; y++) {
  if (game.grid[1][y].number == null) {
    fail(`runPostMergeEffects model: null at column 1 row ${y}`);
  }
}
assertGridDOMMatchesModel(game, gm, 'after runPostMergeEffects');

html.classList.add('low-performance');
game.grid[3][4].number = 64;
game.grid[3][4].merged = false;
gm.syncGridDOMFromModel();
assertGridDOMMatchesModel(game, gm, 'lite mode (low-performance): DOM still matches model');
html.classList.remove('low-performance');

const saveGame = loadSaveGridHelpers();
fillGrid(saveGame, (x, y) => (x === y ? 8 : 4));
const serialized = saveGame._serializeGridV2();
const restored = saveGame._parseGridV2(serialized);
let saveOk = true;
for (let x = 0; x < saveGame.GRID_W; x++) {
  for (let y = 0; y < saveGame.GRID_H; y++) {
    if (restored[x][y].number !== saveGame.grid[x][y].number) saveOk = false;
  }
}
assert(saveOk, 'save grid v2 roundtrip preserves cell values');

const checkWin = loadCheckWin();
const winGame = createMockGame();
fillGrid(winGame, () => 4);
const target = winGame.getLevelConfig(0).target;
winGame.grid[1][1].number = target;
let winHandled = false;
winGame.handleLevelComplete = () => {
  winHandled = true;
};
checkWin.call(winGame);
assertEq(winGame.gamePhase, 'win', 'checkWin sets gamePhase win when target on grid');
assert(winHandled, 'checkWin triggers handleLevelComplete');

// Continue: saved grid v2 restores identical values
{
  const storageCode = readFileSync(join(root, 'js/system/platform/storage.js'), 'utf8');
  const store = new Map();
  const localStorage = {
    getItem(k) {
      return store.has(k) ? store.get(k) : null;
    },
    setItem(k, v) {
      store.set(k, v);
    },
    removeItem(k) {
      store.delete(k);
    },
  };
  const storageFactory = new Function(
    'localStorage',
    'console',
    `${storageCode}\nreturn StorageManager;`,
  );
  const StorageManager = storageFactory(localStorage, console);
  const storage = new StorageManager();

  const resumeGame = loadSaveGridHelpers();
  fillGrid(resumeGame, (x, y) => 2 ** (((x + y) % 4) + 1));
  const gridPayload = resumeGame._serializeGridV2();
  const savePayload = {
    version: 2,
    gridSchemaVersion: 2,
    currentLevel: 2,
    xp: 40,
    grid: gridPayload,
  };
  assert(storage.saveGameState(savePayload), 'autosave payload stored');
  const loaded = storage.loadGameState();
  const parsedGrid = resumeGame._parseGridV2(loaded.grid);
  let resumeOk = true;
  for (let x = 0; x < resumeGame.GRID_W; x++) {
    for (let y = 0; y < resumeGame.GRID_H; y++) {
      if (parsedGrid[x][y].number !== gridPayload[x][y].value) resumeOk = false;
    }
  }
  assert(resumeOk, 'continue restores last saved grid values');
  assertEq(loaded.currentLevel, 2, 'continue restores currentLevel');
}

console.log(`\n${passed} passed, ${failed} failed`);
process.exit(failed > 0 ? 1 : 0);
