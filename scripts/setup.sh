#!/bin/bash
# One-shot environment + data setup. Safe to re-run.
set -euo pipefail
cd "$(dirname "$0")/.."

# conda env with python 3.11 (what the paper environment used)
ENV_NAME=${ENV_NAME:-pga-kd}
command -v conda >/dev/null || { echo "conda not found; install Miniconda first" >&2; exit 1; }
eval "$(conda shell.bash hook)"
if ! conda env list | awk '{print $1}' | grep -qx "$ENV_NAME"; then
    # conda-forge only: the default Anaconda channels require accepting their ToS first
    conda create -y -n "$ENV_NAME" --override-channels -c conda-forge python=3.11
fi
conda activate "$ENV_NAME"
echo "Using $(python --version) at $(which python)"

pip install --upgrade pip
pip install -r requirements.txt
python fix_lib.py

# training data (~20 MMEB-train subsets)
if [ ! -d vlm2vec_train/MMEB-train/images ]; then
    python download.py
else
    echo "[skip] vlm2vec_train/MMEB-train/images exists"
fi

# evaluation images
if [ ! -d eval_images ]; then
    wget -c https://huggingface.co/datasets/TIGER-Lab/MMEB-eval/resolve/main/images.zip
    unzip -q images.zip -d eval_images/
    rm images.zip
else
    echo "[skip] eval_images exists"
fi

# weights & biases is the default logger; set REPORT_TO=none to disable it
echo "Setup done. Run 'conda activate $ENV_NAME', then 'wandb login' (or export REPORT_TO=none)."
