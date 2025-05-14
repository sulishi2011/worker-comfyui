#!/bin/bash

# 运行环境修复脚本
source /root/miniconda3/envs/comfyui/bin/activate
conda-unpack

# 同步自定义节点
rsync -av --exclude='.cache' /workspace/custom_nodes/ /ComfyUI/custom_nodes/

# 创建模型符号链接
cd /ComfyUI/models/
rm -rf *
ln -sf /workspace/models/* ./

# 启动 ComfyUI
cd /ComfyUI
python /ComfyUI/main.py --listen 0.0.0.0 --port 7860 --disable-auto-launch --fp16-unet --bf16-vae --fp16-text-enc --disable-metadata --cuda-malloc --use-pytorch-cross-attention --force-channels-last 