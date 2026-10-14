'use strict';

/**
 * FastVM Marketplace frontend.
 *
 * Talks to the Rust backend through Tauri's `invoke` bridge (exposed on
 * `window.__TAURI__` via `withGlobalTauri`). No Node or filesystem access.
 */

const { invoke } = window.__TAURI__.core;
const { openUrl } = window.__TAURI__.opener;

const $ = (id) => document.getElementById(id);

let APPS = [];
let FILTER = 'All';
let SELECTED = null;
let DOCKER_OK = false;

const CATEGORY_ORDER = [
  'Featured', 'Desktops', 'Gaming', 'Development', 'Content Creation',
  'Office', 'Security', 'Distros', 'Minimal', 'All',
];

function toast(message, isError) {
  const el = $('toast');
  el.textContent = message;
  el.className = 'toast' + (isError ? ' err' : '');
  clearTimeout(toast._t);
  toast._t = setTimeout(() => el.classList.add('hidden'), 3200);
}

function escapeHtml(s) {
  return String(s == null ? '' : s).replace(/[&<>"']/g, (ch) => (
    { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[ch]
  ));
}

function renderTabs() {
  const cats = new Set(APPS.map((a) => a.category));
  const tabs = CATEGORY_ORDER.filter((c) => c === 'All' || c === 'Featured' ? (c !== 'Featured' || APPS.some((a) => a.featured)) : cats.has(c));
  const nav = $('tabs');
  nav.innerHTML = '';
  for (const cat of tabs) {
    const b = document.createElement('button');
    b.className = 'tab' + (FILTER === cat ? ' active' : '');
    b.textContent = cat;
    b.addEventListener('click', () => { FILTER = cat; renderTabs(); renderGrid(); });
    nav.appendChild(b);
  }
}

function visibleApps() {
  const q = $('search').value.trim().toLowerCase();
  return APPS.filter((a) => {
    const inFilter = FILTER === 'All'
      || (FILTER === 'Featured' ? a.featured : a.category === FILTER);
    const inSearch = !q
      || a.name.toLowerCase().includes(q)
      || a.tagline.toLowerCase().includes(q)
      || a.id.toLowerCase().includes(q);
    return inFilter && inSearch;
  });
}

function renderGrid() {
  const grid = $('grid');
  const apps = visibleApps();
  grid.innerHTML = '';
  $('no-results').classList.toggle('hidden', apps.length > 0);
  for (const a of apps) {
    const card = document.createElement('div');
    card.className = 'card' + (SELECTED && SELECTED.id === a.id ? ' selected' : '');
    card.innerHTML = `
      <div class="head">
        <span class="title">${escapeHtml(a.name)}</span>
        ${a.featured ? '<span class="chip featured">★ Featured</span>' : ''}
      </div>
      <div class="tagline">${escapeHtml(a.tagline)}</div>
      <div class="foot">
        <span class="chip">${escapeHtml(a.category)}</span>
        <span class="chip">${escapeHtml(a.ram)} RAM</span>
        ${a.gpu ? '<span class="chip gpu">GPU</span>' : ''}
      </div>
      <button class="install" data-id="${escapeHtml(a.id)}">Deploy</button>`;
    card.addEventListener('click', (e) => {
      if (e.target.classList.contains('install')) return;
      select(a);
    });
    card.querySelector('.install').addEventListener('click', () => select(a, true));
    grid.appendChild(card);
  }
}

function select(app, deployNow) {
  SELECTED = app;
  renderGrid();
  $('details-empty').classList.add('hidden');
  const body = $('details-body');
  body.classList.remove('hidden');
  body.innerHTML = `
    <h2>${escapeHtml(app.name)}</h2>
    <div class="sub">${escapeHtml(app.tagline)}</div>
    <div class="grid2">
      <label class="field"><span>Desktop port</span><input id="host-port" type="number" value="3000" min="1" /></label>
      <label class="field"><span>Dashboard port</span><input id="dash-port" type="number" value="3001" min="0" /></label>
    </div>
    <div class="grid2">
      <label class="field"><span>Container name</span><input id="name" type="text" placeholder="FastVM" /></label>
      <label class="field"><span>Shared memory</span><input id="shm" type="text" value="${app.gpu ? '4gb' : '2gb'}" /></label>
    </div>
    <label class="checkbox"><input id="gpu" type="checkbox" ${app.gpu ? 'checked' : ''} /> GPU passthrough (/dev/dri)</label>
    <div class="preview" id="preview"></div>
    <button class="primary" id="deploy">⚡ Deploy ${escapeHtml(app.name)}</button>
    <p class="result" id="deploy-result"></p>`;

  const update = () => {
    const parts = ['docker', 'run', '-d', '-p', `${$('host-port').value || 3000}:3000`];
    if (Number($('dash-port').value)) parts.push('-p', `${$('dash-port').value}:8099`);
    if ($('name').value) parts.push('--name', $('name').value);
    if ($('shm').value) parts.push('--shm-size', $('shm').value);
    if ($('gpu').checked) parts.push('--device', '/dev/dri');
    parts.push(app.image);
    $('preview').textContent = parts.join(' ');
  };
  for (const id of ['host-port', 'dash-port', 'name', 'shm', 'gpu']) {
    $(id).addEventListener('input', update);
    $(id).addEventListener('change', update);
  }
  $('deploy').addEventListener('click', deploySelected);
  update();

  if (deployNow) deploySelected();
}

async function deploySelected() {
  if (!SELECTED) return;
  const btn = $('deploy');
  const out = $('deploy-result');
  btn.disabled = true;
  out.className = 'result';
  out.textContent = 'Deploying… (the first pull can take a while)';
  const req = {
    tag: SELECTED.id,
    hostPort: Number($('host-port').value) || 3000,
    dashboardPort: Number($('dash-port').value) || 0,
    name: $('name').value || null,
    shmSize: $('shm').value || null,
    gpu: $('gpu').checked,
  };
  try {
    const res = await invoke('deploy', { req });
    if (res.ok) {
      out.className = 'result ok';
      out.textContent = `Running. Desktop at http://localhost:${res.host_port}`;
      toast(`Deployed ${SELECTED.name}`);
      openUrl(`http://localhost:${res.host_port}`);
      refreshInstances();
    } else {
      out.className = 'result err';
      out.textContent = `Failed: ${res.error || 'unknown error'}`;
      toast('Deploy failed', true);
    }
  } catch (err) {
    out.className = 'result err';
    out.textContent = `Failed: ${err}`;
    toast('Deploy failed', true);
  } finally {
    btn.disabled = false;
  }
}

async function refreshInstances() {
  const list = $('instances');
  let rows = [];
  try {
    rows = await invoke('list_instances');
  } catch (err) {
    list.innerHTML = `<div class="empty">Could not list containers: ${escapeHtml(err)}</div>`;
    return;
  }
  $('instance-count').textContent = rows.length ? `· ${rows.length}` : '';
  if (rows.length === 0) {
    list.innerHTML = '<div class="empty">No instances yet. Deploy one from the store above.</div>';
    return;
  }
  list.innerHTML = '';
  for (const c of rows) {
    const up = /^up/i.test(c.status);
    const row = document.createElement('div');
    row.className = 'row';
    row.innerHTML = `
      <div>
        <div class="name">${escapeHtml(c.name)} <span class="pill ${up ? 'up' : ''}">${escapeHtml(c.state)}</span></div>
        <div class="meta">${escapeHtml(c.image)} · ${escapeHtml(c.status)}</div>
      </div>
      <div class="actions"></div>`;
    const actions = row.querySelector('.actions');
    if (c.desktop_port) actions.appendChild(ghost('Open', () => openUrl(`http://localhost:${c.desktop_port}`)));
    if (c.dashboard_port) actions.appendChild(ghost('Dashboard', () => openUrl(`http://localhost:${c.dashboard_port}`)));
    actions.appendChild(ghost('Logs', () => showLogs(c)));
    if (up) actions.appendChild(ghost('Stop', async () => { await invoke('stop_instance', { id: c.id }); refreshInstances(); }));
    actions.appendChild(ghost('Remove', async () => { await invoke('remove_instance', { id: c.id }); refreshInstances(); }));
    list.appendChild(row);
  }
}

function ghost(label, onClick) {
  const b = document.createElement('button');
  b.className = 'ghost';
  b.textContent = label;
  b.addEventListener('click', onClick);
  return b;
}

async function showLogs(container) {
  try {
    const text = await invoke('instance_logs', { id: container.id });
    $('modal-title').textContent = `Logs · ${container.name}`;
    $('modal-body').textContent = text || '(no output)';
    $('modal').classList.remove('hidden');
  } catch (err) {
    toast(`Logs failed: ${err}`, true);
  }
}

async function init() {
  $('search').addEventListener('input', renderGrid);
  $('refresh').addEventListener('click', refreshInstances);
  $('modal-close').addEventListener('click', () => $('modal').classList.add('hidden'));

  try {
    const mp = await invoke('marketplace');
    APPS = mp.apps;
    DOCKER_OK = mp.docker_available;
    const status = $('docker-status');
    if (mp.docker_available) {
      status.textContent = `Docker ${mp.docker_version}`;
      status.className = 'status ok';
    } else {
      status.textContent = 'Docker not found';
      status.className = 'status err';
    }
    renderTabs();
    renderGrid();
  } catch (err) {
    toast(`Could not load marketplace: ${err}`, true);
  }
  refreshInstances();
}

window.addEventListener('DOMContentLoaded', init);
