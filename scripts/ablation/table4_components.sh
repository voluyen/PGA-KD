#!/bin/bash
# Table 4: component ablation (FastVLM-0.5B, VQA). The full model is the main-result VQA run.
set -euo pipefail
cd "$(dirname "$0")/../.."
export STUDENT=fastvlm TASK=vqa EVAL_SETS=id

run() {  # name, then env assignments
    local name=$1; shift
    env "$@" EXP_NAME="PGA_fastvlm_vqa_abl_$name" bash scripts/pga_run.sh
}

run no_pga              DISABLE_PGA=1
run no_intra            DISABLE_INTRA=1
run no_inter            DISABLE_INTER=1
run no_pga_intra        DISABLE_PGA=1 DISABLE_INTRA=1
run no_pga_inter        DISABLE_PGA=1 DISABLE_INTER=1
run no_intra_inter      DISABLE_INTRA=1 DISABLE_INTER=1
bash scripts/pga_run.sh   # full model = main VQA run (default EXP_NAME)
