# =============================================================================
# Justfile - Command runner for php-starter project
# =============================================================================

set shell := ["bash", "-c"]
set dotenv-load

DC_RUN_ARGS := "-f docker-compose.yml"
SUPERVISOR_CMD := "docker compose " + DC_RUN_ARGS + " exec -T php-fpm sh -c 'export PYTHONWARNINGS=\"ignore::UserWarning:supervisor.options\" && supervisorctl -c /usr/local/etc/supervisord.conf -s http://127.0.0.1:9201'"

# 显示所有可用命令的帮助信息
default:
    @just --list

# =============================================================================
# DOCKER COMPOSE MANAGEMENT
# =============================================================================

# 启动所有服务容器 (后台运行，并清理孤儿容器)
up:
    docker compose {{ DC_RUN_ARGS }} up -d --remove-orphans

# 停止所有服务容器
down:
    docker compose {{ DC_RUN_ARGS }} down

# 停止所有服务容器并清理 volume 卷
down-with-volumes:
    docker compose {{ DC_RUN_ARGS }} down -v

# 重启所有服务容器
restart:
    docker compose {{ DC_RUN_ARGS }} restart

# 追踪容器日志 (可选参数指定特定服务，如 just logs php-fpm)
logs service="":
    @if [ -z "{{ service }}" ]; then \
        docker compose {{ DC_RUN_ARGS }} logs -f; \
    else \
        docker compose {{ DC_RUN_ARGS }} logs -f {{ service }}; \
    fi

# 展示格式化后的容器状态
ps:
    @echo "Container Status:"
    @echo "=================="
    @docker compose {{ DC_RUN_ARGS }} ps --format "table {{ "{{" }}.Name{{ "}}" }}\t{{ "{{" }}.Service{{ "}}" }}\t{{ "{{" }}.Status{{ "}}" }}\t{{ "{{" }}.Ports{{ "}}" }}" | \
    awk ' \
        NR==1 {print "   " $$0; next} \
        /unhealthy/ {print "[-] " $$0; next} \
        /healthy/ {print "[+] " $$0; next} \
        {print "[?] " $$0} \
    '

# =============================================================================
# SERVICE OPERATIONS
# =============================================================================

# 进入容器 Shell 环境 (默认为 php-fpm，如 just shell nginx)
shell service="php-fpm":
    docker compose {{ DC_RUN_ARGS }} exec {{ service }} sh

# 在 php-fpm 容器内运行指定命令 (例如 just command-php-fpm "php -m")
command-php-fpm command:
    docker compose {{ DC_RUN_ARGS }} exec php-fpm sh -c "{{ command }}"

# 执行 supervisorctl 管理操作 (动作可选: status, reload, update, start, stop, restart，默认 status)
# 示例：just supervisor start laravel-worker
supervisor action="status" process="":
    @echo "Supervisor: running {{ action }} {{ process }}..."
    {{ SUPERVISOR_CMD }} {{ action }} {{ process }}

# Nginx 管理操作 (动作可选: check, reload, restart，默认为 reload)
nginx action="reload":
    @if [ "{{ action }}" = "check" ]; then \
        docker compose {{ DC_RUN_ARGS }} exec nginx nginx -t; \
    elif [ "{{ action }}" = "reload" ]; then \
        docker compose {{ DC_RUN_ARGS }} exec nginx nginx -s reload; \
    elif [ "{{ action }}" = "restart" ]; then \
        docker compose {{ DC_RUN_ARGS }} restart nginx; \
    else \
        echo "Unknown action: {{ action }}"; \
        exit 1; \
    fi

