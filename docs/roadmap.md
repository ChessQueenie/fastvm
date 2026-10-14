# FastVM roadmap

Planned and known-limitation work, in rough priority order. Nothing here is
implemented yet unless noted.

## Webcam passthrough

**Status:** blocked upstream.

FastVM streams a container desktop through the open-source **KasmVNC** server
(via `ghcr.io/linuxserver/baseimage-kasmvnc:ubuntujammy`). That server has no
webcam support — its source tree contains no camera, `v4l2`, or
`getUserMedia`-for-video code.

Webcam passthrough is a **Kasm Workspaces** (commercial) feature. It requires:

- the `allow_kasm_webcam` group setting, and
- the `v4l2loopback` kernel module loaded on the **host**, which creates a virtual
  V4L2 device that Kasm maps into the session.

Neither is available to a plain `docker run` of the LinuxServer base image, and
the kernel module cannot be installed from inside a container.

### Options if this becomes a priority

1. **Document a host-side workaround.** A user who controls the host can load
   `v4l2loopback`, forward a device into the container with `--device`, and point
   the app at it. This is per-host manual setup, not something the image can do.
2. **Switch streaming stack** to one with native camera support. Large change.
3. **Track upstream.** If KasmVNC ever adds browser-camera-to-v4l2, revisit.

Until then, video calls inside FastVM have no camera; audio and microphone do
work (see [discord-vm.md](discord-vm.md)).

## Other planned work

- **Per-app audio routing** — separate sinks for apps that need independent
  volume in a single desktop session.
- **Gamepad passthrough** — Kasm Workspaces supports it; the OSS base image does
  not, same upstream situation as the webcam.
- **Curated bundles, deeper** — more bundles and per-desktop app choices beyond
  the current set. See [app-bundles.md](app-bundles.md).
