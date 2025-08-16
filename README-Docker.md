# Docker 部署说明

这个项目包含前端（Vue.js）和后端（FastAPI）两个部分，使用Docker多阶段构建将它们打包成一个镜像。

## 项目结构

```
.
├── email/           # 前端项目（Vue.js）
├── email-api/       # 后端项目（FastAPI）
├── Dockerfile       # Docker构建文件
├── nginx.conf       # Nginx配置文件
├── build.sh         # 构建脚本
└── README-Docker.md # 本文档
```

## 快速开始

### 1. 构建镜像

```bash
# 使用构建脚本
chmod +x build.sh
./build.sh

# 或者直接使用docker命令
docker build -t email-app .
```

### 2. 运行容器

```bash
# 前台运行（查看日志）
docker run -p 80:80 -p 8000:8000 email-app

# 后台运行
docker run -d -p 80:80 -p 8000:8000 --name email-app-container email-app
```

### 3. 访问应用

- **前端应用**: http://localhost
- **后端API**: http://localhost:8000

## Dockerfile 说明

### 多阶段构建

1. **前端构建阶段** (`frontend-builder`)
   - 使用 Node.js 18 Alpine 镜像
   - 安装依赖并构建前端项目
   - 生成静态文件到 `dist` 目录

2. **后端构建阶段** (`backend-builder`)
   - 使用 Python 3.11 slim 镜像
   - 安装 Python 依赖
   - 复制后端代码

3. **最终镜像**
   - 基于 Python 3.11 slim
   - 安装 Nginx
   - 复制前端构建产物和后端代码
   - 配置 Nginx 代理

### 服务架构

- **Nginx**: 监听 80 端口，提供静态文件服务和 API 代理
- **FastAPI**: 监听 8000 端口，提供 API 服务
- **启动脚本**: 协调两个服务的启动顺序

## 配置说明

### Nginx 配置

- 静态文件服务：`/var/www/html`
- API 代理：`/api/*` → `http://localhost:8000`
- 支持 SPA 路由：`try_files $uri $uri/ /index.html`

### 端口映射

- `80`: Nginx 服务端口
- `8000`: FastAPI 服务端口

## 常用命令

```bash
# 构建镜像
docker build -t email-app .

# 运行容器
docker run -p 80:80 -p 8000:8000 email-app

# 后台运行
docker run -d -p 80:80 -p 8000:8000 --name email-app-container email-app

# 查看容器日志
docker logs email-app-container

# 进入容器
docker exec -it email-app-container bash

# 停止容器
docker stop email-app-container

# 删除容器
docker rm email-app-container

# 删除镜像
docker rmi email-app
```

## 故障排除

### 1. 构建失败

- 检查 Docker 是否正在运行
- 确保所有源文件都存在
- 检查网络连接（下载依赖需要网络）

### 2. 容器启动失败

- 检查端口是否被占用
- 查看容器日志：`docker logs <container_name>`
- 确保后端服务正常启动

### 3. API 请求失败

- 检查 Nginx 配置是否正确
- 确认后端服务在 8000 端口运行
- 查看 Nginx 错误日志

## 生产环境部署

### 1. 使用 Docker Compose

创建 `docker-compose.yml`:

```yaml
version: '3.8'
services:
  email-app:
    build: .
    ports:
      - "80:80"
      - "8000:8000"
    restart: unless-stopped
    environment:
      - NODE_ENV=production
```

运行：
```bash
docker-compose up -d
```

### 2. 使用 Docker Swarm

```bash
# 初始化 swarm
docker swarm init

# 部署服务
docker stack deploy -c docker-compose.yml email-stack
```

## 性能优化

1. **镜像大小优化**
   - 使用多阶段构建
   - 清理不必要的文件
   - 使用 Alpine 基础镜像

2. **构建速度优化**
   - 合理使用 `.dockerignore`
   - 缓存依赖安装步骤
   - 并行构建阶段

3. **运行时优化**
   - 启用 Nginx gzip 压缩
   - 配置静态资源缓存
   - 使用连接池 