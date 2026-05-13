#!/bin/bash
#SBATCH --job-name=scdfm_emb_replogle
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --account=cu_0055
#SBATCH --gres=gpu:1
#SBATCH --time=48:00:00
#SBATCH --mem=400GB
#SBATCH --output=scdfm_%j.log
#SBATCH --container-image=/dcai/projects/cu_0055/dockers/latest/dcai_test+docker_test+scdfm.sqsh
#SBATCH --container-mounts=/dcai:/dcai,/etc/ssl/certs:/etc/ssl/certs
#SBATCH --container-workdir=/workspace/scDFM

# ── Configure per run ─────────────────────────────────────────────────────────
DATASET="emb_Replogle"
DATA_PATH="/dcai/projects/cu_0055/data/perturbseq/silver/processed_data_filtered/Replogle"
RESULT_PATH="/dcai/users/hilarn/55_cu_0055/code/baselines/scDFM/results"
SPLIT_TOML="/dcai/users/hilarn/55_cu_0055/code/baselines/scDFM/SE_R_k562_example.toml"
FOLD=0
GPU=0
RUN_ID=""        # optional: set to e.g. "run01" for a human-readable folder name
# ─────────────────────────────────────────────────────────────────────────────

unset LMOD_CMD
export PYTHONPATH=/workspace/scDFM
export PYTHONNOUSERSITE=1
export CUDA_DEVICE_ORDER=PCI_BUS_ID

# W&B — private Gefion server
export WANDB_BASE_URL="https://wandb.gefion.dcai.dk"
export SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
export REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt

echo "NODELIST=${SLURM_NODELIST}"
echo "DATASET=${DATASET}  FOLD=${FOLD}"

micromamba run -n sc \
  env PYTHONNOUSERSITE=1 PYTHONPATH=/workspace/scDFM \
  python src/script/run.py \
    --data_name="${DATASET}" \
    --data_path="${DATA_PATH}" \
    --condition_col="gene" \
    --control_value="non-targeting" \
    --preprocessed \
    --split_toml="${SPLIT_TOML}" \
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
    --result_path="${RESULT_PATH}" \
    --print_every=5000 \
    --run_id="${RUN_ID}" \
    --wandb_project="scdfm_baselines" \
    --wandb_entity="cu_0055" \
    --wandb_tags="scdfm,${DATASET},fold${FOLD}"
