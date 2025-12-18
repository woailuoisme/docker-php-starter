#!/bin/bash

# dnsmasq 配置验证脚本
# 用于验证 dnsmasq.conf 配置文件的语法和逻辑
# 主域名: .local

set -e

CONFIG_FILE="dnsmasq.conf"
LOG_FILE="validation.log"

echo "=== dnsmasq 配置验证开始 ===" | tee $LOG_FILE
echo "配置文件: $CONFIG_FILE" | tee -a $LOG_FILE
echo "验证时间: $(date)" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

# 检查配置文件是否存在
if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ 错误: 配置文件 $CONFIG_FILE 不存在" | tee -a $LOG_FILE
    exit 1
fi

echo "✅ 配置文件存在" | tee -a $LOG_FILE

# 基本语法检查
echo "" | tee -a $LOG_FILE
echo "=== 基本语法检查 ===" | tee -a $LOG_FILE

# 检查是否有空行
empty_lines=$(grep -c '^$' $CONFIG_FILE || true)
echo "空行数量: $empty_lines" | tee -a $LOG_FILE

# 检查注释行
comment_lines=$(grep -c '^#' $CONFIG_FILE || true)
echo "注释行数量: $comment_lines" | tee -a $LOG_FILE

# 检查配置行
config_lines=$(grep -v '^#' $CONFIG_FILE | grep -v '^$' | wc -l || true)
echo "配置行数量: $config_lines" | tee -a $LOG_FILE

# 检查关键配置项
echo "" | tee -a $LOG_FILE
echo "=== 关键配置项检查 ===" | tee -a $LOG_FILE

check_config() {
    local key=$1
    local description=$2
    if grep -q "^$key" $CONFIG_FILE; then
        echo "✅ $description: 已配置" | tee -a $LOG_FILE
        grep "^$key" $CONFIG_FILE | head -3 | tee -a $LOG_FILE
    else
        echo "⚠️  $description: 未找到" | tee -a $LOG_FILE
    fi
}

check_config "port=" "监听端口"
check_config "server=" "上游 DNS 服务器"
check_config "address=" "域名解析"
check_config "log-queries" "查询日志"
check_config "domain-needed" "域名必需"
check_config "bogus-priv" "私有地址过滤"
check_config "cache-size=" "缓存大小"

# 检查域名解析配置
echo "" | tee -a $LOG_FILE
echo "=== 域名解析配置检查 ===" | tee -a $LOG_FILE

# 统计不同域名的解析数量
echo ".local 域名解析数量: $(grep -c '\.local' $CONFIG_FILE || true)" | tee -a $LOG_FILE
echo "本地域名解析数量: $(grep -c '127.0.0.1' $CONFIG_FILE || true)" | tee -a $LOG_FILE

# 列出所有配置的域名
echo "" | tee -a $LOG_FILE
echo "配置的域名列表:" | tee -a $LOG_FILE
grep '^address=' $CONFIG_FILE | cut -d'/' -f2 | sort -u | tee -a $LOG_FILE

# 检查安全配置
echo "" | tee -a $LOG_FILE
echo "=== 安全配置检查 ===" | tee -a $LOG_FILE

check_config "stop-dns-rebind" "DNS 重绑定保护"
check_config "rebind-localhost-ok" "本地重绑定允许"
check_config "rebind-domain-ok" "域名重绑定允许"

# 检查性能配置
echo "" | tee -a $LOG_FILE
echo "=== 性能配置检查 ===" | tee -a $LOG_FILE

check_config "dns-forward-max=" "最大转发数"
check_config "neg-ttl=" "否定缓存 TTL"
check_config "max-ttl=" "最大 TTL"
check_config "min-port=" "最小端口"

# 配置摘要
echo "" | tee -a $LOG_FILE
echo "=== 配置摘要 ===" | tee -a $LOG_FILE
echo "总行数: $(wc -l < $CONFIG_FILE)" | tee -a $LOG_FILE
echo "有效配置行: $config_lines" | tee -a $LOG_FILE
echo "注释行: $comment_lines" | tee -a $LOG_FILE
echo "空行: $empty_lines" | tee -a $LOG_FILE

# 最终验证建议
echo "" | tee -a $LOG_FILE
echo "=== 验证建议 ===" | tee -a $LOG_FILE
echo "1. 使用命令测试: dnsmasq --test --conf-file=$CONFIG_FILE" | tee -a $LOG_FILE
echo "2. 启动服务测试: dnsmasq --conf-file=$CONFIG_FILE --no-daemon" | tee -a $LOG_FILE
echo "3. 检查日志输出确认无错误" | tee -a $LOG_FILE
echo "4. 使用 dig 或 nslookup 测试域名解析" | tee -a $LOG_FILE

echo "" | tee -a $LOG_FILE
echo "=== dnsmasq 配置验证完成 ===" | tee -a $LOG_FILE
echo "详细日志已保存到: $LOG_FILE" | tee -a $LOG_FILE

# 设置执行权限
chmod +x $0

echo ""
echo "✅ 验证脚本已创建，使用 ./$(basename $0) 运行"
