#!/bin/bash
# Table A6: LoRA rank sweep (FastVLM-0.5B, VQA). r = 128 / alpha = 512 is the full model.
# Alpha is not a fixed multiple of r in the paper: only 128 -> 512 and 512 -> 896 are stated.
# The other alphas below are set to 4*r, matching the 128 -> 512 pair; adjust if the authors say otherwise.
set -euo pipefail
cd "$(dirname "$0")/../.."
export STUDENT=fastvlm TASK=vqa EVAL_SETS=id

while read -r r a; do
    LORA_R=$r LORA_A=$a EXP_NAME="PGA_fastvlm_vqa_r${r}_a${a}" bash scripts/pga_run.sh
done <<'GRID'
2 8
4 16
8 32
16 64
64 256
128 512
256 1024
512 896
GRID
