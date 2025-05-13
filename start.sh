#!/bin/bash

# 运行 ComfyUI
/comfyui_start.sh &

# 检查 ComfyUI 是否启动成功
echo "等待 ComfyUI 启动..."
MAX_RETRIES=30
RETRY_INTERVAL=2
for i in $(seq 1 $MAX_RETRIES); do
  if curl -s http://127.0.0.1:7860 > /dev/null; then
    echo "ComfyUI 已成功启动"
    break
  fi
  echo "等待 ComfyUI 启动... ($i/$MAX_RETRIES)"
  sleep $RETRY_INTERVAL
done

# 运行 worker-comfyui 处理程序
cd /worker-comfyui
python /worker-comfyui/handler.py 