#!/bin/bash
# Train one PGA-KD student and evaluate it on MMEB.
#
# Everything is configured through environment variables so the main-result and ablation
# wrappers can share one code path. Per-track defaults follow docs/TRAINING.md.
#
#   STUDENT   fastvlm | onevision                (default fastvlm)
#   TASK      cls | vqa | ret | grd              (default vqa)
#   EVAL_SETS id | ood | both | none             (default id)
#   NUM_GPUS  GPUs to use                        (default 1)
#   BATCH_SIZE  per-GPU micro-batch              (default: paper's per-GPU value; lower it on OOM)
#   The paper's global batch (8 x per-GPU) is kept via gradient accumulation.
#   EXP_NAME  run name, also the folder under training/ and eval_outputs/
#   LORA_R LORA_A MSE_W PGA_W SCL_W VAR_T SEED WARMUP   override the track defaults
#   DISABLE_PGA DISABLE_INTRA DISABLE_INTER   set to 1 for the Table 4 ablations
#   OOD_SUBSET  override the OOD subsets to score (e.g. for the seed study)
#
# Finished stages are skipped, so a crashed sweep can simply be relaunched.
set -euo pipefail
cd "$(dirname "$0")/.."

STUDENT=${STUDENT:-fastvlm}
TASK=${TASK:-vqa}
EVAL_SETS=${EVAL_SETS:-id}
NUM_GPUS=${NUM_GPUS:-1}
SEED=${SEED:-42}
MSE_W=${MSE_W:-1.0}
PGA_W=${PGA_W:-2.0}
SCL_W=${SCL_W:-0.01}
VAR_T=${VAR_T:-0.85}

# per-GPU batch (x8 GPUs = global batch), LoRA rank / alpha, warmup
case "$STUDENT:$TASK" in
    fastvlm:cls)     PER_GPU=32; R=64;  A=128; WU=1.0 ;;
    fastvlm:vqa)     PER_GPU=32; R=128; A=512; WU=1.0 ;;
    fastvlm:ret)     PER_GPU=16; R=128; A=128; WU=1.0 ;;
    fastvlm:grd)     PER_GPU=16; R=128; A=256; WU=1.0 ;;
    onevision:cls)   PER_GPU=8;  R=16;  A=32;  WU=0.03 ;;
    onevision:vqa)   PER_GPU=16; R=32;  A=128; WU=1.0 ;;
    onevision:ret)   PER_GPU=16; R=32;  A=128; WU=1.0 ;;
    onevision:grd)   PER_GPU=16; R=32;  A=128; WU=1.0 ;;
    *) echo "unknown STUDENT:TASK = $STUDENT:$TASK" >&2; exit 1 ;;
esac
LORA_R=${LORA_R:-$R}
LORA_A=${LORA_A:-$A}
WARMUP=${WARMUP:-$WU}
BATCH_SIZE=${BATCH_SIZE:-$PER_GPU}
GLOBAL_BS=$(( PER_GPU * 8 ))
if [ $(( GLOBAL_BS % (BATCH_SIZE * NUM_GPUS) )) -ne 0 ]; then
    echo "BATCH_SIZE * NUM_GPUS must divide the global batch $GLOBAL_BS" >&2; exit 1
fi
GRAD_ACCUM=$(( GLOBAL_BS / (BATCH_SIZE * NUM_GPUS) ))

case "$STUDENT" in
    fastvlm)   MODEL="apple/FastVLM-0.5B";                              BACKBONE="llava_qwen2" ;;
    onevision) MODEL="llava-hf/llava-onevision-qwen2-0.5b-ov-hf";       BACKBONE="llava_onevision" ;;
esac

case "$TASK" in
    cls) TRAIN_SUBSETS="ImageNet_1K N24News HatefulMemes VOC2007 SUN397"
         ID_SUBSETS="ImageNet-1K N24News HatefulMemes VOC2007 SUN397"
         OOD_DEFAULT="Place365 ImageNet-A ImageNet-R ObjectNet Country211" ;;
    vqa) TRAIN_SUBSETS="OK-VQA A-OKVQA DocVQA InfographicsVQA ChartQA Visual7W"
         ID_SUBSETS="OK-VQA A-OKVQA DocVQA InfographicsVQA ChartQA Visual7W"
         OOD_DEFAULT="ScienceQA VizWiz GQA TextVQA" ;;
    ret) TRAIN_SUBSETS="VisDial CIRR VisualNews_t2i VisualNews_i2t MSCOCO_t2i MSCOCO_i2t NIGHTS WebQA"
         ID_SUBSETS="VisDial CIRR VisualNews_t2i VisualNews_i2t MSCOCO_t2i MSCOCO_i2t NIGHTS WebQA"
         OOD_DEFAULT="OVEN FashionIQ EDIS Wiki-SS-NQ" ;;
    grd) TRAIN_SUBSETS="MSCOCO"
         ID_SUBSETS="MSCOCO"
         OOD_DEFAULT="Visual7W-Pointing RefCOCO RefCOCO-Matching" ;;
