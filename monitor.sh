#!/bin/bash

# 图床服务监控脚本
# 用于检查服务状态、磁盘空间、日志等

SERVICE_NAME="image-host"
APP_DIR="/opt/image-host"
LOG_FILE="/var/log/image-host-monitor.log"

echo "=== 图床服务监控报告 ==="
echo "时间: $(date)"
echo ""

# 检查服务状态
echo "1. 服务状态检查:"
if systemctl is-active --quiet $SERVICE_NAME; then
    echo "   ✅ 服务正在运行"
    echo "   服务状态: $(systemctl is-active $SERVICE_NAME)"
    echo "   启动时间: $(systemctl show $SERVICE_NAME --property=ActiveEnterTimestamp | cut -d= -f2)"
else
    echo "   ❌ 服务未运行"
    echo "   尝试启动服务..."
    sudo systemctl start $SERVICE_NAME
    sleep 2
    if systemctl is-active --quiet $SERVICE_NAME; then
        echo "   ✅ 服务启动成功"
    else
        echo "   ❌ 服务启动失败"
    fi
fi
echo ""

# 检查端口监听
echo "2. 端口监听检查:"
if netstat -tlnp 2>/dev/null | grep -q ":3000 "; then
    echo "   ✅ 端口 3000 正在监听"
    netstat -tlnp 2>/dev/null | grep ":3000 "
else
    echo "   ❌ 端口 3000 未监听"
fi
echo ""

# 检查磁盘空间
echo "3. 磁盘空间检查:"
if [ -d "$APP_DIR" ]; then
    DISK_USAGE=$(df -h "$APP_DIR" | tail -1 | awk '{print $5}' | sed 's/%//')
    echo "   应用目录: $APP_DIR"
    echo "   磁盘使用率: ${DISK_USAGE}%"
    
    if [ "$DISK_USAGE" -gt 90 ]; then
        echo "   ⚠️  警告: 磁盘空间不足 (使用率 > 90%)"
    elif [ "$DISK_USAGE" -gt 80 ]; then
        echo "   ⚠️  注意: 磁盘空间较高 (使用率 > 80%)"
    else
        echo "   ✅ 磁盘空间正常"
    fi
else
    echo "   ❌ 应用目录不存在: $APP_DIR"
fi
echo ""

# 检查上传目录
echo "4. 上传目录检查:"
UPLOADS_DIR="$APP_DIR/uploads"
if [ -d "$UPLOADS_DIR" ]; then
    FILE_COUNT=$(find "$UPLOADS_DIR" -type f | wc -l)
    DIR_SIZE=$(du -sh "$UPLOADS_DIR" | cut -f1)
    echo "   ✅ 上传目录存在"
    echo "   文件数量: $FILE_COUNT"
    echo "   目录大小: $DIR_SIZE"
else
    echo "   ❌ 上传目录不存在"
    echo "   创建上传目录..."
    mkdir -p "$UPLOADS_DIR"
    chmod 755 "$UPLOADS_DIR"
fi
echo ""

# 检查服务日志
echo "5. 服务日志检查:"
RECENT_ERRORS=$(sudo journalctl -u $SERVICE_NAME --since "1 hour ago" | grep -i error | wc -l)
if [ "$RECENT_ERRORS" -gt 0 ]; then
    echo "   ⚠️  最近1小时有 $RECENT_ERRORS 个错误"
    echo "   最近错误日志:"
    sudo journalctl -u $SERVICE_NAME --since "1 hour ago" | grep -i error | tail -3
else
    echo "   ✅ 最近1小时无错误"
fi
echo ""

# 检查内存使用
echo "6. 内存使用检查:"
if pgrep -f "node.*index.js" > /dev/null; then
    PID=$(pgrep -f "node.*index.js")
    MEMORY_USAGE=$(ps -p $PID -o %mem --no-headers)
    echo "   Node.js 进程 PID: $PID"
    echo "   内存使用率: ${MEMORY_USAGE}%"
else
    echo "   ❌ Node.js 进程未运行"
fi
echo ""

# 检查网络连接
echo "7. 网络连接测试:"
if curl -s --connect-timeout 5 http://localhost:3000/health > /dev/null; then
    echo "   ✅ 服务响应正常"
    HEALTH_RESPONSE=$(curl -s http://localhost:3000/health)
    echo "   健康检查响应: $HEALTH_RESPONSE"
else
    echo "   ❌ 服务无响应"
fi
echo ""

# 生成监控报告
echo "=== 监控报告生成完成 ==="
echo "详细日志: $LOG_FILE"

# 保存监控报告到日志文件
{
    echo "=== 图床服务监控报告 ==="
    echo "时间: $(date)"
    echo "服务状态: $(systemctl is-active $SERVICE_NAME)"
    echo "磁盘使用率: ${DISK_USAGE}%"
    echo "上传文件数: $FILE_COUNT"
    echo "最近错误数: $RECENT_ERRORS"
} >> "$LOG_FILE"

# 如果服务未运行，发送警告
if ! systemctl is-active --quiet $SERVICE_NAME; then
    echo "警告: 图床服务未运行，请检查服务状态"
    exit 1
fi 