#!/usr/bin/env node
/**
 * Print release keystore certificate (SHA-1 / SHA-256) for Play Console / Firebase.
 * Reads android/keystore.properties — passwords are not echoed.
 */
import { spawnSync } from 'node:child_process';
import { existsSync, readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const androidDir = join(root, 'android');
const propsPath = join(androidDir, 'keystore.properties');

function loadProps(path) {
  const text = readFileSync(path, 'utf8');
  const props = {};
  for (const line of text.split('\n')) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;
    const eq = trimmed.indexOf('=');
    if (eq < 0) continue;
    props[trimmed.slice(0, eq).trim()] = trimmed.slice(eq + 1).trim();
  }
  return props;
}

if (!existsSync(propsPath)) {
  console.error('Missing android/keystore.properties');
  console.error('Create it from docs/PLAY_STORE.md → «Підпис release».');
  process.exit(1);
}

const props = loadProps(propsPath);
const storeFile = props.storeFile;
const storePassword = props.storePassword;
const keyAlias = props.keyAlias;
const keyPassword = props.keyPassword ?? storePassword;

if (!storeFile || !storePassword || !keyAlias) {
  console.error('keystore.properties must define storeFile, storePassword, keyAlias');
  process.exit(1);
}

const keystorePath = join(androidDir, storeFile);
if (!existsSync(keystorePath)) {
  console.error(`Keystore not found: ${keystorePath}`);
  console.error('Check storeFile= in android/keystore.properties');
  process.exit(1);
}

console.log(`Keystore: ${keystorePath}`);
console.log(`Alias: ${keyAlias}\n`);

const result = spawnSync(
  'keytool',
  [
    '-list',
    '-v',
    '-keystore',
    keystorePath,
    '-alias',
    keyAlias,
    '-storepass',
    storePassword,
    '-keypass',
    keyPassword,
  ],
  { encoding: 'utf8', shell: false },
);

if (result.stdout) process.stdout.write(result.stdout);
if (result.stderr) process.stderr.write(result.stderr);

if (result.status !== 0) {
  process.exit(result.status ?? 1);
}
