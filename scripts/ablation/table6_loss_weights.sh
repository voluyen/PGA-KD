#!/bin/bash
# Table 6: sensitivity to (lambda_PGA, lambda_SCL, lambda_MSE) (FastVLM-0.5B, VQA).
# The last row (2.0, 0.01, 1.0) is the full model.
set -euo pipefail
cd "$(dirname "$0")/../.."
export STUDENT=fastvlm TASK=vqa EVAL_SETS=id

#        PGA  SCL   MSE
while read -r pga scl mse; do
    PGA_W=$pga SCL_W=$scl MSE_W=$mse \
        EXP_NAME="PGA_fastvlm_vqa_w_pga${pga}_scl${scl}_mse${mse}" bash scripts/pga_run.sh
done <<'GRID'
0.1 0.01 1.0
0.5 0.01 1.0
2.0 0.05 1.0
2.0 0.10 1.0
2.0 0.01 0.2
2.0 0.01 0.5
2.0 0.01 1.0
GRID
