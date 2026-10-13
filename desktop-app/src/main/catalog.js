'use strict';

/**
 * FastVM image catalog.
 *
 * Pure data + tag/argument builders. No Electron and no Docker calls live here
 * so the logic can be unit-tested with plain `node --test`.
 *
 * Keep this in sync with the build matrix in
 * `.github/workflows/build-images.yml`. `scripts/verify-catalog.js` checks it.
 */

const REGISTRY = 'ghcr.io/cloudcompile/fastvm';

const DESKTOPS = [
  'xfce4', 'kde', 'gnome', 'cinnamon', 'lxqt', 'i3', 'budgie', 'mate', 'lxde',
  'fluxbox', 'unity', 'enlightenment', 'icewm', 'awesome', 'ukui', 'bspwm',
  'gnome-flashback', 'wmaker', 'herbstluftwm', 'jwm', 'fvwm', 'xmonad', 'sugar',
  'dwm', 'ratpoison', 'blackbox', 'pop-os', 'pekwm', 'spectrwm', 'sawfish',
  'openbox', 'afterstep', 'ctwm', 'twm', 'nixos', 'pearos',
];

const PRESETS = [
  'none', 'minimal', 'gaming', 'development', 'office', 'content-creation',
];

const SINGLE_APPS = ['browser', 'discord', 'vscode', 'terminal'];

// Distro-flavor images publish a single `<flavor>-latest` tag each.
const FLAVORS = [
  'fastvm-os', 'ubuntu-studio', 'ubuntu-kylin', 'ubuntu-budgie',
  'ubuntu-edubuntu', 'xubuntu', 'lubuntu', 'kubuntu', 'ubuntu-mate',
  'ubuntu-unity', 'pop-os', 'linuxmint', 'kali', 'parrot', 'nixos', 'pearos',
];

const DASHBOARD_PORT = 8099;
const DESKTOP_PORT = 3000;

/** Human-readable metadata used by the picker UI. */
const DESKTOP_META = {
  xfce4: { label: 'XFCE4', vibe: 'Classic GTK', ram: '512 MB', recommended: true },
  kde: { label: 'KDE Plasma', vibe: 'Modern Qt', ram: '1.5 GB' },
  gnome: { label: 'GNOME', vibe: 'Sleek', ram: '2 GB' },
  cinnamon: { label: 'Cinnamon', vibe: 'Windows-like', ram: '1 GB' },
  lxqt: { label: 'LXQt', vibe: 'Minimal', ram: '256 MB' },
  i3: { label: 'i3', vibe: 'Tiling', ram: '128 MB' },
  mate: { label: 'MATE', vibe: 'Classic GNOME 2', ram: '512 MB' },
  lxde: { label: 'LXDE', vibe: 'Ultra-light', ram: '192 MB' },
  openbox: { label: 'Openbox', vibe: 'Stacking WM', ram: '128 MB' },
  twm: { label: 'TWM', vibe: 'Minimal WM', ram: '96 MB' },
  nixos: { label: 'NixOS', vibe: 'Openbox + Nix', ram: '256 MB' },
  pearos: { label: 'pearOS', vibe: 'macOS-like KDE', ram: '1.5 GB' },
  'pop-os': { label: 'Pop!_OS', vibe: 'GNOME (System76)', ram: '2 GB' },
};

/** Return the metadata for a desktop, falling back to a derived label. */
function desktopMeta(id) {
  return DESKTOP_META[id] || { label: id, vibe: '', ram: '' };
}

/** Validate a desktop id, throwing on unknown values. */
function assertDesktop(id) {
  if (!DESKTOPS.includes(id)) throw new Error(`Unknown desktop: ${id}`);
  return id;
}

/** Validate a preset id, throwing on unknown values. */
function assertPreset(id) {
  if (!PRESETS.includes(id)) throw new Error(`Unknown preset: ${id}`);
  return id;
}

/** Validate a flavor id, throwing on unknown values. */
function assertFlavor(id) {
  if (!FLAVORS.includes(id)) throw new Error(`Unknown flavor: ${id}`);
  return id;
}

/** `<desktop>-<preset>-latest` tag for a desktop image. */
function desktopTag(desktop, preset) {
  return `${assertDesktop(desktop)}-${assertPreset(preset)}-latest`;
}

/** `<name>-latest` tag for a single-app image. */
function singleAppTag(name) {
  if (!SINGLE_APPS.includes(name)) throw new Error(`Unknown single-app image: ${name}`);
  return `${name}-latest`;
}

/** `<flavor>-latest` tag for a distro-flavor image. */
function flavorTag(flavor) {
  return `${assertFlavor(flavor)}-latest`;
}

/** Fully-qualified image reference. */
function imageRef(tag) {
  return `${REGISTRY}:${tag}`;
}

/**
 * Build the `docker run` argument vector for an image.
 *
 * @param {object} opts
 * @param {string} opts.image          Full image ref or tag.
 * @param {number} [opts.hostPort]     Host port mapped to the desktop (3000).
 * @param {number} [opts.dashboardPort] Host port mapped to the dashboard, or 0 to omit.
 * @param {string} [opts.name]         Container name.
 * @param {string} [opts.shmSize]      Shared-memory size (e.g. "4gb").
 * @param {string} [opts.memory]       Memory limit (e.g. "3g").
 * @param {string} [opts.cpus]         CPU limit (e.g. "2").
 * @param {boolean} [opts.gpu]         Pass through /dev/dri.
 * @param {string[]} [opts.env]        Extra `KEY=VALUE` environment pairs.
 * @param {string[]} [opts.volumes]    Extra `host:container` volume pairs.
 * @param {boolean} [opts.detach]      Run detached (default true).
 * @returns {string[]} argv for `docker` (without the leading "docker").
 */
function buildRunArgs(opts) {
  const o = opts || {};
  if (!o.image) throw new Error('buildRunArgs requires opts.image');
  const hostPort = o.hostPort == null ? DESKTOP_PORT : o.hostPort;
  const args = ['run'];
  if (o.detach !== false) args.push('-d');
  if (o.name) args.push('--name', o.name);
  args.push('-p', `${hostPort}:${DESKTOP_PORT}`);
  if (o.dashboardPort) args.push('-p', `${o.dashboardPort}:${DASHBOARD_PORT}`);
  if (o.shmSize) args.push('--shm-size', o.shmSize);
  if (o.memory) args.push('--memory', o.memory);
  if (o.cpus) args.push('--cpus', o.cpus);
  if (o.gpu) args.push('--device', '/dev/dri');
  for (const pair of o.env || []) args.push('-e', pair);
  for (const vol of o.volumes || []) args.push('-v', vol);
  args.push(o.image);
  return args;
}

/** Total published image variants (desktop x preset + single-app + flavor). */
function variantCount() {
  return DESKTOPS.length * PRESETS.length + SINGLE_APPS.length + FLAVORS.length;
}

module.exports = {
  REGISTRY,
  DESKTOPS,
  PRESETS,
  SINGLE_APPS,
  FLAVORS,
  DESKTOP_PORT,
  DASHBOARD_PORT,
  desktopMeta,
  assertDesktop,
  assertPreset,
  assertFlavor,
  desktopTag,
  singleAppTag,
  flavorTag,
  imageRef,
  buildRunArgs,
  variantCount,
};
