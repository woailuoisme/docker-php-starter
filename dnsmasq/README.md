# dnsmasq 本地开发 DNS 配置

## 概述
为 Docker 本地开发环境提供 `.local` 域名解析服务。

## 配置特性
- 所有 `.local` 域名解析到 `127.0.0.1`
- 常用服务域名预配置
- 上游 DNS 服务器：Google 和 Cloudflare
- 查询日志记录

## 使用方法

### 1. 启动服务
```bash
# 使用 Docker Compose
docker-compose up -d dnsmasq

# 或直接运行
dnsmasq --conf-file=dnsmasq.conf
```

### 2. 配置系统 DNS
将系统 DNS 设置为 `127.0.0.1`

### 3. 测试域名
```bash
# 测试任意 .local 域名
dig @127.0.0.1 portainer.local
nslookup portainer.local 127.0.0.1

# 测试通配符
dig @127.0.0.1 any-service.local
```

## 预配置域名
- `auth.local` - Authelia 认证
- `portainer.local` - 容器管理
- `dozzle.local` - 日志查看
- `xui.local` - VPN 面板
- `search.local` - 搜索服务
- `minio.local` - 对象存储
- `rabbitmq.local` - 消息队列
- `postgres.local` - 数据库
- `redis.local` - 缓存
- `php.local` - PHP 应用
- `app.local` - 主应用
- `api.local` - API 服务

## 添加新域名
在配置文件中添加：
```
address=/new-service.local/127.0.0.1
```

## 验证配置
```bash
./validate.sh
dnsmasq --test --conf-file=dnsmasq.conf
```

## 注意
- 仅用于本地开发环境
- 确保端口 53 可用
- 配置系统 DNS 后生效