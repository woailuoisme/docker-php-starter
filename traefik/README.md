# Traefik 3.6 配置文档

优化的 Traefik 配置，采用模块化文件结构，支持本地和生产环境 HTTPS。

## 📁 目录结构

```
traefik/
├── traefik.yml                    # 主配置文件
├── Dockerfile                     # Docker 镜像构建文件
├── docker-compose.override.yml    # Docker Compose 配置
├── .env.example                   # 环境变量示例
├── README.md                      # 本文档
└── config/
    ├── dynamic/                   # 动态配置目录
    │   ├── 00-core.yml           # 核心服务（Traefik Dashboard、错误页面）
    │   ├── middlewares.yml       # 中间件配置
    │   ├── tls.yml               # TLS/证书配置
    │   ├── authelia.yml          # Authelia 认证
    │   ├── php-franken.yml       # PHP FrankenPHP 应用
    │   ├── php-octane.yml        # PHP Octane 应用
    │   ├── caddy.yml             # Caddy 服务器
    │   ├── nginx.yml             # Nginx 服务器
    │   ├── postgres.yml          # PostgreSQL 数据库
    │   ├── pgbouncer.yml         # PgBouncer 连接池
    │   ├── pgadmin.yml           # PgAdmin 管理界面
    │   ├── redis.yml             # Redis 缓存
    │   ├── redis-insight.yml     # Redis Insight
    │   ├── minio.yml             # MinIO 对象存储
    │   ├── meilisearch.yml       # Meilisearch 搜索
    │   ├── rabbitmq.yml          # RabbitMQ 消息队列
    │   ├── dozzle.yml            # Dozzle 日志查看
    │   ├── watchtower.yml        # Watchtower 容器更新
    │   ├── homepage.yml          # Homepage 仪表板
    │   ├── gotify.yml            # Gotify 通知
    │   ├── portainer.yml         # Portainer 容器管理
    │   └── registry.yml          # Docker Registry
    ├── certs/                     # 证书目录
    │   ├── localhost.crt         # 本地开发证书
    │   ├── localhost.key         # 本地开发私钥
    │   └── generate-certs.sh     # 证书生成脚本
    └── acme/                      # ACME 证书存储
        ├── acme.json             # 默认证书
        ├── letsencrypt.json      # Let's Encrypt 证书
        ├── cloudflare.json       # Cloudflare DNS 证书
        └── aliyun.json           # 阿里云 DNS 证书
```

## 🚀 快速开始

### 1. 环境配置

```bash
# 复制环境变量文件
cp .env.example .env

# 编辑环境变量
vim .env
```

关键配置项：
- `SITE_ADDRESS`: 你的域名
- `CERTBOT_EMAIL`: 证书通知邮箱
- `ACME_CA_SERVER`: 证书服务器（本地用 staging，生产用正式）

### 2. 生成本地证书（开发环境）

```bash
cd config/certs
bash generate-certs.sh
```

### 3. 启动服务

```bash
# 在主 docker-compose.yml 中取消注释 traefik 服务
# 或使用独立配置
docker-compose -f docker-compose.yml -f traefik/docker-compose.override.yml up -d traefik
```

### 4. 访问服务

- Traefik Dashboard: `https://traefik.yourdomain.com`
- 主应用: `https://app.yourdomain.com` 或 `https://yourdomain.com`
- 其他服务: 参见下方服务列表

## 🔧 配置说明

### 主配置文件 (traefik.yml)

包含：
- 入口点配置（HTTP/HTTPS/Metrics/TCP）
- 证书解析器（本地/Let's Encrypt/Cloudflare/阿里云）
- TLS 配置
- 日志和监控配置

### 动态配置文件

每个服务都有独立的配置文件，包含：
- **Service**: 后端服务定义（负载均衡、健康检查）
- **Router**: 路由规则（域名、路径、中间件）

#### 配置文件命名规范

- `00-core.yml`: 核心服务（优先加载）
- `middlewares.yml`: 中间件定义
- `tls.yml`: TLS 配置
- `<service-name>.yml`: 各服务独立配置

### 中间件链

预定义的中间件链：

1. **web-chain**: 标准 Web 应用
   - security-headers
   - gzip
   - error-pages

2. **web-protected**: 受保护的 Web 应用
   - security-headers
   - authelia
   - gzip
   - error-pages

3. **api-chain**: API 应用
   - security-headers
   - cors-api
   - rate-limit-api
   - gzip

4. **admin-chain**: 管理面板
   - security-headers
   - ip-whitelist-admin
   - auth-basic
   - error-pages

## 📋 服务列表

### 核心服务

| 服务 | 域名 | 端口 | 中间件 |
|------|------|------|--------|
| Traefik Dashboard | traefik.domain.com | 443 | admin-chain |
| 错误页面 | error.domain.com | 443 | web-chain |

### 应用服务

| 服务 | 域名 | 端口 | 中间件 |
|------|------|------|--------|
| PHP FrankenPHP | app.domain.com | 443 | web-chain |
| PHP Octane | octane.domain.com | 443 | web-chain |
| Caddy | caddy.domain.com | 443 | web-chain |
| Nginx | nginx.domain.com | 443 | web-chain |

