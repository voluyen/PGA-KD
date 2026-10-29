#!/bin/bash
# Every ablation of the paper that concerns PGA-KD itself, in order of cost.
set -euo pipefail
cd "$(dirname "$0")/.."
for s in table4_components table5_eta table6_loss_weights tableA6_lora_rank tableA5_seeds; do
    echo "######## $s"
    bash "ablation/$s.sh"
done
