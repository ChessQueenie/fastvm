'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');

const {
  readValues,
  serializeValue,
  updateConfig,
  cleanValue,
} = require('../src/main/config');

const SAMPLE = [
  '# FastVM config',
  'FASTVM_DE=XFCE4',
  'FASTVM_PRESET="content-creation"',
  'export FASTVM_PORT=3000  # web desktop',
  '',
  'FASTVM_OS_FLAVOR=standard',
].join('\n');

test('readValues parses keys, quotes and export', () => {
  const v = readValues(SAMPLE);
  assert.equal(v.FASTVM_DE, 'XFCE4');
  assert.equal(v.FASTVM_PRESET, 'content-creation');
  assert.equal(v.FASTVM_PORT, '3000');
  assert.equal(v.FASTVM_OS_FLAVOR, 'standard');
});

test('cleanValue strips quotes and inline comments', () => {
  assert.equal(cleanValue('"a b"'), 'a b');
  assert.equal(cleanValue("'x'"), 'x');
  assert.equal(cleanValue('3000  # port'), '3000');
});

test('serializeValue quotes only when needed', () => {
  assert.equal(serializeValue('pearos'), 'pearos');
  assert.equal(serializeValue('content-creation'), 'content-creation');
  assert.equal(serializeValue('a b'), '"a b"');
});

test('updateConfig replaces an existing value in place', () => {
  const out = updateConfig(SAMPLE, 'FASTVM_DE', 'pearos');
  assert.match(out, /^FASTVM_DE=pearos$/m);
  // Ordering and comments are preserved.
  assert.equal(out.split('\n')[0], '# FastVM config');
  assert.equal(readValues(out).FASTVM_OS_FLAVOR, 'standard');
});

test('updateConfig preserves an export prefix', () => {
  const out = updateConfig(SAMPLE, 'FASTVM_PORT', '3100');
  assert.match(out, /^export FASTVM_PORT=3100$/m);
});

test('updateConfig appends a missing key', () => {
  const out = updateConfig(SAMPLE, 'FASTVM_NEW_FLAG', 'true');
  assert.equal(readValues(out).FASTVM_NEW_FLAG, 'true');
});
