# FastVM Discord VM

A minimal, single-purpose image that runs **only Discord**: no desktop
environment, no distribution application packages. It is the base KasmVNC image
plus openbox, a few Electron runtime libraries, and the Discord `.deb` unpacked
straight into the filesystem.

## Run it

```bash
docker run -d --name fastvm-discord -p 3000:3000 \
  ghcr.io/cloudcompile/fastvm:discord-latest
```

Open <http://localhost:3000>. Discord launches fullscreen in an openbox session.

## What is actually installed

| Layer | Contents |
| --- | --- |
| Base | `ghcr.io/linuxserver/baseimage-kasmvnc:ubuntujammy` (KasmVNC, PulseAudio, kclient, nginx) |
| Window manager | `openbox` |
| Electron runtime | `libatomic1`, `libgbm1`, `libasound2` |
| App | Discord `.deb`, unpacked with `dpkg -i` |

`dpkg -i` installs exactly the contents of the `.deb` — it does **not** resolve
dependencies from the Ubuntu archive. The three libraries above are the only
additions beyond the base image. See `installable-apps/discord-only.sh`.

## Sound and microphone

Both directions work, and they are provided by the base image rather than by
FastVM:

- **Sound out** — PulseAudio plus the `kclient` PCM player over websocket.
- **Microphone in** — `kclient` calls `getUserMedia` on your *browser's* mic and
  streams it over websocket into the container, where it is loaded as a
  PulseAudio source named `virtmic` (`svc-kclient`).

### Requirements

1. **Grant browser permission.** The browser prompts for microphone access the
   first time. Denying it leaves Discord with no input device.
2. **Secure context.** Browsers only expose `getUserMedia` on `localhost` or over
   HTTPS. On a remote host you must terminate TLS in front of port 3000, or the
   microphone will be silently unavailable.
3. **Open the KasmVNC audio panel** and enable the microphone if it is off.

### Verifying audio in a running container

```bash
docker exec fastvm-discord /fastvm-scripts/audio-self-test.sh
```

This discovers the default sink and source, plays a short tone, and captures
samples. The single-app session also logs the audio input state at startup:

```text
[fastvm] audio input ready: default source=virtmic
```

## Webcam

**Not supported.** Webcam passthrough is a Kasm **Workspaces** (commercial)
feature that requires the `v4l2loopback` kernel module on the host and Kasm's own
web platform. The open-source KasmVNC server that this image streams from has no
webcam code at all. Discord video calls will see no camera. See
[roadmap.md](roadmap.md).

## GPU

On a compute-only accelerator (for example an AMD Instinct MI300X) Discord runs
on CPU rasterization (`llvmpipe`). That is expected and does not affect chat or
voice. See [gpu.md](gpu.md).

## Related

- [audio.md](audio.md) — FastVM audio model
- [image-catalog.md](image-catalog.md) — all image variants
- [roadmap.md](roadmap.md) — webcam passthrough and other planned work
