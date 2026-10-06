#!/usr/bin/env node
/**
 * Захист автоматизованих Git/GAS npm-операцій.
 * За замовчуванням блокує; дозволяє лише з явними env-підтвердженнями.
 *
 * CONFIRM_GIT_OPS=1 — дозвіл на git-синхронізацію / не-prod автоматизацію
 * CONFIRM_PRODUCTION_DEPLOY=1 — додатково для production / clasp deploy
 * ALLOW_DIRTY_TREE=1 — дозволити dirty working tree (інакше — стоп)
 */
import { spawnSync } from 'node:child_process';

const op = process.argv[2] || 'unknown';
const PRODUCTION_OPS = new Set(['ship', 'release', 'push:remote', 'clasp:push']);

function git(args) {
  const r = spawnSync('git', args, { encoding: 'utf8', shell: false });
  if (r.status !== 0) {
    return { ok: false, out: (r.stderr || r.stdout || '').trim() };
  }
  return { ok: true, out: (r.stdout || '').trim() };
}

function fail(msg) {
  console.error(`git-ops-guard [${op}]: ${msg}`);
  process.exit(1);
}

const branch = git(['branch', '--show-current']);
if (!branch.ok) fail(`не вдалося визначити гілку: ${branch.out}`);

const status = git(['status', '--porcelain']);
if (!status.ok) fail(`не вдалося прочитати status: ${status.out}`);

const remote = git(['status', '-sb']);
const staged = git(['diff', '--cached', '--name-only']);

console.log('=== git-ops-guard preflight ===');
console.log(`op:       ${op}`);
console.log(`branch:   ${branch.out || '(detached)'}`);
console.log(`remote:   ${(remote.out || '').split('\n')[0] || '(n/a)'}`);
console.log(`staged:   ${staged.out ? staged.out.split('\n').join(', ') : '(none)'}`);
console.log(`dirty:    ${status.out ? 'yes' : 'no'}`);
if (status.out) {
  console.log(status.out);
}

if (process.env.CONFIRM_GIT_OPS !== '1') {
  fail(
    [
      'заблоковано. Автоматизовані Git/GAS операції потребують окремого дозволу.',
      'Перед запуском: перевірте гілку/tree/remote, локальний CI, список файлів.',
      'Потім: CONFIRM_GIT_OPS=1 npm run ' + op,
      'Для production/clasp додатково: CONFIRM_PRODUCTION_DEPLOY=1',
      'Звичайний git sync не повинен викликати clasp push.',
    ].join('\n'),
  );
}

if (PRODUCTION_OPS.has(op) && process.env.CONFIRM_PRODUCTION_DEPLOY !== '1') {
  fail(
    `op="${op}" вважається production-related. Потрібно CONFIRM_PRODUCTION_DEPLOY=1 після перевірки цілі, коду та CI.`,
  );
}

if (status.out && process.env.ALLOW_DIRTY_TREE !== '1') {
  fail(
    'робоче дерево брудне. Спочатку перевірте/розберіть зміни; git add -A заборонено без ревізії. Або ALLOW_DIRTY_TREE=1.',
  );
}

if (op === 'clasp:push' || op === 'push:remote') {
  console.warn(
    `git-ops-guard [${op}]: preflight OK, але цей stub не виконує clasp/GAS push (у репо немає ship path через clasp).`,
  );
}

console.log(`git-ops-guard [${op}]: preflight OK (подальших git/GAS дій цей stub не виконує).`);
process.exit(0);
