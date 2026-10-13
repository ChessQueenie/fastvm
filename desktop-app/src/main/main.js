'use strict';

/**
 * FastVM desktop client - Electron main process.
 *
 * Security posture:
 *  - contextIsolation on, nodeIntegration off, sandbox on
 *  - the renderer only sees the small API exposed by preload.js
 *  - all shelling out happens here, in the main process
 */

const path = require('node:path');
const { app, BrowserWindow, ipcMain, shell } = require('electron');

const catalog = require('./catalog');
const { Docker, hostPortFor } = require('./docker');

const docker = new Docker();
let mainWindow = null;

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1180,
    height: 780,
    minWidth: 900,
    minHeight: 600,
    title: 'FastVM',
    backgroundColor: '#0a0e27',
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true,
      nodeIntegration: false,
      // Renderer sandbox is on by default. Containers without user namespaces
      // (some CI images, hardened hosts) cannot start a sandboxed renderer, so
      // allow an explicit opt-out via FASTVM_DISABLE_SANDBOX=1.
      sandbox: process.env.FASTVM_DISABLE_SANDBOX !== '1',
    },
  });
  mainWindow.loadFile(path.join(__dirname, '..', 'renderer', 'index.html'));
  mainWindow.on('closed', () => {
    mainWindow = null;
  });
}

/** Open a stream URL in the system browser rather than an in-app webview. */
async function openExternal(url) {
  if (/^https?:\/\//.test(url)) await shell.openExternal(url);
  return { ok: true };
}

function registerIpc() {
  ipcMain.handle('catalog', () => ({
    desktops: catalog.DESKTOPS,
    presets: catalog.PRESETS,
    singleApps: catalog.SINGLE_APPS,
    flavors: catalog.FLAVORS,
    desktopMeta: catalog.DESKTOP_META,
    variantCount: catalog.variantCount(),
    registry: catalog.REGISTRY,
  }));

  ipcMain.handle('docker:version', () => docker.version());

  ipcMain.handle('docker:ps', async () => {
    const res = await docker.ps();
    if (!res.ok) return { ok: false, containers: [], error: res.error };
    return {
      ok: true,
      error: null,
      containers: res.containers.map((c) => ({
        ...c,
        desktopPort: hostPortFor(c.ports, catalog.DESKTOP_PORT),
        dashboardPort: hostPortFor(c.ports, catalog.DASHBOARD_PORT),
      })),
    };
  });

  ipcMain.handle('docker:launch', async (_evt, spec) => {
    try {
      const image = spec.tag ? catalog.imageRef(spec.tag) : spec.image;
      const args = catalog.buildRunArgs({
        image,
        hostPort: spec.hostPort,
        dashboardPort: spec.dashboardPort,
        name: spec.name,
        shmSize: spec.shmSize,
        memory: spec.memory,
        cpus: spec.cpus,
        gpu: spec.gpu,
        env: spec.env,
        volumes: spec.volumes,
      });
      const res = await docker.run(args);
      return { ok: res.code === 0, containerId: res.stdout.trim(), args, error: res.code === 0 ? null : res.stderr.trim() };
    } catch (err) {
      return { ok: false, error: String(err.message || err) };
    }
  });

  ipcMain.handle('docker:stop', (_evt, id) => docker.stop(id));
  ipcMain.handle('docker:rm', (_evt, id) => docker.rm(id, true));
  ipcMain.handle('docker:logs', (_evt, id) => docker.logs(id, 300));
  ipcMain.handle('open:external', (_evt, url) => openExternal(url));
}

app.whenReady().then(() => {
  registerIpc();
  createWindow();
  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow();
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
});

module.exports = { createWindow };
