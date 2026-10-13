# FastVM GPU acceleration

FastVM runs without a GPU by default and falls back to software encoding. When
the host has a GPU, FastVM can use it for hardware video encode (the biggest
practical win) and for GPU-accelerated applications inside the desktop. Every
GPU feature is opt-in: a host with no GPU behaves exactly as before.

There are three places a GPU helps:

1. **Screen recording** — `ffmpeg` hardware encode (NVENC / VA-API / QSV)
   replaces `libx264` and frees CPU for the desktop.
2. **Applications** — Blender, ML/CUDA, and DXVK/Proton games can use the GPU
   directly once the device nodes are mapped.
3. **Streaming** — the KasmVNC stream benefits from the same userspace drivers
   (see the note below on virtual-desktop limits).

## 1. Enable GPU access (compose overlays)

Do **not** set `FASTVM_PRIVILEGED=true`. Use the overlays, which map only the
needed devices. With the installer, set `FASTVM_GPU` in `config.env` and run
`./fastvm-install.sh` — it selects the right overlay automatically:

| `FASTVM_GPU`        | Effect                                              |
| ------------------- | --------------------------------------------------- |
| `false` (default)   | No device mapping; software encoding only.          |
| `true` / `intel` / `amd` | Map `/dev/dri` for VA-API/QSV.                |
| `nvidia`            | NVIDIA device reservation (needs the container toolkit). |

The equivalent manual commands are below.

### Intel / AMD (VA-API, QSV)

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

## 3. Detection, status, and self-test

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

The dashboard shows GPU utilization/VRAM on the overview and the detected GPU +
encoder under **System → GPU acceleration**. Endpoints:

- `GET /api/gpu/status` — capabilities from `gpu.json`
- `GET /api/gpu/metrics` — live metrics (utilization/VRAM for NVIDIA)
- `GET /api/system/status` — includes a `gpu` object

## 4. Images

The GPU-enabled image ships the VA-API/Mesa/Vulkan userspace drivers:

```bash
docker run --rm --device /dev/dri:/dev/dri \
  ghcr.io/cloudcompile/fastvm:gpu-latest
```

`FASTVM_ENABLE_GPU_DRIVERS=true` (default) installs the driver packages at build
time. NVIDIA does not need packages in the image: the toolkit injects the driver
from the host at runtime.

## Limitations

- KasmVNC runs a virtual X server (Xvnc) that does not get full hardware OpenGL
  the way a physical display does. The reliable GPU wins are **hardware encode**
  and **application-side** rendering (Blender, CUDA, DXVK).
- Hardware encode depends on the host driver and the mapped device nodes; when
  either is missing FastVM logs the failure and uses software encoding.
- GPU passthrough is a host/operator decision. FastVM never enables privileged
  mode on its own.
