FROM alpine:latest AS builder

# 下载 Ollama
ARG OLLAMA_VERSION=latest
RUN apk add --no-cache wget ca-certificates tar gzip && \
    if [ "$OLLAMA_VERSION" = "latest" ]; then \
    wget --no-check-certificate https://ollama.com/download/ollama-linux-amd64.tgz -O /tmp/ollama.tgz || \
    wget --no-check-certificate https://ollama.ai/download/ollama-linux-amd64.tgz -O /tmp/ollama.tgz; \
    else \
    wget --no-check-certificate https://github.com/ollama/ollama/releases/download/v${OLLAMA_VERSION}/ollama-linux-amd64.tgz -O /tmp/ollama.tgz; \
    fi && \
    tar -xzf /tmp/ollama.tgz -C /usr/local/bin/ && \
    chmod +x /usr/local/bin/ollama && \
    rm /tmp/ollama.tgz

FROM alpine:latest

# 复制二进制文件
COPY --from=builder /usr/local/bin/ollama /usr/local/bin/ollama

# 运行时不下载任何模型
EXPOSE 11434

# 设置环境变量，禁止自动下载
ENV OLLAMA_MODELS="" \
    OLLAMA_HOST="0.0.0.0:11434"

ENTRYPOINT ["/usr/local/bin/ollama"]
CMD ["serve"]
