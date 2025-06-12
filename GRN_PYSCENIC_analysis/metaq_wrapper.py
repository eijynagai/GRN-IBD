#!/usr/bin/env python3

import os
import glob
import argparse
import logging
import numpy as np
import pandas as pd
import anndata
import loompy
from pathlib import Path
from MetaQ_sc import run_metaq

def parse_args():
    parser = argparse.ArgumentParser(
        description="Batch‐run MetaQ_sc and optionally convert outputs to Loom"
    )
    parser.add_argument(
        "--manifest",
        type=Path,
        default=Path("batch_params.csv"),
        help="CSV with columns: filepath, divisor, data_type, save_name",
    )
    parser.add_argument(
        "--index",
        type=int,
        required=True,
        help="1-based row index in the manifest to process",
    )
    parser.add_argument(
        "--to-loom",
        action="store_true",
        help="After MetaQ finishes, convert .h5ad outputs in 'save' to .loom using ids file for cell indexing",
    )
    return parser.parse_args()

def main():
    args = parse_args()

    # 1) Read & validate manifest
    df = pd.read_csv(args.manifest, on_bad_lines="error")
    expected = {"filepath", "divisor", "data_type", "save_name"}
    if set(df.columns) != expected:
        raise ValueError(f"Manifest columns {df.columns.tolist()} != expected {expected}")

    # 2) Validate SLURM array size
    max_array = int(os.environ.get("SLURM_ARRAY_TASK_COUNT", len(df)))
    if len(df) < max_array:
        raise ValueError(f"Manifest has {len(df)} rows but SLURM_ARRAY_TASK_COUNT={max_array}")

    # 3) Validate --index
    if not (1 <= args.index <= len(df)):
        raise IndexError(f"--index must be between 1 and {len(df)}")
    row = df.iloc[args.index - 1]

    # 4) Unpack parameters
    fp        = Path(row.filepath)
    divisor   = int(row.divisor)
    data_type = row.data_type
    save_name = row.save_name

    # 5) Load original AnnData and compute metacell_num
    orig_adata = anndata.read_h5ad(fp)
    n_cells    = orig_adata.n_obs
    metacell_num = max(1, n_cells // divisor)

    # 6) Logging setup
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
    logging.info(f"[{args.index}/{len(df)}] {fp.name}: n_cells={n_cells}, divisor={divisor} → metacell_num={metacell_num}")

    # 7) Run MetaQ
    run_metaq(
        data_path=[str(fp)],
        data_type=[data_type],
        metacell_num=metacell_num,
        save_name=save_name,
    )

    # 8) Optional: convert to loom using the ids file
    if args.to_loom:
        save_dir = Path("save")
        ids_pattern = str(save_dir / f"{save_name}_*metacell_ids.h5ad")
        ids_matches = glob.glob(ids_pattern)
        if not ids_matches:
            logging.error(f"No ids file matching {ids_pattern!r}—cannot re-index cells.")
            return
        ids_fp = Path(ids_matches[0])
        idata = anndata.read_h5ad(ids_fp)

        expr_pattern = str(save_dir / f"{save_name}_RNA_*metacell.h5ad")
        expr_matches = glob.glob(expr_pattern)
        if not expr_matches:
            logging.error(f"No expression file matching {expr_pattern!r} found—skipping Loom conversion.")
            return
        expr_fp = Path(expr_matches[0])
        madata = anndata.read_h5ad(expr_fp)

        # ✅ Fix gene annotations
        madata.var = orig_adata.var.copy()
        madata.var_names = orig_adata.var_names.copy()
        madata.write_h5ad(expr_fp)
        logging.info(f"Updated gene annotations in {expr_fp.name}")

        # ✅ Create loom with proper format
        loom_fp = expr_fp.with_suffix(".loom")

        row_attrs = {
            "Gene": np.array(madata.var_names)
        }
        col_attrs = {
            "CellID": np.array(madata.obs_names),
            "nUMI": np.sum(madata.X.T, axis=0).A1 if hasattr(madata.X.T, "A") else np.sum(madata.X.T, axis=0),
            "nGene": np.sum((madata.X.T > 0), axis=0).A1 if hasattr(madata.X.T, "A") else np.sum((madata.X.T > 0), axis=0)
        }

        matrix = madata.X.T.A if hasattr(madata.X.T, "A") else madata.X.T
        loompy.create(str(loom_fp), matrix, row_attrs, col_attrs)
        logging.info(f"✅ Wrote Loom file {loom_fp}")

if __name__ == "__main__":
    main()