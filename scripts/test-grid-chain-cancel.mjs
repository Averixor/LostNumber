#!/usr/bin/env node
/**
 * Smoke tests: cancel chain when pointer leaves grid or releases outside.
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

const ErrorHandler = { info() {}, warn() {}, debug() {}, handle() {} };
const Chain = {
  numbers: [],
  get sum() {
    return Chain.numbers.reduce((total, n) => total + (Number(n) || 0), 0);
  },
  set sum(_value) {},
};

function createMockDOM() {
  class ClassList {
    constructor() {
      this._set = new Set();
    }
    add(...names) {
      names.forEach((name) => this._set.add(name));
    }
    remove(...names) {
      names.forEach((name) => this._set.delete(name));
    }
    contains(name) {
      return this._set.has(name);
    }
  }

  function createElement(tag) {
    const el = {
      tagName: tag.toUpperCase(),
      classList: new ClassList(),
      dataset: {},
      children: [],
      style: {},
      _listeners: {},
      setPointerCapture() {},
      hasPointerCapture() {
        return false;
      },
      releasePointerCapture() {},
      addEventListener(type, handler) {
        this._listeners[type] = handler;
      },
      querySelector(sel) {
        if (sel === '.cell[data-x="0"][data-y="0"]') {
          return this._cell || null;
        }
        return null;
      },
      querySelectorAll(sel) {
        if (sel === '.cell.selected, .cell.highlight') {
          return this._selected || [];
        }
        return [];
      },
    };
    return el;
  }

  const grid = createElement('div');
  grid.id = 'grid';
  const cell = createElement('div');
  cell.classList.add('cell');
  cell.dataset.x = '0';
  cell.dataset.y = '0';
  grid._cell = cell;

  return {
    getElementById(id) {
      if (id === 'grid') return grid;
      return null;
    },
    querySelectorAll(sel) {
      if (sel === '.cell.selected, .cell.highlight') return [];
      return [];
    },
    grid,
    cell,
  };
}

function loadGameWithUiEvents(document) {
  function LostNumberGame() {
    this.GRID_W = 5;
    this.GRID_H = 8;
    this.grid = [];
    this.gamePhase = 'playing';
    this.isDragging = false;
    this.selected = [];
    this.activeBonus = null;
    this._bubblePointerX = null;
    this._bubblePointerY = null;
    this._mergeCalls = 0;
    this.audioManager = {
      playChainLink() {},
      playError() {},
    };
    this.core = {
      isAdjacent: () => true,
      isValidNextNumber: () => true,
      canFinishChain: () => true,
    };
    this.gridManager = {
      getCellFromPoint(clientX, clientY) {
        if (clientX >= 0 && clientX <= 100 && clientY >= 0 && clientY <= 100) {
          return { x: 0, y: 0 };
        }
        return null;
      },
    };
    this.t = (key) => key;
    this.showMessage = () => {};
    this.hidePreviewBubble = () => {};
    this.updatePreviewBubble = () => {};
    this.mergeChain = () => {
      this._mergeCalls += 1;
    };
    for (let x = 0; x < this.GRID_W; x++) {
      this.grid[x] = [];
      for (let y = 0; y < this.GRID_H; y++) {
        this.grid[x][y] = { number: y === 0 && x === 0 ? 4 : 2, merged: false };
      }
    }
  }

  const uiEventsCode = readFileSync(join(root, 'js/app/ui/ui-events.js'), 'utf8');
  const factory = new Function(
    'LostNumberGame',
    'ErrorHandler',
    'Chain',
    'document',
    `${uiEventsCode}\nreturn LostNumberGame;`,
  );
  factory(LostNumberGame, ErrorHandler, Chain, document);
  return new LostNumberGame();
}

const dom = createMockDOM();
const game = loadGameWithUiEvents(dom);

game.isDragging = true;
game.selected = [{ x: 0, y: 0 }];
Chain.numbers = [4];
dom.cell.classList.add('selected');
dom.grid._selected = [dom.cell];

game.handlePointerMove({ clientX: 200, clientY: 200, preventDefault() {} });
game._flushPendingPointerMove();
assertEq(game.isDragging, false, 'pointer move outside grid stops dragging');
assertEq(game.selected.length, 0, 'pointer move outside grid clears selection');
assertEq(Chain.numbers.length, 0, 'pointer move outside grid clears chain numbers');
assert(
  !dom.cell.classList.contains('selected'),
  'pointer move outside grid removes selected class',
);
assertEq(game._mergeCalls, 0, 'pointer move outside grid does not merge');

game.isDragging = true;
game.selected = [{ x: 0, y: 0 }];
Chain.numbers = [4];
dom.cell.classList.add('selected');
game.handlePointerUp({ clientX: 200, clientY: 200, pointerId: 1 });
assertEq(game.selected.length, 0, 'pointer up outside grid clears selection');
assertEq(game._mergeCalls, 0, 'pointer up outside grid does not merge');

game.isDragging = true;
game.selected = [{ x: 0, y: 0 }];
Chain.numbers = [4];
game.handleGridPointerLeave({ pointerId: 2 });
assertEq(game.isDragging, false, 'pointer leave grid stops dragging');
assertEq(Chain.numbers.length, 0, 'pointer leave grid clears chain numbers');

const uiEventsJs = readFileSync(join(root, 'js/app/ui/ui-events.js'), 'utf8');
assert(uiEventsJs.includes('pointerleave'), 'grid listens for pointerleave');
assert(uiEventsJs.includes('handlePointerCancel'), 'grid handles pointercancel separately');
assert(uiEventsJs.includes('setPointerCapture'), 'grid captures pointer during drag');

const gridRenderJs = readFileSync(join(root, 'js/game/grid/grid-render.js'), 'utf8');
assert(gridRenderJs.includes('tile--largest'), 'grid render marks largest tile');
assert(gridRenderJs.includes('tile-crown.svg'), 'grid render uses tile crown asset');

const gridCss = readFileSync(join(root, 'css/grid.css'), 'utf8');
assert(gridCss.includes('.tile--largest'), 'grid css styles largest tile crown');

console.log(`\n${passed} passed, ${failed} failed`);
process.exit(failed > 0 ? 1 : 0);
