#!/usr/bin/env node
/**
 * Lightweight repo smoke tests (no godot4 required): Godot project layout + privacy page.
 */
import { spawnSync } from 'node:child_process';
import { existsSync, readdirSync, readFileSync, statSync } from 'node:fs';
import { dirname, join, relative } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const failures = [];

function requirePath(rel) {
  const full = join(root, rel);
  if (!existsSync(full)) {
    failures.push(`Missing required path: ${rel}`);
  }
}

const requiredPaths = [
  'godot/project.godot',
  'godot/export_presets.cfg',
  'godot/scenes/Boot.tscn',
  'godot/scenes/App.tscn',
  'godot/scenes/MainMenu.tscn',
  'godot/scenes/Game.tscn',
  'godot/scripts/ui/ScreenRouter.gd',
  'godot/scripts/managers/SaveManager.gd',
  'godot/assets/i18n/uk.json',
  'godot/assets/i18n/ru.json',
  'godot/assets/i18n/en.json',
  'privacy.html',
  'store/PLAY_CONSOLE_LISTING.md',
];

for (const rel of requiredPaths) {
  requirePath(rel);
}

const projectGodot = join(root, 'godot/project.godot');
if (existsSync(projectGodot)) {
  const content = readFileSync(projectGodot, 'utf8');
  if (!content.includes('run/main_scene="res://scenes/Boot.tscn"')) {
    failures.push('godot/project.godot must use Boot.tscn as main scene');
  }
  if (!content.includes('ScreenRouter=')) {
    failures.push('godot/project.godot must autoload ScreenRouter');
  }
}

// Git LFS: усі mp3 під godot/assets/audio/ мають бути матеріализовані (не pointer).
const lfsPointerPrefix = 'version https://git-lfs.github.com/spec/v1';
const audioRoot = join(root, 'godot/assets/audio');

function listMp3Files(dir) {
  const out = [];
  if (!existsSync(dir)) {
    return out;
  }
  for (const name of readdirSync(dir)) {
    const full = join(dir, name);
    const st = statSync(full);
    if (st.isDirectory()) {
      out.push(...listMp3Files(full));
    } else if (name.toLowerCase().endsWith('.mp3')) {
      out.push(full);
    }
  }
  return out;
}

const audioMp3 = listMp3Files(audioRoot);
if (audioMp3.length === 0) {
  failures.push('Missing godot/assets/audio/**/*.mp3 (expected music + sfx via Git LFS)');
} else {
  for (const full of audioMp3) {
    const rel = relative(root, full);
    const head = readFileSync(full).subarray(0, 64).toString('utf8');
    if (head.startsWith(lfsPointerPrefix)) {
      failures.push(`${rel} is still a Git LFS pointer — run: git lfs pull`);
    }
  }
}

// Guard: небезпечні npm git/GAS ops мають блокуватися без CONFIRM_*.
// Порожній рядок залишає ключ у env; для «unset» треба delete.
function envWithoutGitOpConfirms() {
  const env = { ...process.env };
  delete env.CONFIRM_GIT_OPS;
  delete env.CONFIRM_PRODUCTION_DEPLOY;
  delete env.ALLOW_DIRTY_TREE;
  return env;
}

const guardedOps = ['gh', 'ship', 'go', 'release', 'push:remote', 'clasp:push'];
for (const op of guardedOps) {
  const blocked = spawnSync(process.execPath, [join(root, 'scripts/git-ops-guard.mjs'), op], {
    cwd: root,
    encoding: 'utf8',
    shell: false,
    env: envWithoutGitOpConfirms(),
  });
  if (blocked.status === 0) {
    failures.push(`git-ops-guard must block npm run ${op} without CONFIRM_GIT_OPS`);
  }
}

// З обома підтвердженнями prod-ops мають проходити preflight (stub не пушить).
for (const op of ['push:remote', 'clasp:push']) {
  const allowed = spawnSync(process.execPath, [join(root, 'scripts/git-ops-guard.mjs'), op], {
    cwd: root,
    encoding: 'utf8',
    shell: false,
    env: {
      ...process.env,
      CONFIRM_GIT_OPS: '1',
      CONFIRM_PRODUCTION_DEPLOY: '1',
      ALLOW_DIRTY_TREE: '1',
    },
  });
  if (allowed.status !== 0) {
    failures.push(
      `git-ops-guard must allow npm run ${op} with CONFIRM_GIT_OPS + CONFIRM_PRODUCTION_DEPLOY (got ${allowed.status})`,
    );
  }
}

if (failures.length) {
  console.error('Smoke tests failed:');
  for (const failure of failures) {
    console.error(`- ${failure}`);
  }
  process.exit(1);
}

console.log('Smoke tests passed (Godot project layout + git-ops guard).');
