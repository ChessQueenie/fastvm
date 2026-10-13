'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');

const {
  parsePsOutput,
  filterFastvm,
  hostPortFor,
  nextFreePort,
} = require('../src/main/docker');

test('parsePsOutput parses newline-delimited JSON', () => {
  const text = [
    '{"ID":"abc123","Names":"FastVM","Image":"ghcr.io/cloudcompile/fastvm:xfce4-none-latest","State":"running","Status":"Up 3 minutes","Ports":"0.0.0.0:3000->3000/tcp"}',
    '',
    'not json',
  ].join('\n');
  const rows = parsePsOutput(text);
  assert.equal(rows.length, 1);
  assert.equal(rows[0].id, 'abc123');
  assert.equal(rows[0].name, 'FastVM');
  assert.equal(rows[0].state, 'running');
});

test('parsePsOutput tolerates empty input', () => {
  assert.deepEqual(parsePsOutput(''), []);
  assert.deepEqual(parsePsOutput(null), []);
});

test('hostPortFor extracts the mapped host port', () => {
  const ports = '0.0.0.0:3000->3000/tcp, [::]:3000->3000/tcp, 0.0.0.0:3001->8099/tcp';
  assert.equal(hostPortFor(ports, 3000), 3000);
  assert.equal(hostPortFor(ports, 8099), 3001);
  assert.equal(hostPortFor(ports, 9999), null);
});

test('nextFreePort skips used ports', () => {
  assert.equal(nextFreePort([3000, 3001], 3000), 3002);
  assert.equal(nextFreePort([], 3000), 3000);
});

test('filterFastvm keeps labelled or FastVM-named containers', () => {
  const containers = [
    { name: 'FastVM', image: 'ghcr.io/cloudcompile/fastvm:pearos-latest' },
    { name: 'FastVM-2', image: 'ghcr.io/cloudcompile/fastvm:kali-latest' },
    { name: 'unrelated', image: 'nginx' },
  ];
  const kept = filterFastvm(containers);
  assert.deepEqual(kept.map((c) => c.name), ['FastVM', 'FastVM-2']);
});

test('filterFastvm requireLabel drops name-only matches', () => {
  const containers = [
    { name: 'FastVM', image: 'x' },
    { name: 'FastVM-labelled', image: 'y', labels: { 'dev.cloudcompile.fastvm': '1' } },
  ];
  const kept = filterFastvm(containers, { requireLabel: true });
  assert.deepEqual(kept.map((c) => c.name), ['FastVM-labelled']);
});
