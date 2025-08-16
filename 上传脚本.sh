#!/bin/bash

# 项目自动上传和部署脚本
# 使用方法: ./上传脚本.sh <服务器IP> <用户名> [项目路径]

if [ $# -lt 2 ]; then
    echo "使用方法: $0 <服务器IP> <用户名> [项目路径]"
    echo "示例: $0 192.168.1.100 root /home/user/email"
    exit 1
fi

SERVER_IP=$1
USERNAME=$2
REMOTE_PATH=${3:-"/home/$USERNAME/email"}
LOCAL_PATH="."

echo "=== 项目自动上传和部署脚本 ==="
echo "服务器: $USERNAME@$SERVER_IP"
echo "远程路径: $REMOTE_PATH"
echo ""

# 1. 检查本地项目文件
echo "📁 检查本地项目文件..."
required_files=("docker-compose.yml" "email" "email-api")
for file in "${required_files[@]}"; do
    if [ ! -e "$file" ]; then
        echo "❌ 缺少必要文件/目录: $file"
        exit 1
    fi
done
echo "✅ 本地文件检查通过"

# 2. 测试服务器连接
echo ""
echo "🔗 测试服务器连接..."
if ! ssh -o ConnectTimeout=10 "$USERNAME@$SERVER_IP" "echo '连接成功'" 2>/dev/null; then
    echo "❌ 无法连接到服务器 $USERNAME@$SERVER_IP"
    echo "请检查："
    echo "- 服务器IP是否正确"
    echo "- 用户名是否正确"
    echo "- SSH密钥或密码是否配置正确"
    exit 1
fi
echo "✅ 服务器连接正常"

# 3. 上传项目文件
echo ""
echo "📤 上传项目文件到服务器..."
echo "正在创建远程目录..."
ssh "$USERNAME@$SERVER_IP" "mkdir -p $REMOTE_PATH"

echo "正在上传文件..."
rsync -avz --progress \
    --exclude='node_modules' \
    --exclude='.git' \
    --exclude='__pycache__' \
    --exclude='*.log' \
    "$LOCAL_PATH/" "$USERNAME@$SERVER_IP:$REMOTE_PATH/"

if [ $? -eq 0 ]; then
    echo "✅ 文件上传成功"
else
    echo "❌ 文件上传失败"
    exit 1
fi

# 4. 检查服务器Docker环境
echo ""
echo "🐳 检查服务器Docker环境..."
ssh "$USERNAME@$SERVER_IP" "
    if ! command -v docker &> /dev/null; then
        echo '❌ Docker未安装'
        echo '正在安装Docker...'
        if command -v yum &> /dev/null; then
            sudo yum install -y docker docker-compose
        elif command -v apt &> /dev/null; then
            sudo apt update && sudo apt install -y docker.io docker-compose
        else
            echo '请手动安装Docker和Docker Compose'
            exit 1
        fi
        sudo systemctl start docker
        sudo systemctl enable docker
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        echo '❌ Docker Compose未安装'
        echo '请手动安装Docker Compose'
        exit 1
    fi
    
    echo '✅ Docker环境检查通过'
"

# 5. 在服务器上部署项目
echo ""
echo "🚀 在服务器上部署项目..."
ssh "$USERNAME@$SERVER_IP" "
    cd $REMOTE_PATH
    
    echo '停止现有服务（如果存在）...'
    sudo docker-compose down 2>/dev/null || true
    
    echo '构建并启动服务...'
    sudo docker-compose up -d --build
    
    echo '等待服务启动...'
    sleep 10
    
    echo '检查服务状态...'
    sudo docker-compose ps
"

# 6. 获取访问地址
echo ""
echo "🎉 部署完成！"
echo ""
SERVER_PUBLIC_IP=$(ssh "$USERNAME@$SERVER_IP" "curl -s ifconfig.me" 2>/dev/null || echo "$SERVER_IP")
echo "访问地址："
echo "- 前端应用: http://$SERVER_PUBLIC_IP"
echo "- 后端API: http://$SERVER_PUBLIC_IP:8000"
echo ""
echo "常用管理命令："
echo "ssh $USERNAME@$SERVER_IP 'cd $REMOTE_PATH && sudo docker-compose logs -f'  # 查看日志"
echo "ssh $USERNAME@$SERVER_IP 'cd $REMOTE_PATH && sudo docker-compose restart'   # 重启服务"
echo "ssh $USERNAME@$SERVER_IP 'cd $REMOTE_PATH && sudo docker-compose down'      # 停止服务" 