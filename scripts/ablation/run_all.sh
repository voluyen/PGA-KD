#!/bin/bash
# Ablations backing the paper's claims; Table 5 (eta), Table 6 / A6 (hyperparameter picks) and A5 (seeds) are skipped.
set -euo pipefail
cd "$(dirname "$0")/.."
for s in table4_components; do
    echo "######## $s"
    bash "ablation/$s.sh"
done
