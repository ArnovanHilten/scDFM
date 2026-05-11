#!/bin/bash
# Run scDFM on a STATE-prepared h5ad file.
#
# Place your h5ad at:  ./data/${DATASET}.h5ad
#
# The h5ad must have:
#   obs[CONDITION_COL]  - perturbation labels (e.g. gene names + control)
#   X                   - log1p-normalised expression (set PREPROCESSED=True)
#                         OR raw counts (set PREPROCESSED=False)

# ── Configure these for your experiment ──────────────────────────────────────
DATASET="SE_FR_Rk562"       # must match h5ad filename (without .h5ad)
CONDITION_COL="gene"         # obs column holding perturbation labels
CONTROL_VALUE="non-targeting"  # value in CONDITION_COL that means "unperturbed"
PREPROCESSED="True"          # True = X already log1p-normalised; False = raw counts
FOLD=0                       # which of 5 random train/test splits (0–4)
GPU=0
# ─────────────────────────────────────────────────────────────────────────────

CUDA_VISIBLE_DEVICES=${GPU} python src/script/run.py \
  --data_name="${DATASET}" \
  --condition_col="${CONDITION_COL}" \
  --control_value="${CONTROL_VALUE}" \
  $([ "${PREPROCESSED}" = "True" ] && echo "--preprocessed" || echo "--no-preprocessed") \
  --fold=${FOLD} \
  --model_type=origin \
  --n_top_genes=5000 \
  --infer_top_gene=1000 \
  --batch_size=48 \
  --devices="${GPU}" \
  --lr=5e-5 \
  --steps=200000 \
  --eta_min=1e-6 \
  --d_model=128 \
  --fusion_method=differential_perceiver \
  --perturbation_function=crisper \
  --noise_type=Gaussian \
  --mode=predict_y \
  --split_method=additive \
  --result_path=./result/custom \
  --print_every=5000
