
#!/bin/bash

project=GRN-IBD
proj_path=/nfs/proj/COST_IBD/$project
env_path=$proj_path
img=aertslab-pyscenic-scanpy-0.12.1-1.9.1.sif
img_path=$env_path/$img
log_path=$proj_path/log
log_file=$log_path/jupyternotebook.log

mkdir -p $log_path

echo "Initializing Jupyter notebook at the server "$server
echo "You are using the image: "$img

cd $proj_path
nohup singularity exec -H $env_path --bind /nfs,/nfs/scratch/nf-core_work/  $img_path jupyter notebook --no-browser >& $log_file &
cd -

echo "Wait a few seconds..."
sleep 20

echo "To establish a connection from your local computer to this server, use the information below:"
cat $log_file | grep localhost

echo "In your local terminal type:"
echo "ssh -N -f -L localhost:8884:localhost:XXXX server"
echo ""
echo "Replace the XXXX with the available port and check the server used"
echo "When the browser opens, use the token above."
echo ""
echo "The log is located at: "$log_file