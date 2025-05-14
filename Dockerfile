FROM runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04

# 设置环境变量
ENV DEBIAN_FRONTEND=noninteractive
ENV PIP_PREFER_BINARY=1
ENV PYTHONUNBUFFERED=1
ENV COMFY_HOST="127.0.0.1:7860"

# 安装依赖包
RUN apt-get update && \
    apt-get install -y git wget rsync curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 克隆 worker-comfyui 配置
WORKDIR /
RUN git clone https://github.com/sulishi2011/worker-comfyui.git /worker-comfyui

# 克隆 ComfyUI 并切换到指定版本
RUN git clone https://github.com/comfyanonymous/ComfyUI.git /ComfyUI && \
    cd /ComfyUI && \
    git checkout tags/v0.3.15

# 清理git文件
RUN rm -rf /ComfyUI/.git /worker-comfyui/.git

# 安装 ComfyUI 依赖
WORKDIR /ComfyUI
RUN pip install -r requirements.txt && \
    pip install huggingface_hub && \
    pip cache purge

# 下载 Miniconda
WORKDIR /root
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh && \
    bash miniconda.sh -b -p /root/miniconda3 && \
    rm miniconda.sh && \
    /root/miniconda3/bin/conda clean -afy

# 将 Miniconda 添加到 PATH
ENV PATH="/root/miniconda3/bin:${PATH}"

# 下载和解压 comfyui_env.tar.gz
WORKDIR /
RUN mkdir -p /root/miniconda3/envs/comfyui && \
    huggingface-cli download ChuuniZ/comfyui_env comfyui_env_smaller.tar.gz --local-dir ./ && \
    tar -xzf comfyui_env_smaller.tar.gz -C /root/miniconda3/envs/comfyui && \
    rm comfyui_env_smaller.tar.gz && \
    rm -rf ~/.cache/huggingface

# 在conda环境中安装runpod
RUN /root/miniconda3/bin/pip install runpod && \
    /root/miniconda3/bin/pip install websocket-client && \
    /root/miniconda3/bin/pip install requests

# 添加环境修复脚本
RUN echo '#!/bin/bash\n\
source /root/miniconda3/envs/comfyui/bin/activate\n\
conda-unpack\n\
' > /fix_env.sh && chmod +x /fix_env.sh

# 复制文件和设置目录
COPY src/extra_model_paths.yaml /ComfyUI/extra_model_paths.yaml
COPY handler.py /worker-comfyui/handler.py
COPY comfyui_start.sh /comfyui_start.sh
COPY start.sh /start.sh

# 设置权限并清理模型目录
RUN chmod +x /comfyui_start.sh /start.sh && \
    rm -rf /ComfyUI/models/* && \
    mkdir -p /ComfyUI/models

# 最终清理
RUN pip cache purge && \
    conda clean -afy && \
    find / -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true

WORKDIR /
CMD ["/start.sh"]