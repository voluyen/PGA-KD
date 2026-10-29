#!/bin/bash
# One-shot environment + data setup. Safe to re-run.
set -euo pipefail
cd "$(dirname "$0")/.."

# prefer python3.11 (what the paper environment used), fall back to whatever python3 is installed
PY=${PYTHON:-$(command -v python3.11 || command -v python3 || true)}
[ -n "$PY" ] || { echo "no python3 found; install it or set PYTHON=/path/to/python" >&2; exit 1; }
echo "Using $($PY --version) at $PY"
if [ ! -d vlm ]; then
    $PY -m venv vlm
fi
source vlm/bin/activate
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
echo "Setup done. Run 'wandb login' (or export REPORT_TO=none), then 'source vlm/bin/activate'."
