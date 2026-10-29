#!/bin/bash
# Table 5: spectral threshold eta (FastVLM-0.5B, VQA). eta = 0.85 is the full model.
set -euo pipefail
cd "$(dirname "$0")/../.."
export STUDENT=fastvlm TASK=vqa EVAL_SETS=id

for eta in 1.0 0.95 0.85 0.75 0.50; do
    VAR_T=$eta EXP_NAME="PGA_fastvlm_vqa_eta${eta}" bash scripts/pga_run.sh
done
