# FastVM GPU acceleration

FastVM runs without a GPU by default and falls back to software encoding and
software (llvmpipe) desktop rendering. When the host has a GPU, FastVM can use it
for **real GPU rasterization of the desktop**, hardware video encode, and
GPU-accelerated applications. Every GPU feature is opt-in: a host with no GPU
behaves exactly as before.

There are three places a GPU helps:

1. **Desktop rendering** — KasmVNC's DRI3 mode (`-hw3d`) makes the X server
   rasterize the desktop on the GPU instead of CPU RAM, so GL/3D apps and the
   composited desktop stop falling back to `llvmpipe`.
2. **Screen recording** — `ffmpeg` hardware encode (NVENC / VA-API / QSV)
   replaces `libx264` and frees CPU for the desktop.
3. **Applications** — Blender, ML/CUDA, and DXVK/Proton games use the GPU
   directly once the device nodes are mapped.

## What "real GPU rasterization" means here

FastVM's desktop is drawn by Xvnc, a *virtual* X server that normally allocates
the screen in system RAM and renders GL with Mesa's software rasterizer
(`llvmpipe`). Mapping `/dev/dri` alone does not change that — the X server has to
be told to use the GPU. The base image handles the server side automatically:
when `/dev/dri` is present (and NVIDIA's `nvidia-smi` is **not**), it starts Xvnc
with `-hw3d`, which enables **DRI3** and makes the GPU the render device for the
whole session. FastVM then sets the per-session userspace variables
(`scripts/gpu-session-env.sh`) so applications pick the same GPU.

DRI3 has two requirements worth knowing:

- **Compositing must be off.** KasmVNC does not support desktop compositing with
  DRI3; with it on, the window manager still falls back to `llvmpipe`. See
  [Desktop compositing](#desktop-compositing) below.
- **Open-source drivers only.** Intel and AMD work directly. NVIDIA's closed
  driver has no DRI3 and is reached through **Zink** (OpenGL-over-Vulkan)
  instead.

## 1. Enable GPU access (compose overlays)

Do **not** set `FASTVM_PRIVILEGED=true`. Use the overlays, which map only the
needed devices. With the installer, set `FASTVM_GPU` in `config.env` and run
`./fastvm-install.sh` — it selects the right overlay automatically:

| `FASTVM_GPU`        | Effect                                              |
| ------------------- | --------------------------------------------------- |
| `false` (default)   | No device mapping; software encoding only.          |
| `true` / `intel` / `amd` | Map `/dev/dri` for DRI3/VA-API/QSV.           |
| `nvidia`            | NVIDIA device reservation (needs the container toolkit). |

The equivalent manual commands are below.

### Intel / AMD (VA-API, QSV, DRI3)

```bash
docker compose -f docker-compose.yml -f docker-compose.gpu.yml up -d
```

This maps `/dev/dri` and adds the `video`/`render` groups. Verify inside the
container:

```text
vainfo
ffmpeg -hide_banner -encoders | grep -E 'vaapi|qsv'
```

### NVIDIA (NVENC)

Host prerequisite: install the [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html)
and run `nvidia-ctk runtime configure --runtime=docker`, then restart Docker.

```bash
docker compose -f docker-compose.yml -f docker-compose.gpu-nvidia.yml up -d
```

NVENC needs the `video` capability; CUDA/ML needs `compute`. The overlay sets
`NVIDIA_DRIVER_CAPABILITIES=compute,video,utility` by default. Verify:

```text
nvidia-smi
ffmpeg -hide_banner -encoders | grep nvenc
```

## 2. Choose an encoder

Set `FASTVM_RECORDING_ENCODER` in `config.env`:

| Value      | Behaviour                                                        |
| ---------- | ---------------------------------------------------------------- |
| `auto`     | Use the encoder detected at startup; fall back to software.      |
| `nvenc`    | Force NVIDIA NVENC (`h264_nvenc`).                               |
| `vaapi`    | Force VA-API (`h264_vaapi`) — Intel/AMD.                         |
| `qsv`      | Force Intel Quick Sync (`h264_qsv`).                             |
| `software` | Force `libx264` (CPU).                                           |

Hardware encoders produce H.264, so `auto` forces an H.264-capable container
(`mp4`/`mkv`) even if `FASTVM_RECORDING_FORMAT` asks for `webm`.

## 4. Desktop compositing

KasmVNC's DRI3 mode does **not** support desktop compositing: with the
compositor enabled, the window manager (and therefore the whole desktop) renders
through `llvmpipe` on the CPU even when a GPU is mapped. To get GPU-rasterized
desktop sessions, turn the compositor off.

`FASTVM_GPU_HW=true` (set by the GPU overlays) sources
`scripts/gpu-session-env.sh` into the session, which exports the GPU render node
(`LIBVA_DRM_DEVICE`, plus Zink variables on NVIDIA) so applications use the same
GPU. The compositor itself is a per-desktop setting:

| Desktop | Where to disable compositing |
| ------- | ---------------------------- |
| XFCE    | Settings Manager → Window Manager Tweaks → Compositor → uncheck "Enable display compositing" |
| KDE     | System Settings → Display and Monitor → Compositor → uncheck "Enable on startup" |
| MATE    | System → Control Center → Windows → uncheck "Enable software compositing window manager" |
| GNOME   | Not supported; GNOME is forced to use `llvmpipe` |

> Leave compositing **enabled** if you need translucent windows and effects and
> do not mind the desktop rendering on the CPU. GPU compute, hardware encode, and
> application rendering still work; only the desktop rasterization falls back.

## 5. Detection, status, and self-test

At container start, `scripts/gpu-detect.sh` probes for a GPU and writes
`/config/.fastvm/gpu.json`:

```text
/fastvm-scripts/gpu-detect.sh detect   # probe now
/fastvm-scripts/gpu-detect.sh show     # print the record
```

A short encoder self-test runs at startup (disable with
`FASTVM_GPU_SELFTEST=false`) and warns if a selected hardware encoder fails:

```text
/fastvm-scripts/gpu-self-test.sh          # test the resolved encoder
/fastvm-scripts/gpu-self-test.sh nvenc    # test a specific encoder
```

Check what the session exported for GPU access:

```text
/fastvm-scripts/gpu-session-env.sh --print
```

The dashboard shows GPU utilization/VRAM on the overview and the detected GPU +
encoder under **System → GPU acceleration**. Endpoints:

- `GET /api/gpu/status` — capabilities from `gpu.json`
- `GET /api/gpu/metrics` — live metrics (utilization/VRAM for NVIDIA)
- `GET /api/system/status` — includes a `gpu` object

## 6. Images

The GPU-enabled image ships the VA-API/Mesa/Vulkan userspace drivers:

```bash
docker run --rm --device /dev/dri:/dev/dri \
  ghcr.io/cloudcompile/fastvm:gpu-latest
```

`FASTVM_ENABLE_GPU_DRIVERS=true` (default) installs the driver packages at build
time. NVIDIA does not need packages in the image: the toolkit injects the driver
from the host at runtime.

## Limitations

- DRI3 acceleration covers the **open-source** Intel and AMD drivers. NVIDIA's
  closed driver has no DRI3; on NVIDIA the desktop itself is not GPU-rasterized,
  and GPU access is limited to compute, hardware encode, and application
  rendering via Zink/Vulkan.
- Desktop compositing and DRI3 are mutually exclusive (see above). GNOME cannot
  disable compositing, so it always renders on the CPU.
- The screen is still a virtual framebuffer in RAM, so there is a per-frame copy
  from GPU to RAM for the stream. The win is that rasterization happens on the
  GPU instead of `llvmpipe`.
- Hardware encode and DRI3 depend on the host driver and the mapped device nodes;
  when either is missing FastVM logs the failure and uses software paths.
- GPU passthrough is a host/operator decision. FastVM never enables privileged
  mode on its own.
