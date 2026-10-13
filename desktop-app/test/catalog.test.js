'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const path = require('node:path');
const { execFileSync } = require('node:child_process');

const catalog = require('../src/main/catalog');

test('catalog has 36 desktops and 6 presets', () => {
  assert.equal(catalog.DESKTOPS.length, 36);
  assert.equal(catalog.PRESETS.length, 6);
  assert.equal(catalog.FLAVORS.length, 16);
  assert.equal(catalog.SINGLE_APPS.length, 4);
});

test('variantCount matches README claim of 236', () => {
  assert.equal(catalog.variantCount(), 236);
});

test('desktopTag builds <desktop>-<preset>-latest', () => {
  assert.equal(catalog.desktopTag('xfce4', 'minimal'), 'xfce4-minimal-latest');
  assert.equal(catalog.desktopTag('pearos', 'gaming'), 'pearos-gaming-latest');
});

test('flavor and single-app tags', () => {
  assert.equal(catalog.flavorTag('pearos'), 'pearos-latest');
  assert.equal(catalog.singleAppTag('browser'), 'browser-latest');
});

test('unknown values are rejected', () => {
  assert.throws(() => catalog.desktopTag('not-a-desktop', 'none'), /Unknown desktop/);
  assert.throws(() => catalog.desktopTag('xfce4', 'nope'), /Unknown preset/);
  assert.throws(() => catalog.flavorTag('minty'), /Unknown flavor/);
});

test('imageRef prefixes the registry', () => {
  assert.equal(catalog.imageRef('pearos-latest'), 'ghcr.io/cloudcompile/fastvm:pearos-latest');
});

test('buildRunArgs produces a sane default command', () => {
  const args = catalog.buildRunArgs({ image: 'ghcr.io/cloudcompile/fastvm:xfce4-none-latest' });
  assert.deepEqual(args, [
    'run', '-d', '-p', '3000:3000', 'ghcr.io/cloudcompile/fastvm:xfce4-none-latest',
  ]);
});

test('buildRunArgs includes dashboard port, name, shm and gpu', () => {
  const args = catalog.buildRunArgs({
    image: 'x:pearos-latest',
    dashboardPort: 3001,
    name: 'FastVM-pearOS',
    shmSize: '4gb',
    gpu: true,
    env: ['TZ=Etc/UTC'],
  });
  assert.deepEqual(args, [
    'run', '-d', '--name', 'FastVM-pearOS', '-p', '3000:3000', '-p', '3001:8099',
    '--shm-size', '4gb', '--device', '/dev/dri', '-e', 'TZ=Etc/UTC', 'x:pearos-latest',
  ]);
});

test('buildRunArgs requires an image', () => {
  assert.throws(() => catalog.buildRunArgs({}), /requires opts.image/);
});

test('catalog stays in sync with the build workflow', () => {
  const root = path.join(__dirname, '..', '..');
  const script = path.join(root, 'scripts', 'verify-catalog.js');
  const out = execFileSync(process.execPath, [script, '--json'], { encoding: 'utf8' });
  const report = JSON.parse(out);
  assert.equal(report.ok, true, JSON.stringify(report.mismatches));
});
