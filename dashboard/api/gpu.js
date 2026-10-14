// GPU metrics + capability reporting for the FastVM dashboard.
// Reads the gpu.json record written by scripts/gpu-detect.sh and, when an
// NVIDIA GPU is present, queries live utilization/VRAM via nvidia-smi.

'use strict';

const express = require('express');
const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');

const router = express.Router();
const DATA_ROOT = process.env.FASTVM_DATA_ROOT || '/config';
const GPU_JSON = path.join(DATA_ROOT, '.fastvm', 'gpu.json');

function readCapabilities() {
    try {
        return JSON.parse(fs.readFileSync(GPU_JSON, 'utf8'));
    } catch {
        return {
            detected: false,
            vendor: 'none',
            render_node: '',
            encoders: {},
            recommended_encoder: 'software',
        };
    }
}

function readNvidiaStats() {
    try {
        const out = execFileSync('nvidia-smi', [
            '--query-gpu=index,name,utilization.gpu,memory.used,memory.total,temperature.gpu',
            '--format=csv,noheader,nounits',
        ], { encoding: 'utf8', timeout: 4000 });
        return out.trim().split('\n').filter(Boolean).map((line) => {
            const [index, name, util, memUsed, memTotal, temp] = line.split(',').map((s) => s.trim());
            return {
                index: parseInt(index, 10),
                name,
                utilization: parseInt(util, 10),
                memory_used: parseInt(memUsed, 10) * 1024 * 1024,
                memory_total: parseInt(memTotal, 10) * 1024 * 1024,
                temperature: parseInt(temp, 10),
            };
        });
    } catch {
        return [];
    }
}

// Compact snapshot used by the WebSocket broadcaster.
function readGpu() {
    const caps = readCapabilities();
    const result = {
        detected: !!caps.detected,
        vendor: caps.vendor || 'none',
        compute_only: !!caps.compute_only,
        recommended_encoder: caps.recommended_encoder || 'software',
        requested_encoder: process.env.FASTVM_RECORDING_ENCODER || 'auto',
        encoders: caps.encoders || {},
        devices: [],
    };
    if (result.vendor === 'nvidia') {
        result.devices = readNvidiaStats();
        if (result.devices.length) {
            const d = result.devices[0];
            result.utilization = d.utilization;
            result.memory_used = d.memory_used;
            result.memory_total = d.memory_total;
            result.temperature = d.temperature;
        }
    }
    return result;
}

router.get('/status', (_req, res) => res.json({ ok: true, gpu: readCapabilities() }));
router.get('/metrics', (_req, res) => res.json(readGpu()));

module.exports = { router, readGpu };
