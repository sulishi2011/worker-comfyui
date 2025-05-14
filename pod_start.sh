#!/bin/bash

# 运行环境修复脚本
/fix_env.sh

# 创建必要的目录结构
mkdir -p /workspace/models
mkdir -p /workspace/custom_nodes

# 启动 Nginx
echo "启动 Nginx 服务器..."
nginx -c /nginx/conf/nginx.conf

# 同步自定义节点
echo "同步自定义节点..."
rsync -av --exclude='.cache' /workspace/custom_nodes/ /ComfyUI/custom_nodes/

# 创建模型符号链接
echo "创建模型符号链接..."
cd /ComfyUI/models/
rm -rf *
ln -sf /workspace/models/* ./

# 打印启动信息
echo "===================================="
echo "       启动 ComfyUI - Pod 模式       "
echo "===================================="

# 启动 ComfyUI
cd /ComfyUI
python /ComfyUI/main.py --listen 0.0.0.0 --port 7860 --disable-auto-launch --fp16-unet --bf16-vae --fp16-text-enc --disable-metadata --cuda-malloc --use-pytorch-cross-attention --force-channels-last 