# 运行容器服务健康检查 (服务可选: all, php-fpm, nginx, postgres, redis，默认 all)
check service="all":
    @if [ "{{ service }}" = "all" ]; then \
        echo "Running comprehensive service health checks..."; \
        docker compose {{ DC_RUN_ARGS }} exec php-fpm php-fpm -t; \
        docker compose {{ DC_RUN_ARGS }} exec nginx nginx -t; \
        docker compose {{ DC_RUN_ARGS }} exec postgres pg_isready; \
        docker compose {{ DC_RUN_ARGS }} exec redis redis-cli ping; \
        echo "All service health checks completed"; \
    elif [ "{{ service }}" = "php-fpm" ]; then \
        docker compose {{ DC_RUN_ARGS }} exec php-fpm php-fpm -t; \
    elif [ "{{ service }}" = "nginx" ]; then \
        docker compose {{ DC_RUN_ARGS }} exec nginx nginx -t; \
    elif [ "{{ service }}" = "postgres" ]; then \
        docker compose {{ DC_RUN_ARGS }} exec postgres pg_isready; \
    elif [ "{{ service }}" = "redis" ]; then \
        docker compose {{ DC_RUN_ARGS }} exec redis redis-cli ping; \
    else \
        echo "Unknown service: {{ service }}"; \
        exit 1; \
    fi

# =============================================================================
# BUILD AND DEPLOYMENT
# =============================================================================

# 构建所有或指定服务容器 (如 just build php-fpm)
build service="":
    @if [ -z "{{ service }}" ]; then \
        docker compose {{ DC_RUN_ARGS }} build; \
    else \
        docker compose {{ DC_RUN_ARGS }} build {{ service }}; \
    fi

# 无缓存强制重新构建所有或指定服务容器
rebuild service="":
    @if [ -z "{{ service }}" ]; then \
        docker compose {{ DC_RUN_ARGS }} build --no-cache; \
    else \
        docker compose {{ DC_RUN_ARGS }} build --no-cache {{ service }}; \
    fi

# 拉取最新的基础镜像
pull:
    docker compose {{ DC_RUN_ARGS }} pull

# =============================================================================
# UTILITIES AND CLEANUP
# =============================================================================

# =============================================================================
# CODE QUALITY AND LINTING
# =============================================================================

# 运行所有静态代码校验 (Hadolint, ShellCheck, shfmt)
lint:
    @echo "Running Hadolint on Dockerfiles..."
    -@fd -g "Dockerfile" -X hadolint
    @echo "Running ShellCheck on scripts..."
    -@fd -e sh . scripts -X shellcheck
    @echo "Checking formatting with shfmt..."
    -@fd -e sh . scripts -X shfmt -i 4 -ci -sr -d
    @echo "All lint checks completed!"

# 自动格式化 Shell 脚本与 Justfile
fmt:
    @echo "Formatting scripts with shfmt..."
    @fd -e sh . scripts -X shfmt -i 4 -ci -sr -w
    @echo "Formatting Justfile..."
    @just --fmt
    @echo "All formatting completed!"

# 验证并输出计算合并后的 docker-compose.yml 配置
compose-validate:
    docker compose {{ DC_RUN_ARGS }} config

# 打印各服务的软件版本号
show-versions:
    @echo "Service Versions:"
    @echo "==================="
    @echo "PHP-FPM: $(docker compose {{ DC_RUN_ARGS }} exec php-fpm php -v | head -1)"
    @echo "Nginx: $(docker compose {{ DC_RUN_ARGS }} exec nginx nginx -v 2>&1)"
    @echo "PostgresSQL: $(docker compose {{ DC_RUN_ARGS }} exec postgres psql --version)"
    @echo "Redis: $(docker compose {{ DC_RUN_ARGS }} exec redis redis-server --version | head -1)"

# 清理悬挂的/未使用的 Docker 镜像
clean-images:
    docker image prune -f

# 清理未使用的 Docker Volume 卷
clean-volumes:
    docker volume prune -f

# 深度清理所有未使用的 Docker 资源
clean-all:
    docker system prune -f

# =============================================================================
# SECURITY AND CERTIFICATES
# =============================================================================

