'use strict';

/**
 * Renderer UI. Talks to the main process only through `window.fastvm`
 * (see preload.js). No Node APIs are available here.
 */

const $ = (id) => document.getElementById(id);

let CATALOG = null;

function fillSelect(select, values, meta) {
  select.innerHTML = '';
  for (const v of values) {
    const opt = document.createElement('option');
    opt.value = v;
    const m = meta && meta[v];
    opt.textContent = m && m.label ? `${m.label}  ·  ${m.vibe}` : v;
    select.appendChild(opt);
  }
}

/** Compute the image tag for the current form state. */
function currentTag() {
  const kind = $('kind').value;
  if (kind === 'desktop') return `${$('desktop').value}-${$('preset').value}-latest`;
  if (kind === 'flavor') return `${$('flavor').value}-latest`;
  return `${$('single').value}-latest`;
}

function currentImage() {
  return `${CATALOG.registry}:${currentTag()}`;
}

function updateVisibility() {
  const kind = $('kind').value;
  $('desktop-field').classList.toggle('hidden', kind !== 'desktop');
  $('preset-field').classList.toggle('hidden', kind !== 'desktop');
  $('flavor-field').classList.toggle('hidden', kind !== 'flavor');
  $('single-field').classList.toggle('hidden', kind !== 'single');
}

function updatePreview() {
  const dash = Number($('dash-port').value) || 0;
  const parts = [
    'docker', 'run', '-d',
    '-p', `${$('host-port').value || 3000}:3000`,
  ];
  if (dash) parts.push('-p', `${dash}:8099`);
  if ($('name').value) parts.push('--name', $('name').value);
  if ($('shm').value) parts.push('--shm-size', $('shm').value);
  if ($('gpu').checked) parts.push('--device', '/dev/dri');
  parts.push(currentImage());
  $('preview').textContent = parts.join(' ');
}

async function refreshInstances() {
  const list = $('instances');
  const res = await window.fastvm.list();
  if (!res.ok) {
    list.innerHTML = `<div class="empty">Could not list containers: ${res.error || 'unknown error'}</div>`;
    return;
  }
  const containers = res.containers.filter(
    (c) => (c.image || '').includes('fastvm') || (c.name || '').startsWith('FastVM'),
  );
  if (containers.length === 0) {
    list.innerHTML = '<div class="empty">No FastVM containers yet. Launch one on the left.</div>';
    return;
  }
  list.innerHTML = '';
  for (const c of containers) {
    const card = document.createElement('div');
    card.className = 'card';
    const up = /^up/i.test(c.status);
    const desktopUrl = c.desktopPort ? `http://localhost:${c.desktopPort}` : null;
    const dashUrl = c.dashboardPort ? `http://localhost:${c.dashboardPort}` : null;
    card.innerHTML = `
      <div class="row">
        <div>
          <div class="name">${escapeHtml(c.name)} <span class="pill ${up ? 'up' : ''}">${escapeHtml(c.state)}</span></div>
          <div class="meta">${escapeHtml(c.image)} · ${escapeHtml(c.status)}</div>
        </div>
        <div class="actions"></div>
      </div>`;
    const actions = card.querySelector('.actions');
    if (desktopUrl) actions.appendChild(button('Open', () => window.fastvm.openExternal(desktopUrl)));
    if (dashUrl) actions.appendChild(button('Dashboard', () => window.fastvm.openExternal(dashUrl)));
    actions.appendChild(button('Logs', () => showLogs(c)));
    if (up) actions.appendChild(button('Stop', async () => { await window.fastvm.stop(c.id); refreshInstances(); }));
    actions.appendChild(button('Remove', async () => { await window.fastvm.remove(c.id); refreshInstances(); }));
    list.appendChild(card);
  }
}

function button(label, onClick) {
  const b = document.createElement('button');
  b.className = 'ghost';
  b.textContent = label;
  b.addEventListener('click', onClick);
  return b;
}

async function showLogs(container) {
  const res = await window.fastvm.logs(container.id);
  const text = (res.stdout || '') + (res.stderr || '');
  const modal = $('modal');
  $('modal-title').textContent = `Logs · ${container.name}`;
  $('modal-body').textContent = text || '(no output)';
  modal.classList.remove('hidden');
}

function escapeHtml(s) {
  return String(s == null ? '' : s).replace(/[&<>"']/g, (ch) => (
    { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[ch]
  ));
}

async function launch() {
  const btn = $('launch');
  const out = $('launch-result');
  btn.disabled = true;
  out.className = 'result';
  out.textContent = 'Launching…';
  const spec = {
    tag: currentTag(),
    hostPort: Number($('host-port').value) || 3000,
    dashboardPort: Number($('dash-port').value) || 0,
    name: $('name').value || undefined,
    shmSize: $('shm').value || undefined,
    gpu: $('gpu').checked,
  };
  const res = await window.fastvm.launch(spec);
  btn.disabled = false;
  if (res.ok) {
    out.className = 'result ok';
    out.textContent = `Started ${res.containerId ? res.containerId.slice(0, 12) : 'container'}. Opening desktop…`;
    await window.fastvm.openExternal(`http://localhost:${spec.hostPort}`);
    refreshInstances();
  } else {
    out.className = 'result err';
    out.textContent = `Failed: ${res.error || 'unknown error'}`;
  }
}

async function init() {
  CATALOG = await window.fastvm.catalog();
  $('variant-count').textContent = `· ${CATALOG.variantCount} image variants`;
  fillSelect($('desktop'), CATALOG.desktops, CATALOG.desktopMeta);
  fillSelect($('preset'), CATALOG.presets);
  fillSelect($('flavor'), CATALOG.flavors);
  fillSelect($('single'), CATALOG.singleApps);

  const v = await window.fastvm.dockerVersion();
  const status = $('docker-status');
  if (v.available) {
    status.textContent = `Docker ${v.version}`;
    status.className = 'status ok';
  } else {
    status.textContent = 'Docker not found';
    status.className = 'status err';
  }

  $('kind').addEventListener('change', () => { updateVisibility(); updatePreview(); });
  for (const id of ['desktop', 'preset', 'flavor', 'single', 'host-port', 'dash-port', 'name', 'shm', 'gpu']) {
    $(id).addEventListener('input', updatePreview);
    $(id).addEventListener('change', updatePreview);
  }
  $('launch').addEventListener('click', launch);
  $('refresh').addEventListener('click', refreshInstances);
  $('modal-close').addEventListener('click', () => $('modal').classList.add('hidden'));

  updateVisibility();
  updatePreview();
  refreshInstances();
}

window.addEventListener('DOMContentLoaded', init);
