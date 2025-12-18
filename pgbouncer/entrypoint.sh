#!/bin/bash
set -e

# PgBouncer 启动脚本
# 提供配置验证、优雅启动和信号处理

echo "==================================="
echo "PgBouncer 启动中..."
echo "==================================="

# 环境变量配置
PGBOUNCER_CONFIG="${PGBOUNCER_CONFIG:-/etc/pgbouncer/pgbouncer.ini}"
PGBOUNCER_AUTH_FILE="${PGBOUNCER_AUTH_FILE:-/etc/pgbouncer/userlist.txt}"

# 验证配置文件
if [ ! -f "$PGBOUNCER_CONFIG" ]; then
    echo "错误: 配置文件不存在: $PGBOUNCER_CONFIG"
    exit 1
fi

if [ ! -f "$PGBOUNCER_AUTH_FILE" ]; then
    echo "错误: 认证文件不存在: $PGBOUNCER_AUTH_FILE"
    exit 1
fi

# 显示配置信息
echo "配置文件: $PGBOUNCER_CONFIG"
echo "认证文件: $PGBOUNCER_AUTH_FILE"
echo "监听地址: $(grep listen_addr "$PGBOUNCER_CONFIG" | grep -v '^;' | cut -d'=' -f2 | xargs)"
echo "监听端口: $(grep listen_port "$PGBOUNCER_CONFIG" | grep -v '^;' | cut -d'=' -f2 | xargs)"
echo "连接池模式: $(grep pool_mode "$PGBOUNCER_CONFIG" | grep -v '^;' | cut -d'=' -f2 | xargs)"
echo "最大客户端连接: $(grep max_client_conn "$PGBOUNCER_CONFIG" | grep -v '^;' | cut -d'=' -f2 | xargs)"
echo "默认连接池大小: $(grep default_pool_size "$PGBOUNCER_CONFIG" | grep -v '^;' | cut -d'=' -f2 | xargs)"

# 信号处理函数
shutdown() {
    echo ""
    echo "==================================="
    echo "收到停止信号，正在优雅关闭..."
    echo "==================================="
    
    # 发送 SIGTERM 给 pgbouncer 进程
    if [ -f /var/run/pgbouncer/pgbouncer.pid ]; then
        PID=$(cat /var/run/pgbouncer/pgbouncer.pid)
        if kill -0 "$PID" 2>/dev/null; then
            echo "正在关闭 PgBouncer (PID: $PID)..."
            kill -TERM $PID
            
            # 等待进程退出
            for i in {1..30}; do
                if ! kill -0 $PID 2>/dev/null; then
                    echo "PgBouncer 已成功关闭"
                    exit 0
                fi
                sleep 1
            done
            
            echo "警告: PgBouncer 未在30秒内关闭，强制终止"
            kill -KILL $PID 2>/dev/null || true
        fi
    fi
    
    exit 0
}

# 注册信号处理
trap shutdown SIGTERM SIGINT SIGQUIT

echo "==================================="
echo "PgBouncer 启动完成"
echo "==================================="
echo ""

# 启动 pgbouncer
exec "$@"
