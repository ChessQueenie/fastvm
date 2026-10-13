'use strict';

/**
 * Minimal reader/writer for the FastVM `config.env` file.
 *
 * The parser preserves comments, blank lines, and ordering so writing a value
 * back only touches the single line that changed. Pure functions, unit-tested
 * without touching disk.
 */

const fs = require('node:fs');

const KEY_RE = /^\s*(?:export\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$/;

/** Strip surrounding quotes and trailing inline comments from a raw value. */
function cleanValue(raw) {
  let v = String(raw == null ? '' : raw).trim();
  if ((v.startsWith('"') && v.endsWith('"')) || (v.startsWith("'") && v.endsWith("'"))) {
    return v.slice(1, -1);
  }
  const hash = v.indexOf(' #');
  if (hash !== -1) v = v.slice(0, hash).trim();
  return v;
}

/** Parse config text into { values, lines }. */
function parseConfig(text) {
  const lines = String(text == null ? '' : text).split('\n');
  const values = {};
  lines.forEach((line, index) => {
    if (/^\s*#/.test(line)) return;
    const m = line.match(KEY_RE);
    if (m) values[m[1]] = { value: cleanValue(m[2]), line: index };
  });
  return { values, lines };
}

/** Convenience: just the key -> value map. */
function readValues(text) {
  const { values } = parseConfig(text);
  const out = {};
  for (const [k, v] of Object.entries(values)) out[k] = v.value;
  return out;
}

/** Serialize a JS value for config.env (quote when it contains spaces). */
function serializeValue(value) {
  const s = String(value);
  if (s === '' || /\s/.test(s)) return `"${s.replace(/"/g, '\\"')}"`;
  return s;
}

/**
 * Return new file text with `key` set to `value`. If the key is absent it is
 * appended. Comments and ordering elsewhere are untouched.
 */
function updateConfig(text, key, value) {
  const { values, lines } = parseConfig(text);
  const rendered = `${key}=${serializeValue(value)}`;
  if (values[key]) {
    const i = values[key].line;
    lines[i] = lines[i].replace(KEY_RE, (full, k) => full.replace(/=.*$/, '=') + serializeValue(value));
    return lines.join('\n');
  }
  const sep = lines.length && lines[lines.length - 1] === '' ? '' : '\n';
  return lines.join('\n') + sep + rendered + '\n';
}

/** Read config.env from disk, returning {} when missing. */
function loadConfigFile(filePath) {
  try {
    return readValues(fs.readFileSync(filePath, 'utf8'));
  } catch {
    return {};
  }
}

module.exports = {
  cleanValue,
  parseConfig,
  readValues,
  serializeValue,
  updateConfig,
  loadConfigFile,
};
