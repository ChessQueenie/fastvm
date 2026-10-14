#!/bin/bash
# FastVM GPU encoder self-test. Records a short synthetic clip with the selected
# encoder and reports whether it produced valid output. This catches the common
# case where a hardware encoder is selected but fails at runtime (missing driver,
# no render node, unsupported pixel format) so operators are not misled.
#
#     gpu-self-test.sh            # test the resolved encoder
#     gpu-self-test.sh nvenc      # force a specific encoder id

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib-common.sh
source "${SCRIPT_DIR}/lib-common.sh"

choice="${1:-${FASTVM_RECORDING_ENCODER:-auto}}"
# Resolve without the environment override so an explicit arg wins.
vcodec="$(FASTVM_RECORDING_ENCODER="$choice" resolve_encoder)"

# A compute-only accelerator (e.g. AMD Instinct) exposes a render node but no
# usable VA-API device; fall back to software rather than failing the probe.
if [[ "$vcodec" == "h264_vaapi" ]] && gpu_is_compute_only; then
    log_warn "Compute-only GPU: VA-API unavailable; testing software instead"
    vcodec="libx264"
fi

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
out="${tmpdir}/probe.mp4"

enc_args=(-c:v "$vcodec" -preset veryfast)
case "$vcodec" in
    h264_nvenc) enc_args=(-c:v h264_nvenc -preset p4) ;;
    h264_qsv)   enc_args=(-c:v h264_qsv) ;;
    h264_vaapi)
        render="$(jq -r '.render_node // ""' "$(gpu_json_path)" 2>/dev/null || true)"
        [[ -n "$render" ]] || render="$(ls /dev/dri/renderD* 2>/dev/null | head -n1 || true)"
        [[ -n "$render" ]] || { log_error "VAAPI requested but no render node present"; exit 2; }
        enc_args=(-vaapi_device "$render" -vf "format=nv12,hwupload" -c:v h264_vaapi)
        ;;
    *) enc_args=(-c:v libx264 -preset veryfast) ;;
esac

if ! command -v ffmpeg >/dev/null 2>&1; then
    log_error "ffmpeg not installed; cannot self-test"
    exit 2
fi

log_step "Testing encoder ${vcodec} (requested: ${choice})"
if ffmpeg -hide_banner -loglevel error -y \
        -f lavfi -i testsrc=size=640x480:rate=30 -t 2 \
        "${enc_args[@]}" "$out" >/dev/null 2>&1 && [[ -s "$out" ]]; then
    log_success "Encoder ${vcodec} works"
    echo "OK ${vcodec}"
    exit 0
fi

log_warn "Encoder ${vcodec} failed; software (libx264) is the fallback"
if ffmpeg -hide_banner -loglevel error -y \
        -f lavfi -i testsrc=size=640x480:rate=30 -t 2 \
        -c:v libx264 -preset veryfast "$out" >/dev/null 2>&1 && [[ -s "$out" ]]; then
    echo "FALLBACK software"
    exit 1
fi

log_error "Even software encoding failed; check the ffmpeg build"
exit 2