esac
OOD_SUBSETS=${OOD_SUBSET:-$OOD_DEFAULT}

EXP_NAME=${EXP_NAME:-PGA_${STUDENT}_${TASK}_r${LORA_R}_a${LORA_A}_mse${MSE_W}_pga${PGA_W}_scl${SCL_W}_var${VAR_T}_s${SEED}}
CKPT="training/$EXP_NAME/checkpoint-final"

EXTRA=()
[ "${DISABLE_PGA:-0}" = 1 ]   && EXTRA+=(--pga_disable_pga True)
[ "${DISABLE_INTRA:-0}" = 1 ] && EXTRA+=(--pga_disable_intra True)
[ "${DISABLE_INTER:-0}" = 1 ] && EXTRA+=(--pga_disable_inter True)

echo "=== $EXP_NAME | $STUDENT/$TASK | r=$LORA_R a=$LORA_A bs/gpu=$BATCH_SIZE x accum=$GRAD_ACCUM (global $GLOBAL_BS) seed=$SEED"
echo "    mse=$MSE_W pga=$PGA_W scl=$SCL_W eta=$VAR_T ${EXTRA[*]:-}"

# ---- train ----
if [ -d "$CKPT" ]; then
    echo "[skip] $CKPT exists"
else
    torchrun --nproc_per_node="$NUM_GPUS" main.py \
        --model_name "$MODEL" \
        --teacher_model_name "raghavlite/B3_Qwen2_2B" \
        --lora True --teacher_lora True \
        --lora_r "$LORA_R" --lora_alpha "$LORA_A" --teacher_lora_r 8 \
        --teacher_pooling "eos" --teacher_backbone "qwen2_vl" \
        --model_backbone "$BACKBONE" --pooling "eos" \
        --dataset_name "TIGER-Lab/MMEB-train" \
        --subset_name $TRAIN_SUBSETS \
        --dataset_split "original" \
        --image_dir "vlm2vec_train/MMEB-train" \
        --output_dir "training/$EXP_NAME" \
        --per_device_train_batch_size "$BATCH_SIZE" \
        --gradient_accumulation_steps "$GRAD_ACCUM" \
        --learning_rate 1e-4 --num_train_epochs 1 --bf16 \
        --save_total_limit 2 --logging_steps 1 --save_strategy "epoch" \
        --seed "$SEED" --weight_decay 0.01 \
        --normalize True --teacher_normalize True \
        --lr_scheduler_type "constant" --warmup_ratio "$WARMUP" \
        --kd_weight 0.3 --kd_loss_type "pga" \
        --image_resolution "low" \
        --projector_config_path "./config/projector_config.json" \
        --projector_lr 5e-4 \
        --report_to "${REPORT_TO:-none}" --run_name "$EXP_NAME" \
        --pga_mse_loss_weight "$MSE_W" \
        --pga_loss_weight "$PGA_W" \
        --pga_scl_loss_weight "$SCL_W" \
        --pga_spectral_variance_threshold "$VAR_T" \
        "${EXTRA[@]}"
fi

# ---- eval ----
evaluate() {
    local subset=$1 out="eval_outputs/$EXP_NAME"
    # a subset is done when its score file exists
    local todo=()
    for s in $subset; do
        [ -f "$out/${s}_score.json" ] || todo+=("$s")
    done
    [ ${#todo[@]} -eq 0 ] && { echo "[skip] eval: $subset"; return; }
    export PYTHONPATH="$PWD:${PYTHONPATH:-}"
    accelerate launch --multi_gpu --num_processes="$NUM_GPUS" eval_mmeb.py \
        --model_name "$CKPT" \
        --encode_output_path "$out" \
        --dataset_name "TIGER-Lab/MMEB-eval" \
        --subset_name "${todo[@]}" \
        --dataset_split "test" \
        --per_device_eval_batch_size 128 \
        --image_dir "eval_images/" \
        --pooling "eos" \
        --model_backbone "$BACKBONE" \
        --normalize True --bf16 --tgt_prefix_mod
}

case "$EVAL_SETS" in
    id)   evaluate "$ID_SUBSETS" ;;
    ood)  evaluate "$OOD_SUBSETS" ;;
    both) evaluate "$ID_SUBSETS"; evaluate "$OOD_SUBSETS" ;;
    none) ;;
esac
echo "=== done: $EXP_NAME  (results: eval_outputs/$EXP_NAME)"
