#!/usr/bin/env node
/**
 * Node checks for GameState min tile progression (no test framework).
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
  else fail(`${msg} (expected ${expected}, got ${actual})`);
}

function isPowerOfTwo(n) {
  return (
    typeof n === 'number' &&
    Number.isFinite(n) &&
    n >= 2 &&
    Number.isInteger(n) &&
    (n & (n - 1)) === 0
  );
}

/** Matches GameState._floorPowerOfTwo — largest power of two <= n (min 2). */
function floorPowerOfTwo(n) {
  const v = Number(n);
  if (!Number.isFinite(v) || v < 2) return 2;
  const exp = Math.floor(Math.log2(v));
  const p = 2 ** Math.max(0, exp);
  return Number.isFinite(p) && p >= 2 ? p : 2;
}

function loadGameState() {
  const ErrorHandler = {
    info() {},
    warn() {},
    handle() {},
    error() {},
  };
  const GameCore = class GameCore {
    constructor() {}
  };
  const Chain = { numbers: [], sum: 0 };
  const code = readFileSync(join(root, 'js/game/state.js'), 'utf8');
  const factory = new Function('ErrorHandler', 'GameCore', 'Chain', `${code}\nreturn GameState;`);
  const GameState = factory(ErrorHandler, GameCore, Chain);
  return new GameState();
}

const EXACT = [
  [1, 2],
  [6, 2],
  [7, 4],
  [11, 4],
  [12, 8],
  [15, 8],
  [16, 16],
  [19, 16],
  [20, 32],
  [23, 32],
  [24, 64],
  [27, 64],
  [28, 128],
];

const VALID_ONLY = [40, 41, 50, 100, 200, 500];

const state = loadGameState();

for (const [human, expected] of EXACT) {
  const levelIndex = human - 1;
  const target = state.getLevelConfig(levelIndex).target;
  const min = state.getMinimumSpawnTile(levelIndex);
  assertEq(min, expected, `human level ${human} minSpawn`);
  assertEq(
    state.getMinimumTileForLevel(levelIndex, target),
    expected,
    `human level ${human} getMinimumTileForLevel`,
  );
}

for (const human of VALID_ONLY) {
  const levelIndex = human - 1;
  const config = state.getLevelConfig(levelIndex);
  const target = config.target;
  const min = state.getMinimumSpawnTile(levelIndex);

  assert(Number.isFinite(min), `human ${human}: min finite`);
  assert(min !== Infinity && min !== -Infinity, `human ${human}: min not Infinity`);
  assert(!Number.isNaN(min), `human ${human}: min not NaN`);
  assert(min >= 2, `human ${human}: min >= 2`);
  assert(isPowerOfTwo(min), `human ${human}: min power-of-two (${min})`);

  if (Number.isFinite(target) && target > 4096) {
    const capValue = target / 4096;
    const capTile = floorPowerOfTwo(capValue);
    assert(
      min <= capTile,
      `human ${human}: min ${min} <= floorPo2(target/4096) (${capTile}, raw cap ${capValue})`,
    );
    assert(min <= capValue, `human ${human}: min ${min} <= target/4096 (${capValue})`);
  }
}

// Regression: at max procedural target (2^52), cap is 2^40 — not 2^52 (prior audit misread logs).
const MAX_PROCEDURAL_TARGET = 4503599627370496;
const MAX_MIN_AT_CAP = 1099511627776;

for (const human of [200, 500]) {
  const levelIndex = human - 1;
  const target = state.getLevelConfig(levelIndex).target;
  const min = state.getMinimumSpawnTile(levelIndex);
  assertEq(target, MAX_PROCEDURAL_TARGET, `human ${human}: target at 2^52 cap`);
  assertEq(min, MAX_MIN_AT_CAP, `human ${human}: minSpawn capped to 2^40 (not 2^52)`);
}

console.log(`\n${passed} passed, ${failed} failed`);
process.exit(failed > 0 ? 1 : 0);