### 数据库服务

| 服务 | 域名 | 端口 | 中间件 |
|------|------|------|--------|
| PgAdmin | pgadmin.domain.com | 443 | admin-chain |
| Redis Insight | redis.domain.com | 443 | admin-chain |
| PostgreSQL (TCP) | - | 45432 | - |
| Redis (TCP) | - | 46379 | - |

### 存储与搜索

| 服务 | 域名 | 端口 | 中间件 |
|------|------|------|--------|
| MinIO Console | minio.domain.com | 443 | web-chain |
| MinIO S3 API | s3.domain.com | 443 | web-chain |
| Meilisearch | search.domain.com | 443 | api-chain |

### 监控与管理

| 服务 | 域名 | 端口 | 中间件 |
|------|------|------|--------|
| Dozzle | logs.domain.com | 443 | admin-chain |
| Watchtower | watchtower.domain.com | 443 | admin-chain |
| Homepage | home.domain.com | 443 | web-chain |
| Portainer | portainer.domain.com | 443 | admin-chain |
| Gotify | notify.domain.com | 443 | admin-chain |
| RabbitMQ | rabbitmq.domain.com | 443 | admin-chain |

## 🔐 证书配置

### 本地开发环境

使用自签名证书：

```bash
cd config/certs
bash generate-certs.sh
```

配置使用 `default` 证书解析器。

### 生产环境

#### 方式 1: HTTP 挑战（推荐）

适用于公网可访问的服务器：

```yaml
# .env
ACME_CA_SERVER=https://acme-v02.api.letsencrypt.org/directory
```

使用 `letsencrypt` 证书解析器。

#### 方式 2: Cloudflare DNS 挑战

适用于使用 Cloudflare DNS 的域名：

```yaml
# .env
CLOUDFLARE_API_TOKEN=your_token
```

在路由中使用：
```yaml
tls:
  certResolver: cloudflare
```

#### 方式 3: 阿里云 DNS 挑战

适用于使用阿里云 DNS 的域名：

```yaml
# .env
ALIYUN_ACCESS_KEY_ID=your_key_id
ALIYUN_ACCESS_KEY_SECRET=your_key_secret
```

在路由中使用：
```yaml
tls:
  certResolver: aliyun
```

## 📝 添加新服务

### 1. 创建配置文件

```bash
vim config/dynamic/myservice.yml
```

### 2. 配置模板

```yaml
# MyService 配置
# 文件: traefik/config/dynamic/myservice.yml

http:
  services:
    myservice:
      loadBalancer:
        servers:
          - url: "http://myservice:8080"
        passHostHeader: true
        healthCheck:
          path: /health
          interval: "30s"
          timeout: "5s"

  routers:
    myservice:
      entryPoints:
        - websecure
      rule: 'Host(`myservice.{{ env "DOMAIN" }}`)'
      service: myservice
      middlewares:
        - web-chain@file
      tls:
        certResolver: default
      priority: 40
```

### 3. 重启 Traefik

```bash
docker-compose restart traefik
```

配置会自动热加载（watch: true）。

## 🛠️ 常用命令

```bash
# 查看日志
docker-compose logs -f traefik

# 重启服务
docker-compose restart traefik

# 查看配置
docker exec traefik cat /etc/traefik/traefik.yml

# 测试配置
docker exec traefik traefik version

# 查看证书
docker exec traefik ls -la /config/acme/
```

## 🔍 故障排查

### 1. 证书问题

```bash
# 检查 ACME 日志
docker-compose logs traefik | grep -i acme

# 删除证书重新申请
rm config/acme/acme.json
docker-compose restart traefik
```

### 2. 路由不生效

```bash
# 检查动态配置
docker exec traefik ls -la /config/dynamic/

# 查看路由状态
curl -s http://localhost:8080/api/http/routers | jq
```

### 3. 中间件错误

```bash
# 检查中间件配置
docker exec traefik cat /config/dynamic/middlewares.yml

# 查看中间件状态
curl -s http://localhost:8080/api/http/middlewares | jq
```

## 📚 参考资料

- [Traefik 官方文档](https://doc.traefik.io/traefik/)
- [Traefik 3.6 更新日志](https://github.com/traefik/traefik/releases/tag/v3.6.0)
- [Let's Encrypt 文档](https://letsencrypt.org/docs/)
- [Cloudflare API 文档](https://developers.cloudflare.com/api/)

## 🎯 最佳实践

1. **本地开发**: 使用自签名证书 + staging CA
2. **生产环境**: 使用 Let's Encrypt 正式 CA
3. **通配符证书**: 使用 DNS 挑战（Cloudflare/阿里云）
4. **安全性**: 启用 HSTS、安全头、IP 白名单
5. **性能**: 启用 Gzip、HTTP/2、HTTP/3
6. **监控**: 启用 Prometheus metrics、访问日志
7. **模块化**: 每个服务独立配置文件，便于管理

## 📄 许可证

MIT License
