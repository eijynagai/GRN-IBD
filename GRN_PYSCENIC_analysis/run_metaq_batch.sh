#!/bin/bash
#SBATCH --job-name=metaQ
#SBATCH --partition=shared-gpu
#SBATCH --gres=gpu:1              # <-- use gpu:1 (not “shard”)
#SBATCH --cpus-per-task=10
#SBATCH --mem=128G
#SBATCH --time=48:00:00
#SBATCH --ntasks=1

#SBATCH --array=1-4%2             # <-- 4 jobs, max 2 concurrent
#SBATCH --mail-user=eijynagai@gmail.com
#SBATCH --mail-type=END,FAIL
#SBATCH --error=metaQ_%A_%a.err
#SBATCH --output=metaQ_%A_%a.out

# Load environment
source ~/.bashrc
conda activate MetaQ

# Each job picks its CSV row from SLURM_ARRAY_TASK_ID
python metaq_wrapper.py \
  --manifest batch_params.csv \
  --index $SLURM_ARRAY_TASK_ID \
  --to-loom