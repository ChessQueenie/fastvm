#!/bin/bash
# FastVM common shell library: logging, config loading, helpers.
# Source this from other scripts: source "$(dirname "$0")/lib-common.sh"

# Colors (auto-disable if not a TTY).
if [[ -t 1 ]]; then
    FVM_RED='\033[0;31m'
    FVM_GREEN='\033[0;32m'
    FVM_YELLOW='\033[1;33m'
    FVM_BLUE='\033[0;34m'
    FVM_CYAN='\033[0;36m'
    FVM_MAGENTA='\033[0;35m'
    FVM_BOLD='\033[1m'
    FVM_NC='\033[0m'
else
    FVM_RED='' FVM_GREEN='' FVM_YELLOW='' FVM_BLUE='' FVM_CYAN='' FVM_MAGENTA='' FVM_BOLD='' FVM_NC=''
fi

log_info()    { echo -e "${FVM_BLUE}[INFO]${FVM_NC} $*"; }
log_success() { echo -e "${FVM_GREEN}[ OK ]${FVM_NC} $*"; }
log_warn()    { echo -e "${FVM_YELLOW}[WARN]${FVM_NC} $*"; }
log_error()   { echo -e "${FVM_RED}[FAIL]${FVM_NC} $*" >&2; }
log_step()    { echo -e "${FVM_CYAN}[STEP]${FVM_NC} ${FVM_BOLD}$*${FVM_NC}"; }

# FastVM data roots (overridable for in-container vs host execution).
: "${FASTVM_DATA_ROOT:=/config}"
: "${FASTVM_BACKUP_DIR:=${FASTVM_DATA_ROOT}/backups}"
: "${FASTVM_RECORDINGS_DIR:=${FASTVM_DATA_ROOT}/recordings}"
: "${FASTVM_LOG_DIR:=/var/log/fastvm}"

ensure_dir() {
    local d="$1"
    [[ -d "$d" ]] || mkdir -p "$d"
}

# Load config.env if it exists in the script tree (host invocation).
load_fastvm_config() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[1]:-$0}")" && pwd)"
    local cfg="${script_dir}/../config.env"
    if [[ -f "$cfg" ]]; then
        set -a
        # shellcheck disable=SC1090
        source "$cfg"
        set +a
    fi
}

# GPU helpers ----------------------------------------------------------------
# Path to the GPU capability record written by gpu-detect.sh.
gpu_json_path() { echo "${FASTVM_DATA_ROOT}/.fastvm/gpu.json"; }

# Print the encoder id recommended by the last detection (software if unknown).
gpu_recommended_encoder() {
    local f; f="$(gpu_json_path)"
    if [[ -r "$f" ]] && command -v jq >/dev/null 2>&1; then
        jq -r '.recommended_encoder // "software"' "$f" 2>/dev/null || echo software
    else
        echo software
    fi
}

# Resolve FASTVM_RECORDING_ENCODER (auto|nvenc|vaapi|qsv|software) to an ffmpeg
# encoder name. Explicit choices are honoured as-is; "auto" uses the detection
# result. Detection runs on demand so this works without container init.
resolve_encoder() {
    local choice="${FASTVM_RECORDING_ENCODER:-auto}"
    if [[ "$choice" == "auto" ]]; then
        local f; f="$(gpu_json_path)"
        if [[ ! -r "$f" ]] && [[ -x "${FASTVM_SCRIPTS_DIR:-/fastvm-scripts}/gpu-detect.sh" ]]; then
            "${FASTVM_SCRIPTS_DIR:-/fastvm-scripts}/gpu-detect.sh" detect >/dev/null 2>&1 || true
        fi
        choice="$(gpu_recommended_encoder)"
    fi
    case "$choice" in
        nvenc)    echo h264_nvenc ;;
        vaapi)    echo h264_vaapi ;;
        qsv)      echo h264_qsv ;;
        software|*) echo libx264 ;;
    esac
}

# Human-readable bytes.
human_bytes() {
    local bytes=${1:-0}
    awk -v b="$bytes" 'BEGIN{
        split("B KB MB GB TB PB", u);
        i=1; while (b>=1024 && i<6) { b/=1024; i++ }
        printf("%.2f %s", b, u[i])
    }'
}
