#!/bin/bash

output_file="batch_params.csv"

# Clear or create the output file
> "$output_file"

echo "filepath,divisor,data_type,save_name" > "$output_file"

indir=/nfs/proj/COST_IBD/GRN-IBD/data/original_data/subsamples_by_celltype_and_condition_v03_00_03_sub
# 
for i in $indir/*.h5ad; do
    filename=$(basename "$i")
    base_name="${filename%_subset.h5ad}"
    echo "$indir/$filename,100,RNA,$base_name" >> "$output_file"
done