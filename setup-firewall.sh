#!/bin/bash

# Ubuntu 防火墙配置脚本
# 使用 UFW (Uncomplicated Firewall)

echo "=== Ubuntu 防火墙配置脚本 ==="

# 检查 UFW 是否已安装
if ! command -v ufw &> /dev/null; then
    echo "正在安装 UFW 防火墙..."
    sudo apt update
    sudo apt install -y ufw
else
    echo "UFW 已安装"
fi

# 重置 UFW 规则
echo "正在重置防火墙规则..."
sudo ufw --force reset

# 设置默认策略
echo "正在设置默认策略..."
sudo ufw default deny incoming
sudo ufw default allow outgoing

# 允许 SSH 连接（重要！）
echo "正在配置 SSH 访问..."
sudo ufw allow ssh
sudo ufw allow 22/tcp

# 允许 HTTP 和 HTTPS
echo "正在配置 Web 访问..."
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# 允许图床服务端口（如果直接访问）
echo "正在配置图床服务端口..."
sudo ufw allow 3000/tcp

# 启用防火墙
echo "正在启用防火墙..."
sudo ufw --force enable

# 显示防火墙状态
echo "=== 防火墙配置完成 ==="
echo "当前防火墙状态:"
sudo ufw status verbose

echo ""
echo "防火墙规则说明:"
echo "- 默认拒绝所有入站连接"
echo "- 允许所有出站连接"
echo "- 允许 SSH (端口 22)"
echo "- 允许 HTTP (端口 80)"
echo "- 允许 HTTPS (端口 443)"
echo "- 允许图床服务 (端口 3000)"
echo ""
echo "如果需要添加其他端口，请使用: sudo ufw allow <端口号>" 