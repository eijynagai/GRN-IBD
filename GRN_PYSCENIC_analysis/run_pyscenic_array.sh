#!/bin/bash
#SBATCH --job-name=grn_pyscenic
#SBATCH --partition=shared-cpu
#SBATCH --cpus-per-task=30
#SBATCH --mem=300G
#SBATCH --time=72:00:00
#SBATCH --ntasks=1
#SBATCH --array=0-14   # <- 15 datasets = indices 0-13
#SBATCH --output=logs/grn_%A_%a.out
#SBATCH --error=logs/grn_%A_%a.err
#SBATCH --mail-user=eijynagai@gmail.com
#SBATCH --mail-type=END,FAIL

# Activate environment
source ~/.bashrc
mamba activate pyscenic_envdev

# Paths
LOOM_PATH="/nfs/proj/COST_IBD/GRN-IBD/data/original_data/subsamples_by_celltype_and_condition_v03_00_03_sub"
OUTPUT_DIR="/nfs/proj/COST_IBD/GRN-IBD/GRN_PYSCENIC_analysis/results"
TF_LIST="/nfs/proj/COST_IBD/GRN-IBD/SCENIC_DATABASE/TFs/allTFs_hg38.txt"
DB_FILES="/nfs/proj/COST_IBD/GRN-IBD/SCENIC_DATABASE/feather_files/hg38__refseq-r80__10kb_up_and_down_tss.mc9nr.genes_vs_motifs.rankings.feather \
          /nfs/proj/COST_IBD/GRN-IBD/SCENIC_DATABASE/feather_files/hg38__refseq-r80__500bp_up_and_100bp_down_tss.mc9nr.genes_vs_motifs.rankings.feather"
MOTIF_PATH="/nfs/proj/COST_IBD/GRN-IBD/SCENIC_DATABASE/motifs/motifs-v9-nr.hgnc-m0.001-o0.0.tbl"

# Create outputdir
mkdir -p $OUTPUT_DIR

# Get the loom file for this SLURM_ARRAY_TASK_ID
LOOM_FILE=$(sed -n "$((SLURM_ARRAY_TASK_ID+1))p" loom_list.txt)
PREFIX=$(basename "$LOOM_FILE" .loom)

LOOM_PRE="$LOOM_PATH/$LOOM_FILE"
LOOM_IN="$LOOM_PATH/${PREFIX}_filtered.loom"
ADJ_OUT="$OUTPUT_DIR/${PREFIX}_adj.csv"
REG_PRED="$OUTPUT_DIR/${PREFIX}_reg_pred.csv"
REG_ACT="$OUTPUT_DIR/${PREFIX}_reg_act.csv"

echo "Processing $LOOM_FILE on task ID $SLURM_ARRAY_TASK_ID"

# 0) filter RcisTarget genes
python filter_loom.py "$LOOM_PRE"

# 1) pySCENIC grn step
pyscenic grn "$LOOM_IN" "$TF_LIST" --output "$ADJ_OUT" --num_workers 30

# 2) pySCENIC ctx step
pyscenic ctx "$ADJ_OUT" $DB_FILES --annotations_fname "$MOTIF_PATH" \
  --expression_mtx_fname "$LOOM_IN" --output "$REG_PRED" \
  --mask_dropouts --num_workers 30

# 3) pySCENIC aucell step
pyscenic aucell "$LOOM_IN" "$REG_PRED" \
  --output "$REG_ACT" --num_workers 30 --auc_threshold 0.05

echo "Done processing $LOOM_FILE"