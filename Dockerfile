# 多阶段构建Dockerfile - 将前端和后端打包成一个镜像
# 第一阶段：构建前端
FROM node:18-alpine AS frontend-builder

# 设置工作目录
WORKDIR /app/frontend

# 复制前端项目文件
COPY email/package*.json ./

# 安装前端依赖（包括开发依赖，因为需要构建）
RUN npm ci

# 复制前端源代码
COPY email/ ./

# 构建前端项目
RUN npm run build

# 第二阶段：构建后端
FROM python:3.11-slim AS backend-builder

# 设置工作目录
WORKDIR /app/backend

# 复制后端依赖文件
COPY email-api/requirements.txt ./

# 安装后端依赖
RUN pip install --no-cache-dir -r requirements.txt

# 复制后端源代码
COPY email-api/ ./

# 第三阶段：最终镜像
FROM python:3.11-slim

# 安装nginx和必要的工具
RUN apt-get update && \
    apt-get install -y nginx curl && \
    rm -rf /var/lib/apt/lists/*

# 设置工作目录
WORKDIR /app

# 从第一阶段复制构建好的前端文件
COPY --from=frontend-builder /app/frontend/dist /var/www/html

# 从第二阶段复制后端文件
COPY --from=backend-builder /app/backend /app/backend
COPY --from=backend-builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages

# 配置nginx
COPY nginx.conf /etc/nginx/nginx.conf

# 创建启动脚本
RUN echo '#!/bin/bash\n\
# 等待后端服务启动\n\
echo "启动后端服务..."\n\
cd /app/backend\n\
python all.py &\n\
BACKEND_PID=$!\n\
\n\
# 等待后端服务就绪\n\
echo "等待后端服务就绪..."\n\
while ! curl -s http://localhost:8000 > /dev/null; do\n\
    sleep 1\n\
done\n\
echo "后端服务已就绪"\n\
\n\
# 启动nginx\n\
echo "启动nginx..."\n\
nginx -g "daemon off;" &\n\
NGINX_PID=$!\n\
\n\
# 等待进程\n\
wait $BACKEND_PID $NGINX_PID' > /app/start.sh && chmod +x /app/start.sh

# 暴露端口
EXPOSE 80 8000

# 启动服务
CMD ["/app/start.sh"] 