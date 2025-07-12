#!/bin/bash

# Ubuntu Linux 图床系统部署脚本
# 适用于 Ubuntu 18.04+ 系统

set -e

echo "=== Ubuntu Linux 图床系统部署脚本 ==="
echo "正在检查系统环境..."

# 检查是否为 Ubuntu 系统
if ! grep -q "Ubuntu" /etc/os-release; then
    echo "警告: 此脚本专为 Ubuntu 系统设计，其他系统可能不兼容"
fi

# 更新系统包
echo "正在更新系统包..."
sudo apt update

# 安装必要的系统依赖
echo "正在安装系统依赖..."
sudo apt install -y curl wget git build-essential

# 检查 Node.js 是否已安装
if ! command -v node &> /dev/null; then
    echo "正在安装 Node.js..."
    
    # 添加 NodeSource 仓库
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    
    # 安装 Node.js
    sudo apt install -y nodejs
    
    echo "Node.js 安装完成"
else
    echo "Node.js 已安装，版本: $(node --version)"
fi

# 检查 npm 是否已安装
if ! command -v npm &> /dev/null; then
    echo "正在安装 npm..."
    sudo apt install -y npm
else
    echo "npm 已安装，版本: $(npm --version)"
fi

# 创建应用目录（如果不存在）
APP_DIR="/opt/image-host"
echo "正在创建应用目录: $APP_DIR"
sudo mkdir -p $APP_DIR

# 复制项目文件到应用目录
echo "正在复制项目文件..."
sudo cp -r . $APP_DIR/
sudo chown -R $USER:$USER $APP_DIR

# 进入应用目录
cd $APP_DIR

# 安装项目依赖
echo "正在安装项目依赖..."
npm install

# 创建 uploads 目录并设置权限
echo "正在创建上传目录..."
mkdir -p uploads
chmod 755 uploads

# 创建 systemd 服务文件
echo "正在创建系统服务..."
sudo tee /etc/systemd/system/image-host.service > /dev/null <<EOF
[Unit]
Description=Image Host Service
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$APP_DIR
ExecStart=/usr/bin/node index.js
Restart=always
RestartSec=10
Environment=NODE_ENV=production
Environment=PORT=3000

[Install]
WantedBy=multi-user.target
EOF

# 重新加载 systemd 配置
sudo systemctl daemon-reload

# 启用服务
sudo systemctl enable image-host.service

echo "=== 部署完成 ==="
echo "服务已安装并启用"
echo ""
echo "管理命令:"
echo "  启动服务: sudo systemctl start image-host"
echo "  停止服务: sudo systemctl stop image-host"
echo "  重启服务: sudo systemctl restart image-host"
echo "  查看状态: sudo systemctl status image-host"
echo "  查看日志: sudo journalctl -u image-host -f"
echo ""
echo "服务将在系统启动时自动运行"
echo "访问地址: http://localhost:3000"
echo ""
echo "是否现在启动服务? (y/n)"
read -r response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    sudo systemctl start image-host
    echo "服务已启动"
    sudo systemctl status image-host
fi 