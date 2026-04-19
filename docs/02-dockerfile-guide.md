# Dockerfile 完全指南

## Dockerfile 是什么？

Dockerfile 是一个文本文件，用来定义如何构建 Docker 镜像。  
每一行指令都会创建一个新的镜像层。

## 核心指令

### 1. FROM - 基础镜像
```dockerfile
FROM nginx:1.25-alpine
FROM alpine:3.18
FROM python:3.9
FROM golang:1.21
```

**说明：** 必须是第一条指令，指定基础镜像

### 2. RUN - 执行命令
```dockerfile
# 安装包（Alpine）
RUN apk add --no-cache curl git

# 安装包（Ubuntu/Debian）
RUN apt-get update && apt-get install -y curl

# 执行 shell 命令
RUN echo "Hello Docker"
```

**最佳实践：** 合并多个 RUN 指令，减少镜像层数

```dockerfile
# ❌ 不好：创建3个层
RUN apt-get update
RUN apt-get install -y curl
RUN apt-get install -y git

# ✅ 好：创建1个层
RUN apt-get update && \
    apt-get install -y curl git && \
    apt-get clean
```

### 3. COPY - 复制文件
```dockerfile
# 复制单个文件
COPY nginx.conf /etc/nginx/nginx.conf

# 复制整个目录
COPY app.py /app/

# 复制并改变所有者
COPY --chown=nginx:nginx app /app/
```

### 4. ADD - 复制文件（支持 URL 和自动解压）
```dockerfile
# 可以从 URL 下载
ADD https://example.com/app.tar.gz /tmp/

# 自动解压 tar 文件
ADD app.tar.gz /app/
```

**建议：** 优先使用 COPY，ADD 用于特殊场景

### 5. WORKDIR - 设置工作目录
```dockerfile
WORKDIR /app
RUN npm install
COPY . .
CMD ["npm", "start"]
```

### 6. ENV - 设置环境变量
```dockerfile
ENV NODE_ENV=production
ENV PORT=3000
```

### 7. EXPOSE - 声明端口
```dockerfile
EXPOSE 80          # Nginx 前端
EXPOSE 8081        # Go 后端
EXPOSE 5432        # PostgreSQL 数据库
```

**注意：** 这只是声明，实际需要用 `docker run -p` 映射

### 8. CMD - 容器启动命令
```dockerfile
# 推荐形式（JSON 数组）
CMD ["nginx", "-g", "daemon off;"]

# Shell 形式
CMD nginx -g "daemon off;"
```

**重要：** 每个 Dockerfile 只能有一个 CMD

### 9. ENTRYPOINT - 容器入口点
```dockerfile
ENTRYPOINT ["python", "app.py"]
```

## 实例 1：前端 Dockerfile

```dockerfile
FROM nginx:1.25-alpine

# 设置镜像源
RUN echo "https://mirrors.aliyun.com/alpine/v3.18/main" > /etc/apk/repositories && \
    echo "https://mirrors.aliyun.com/alpine/v3.18/community" >> /etc/apk/repositories

# 安装必要工具
RUN apk add --no-cache tar && rm -rf /usr/share/nginx/html/*

# 复制 nginx 配置
COPY nginx.conf /etc/nginx/nginx.conf

# 复制前端文件
COPY dist2.0.tar /tmp/

# 解压并设置权限
RUN cd /usr/share/nginx/html && \
    tar -xf /tmp/dist2.0.tar --strip-components=1 && \
    rm /tmp/dist2.0.tar && \
    chown -R nginx:nginx /usr/share/nginx/html && \
    chmod -R 755 /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
```

## 实例 2：后端 Go Dockerfile

```dockerfile
FROM golang:1.21-alpine AS builder

WORKDIR /app

# 复制源代码
COPY . .

# 编译
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o hr_backend .

# 最小化运行时镜像
FROM alpine:3.18

WORKDIR /app

# 只复制编译好的二进制文件
COPY --from=builder /app/hr_backend .

EXPOSE 8081

CMD ["./hr_backend"]
```

## 实例 3：Python Dockerfile

```dockerfile
FROM python:3.9-slim

WORKDIR /app

# 复制依赖文件
COPY requirements.txt .

# 安装依赖
RUN pip install --no-cache-dir -r requirements.txt

# 复制源代码
COPY . .

EXPOSE 5000

CMD ["python", "app.py"]
```

## 构建镜像

```bash
# 构建镜像（指定 tag）
docker build -t myapp:1.0 .

# 构建时指定 Dockerfile 位置
docker build -f path/to/Dockerfile -t myapp:1.0 .

# 构建时传递参数
docker build --build-arg ENV=production -t myapp:1.0 .
```

## 最佳实践

### ✅ 优化镜像大小

1. **使用轻量级基础镜像**
```dockerfile
# ❌ 700 MB
FROM ubuntu:20.04

# ✅ 50 MB
FROM alpine:3.18
```

2. **多阶段构建**
```dockerfile
# 阶段1：构建
FROM golang:1.21 AS builder
WORKDIR /app
COPY . .
RUN go build -o app .

# 阶段2：运行（只需要二进制文件）
FROM alpine:3.18
COPY --from=builder /app/app .
CMD ["./app"]
```

3. **清理不必要的文件**
```dockerfile
RUN apt-get update && \
    apt-get install -y curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
```

### ✅ 安全最佳实践

1. **使用非 root 用户**
```dockerfile
RUN addgroup -g 1000 app && \
    adduser -D -u 1000 -G app app
USER app
```

2. **扫描镜像漏洞**
```bash
docker scan myapp:1.0
```

### ✅ 构建最佳实践

1. **把最不常变的内容放在前面**
```dockerfile
# 基础库先复制
COPY requirements.txt .
RUN pip install -r requirements.txt

# 经常变的代码最后复制
COPY . .
```

2. **使用 .dockerignore 文件**
```
node_modules/
.git
.env
__pycache__
```

3. **添加元数据标签**
```dockerfile
LABEL maintainer="your@email.com"
LABEL version="1.0"
LABEL description="HR System Frontend"
```

## 常见错误

| 错误 | 原因 | 解决方案 |
|------|------|--------|
| COPY failed: no such file | 文件路径错误 | 检查相对路径 |
| Command not found | 基础镜像中没有该命令 | 使用 RUN 安装 |
| Permission denied | 文件权限问题 | 使用 chmod 改权限 |
| Port already in use | 端口被占用 | 换其他端口映射 |

## 下一步

学习如何用 docker-compose 编排多个容器。参考：`03-docker-compose-guide.md`
