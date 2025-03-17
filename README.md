# GRN-IBD

### Recommended: Conda environment 
For reproducibility, it's recommended to use the environment.yml file provided in this repository. It took sometime to check multiple tools compatibility. The test on the PBMC dataset works well using this environment.

##### Create environment using environment.yml
`mamba env create -f environment.yml`

##### Activate the environment
`mamba activate pyscenic_env`

##### Jupyter notebook
To start Jupyter notebook in the server (via browser, to cancel use Ctrl+C):
`jupyter lab --ip=0.0.0.0 --no-browser`








### Not recommended: Singularity image
Tool is no longer maintained and newer versions of package have several conflicts.

There were two versions of singularity image.
pySCENIC CLI version
`singularity build aertslab-pyscenic-0.12.1.sif docker://aertslab/pyscenic:0.12.1`

pySCENIC CLI version + ipython kernel + scanpy
`singularity build aertslab-pyscenic-scanpy-0.12.1-1.9.1.sif docker://aertslab/pyscenic_scanpy:0.12.1_1.9.1`


### Running pySCENIC with  Singulairity:
To run commands in command line mode using singularity:
```
singularity run aertslab-pyscenic-0.12.1.sif \
    pyscenic grn \
        -B /data:/data
        --num_workers 6 \
        -o /data/expr_mat.adjacencies.tsv \
        /data/expr_mat.tsv \
        /data/allTFs_hg38.txt
```