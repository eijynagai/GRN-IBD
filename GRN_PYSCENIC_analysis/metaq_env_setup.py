# Create the environment
conda create -n MetaQ python=3.11.6
conda activate MetaQ

# Install CUDA toolkit, check the version in the servers
conda install pytorch=2.1.1 torchvision torchaudio pytorch-cuda=12.1 faiss-gpu=1.7.4 -c pytorch -c nvidia -c conda-forge

# Install common packages
conda install scanpy=1.9.6 numpy=1.26.0 scipy=1.11.3 scikit-learn=1.1.3 -c conda-forge

# Or install it using mamba
# mamba install pytorch=2.1.1 torchvision torchaudio pytorch-cuda=12.1 faiss-gpu=1.7.4 scanpy=1.9.6 numpy=1.26.0 scipy=1.11.3 scikit-learn=1.1.3 -c pytorch -c nvidia -c conda-forge -y

# Install specific packages, pip-only
pip install alive-progress==3.1.5 geosketch==1.2

# Install MetaQ
pip install MetaQ-sc

# Test if the installation worked
python MetaQ.py
