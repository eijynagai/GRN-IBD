#!/usr/bin/env python3

'''
Script to filter genes overlapping the RcisTarget database.
This step reduces drastically the number of genes to ~27,000.
'''

import sys
import logging
import numpy as np
import anndata
import loompy
from pathlib import Path
import pyarrow.feather as feather

# --- Setup logging ---
logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")

def filter_loom_by_rcistarget(loom_path):
    loom_path = Path(loom_path)
    if not loom_path.exists():
        logging.error(f"Loom file not found: {loom_path}")
        sys.exit(1)

    # Load loom as AnnData
    logging.info(f"Loading: {loom_path}")
    adata = anndata.read_loom(loom_path)

    # Load RcisTarget genes from feather file
    feather_path = "/nfs/proj/COST_IBD/GRN-IBD/SCENIC_DATABASE/feather_files/hg38__refseq-r80__500bp_up_and_100bp_down_tss.mc9nr.genes_vs_motifs.rankings.feather"
    table = feather.read_table(feather_path)
    rcistarget_genes = table.column_names[1:]  # Skip motif column
    logging.info(f"Loaded {len(rcistarget_genes)} genes from RcisTarget")

    # Filter AnnData object to retain only genes present in the RcisTarget database
    genes_to_keep = [g for g in adata.var_names if g in rcistarget_genes]
    logging.info(f"Genes before filtering: {adata.shape[1]}, after filtering: {len(genes_to_keep)}")

    if not genes_to_keep:
        logging.error("No overlapping genes found. Exiting.")
        sys.exit(1)

    adata_filtered = adata[:, genes_to_keep].copy()

    # Prepare output filename
    filtered_path = loom_path.with_name(loom_path.stem + "_filtered.loom")

    # Transpose matrix to shape (genes x cells), as expected by pySCENIC
    matrix = adata_filtered.X.T.A if hasattr(adata_filtered.X.T, "A") else adata_filtered.X.T

    # Create loom attributes
    row_attrs = {"Gene": np.array(adata_filtered.var_names)}
    col_attrs = {
        "CellID": np.array(adata_filtered.obs_names),
        "nUMI": np.array(np.sum(adata_filtered.X, axis=1)).flatten(),
        "nGene": np.array(np.sum(adata_filtered.X > 0, axis=1)).flatten()
    }

    print("First 5 genes:", adata_filtered.var_names[:5].tolist())
    print("First 5 cells:", adata_filtered.obs_names[:5].tolist())

    logging.info(f"Saving filtered loom: {filtered_path}")
    loompy.create(str(filtered_path), matrix, row_attrs, col_attrs)
    logging.info("✅ Done.")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python filter_loom_by_rcistarget.py path_to_input.loom")
        sys.exit(1)
    loom_input = sys.argv[1]
    filter_loom_by_rcistarget(loom_input)