'use strict';

/**
 * Preload bridge. Exposes a tiny, explicit API to the renderer over
 * contextBridge. The renderer never touches Node or the Docker CLI directly.
 */

const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('fastvm', {
  catalog: () => ipcRenderer.invoke('catalog'),
  dockerVersion: () => ipcRenderer.invoke('docker:version'),
  list: () => ipcRenderer.invoke('docker:ps'),
  launch: (spec) => ipcRenderer.invoke('docker:launch', spec),
  stop: (id) => ipcRenderer.invoke('docker:stop', id),
  remove: (id) => ipcRenderer.invoke('docker:rm', id),
  logs: (id) => ipcRenderer.invoke('docker:logs', id),
  openExternal: (url) => ipcRenderer.invoke('open:external', url),
});
