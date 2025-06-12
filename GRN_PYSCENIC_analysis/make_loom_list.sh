#!/bin/bash

# Set the directory containing the loom files
LOOM_DIR="/nfs/proj/COST_IBD/GRN-IBD/data/original_data/subsamples_by_celltype_and_condition_v03_00_03_sub"

# Output file
OUTPUT_FILE="loom_list.txt"

# Create or overwrite the output file with loom file names
find "$LOOM_DIR" -maxdepth 1 -type f -name "*.loom" -exec basename {} \; | sort > "$OUTPUT_FILE"

echo "Saved loom file list to $OUTPUT_FILE"