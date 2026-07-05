#!/usr/bin/env node
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

function loadFeedbackService() {
  const platformCode = readFileSync(join(root, 'js/system/platform/platform.js'), 'utf8');
  const feedbackCode = readFileSync(join(root, 'js/system/platform/feedback.js'), 'utf8');
  const factory = new Function(
    'window',
    'navigator',
    'document',
    `${platformCode}\n${feedbackCode}\nreturn FeedbackService;`,
  );

  const window = {
    Capacitor: {
      Plugins: {
        App: {
          getInfo: async () => ({ version: '2.1.4', build: '14' }),
        },
      },
    },
    screen: { width: 1080, height: 2400 },
    localStorage: {
      store: new Map(),
      getItem(key) {
        return this.store.has(key) ? this.store.get(key) : null;
      },
      setItem(key, value) {
        this.store.set(key, String(value));
      },
    },
    dispatchEvent() {},
  };

  const navigator = {
    userAgent: 'Mozilla/5.0 (Linux; Android 14; Pixel 7) AppleWebKit/537.36',
  };

  const document = {
    body: {
      appendChild() {},
      removeChild() {},
    },
    createElement() {
      return { style: {}, click() {} };
    },
  };

  return factory(window, navigator, document);
}

const FeedbackService = loadFeedbackService();
const t = (key) => key;

assert(FeedbackService.FEEDBACK_EMAIL === 'rsabergman@gmail.com', 'feedback email configured');

const body = FeedbackService.buildBody(t, '2.1.4', FeedbackService.getDeviceInfo());
assert(body.includes('feedback_body_intro'), 'feedback body includes intro key');
assert(body.includes('2.1.4'), 'feedback body includes app version');
assert(body.includes('1080x2400'), 'feedback body includes screen size');
assert(body.includes('Android'), 'feedback body includes user agent');

const version = await FeedbackService.getAppVersion();
assert(version === '2.1.4', 'feedback reads Capacitor app version');

FeedbackService.trackFeedbackClick();
const stats = FeedbackService.getFeedbackClickStats();
assert(stats.count >= 1, 'feedback click analytics increments count');
assert(
  typeof stats.lastClick === 'string' && stats.lastClick.length > 0,
  'feedback click stores timestamp',
);

const indexHtml = readFileSync(join(root, 'index.html'), 'utf8');
assert(indexHtml.includes('feedbackBtn'), 'index.html has feedback button');
assert(indexHtml.includes('js/system/platform/feedback.js'), 'index.html loads feedback.js');

const i18n = readFileSync(join(root, 'js/system/i18n/i18n.js'), 'utf8');
assert(i18n.includes('btn_feedback'), 'i18n defines btn_feedback');
assert(i18n.includes('feedback_subject'), 'i18n defines feedback_subject');

const mainActivity = readFileSync(
  join(root, 'android/app/src/main/java/com/averixor/lostnumber/MainActivity.java'),
  'utf8',
);
assert(mainActivity.includes('FeedbackPlugin'), 'MainActivity registers FeedbackPlugin');

if (failed > 0) {
  console.error(`Feedback tests failed: ${failed}`);
  process.exit(1);
}

console.log(`Feedback tests passed (${passed}).`);
