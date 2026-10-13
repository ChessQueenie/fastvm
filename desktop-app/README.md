# FastVM Desktop

A native client for FastVM. It launches and manages streamed Linux desktops
without a terminal — pick a desktop, preset, or distro flavor, press Launch, and
the desktop opens in your browser while the container runs in the background.

Runs on **Linux, Windows, and macOS** from one Electron codebase.

## What it does

- Browse the full image catalog: 36 desktops × 6 presets, 4 single-app images,
  and 16 distro-flavor images (236 variants).
- Build a `docker run` command from a form: ports, container name, shared
  memory, and GPU passthrough.
- See running FastVM containers, open the desktop or dashboard, stream logs,
  and stop or remove containers.
- Detects whether the Docker CLI is available and shows the version.

## Requirements

- [Docker](https://docs.docker.com/get-docker/) installed and running.
- Node.js 18+ to run or build the app.

## Run it

```bash
cd desktop-app
npm install
npm start
```

## Build installers

`electron-builder` produces platform packages. Build each on (or for) its target
platform:

```bash
npm run dist:linux   # AppImage + deb
npm run dist:win     # NSIS installer
npm run dist:mac     # dmg
```

> macOS builds must run on macOS and be code-signed/notarized for distribution.
> Windows builds should be code-signed to avoid SmartScreen warnings.

## Test

```bash
npm test
```

The tests cover the pure logic — the image catalog, the `docker run` argument
builder, the `docker ps` parser, and the `config.env` reader/writer — so they run
without Docker or a display.

## Architecture

```
desktop-app/
├── src/
│   ├── main/                 Electron main process (Node)
│   │   ├── main.js           window + IPC handlers
│   │   ├── preload.js        contextBridge API (the renderer's only surface)
│   │   ├── catalog.js        image catalog + tag/run-arg builders (pure)
│   │   ├── docker.js         Docker CLI wrapper + parsers (pure helpers)
│   │   └── config.js         config.env reader/writer (pure)
│   └── renderer/             UI (no Node access)
│       ├── index.html
│       ├── styles.css
│       └── renderer.js
└── test/                     node --test suites
```

### Security posture

- `contextIsolation: true`, `nodeIntegration: false`, `sandbox: true`.
- The renderer only sees the small API exposed in `preload.js`.
- All Docker commands run in the main process via `execFile` (no shell), so
  user input cannot inject shell commands.
- A strict Content-Security-Policy is set in `index.html`.

## Keeping the catalog in sync

`catalog.js` mirrors the build matrix in
`.github/workflows/build-images.yml`. After changing either, run:

```bash
node ../scripts/verify-catalog.js
```

The `catalog stays in sync with the build workflow` test runs the same check, so
drift fails CI.

## Roadmap

- Embed the KasmVNC stream in an app window (no browser) with native decoding.
- Saved connections for local Docker, remote VPS, and Pterodactyl hosts.
- OS keychain storage for dashboard tokens.
- File transfer, USB passthrough, and multi-monitor windows.
