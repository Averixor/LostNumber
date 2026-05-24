#!/usr/bin/env node
/**
 * Node checks for GameState endless / preset getLevelConfig (no test framework).
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

function isPowerOfTwo(n) {
  return (
    typeof n === 'number' &&
    Number.isFinite(n) &&
    n >= 2 &&
    Number.isInteger(n) &&
    (n & (n - 1)) === 0
  );
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

const LEVEL_INDICES = [0, 19, 39, 40, 49, 99, 199, 499];

const state = loadGameState();

for (const levelIndex of LEVEL_INDICES) {
  const label = `levelIndex ${levelIndex}`;
  const config = state.getLevelConfig(levelIndex);

  assert(config != null && typeof config === 'object', `${label}: config exists`);
  if (!config) continue;

  const target = config.target;
  assert(target != null, `${label}: target not null/undefined`);
  assert(typeof target === 'number', `${label}: target is number`);
  assert(Number.isFinite(target), `${label}: target finite`);
  assert(!Number.isNaN(target), `${label}: target not NaN`);
  assert(target !== Infinity && target !== -Infinity, `${label}: target not Infinity`);
  assert(Number.isSafeInteger(target), `${label}: target safe integer (${target})`);
  assert(target >= 2, `${label}: target >= 2`);
  assert(isPowerOfTwo(target), `${label}: target power-of-two (${target})`);

  assert(Array.isArray(config.numbers), `${label}: numbers array`);
  assert(Array.isArray(config.newNumbers), `${label}: newNumbers array`);
}

console.log(`\n${passed} passed, ${failed} failed`);
process.exit(failed > 0 ? 1 : 0);
