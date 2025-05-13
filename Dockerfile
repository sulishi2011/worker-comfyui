FROM runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04

# 设置环境变量
ENV DEBIAN_FRONTEND=noninteractive
ENV PIP_PREFER_BINARY=1
ENV PYTHONUNBUFFERED=1
ENV COMFY_HOST="127.0.0.1:7860"

# 安装必要的依赖包
RUN apt-get update && apt-get install -y \
    git \
    wget \
    rsync \
    curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 克隆 worker-comfyui 配置
WORKDIR /
RUN git clone https://github.com/sulishi2011/worker-comfyui.git /worker-comfyui

# 克隆 ComfyUI 并切换到指定版本
RUN git clone https://github.com/comfyanonymous/ComfyUI.git /ComfyUI && \
    cd /ComfyUI && \
    git checkout tags/v0.3.15

# 安装 ComfyUI 依赖
WORKDIR /ComfyUI
RUN pip install -r requirements.txt

# 安装 worker-comfyui 依赖
RUN pip install runpod requests websocket-client

# 下载 Miniconda
WORKDIR /root
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh && \
    bash miniconda.sh -b -p /root/miniconda3 && \
    rm miniconda.sh

# 将 Miniconda 添加到 PATH
ENV PATH="/root/miniconda3/bin:${PATH}"

# 安装 huggingface-cli
RUN pip install huggingface_hub

# 下载 comfyui_env.tar.gz
WORKDIR /
RUN huggingface-cli download ChuuniZ/comfyui_env comfyui_env.tar.gz --local-dir ./

# 创建并设置 conda 环境
RUN mkdir -p /root/miniconda3/envs/comfyui && \
    tar -xzf comfyui_env.tar.gz -C /root/miniconda3/envs/comfyui && \
    rm comfyui_env.tar.gz

# 添加修复环境的命令到启动脚本
RUN echo '#!/bin/bash\n\
source /root/miniconda3/envs/comfyui/bin/activate\n\
conda-unpack\n\
' > /fix_env.sh && chmod +x /fix_env.sh

# 复制自定义的 extra_model_paths.yaml
COPY src/extra_model_paths.yaml /ComfyUI/extra_model_paths.yaml

# 处理模型目录
WORKDIR /ComfyUI
RUN rm -rf models/* && \
    mkdir -p models

# 复制 worker-comfyui 的处理程序到容器
COPY handler.py /worker-comfyui/handler.py

# 复制 comfyui_start.sh 到容器
COPY comfyui_start.sh /comfyui_start.sh
RUN chmod +x /comfyui_start.sh

# 创建启动脚本
COPY start.sh /start.sh
RUN chmod +x /start.sh

WORKDIR /
CMD ["/start.sh"]