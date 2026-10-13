#!/bin/bash
# FastVM GPU detection. Probes the container for a usable GPU, records what it
# finds in $FASTVM_DATA_ROOT/.fastvm/gpu.json, and recommends a hardware video
# encoder. Best-effort by design: a host with no GPU is not an error.
#
#     gpu-detect.sh detect     # probe and (re)write gpu.json (default)
#     gpu-detect.sh show       # print the cached gpu.json
#     gpu-detect.sh encoder    # print the recommended encoder id

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib-common.sh
source "${SCRIPT_DIR}/lib-common.sh"

STATE_DIR="${FASTVM_DATA_ROOT}/.fastvm"
ensure_dir "$STATE_DIR"
OUT="${STATE_DIR}/gpu.json"

ffmpeg_has_encoder() {
    command -v ffmpeg >/dev/null 2>&1 || return 1
    ffmpeg -hide_banner -encoders 2>/dev/null | awk 'NF>=2 {print $2}' | grep -qx "$1"
}

# Map a DRM vendor id to a friendly name.
drm_vendor_name() {
    case "$1" in
        0x8086) echo intel ;;
        0x1002) echo amd ;;
        0x10de) echo nvidia ;;
        *) echo unknown ;;
    esac
}

detect_nvidia() {
    [[ -e /dev/nvidiactl || -e /dev/nvidia0 ]] && return 0
    command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi -L >/dev/null 2>&1
}

nvidia_driver_version() {
    command -v nvidia-smi >/dev/null 2>&1 || return 0
    nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null | head -n1
}

detect() {
    local render_node="" card="" vendor="none" detected="false"
    local nvenc="false" vaapi_enc="false" qsv="false"
    local recommended="software" vaapi_driver=""

    render_node="$(ls /dev/dri/renderD* 2>/dev/null | head -n1 || true)"
    card="$(ls /dev/dri/card* 2>/dev/null | head -n1 || true)"

    if detect_nvidia; then
        vendor="nvidia"
        detected="true"
        ffmpeg_has_encoder h264_nvenc && nvenc="true"
    fi

    if [[ -n "$render_node" ]]; then
        detected="true"
        local vf="/sys/class/drm/$(basename "$render_node")/device/vendor"
        if [[ -r "$vf" ]]; then
            vendor="$(drm_vendor_name "$(cat "$vf")")"
        elif [[ "$vendor" == "none" ]]; then
            vendor="unknown"
        fi
        # QSV is Intel-only and needs the media driver.
        if [[ "$vendor" == "intel" ]] && ffmpeg_has_encoder h264_qsv; then
            qsv="true"
        fi
        if ffmpeg_has_encoder h264_vaapi; then
            vaapi_enc="true"
        fi
        if command -v vainfo >/dev/null 2>&1; then
            vaapi_driver="$(vainfo --display drm --device "$render_node" 2>/dev/null \
                | awk -F': ' '/vainfo: Driver version/ {print $2; exit}' || true)"
        fi
    fi

    if [[ "$nvenc" == "true" ]]; then
        recommended="nvenc"
    elif [[ "$vaapi_enc" == "true" && -n "$render_node" ]]; then
        recommended="vaapi"
    elif [[ "$qsv" == "true" ]]; then
        recommended="qsv"
    fi

    local driver_version
    driver_version="$(nvidia_driver_version || true)"

    cat > "$OUT" <<JSON
{
  "detected": ${detected},
  "vendor": "${vendor}",
  "render_node": "${render_node}",
  "card": "${card}",
  "nvidia": {
    "present": $([[ "$vendor" == "nvidia" ]] && echo true || echo false),
    "driver_version": "${driver_version}"
  },
  "vaapi": {
    "available": ${vaapi_enc},
    "driver": "${vaapi_driver}"
  },
  "encoders": {
    "h264_nvenc": ${nvenc},
    "h264_vaapi": ${vaapi_enc},
    "h264_qsv": ${qsv}
  },
  "recommended_encoder": "${recommended}",
  "generated_at": "$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
}
JSON
    chmod 0644 "$OUT" 2>/dev/null || true

    if [[ "$detected" == "true" ]]; then
        log_success "GPU detected: vendor=${vendor} encoder=${recommended}"
    else
        log_info "No GPU detected; using software encoding"
    fi
}

cmd="${1:-detect}"
case "$cmd" in
    detect) detect ;;
    show)   [[ -r "$OUT" ]] && cat "$OUT" || log_error "No gpu.json yet; run: gpu-detect.sh detect" ;;
    encoder)
        [[ -r "$OUT" ]] || detect >/dev/null 2>&1 || true
        jq -r '.recommended_encoder // "software"' "$OUT" 2>/dev/null || echo software
        ;;
    *) log_error "Unknown command: $cmd"; exit 1 ;;
esac
