#!/usr/bin/env node
/**
 * Smoke tests: pause/resume background music on app hide/show.
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

function loadAudioManager() {
  const code = readFileSync(join(root, 'js/system/platform/audio.js'), 'utf8');
  const factory = new Function(`${code}\nreturn AudioManager;`);
  return factory();
}

function createTrack() {
  return {
    paused: false,
    currentTime: 0,
    volume: 0.3,
    loop: true,
    play() {
      this.paused = false;
      return Promise.resolve();
    },
    pause() {
      this.paused = true;
    },
  };
}

const AudioManager = loadAudioManager();
const audio = new AudioManager();
const track = createTrack();
audio._unlocked = true;
audio.musicEnabled = true;
audio._currentMusic = track;
audio._currentMusicKey = 'ambient';
audio.music.ambient = track;

audio.handleAppBackground();
assert(track.paused, 'background hides pause active music');
assert(audio._wasMusicPlayingBeforeBackground, 'background remembers music was playing');

audio.handleAppForeground();
assert(!track.paused, 'foreground resumes music that was playing');
assert(!audio._wasMusicPlayingBeforeBackground, 'foreground clears resume flag');

track.paused = false;
audio.musicEnabled = false;
audio._appInBackground = false;
audio.handleAppBackground();
assert(!track.paused, 'disabled music is not paused on background');
audio.handleAppForeground();
assert(!audio._wasMusicPlayingBeforeBackground, 'disabled music does not set resume flag');

const audioJs = readFileSync(join(root, 'js/system/platform/audio.js'), 'utf8');
assert(audioJs.includes('setupLifecycleHandlers'), 'audio manager exposes lifecycle setup');
assert(audioJs.includes('handleAppBackground'), 'audio manager handles background');
assert(audioJs.includes('appStateChange'), 'audio manager listens to Capacitor app state');

const gameJs = readFileSync(join(root, 'js/app/core/LostNumberGame.js'), 'utf8');
assert(gameJs.includes('setupLifecycleHandlers'), 'game boot wires audio lifecycle handlers');

console.log(`\n${passed} passed, ${failed} failed`);
process.exit(failed > 0 ? 1 : 0);
