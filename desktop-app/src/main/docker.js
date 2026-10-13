'use strict';

/**
 * Docker CLI wrapper for the FastVM desktop client.
 *
 * The parsing helpers are pure functions so they can be unit-tested without a
 * running Docker daemon. Only `run`/`ps`/`logs`/`stop`/`rm`/`version` actually
 * shell out, and they do so via `execFile` (no shell) to avoid injection.
 */

const { execFile } = require('node:child_process');

const FASTVM_LABEL = 'dev.cloudcompile.fastvm';

/** Run a command and resolve with { code, stdout, stderr }. Never rejects. */
function exec(cmd, args, opts) {
  return new Promise((resolve) => {
    execFile(cmd, args, { maxBuffer: 8 * 1024 * 1024, ...(opts || {}) }, (err, stdout, stderr) => {
      resolve({
        code: err && typeof err.code === 'number' ? err.code : err ? 1 : 0,
        stdout: stdout || '',
        stderr: stderr || '',
        error: err ? String(err.message || err) : null,
      });
    });
  });
}

/**
 * Parse `docker ps --format '{{json .}}'` output (one JSON object per line)
 * into an array of container summaries.
 */
function parsePsOutput(text) {
  const out = [];
  for (const line of String(text || '').split('\n')) {
    const trimmed = line.trim();
    if (!trimmed) continue;
    try {
      const row = JSON.parse(trimmed);
      out.push({
        id: row.ID || row.Id || '',
        name: row.Names || row.Name || '',
        image: row.Image || '',
        state: row.State || '',
        status: row.Status || '',
        ports: row.Ports || '',
      });
    } catch {
      // Ignore non-JSON lines rather than failing the whole listing.
    }
  }
  return out;
}

/**
 * Keep only FastVM containers. When a name prefix is given, further filter by
 * it. `label` is preferred but callers may fall back to a name prefix when the
 * container predates labels.
 */
function filterFastvm(containers, opts) {
  const o = opts || {};
  return containers.filter((c) => {
    const byLabel = c.labels && c.labels[FASTVM_LABEL];
    const byName = (c.name || '').startsWith(o.namePrefix || 'FastVM');
    return o.requireLabel ? Boolean(byLabel) : Boolean(byLabel || byName);
  });
}

/** Extract the published host port mapped to a container port from `docker ps` Ports text. */
function hostPortFor(portsText, containerPort) {
  const text = String(portsText || '');
  const re = new RegExp(`(?:0\\.0\\.0\\.0|\\[::\\]|::):(\\d+)->${containerPort}/tcp`);
  const m = text.match(re);
  return m ? Number(m[1]) : null;
}

/** Detect the first free host port starting at `start`. */
function nextFreePort(used, start) {
  const taken = new Set((used || []).map(Number));
  let p = start || 3000;
  while (taken.has(p)) p += 1;
  return p;
}

class Docker {
  constructor(cmd) {
    this.cmd = cmd || 'docker';
  }

  /** { available, version, error } */
  async version() {
    const res = await exec(this.cmd, ['version', '--format', '{{.Server.Version}}']);
    if (res.code === 0 && res.stdout.trim()) {
      return { available: true, version: res.stdout.trim(), error: null };
    }
    return { available: false, version: null, error: res.error || res.stderr.trim() || 'docker not available' };
  }

  async ps() {
    const res = await exec(this.cmd, ['ps', '-a', '--no-trunc', '--format', '{{json .}}']);
    if (res.code !== 0) {
      return { ok: false, containers: [], error: res.error || res.stderr.trim() };
    }
    return { ok: true, containers: parsePsOutput(res.stdout), error: null };
  }

  async run(args) {
    return exec(this.cmd, args);
  }

  async logs(id, tail) {
    return exec(this.cmd, ['logs', '--tail', String(tail || 200), id]);
  }

  async stop(id) {
    return exec(this.cmd, ['stop', id]);
  }

  async rm(id, force) {
    return exec(this.cmd, force ? ['rm', '-f', id] : ['rm', id]);
  }
}

module.exports = {
  FASTVM_LABEL,
  Docker,
  exec,
  parsePsOutput,
  filterFastvm,
  hostPortFor,
  nextFreePort,
};
