#!/bin/bash
# Table A5: three-seed OOD VQA study for PGA-KD (FastVLM-0.5B). MSE / EM-KD rows are baselines and not run here.
# Seed 42 reuses the main-result VQA checkpoint; only ScienceQA, GQA and TextVQA are scored.
set -euo pipefail
cd "$(dirname "$0")/../.."
export STUDENT=fastvlm TASK=vqa EVAL_SETS=ood OOD_SUBSET="ScienceQA GQA TextVQA"

for seed in 42 1234 2026; do
    SEED=$seed bash scripts/pga_run.sh
done
