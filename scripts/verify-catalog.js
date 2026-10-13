#!/usr/bin/env node
'use strict';

/**
 * Verify that desktop-app/src/main/catalog.js stays in sync with the build
 * matrix in .github/workflows/build-images.yml.
 *
 * Usage:
 *   node scripts/verify-catalog.js          # human-readable report
 *   node scripts/verify-catalog.js --json    # machine-readable (used by tests)
 *
 * Exit code 0 when in sync, 1 when there is drift.
 */

const fs = require('node:fs');
const path = require('node:path');

const ROOT = path.resolve(__dirname, '..');
const WORKFLOW = path.join(ROOT, '.github', 'workflows', 'build-images.yml');
const catalog = require(path.join(ROOT, 'desktop-app', 'src', 'main', 'catalog.js'));

/**
 * Extract the `desktop:` list from the `build` job's matrix. Parsing is
 * intentionally simple (indentation based) to avoid a YAML dependency.
 */
function extractMatrixDesktops(text) {
  const lines = text.split('\n');
  const out = [];
  let inMatrix = false;
  let inDesktop = false;
  let indent = 0;
  for (const line of lines) {
    if (/^\s*matrix:\s*$/.test(line)) { inMatrix = true; continue; }
    if (!inMatrix) continue;
    const desktopMatch = line.match(/^(\s*)desktop:\s*$/);
    if (desktopMatch) { inDesktop = true; indent = desktopMatch[1].length; continue; }
    if (inDesktop) {
      const item = line.match(/^\s*-\s+(\S+)\s*$/);
      if (item) { out.push(item[1]); continue; }
      if (/^\s*\S/.test(line) && line.search(/\S/) <= indent) break;
    }
  }
  return out;
}

function compare(actual, expected, label) {
  const missing = expected.filter((v) => !actual.includes(v));
  const extra = actual.filter((v) => !expected.includes(v));
  return { label, missing, extra, ok: missing.length === 0 && extra.length === 0 };
}

function main() {
  const text = fs.readFileSync(WORKFLOW, 'utf8');
  const matrixDesktops = extractMatrixDesktops(text);

  const checks = [
    compare(catalog.DESKTOPS, matrixDesktops, 'desktops'),
  ];

  const mismatches = checks.filter((c) => !c.ok);
  const report = {
    ok: mismatches.length === 0,
    matrixDesktops,
    catalogDesktops: catalog.DESKTOPS,
    checks,
    mismatches,
  };

  if (process.argv.includes('--json')) {
    process.stdout.write(JSON.stringify(report, null, 2) + '\n');
  } else {
    for (const c of checks) {
      if (c.ok) {
        console.log(`[ OK ] ${c.label}: ${c.extra.length === 0 ? '' : ''}in sync`);
      } else {
        console.log(`[FAIL] ${c.label}`);
        if (c.missing.length) console.log(`       missing from catalog: ${c.missing.join(', ')}`);
        if (c.extra.length) console.log(`       not in workflow: ${c.extra.join(', ')}`);
      }
    }
  }

  process.exit(report.ok ? 0 : 1);
}

main();
