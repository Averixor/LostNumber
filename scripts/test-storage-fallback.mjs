#!/usr/bin/env node
/**
 * Node checks for StorageManager localStorage + memory fallback (no test framework).
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

function createMockLocalStorage() {
  const store = new Map();
  let setItemThrows = false;
  let getItemThrows = false;

  return {
    getItem(key) {
      if (getItemThrows) throw new Error('getItem failed');
      return store.has(key) ? store.get(key) : null;
    },
    setItem(key, value) {
      if (setItemThrows) throw new Error('setItem failed');
      store.set(key, value);
    },
    removeItem(key) {
      store.delete(key);
    },
    clear() {
      store.clear();
      setItemThrows = false;
      getItemThrows = false;
    },
    setThrowOnSet(v) {
      setItemThrows = v;
    },
    setThrowOnGet(v) {
      getItemThrows = v;
    },
    raw: store,
  };
}

function loadStorageManager(localStorage) {
  const code = readFileSync(join(root, 'js/system/storage.js'), 'utf8');
  const factory = new Function('localStorage', 'console', `${code}\nreturn StorageManager;`);
  const StorageManager = factory(localStorage, console);
  return new StorageManager();
}

const ls = createMockLocalStorage();

// 1. setItem success → load returns localStorage save
{
  ls.clear();
  const sm = loadStorageManager(ls);
  const payload = { currentLevel: 3, marker: 'ls' };
  assert(sm.saveGameState(payload), 'saveGameState returns true on LS success');
  const loaded = sm.loadGameState();
  assertEq(loaded?.marker, 'ls', 'loadGameState prefers LS after successful setItem');
  assertEq(loaded?.currentLevel, 3, 'loadGameState LS payload intact');
}

// 2. setItem throws → _memorySave set
{
  ls.clear();
  const sm = loadStorageManager(ls);
  ls.setThrowOnSet(true);
  const payload = { currentLevel: 7, marker: 'memory-only' };
  assert(sm.saveGameState(payload), 'saveGameState returns true when setItem throws');
  assert(sm._memorySave === payload, '_memorySave set after setItem failure');
  ls.setThrowOnSet(false);
}

// 3. getItem null + _memorySave → load returns memory
{
  ls.clear();
  const sm = loadStorageManager(ls);
  ls.setThrowOnSet(true);
  const payload = { marker: 'mem-fallback-null-get' };
  sm.saveGameState(payload);
  ls.setThrowOnSet(false);
  assert(ls.getItem(sm.SAVE_KEY) == null, 'LS empty after failed setItem');
  const loaded = sm.loadGameState();
  assertEq(
    loaded?.marker,
    'mem-fallback-null-get',
    'loadGameState uses memory when getItem is null',
  );
}

// 4. getItem throws + _memorySave → load returns memory
{
  ls.clear();
  const sm = loadStorageManager(ls);
  ls.setThrowOnSet(true);
  const payload = { marker: 'mem-fallback-get-throws' };
  sm.saveGameState(payload);
  ls.setThrowOnSet(false);
  ls.setThrowOnGet(true);
  const loaded = sm.loadGameState();
  ls.setThrowOnGet(false);
  assertEq(
    loaded?.marker,
    'mem-fallback-get-throws',
    'loadGameState uses memory when getItem throws',
  );
}

// 5. valid LS save has priority over memory fallback
{
  ls.clear();
  const sm = loadStorageManager(ls);
  ls.setThrowOnSet(true);
  sm.saveGameState({ marker: 'stale-memory', currentLevel: 1 });
  ls.setThrowOnSet(false);
  const lsPayload = { marker: 'authoritative-ls', currentLevel: 99 };
  ls.setItem(sm.SAVE_KEY, JSON.stringify(lsPayload));
  const loaded = sm.loadGameState();
  assertEq(loaded?.marker, 'authoritative-ls', 'LS save wins over _memorySave');
  assertEq(loaded?.currentLevel, 99, 'LS currentLevel wins over memory');
}

console.log(`\n${passed} passed, ${failed} failed`);
process.exit(failed > 0 ? 1 : 0);
