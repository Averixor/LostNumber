#!/usr/bin/env node
/**
 * Lightweight repo smoke tests (no godot4 required): Godot project layout + privacy page.
 */
import { existsSync, readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
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

if (failures.length) {
  console.error('Smoke tests failed:');
  for (const failure of failures) {
    console.error(`- ${failure}`);
  }
  process.exit(1);
}

console.log('Smoke tests passed (Godot project layout).');
