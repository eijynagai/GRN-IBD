import torch
print("CUDA available:", torch.cuda.is_available())
print("GPU Name:", torch.cuda.get_device_name(0))

import faiss
print("FAISS GPU:", hasattr(faiss, 'StandardGpuResources'))

import scanpy as sc
print("Scanpy version:", sc.__version__)