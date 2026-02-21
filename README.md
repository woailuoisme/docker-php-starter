# Lunchbox - Docker 镜像集合

一套精心构建的 Docker 镜像集合，专注于 PHP 应用开发和部署。

## 🚀 特性

- **多架构支持**: 支持 amd64 和 arm64 架构
- **PHP 全栈**: 包含 CLI、FPM、Octane (RoadRunner, FrankenPHP) 等多种 PHP 运行环境
- **现代化工具**: 集成 RoadRunner, Swoole, FrankenPHP 等高性能服务器
- **多仓库同步**: 自动同步到 Docker Hub, RedHat Registry (Quay.io), 腾讯云 TCR

## 📦 主要镜像

### PHP 开发镜像 (jiaoio/php8.x-dev)

- `cli-alpine` / `cli-trixie` - PHP CLI 环境
- `fpm-alpine` / `fpm-trixie` - PHP FPM 环境 (支持 Xdebug)
- `franken-alpine` / `franken-trixie` - FrankenPHP 环境
- `roadrunner-alpine` / `roadrunner-trixie` - RoadRunner 环境

### PHP 生产镜像 (jiaoio/php8.x)

- `cli-alpine` / `cli-trixie` - PHP CLI 生产环境
- `fpm-alpine` / `fpm-trixie` - PHP FPM 生产环境
- `franken-alpine` / `franken-trixie` - FrankenPHP 生产环境
- `roadrunner-alpine` / `roadrunner-trixie` - RoadRunner 生产环境

### 服务镜像
- `caddy-base` - Caddy Web 服务器
- `nginx` - Nginx Web 服务器
- `pgsql` - PostgreSQL 数据库
- `redis` - Redis 缓存
- `rabbitmq` - RabbitMQ 消息队列

## 🛠️ 使用方式

### 构建镜像
```bash
# 手动触发构建工作流
# 通过 GitHub Actions 界面选择要构建的镜像版本和变体
```

### 拉取镜像
```bash
# Docker Hub
docker pull jiaoio/php8.5-dev:fpm-trixie

# 腾讯云 TCR  
docker pull ccr.ccs.tencentyun.com/jiaoio/php8.5-dev:fpm-trixie

# RedHat Registry (Quay.io)
docker pull quay.io/jiaoio/php8.5-dev:fpm-trixie
```

## 🔧 开发

### 项目结构
```
lunchbox/
├── .github/workflows/    # CI/CD 工作流
├── php8.4-dev-*/        # PHP 8.4 开发镜像
├── php8.5-dev-*/        # PHP 8.5 开发镜像
├── php8.5-prod-*/       # PHP 8.5 生产镜像
├── caddy-base*/         # Caddy 镜像
└── nginx/               # Nginx 镜像
```

### 构建参数
- `CHANGE_SOURCE` - 是否使用国内镜像源
- `TIMEZONE` - 时区设置 (默认: Asia/Shanghai)
- `WITH_*` - 可选功能开关 (如 WITH_PG, WITH_XDEBUG)

## 📋 自动化

### 镜像构建

- 手动触发多架构（amd64/arm64）构建
- 自动推送到 Docker Hub 和 Quay.io

### 镜像同步

- 定时/手动同步所有镜像到腾讯云 TCR
- 支持跨区域快速拉取

## 📄 许可证

MIT License

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

---

**为现代 PHP 应用提供可靠的容器化解决方案**