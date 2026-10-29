#!/bin/bash
# Main results: Tables 1-3 (PGA-KD rows only). Baselines are not run.
#   Table 1: FastVLM CLS / VQA / RET / GRD (ID); Table 3: OOD for CLS and VQA
#   Table 2: OneVision CLS / VQA (ID)
# Usage: bash scripts/run_main.sh [fastvlm|onevision|all]
set -euo pipefail
cd "$(dirname "$0")/.."
WHICH=${1:-all}

if [ "$WHICH" = fastvlm ] || [ "$WHICH" = all ]; then
    for task in cls vqa; do
        STUDENT=fastvlm TASK=$task EVAL_SETS=both bash scripts/pga_run.sh
    done
    for task in ret grd; do
        STUDENT=fastvlm TASK=$task EVAL_SETS=id bash scripts/pga_run.sh
    done
fi

if [ "$WHICH" = onevision ] || [ "$WHICH" = all ]; then
    for task in cls vqa; do
        STUDENT=onevision TASK=$task EVAL_SETS=id bash scripts/pga_run.sh
    done
fi
