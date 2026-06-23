#!/usr/bin/env node
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import vm from 'node:vm';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const timers = [];
const calls = [];

const fakeConsole = new Proxy(
  {},
  {
    get() {
      return (...args) => calls.push(args);
    },
  },
);

const window = {
  AppEnv: { debugMode: 'off', isDev: false, isDebugFull: false, isProd: true },
  ErrorHandlerConfig: {
    logToConsole: false,
    showUserMessages: false,
  },
  addEventListener() {},
  navigator: {
    userAgent: 'node-test',
    platform: 'node',
    language: 'en',
    onLine: true,
    sendBeacon: null,
  },
  location: { href: 'https://example.test/LostNumber/' },
  screen: { width: 390, height: 844 },
  innerWidth: 390,
  innerHeight: 844,
};

const context = {
  window,
  console: fakeConsole,
  navigator: window.navigator,
  performance: {},
  Blob,
  Date,
  Error,
  JSON,
  setTimeout(fn) {
    timers.push(fn);
    return timers.length;
  },
  clearTimeout() {},
};
context.globalThis = context;

vm.runInNewContext(readFileSync(join(root, 'js/system/error/errorHandler.js'), 'utf8'), context, {
  filename: 'errorHandler.js',
});

const mainErrorHandler = window.ErrorHandler;
assert.equal(typeof mainErrorHandler, 'function', 'main ErrorHandler should be defined');

vm.runInNewContext(
  readFileSync(join(root, 'js/system/error/errorHandlerFallback.js'), 'utf8'),
  context,
  { filename: 'errorHandlerFallback.js' },
);

assert.equal(window.ErrorHandler, mainErrorHandler, 'fallback must not replace the main handler');

for (const timer of timers.splice(0)) {
  timer();
}

assert.equal(
  window.ErrorHandler,
  mainErrorHandler,
  'main handler should remain after install timer',
);
assert.equal(window.ErrorHandler._installed, true, 'main handler should install successfully');
assert.equal(window.ErrorHandler._isFallback, undefined, 'fallback marker must not be set');

console.log('ErrorHandler fallback smoke test passed.');
