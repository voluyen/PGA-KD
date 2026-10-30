#!/bin/bash
# Table A5: three-seed OOD VQA study for PGA-KD (FastVLM-0.5B). MSE / EM-KD rows are baselines and not run here.
# Seed 42 reuses the main-result VQA checkpoint; only ScienceQA, GQA and TextVQA are scored.
set -euo pipefail
# opt-in: the sweep already running parsed its list before A5 was dropped from run_all.sh
[ "${RUN_SEEDS:-0}" = 1 ] || { echo "[skip] seed study (set RUN_SEEDS=1 to run it)"; exit 0; }
cd "$(dirname "$0")/../.."
export STUDENT=fastvlm TASK=vqa EVAL_SETS=ood OOD_SUBSET="ScienceQA GQA TextVQA"

for seed in 42 1234 2026; do
    SEED=$seed bash scripts/pga_run.sh
done