# 查看 SSL 证书详细信息
cert:
    @echo "Checking SSL certificates..."
    @docker compose {{ DC_RUN_ARGS }} exec nginx openssl x509 -in /etc/nginx/ssl/live/haoxiaoguai.xyz/fullchain.pem -text -noout | rg "(Subject:|Not Before:|Not After :)"

# 校验 Caddy 配置文件
check-caddy:
    @echo "Checking Caddy service..."
    @docker compose {{ DC_RUN_ARGS }} exec caddy caddy validate --config /etc/caddy/Caddyfile

# 在 macOS 钥匙串中信任 Caddy 的根证书
trust-caddy-cert:
    @echo "Installing Caddy root certificate to macOS system keychain..."
    @docker compose {{ DC_RUN_ARGS }} cp \
        caddy:/data/caddy/pki/authorities/local/root.crt \
        /tmp/root.crt \
    && sudo security add-trusted-cert -d -r trustRoot \
        -k /Library/Keychains/System.keychain /tmp/root.crt
    @echo "Caddy root certificate installed successfully"

# 在 Linux 系统中信任 Caddy 的根证书
trust-caddy-cert-linux:
    @echo "Installing Caddy root certificate on Linux..."
    @docker compose {{ DC_RUN_ARGS }} cp \
        caddy:/data/caddy/pki/authorities/local/root.crt \
        /usr/local/share/ca-certificates/root.crt \
    && sudo update-ca-certificates
    @echo "Caddy root certificate installed successfully on Linux"

# 在 Windows 系统中信任 Caddy 的根证书
trust-caddy-cert-windows:
    @echo "Installing Caddy root certificate on Windows..."
    @docker compose {{ DC_RUN_ARGS }} cp \
        caddy:/data/caddy/pki/authorities/local/root.crt \
        %TEMP%/root.crt \
    && certutil -addstore -f "ROOT" %TEMP%/root.crt
    @echo "Caddy root certificate installed successfully on Windows"

# 验证 Authelia 配置
authelia-config-validate:
    @echo "Validating Authelia configuration..."
    @docker compose {{ DC_RUN_ARGS }} exec authelia authelia validate-config

# 生成 Authelia 密码 Hash 值 (argon2)
authelia-generate-password password:
    @echo "Generating Authelia password hash..."
    @docker compose {{ DC_RUN_ARGS }} exec authelia authelia crypto hash generate argon2 --password '{{ password }}'

# =============================================================================
# QUICK ACTIONS
# =============================================================================

# 快速启动开发环境并运行服务检查
dev:
    @just up
    @just check

# 重置整个开发环境容器
reset:
    @just down
    @just up

# 拉取最新镜像并重启所有服务
update:
    @just pull
    @just down
    @just up

# 展示系统及容器综合状态信息
status:
    @just ps
    @just check

# =============================================================================
# MAINTENANCE AND LOGS
# =============================================================================

# 备份 PostgreSQL 数据库到 backup/ 目录下
backup-db:
    @echo "Backing up PostgreSQL database..."
    @docker compose {{ DC_RUN_ARGS }} exec postgres pg_dump -U $POSTGRES_USER $POSTGRES_DB > backup/$(date +%Y%m%d_%H%M%S)_backup.sql
    @echo "Backup completed"

# 从备份文件恢复 PostgreSQL 数据库 (例如 just restore-db backup/2026_backup.sql)
restore-db file:
    @echo "Restoring PostgreSQL database from {{ file }}..."
    @docker compose {{ DC_RUN_ARGS }} exec -T postgres psql -U $POSTGRES_USER $POSTGRES_DB < {{ file }}
    @echo "Database restored from {{ file }}"

# 一次性查看所有服务的日志
view-logs:
    docker compose {{ DC_RUN_ARGS }} logs

# 清理挂载在宿主机的 logs 目录下的全部日志文件
clean-logs:
    @echo "Cleaning container logs..."
    @fd -e log -t f . ./logs -X rm -f
    @echo "Logs cleaned"
