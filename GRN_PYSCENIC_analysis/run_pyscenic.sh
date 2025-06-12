#!/bin/bash

# Purpose of this script: run PYSCENIC command line full analysis
# Input: specific human data loom files from a given directory

#SBATCH --job-name=grn_pyscenic
#SBATCH --partition=shared-cpu
#SBATCH --cpus-per-task=30
#SBATCH --mem=400G
#SBATCH --time=72:00:00
#SBATCH --ntasks=1

#SBATCH --mail-user=eijynagai@gmail.com
#SBATCH --mail-type=END,FAIL
#SBATCH --error=logs/metaQ_%A_%a.err
#SBATCH --output=logs/metaQ_%A_%a.out

# Activate environment
source ~/.bashrc
mamba activate pyscenic_envdev

# Paths and lists
LOOM_PATH="/nfs/proj/COST_IBD/GRN-IBD/data/original_data/subsamples_by_celltype_and_condition/MetaQ/save"
LOOM_FILES="B_plasma_CD_RNA_849metacell.loom myeloid_UC_RNA_283metacell.loom  stromal_CD_RNA_286metacell.loom B_plasma_HC_RNA_512metacell.loom stromal_HC_RNA_454metacell.loom B_plasma_UC_RNA_1153metacell.loom      stromal_UC_RNA_410metacell.loom epithelial_CD_RNA_806metacell.loom     T_NK_ILC_CD_RNA_1009metacell.loom epithelial_HC_RNA_728metacell.loom
myeloid_CD_RNA_270metacell.loom T_NK_ILC_HC_RNA_357metacell.loom T_NK_ILC_UC_RNA_1026metacell.loom myeloid_HC_RNA_100metacell.loom"

TF_LIST="/nfs/proj/COST_IBD/GRN-IBD/SCENIC_DATABASE/TFs/allTFs_hg38.txt"
DB_FILES="/nfs/proj/COST_IBD/GRN-IBD/SCENIC_DATABASE/feather_files/hg38__refseq-r80__10kb_up_and_down_tss.mc9nr.genes_vs_motifs.rankings.feather \
/nfs/proj/COST_IBD/GRN-IBD/SCENIC_DATABASE/feather_files/hg38__refseq-r80__500bp_up_and_100bp_down_tss.mc9nr.genes_vs_motifs.rankings.feather"
MOTIF_PATH="/nfs/proj/COST_IBD/GRN-IBD/SCENIC_DATABASE/motifs/motifs-v9-nr.hgnc-m0.001-o0.0.tbl"
OUTPUT_DIR="/nfs/proj/COST_IBD/GRN-IBD/tests/metaq_pyscenic_batch"

# Loop over each .loom file
for loom_file in $LOOM_FILES
do
    # Strip the .loom extension to create a prefix
    prefix=$(basename "$loom_file" .loom)

    # Define input and output filenames
    LOOM_PRE="$LOOM_PATH/$loom_file"
    LOOM_IN="$LOOM_PATH/${prefix}_filtered.loom"
    ADJ_OUT="$OUTPUT_DIR/${prefix}_adj.csv"
    REG_PRED="$OUTPUT_DIR/${prefix}_reg_pred.csv"
    REG_ACT="$OUTPUT_DIR/${prefix}_reg_act.csv"

    echo "------------------------------------------"
    echo "Processing $loom_file"
    echo "  LOOM_PRE = $LOOM_PRE"
    echo "  LOOM_IN  = $LOOM_IN"
    echo "  ADJ_OUT  = $ADJ_OUT"
    echo "  REG_PRED  = $REG_PRED"
    echo "  REG_ACT  = $REG_ACT"
    echo "------------------------------------------"

    # 0) filter RcisTarget genes
    python filter_loom.py "$LOOM_PRE"

    # 1) pySCENIC grn step
    pyscenic grn "$LOOM_IN" "$TF_LIST" \
      --output "$ADJ_OUT" \
      --num_workers 30 

    # 2) pySCENIC ctx step
    pyscenic ctx "$ADJ_OUT" $DB_FILES \
      --annotations_fname "$MOTIF_PATH" \
      --expression_mtx_fname "$LOOM_IN" \
      --output "$REG_PRED" \
      --mask_dropouts \
      --num_workers 30

    # 3) pySCENIC aucell step
    pyscenic aucell "$LOOM_IN" "$REG_PRED" \
      --output "$REG_ACT" \
      --num_workers 30 \
      --auc_threshold 0.05

    echo "Done processing $loom_file"
    echo
done

echo "All pySCENIC jobs finished."
