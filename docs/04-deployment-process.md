# 完整部署流程

## 部署架构

```
┌─────────────────────────────────────────────────────┐
│              Docker 部署架构图                        │
├─────────────────────────────────────────────────────┤
│                                                       │
│   ┌──────────────────┐         ┌──────────────────┐  │
│   │     Frontend     │         │    Backend       │  │
│   │   (Nginx/Vue)    │◄──────► │   (Go/Java)      │  │
│   │   Port: 80       │         │   Port: 8081     │  │
│   └──────────────────┘         └──────────────────┘  │
│            │                           │              │
│            └───────────┬────────────────┘              │
│                        │                              │
│                   ┌────▼──────┐                       │
│                   │  Database  │                       │
│                   │ (PostgreSQL)│                       │
│                   │ Port: 5432 │                       │
│                   └───────────┘                       │
│                                                       │
└─────────────────────────────────────────────────────┘
```

## 部署步骤详解

### 第一步：准备环境

#### 1. 安装 Docker 和 Docker Compose

**Ubuntu/Debian:**
```bash
# 更新包列表
sudo apt-get update

# 安装 Docker
sudo apt-get install -y docker.io

# 安装 Docker Compose
sudo apt-get install -y docker-compose

# 验证安装
docker --version
docker-compose --version
```

**CentOS/RHEL:**
```bash
sudo yum install -y docker
sudo yum install -y docker-compose

sudo systemctl start docker
sudo systemctl enable docker
```

#### 2. 配置当前用户

```bash
# 将用户添加到 docker 组（免 sudo）
sudo usermod -aG docker $USER

# 刷新用户组
newgrp docker

# 验证
docker ps
```

### 第二步：准备应用文件

#### 项目结构

```
hr-deployment-learning/
├── docker-compose.yml          # Docker Compose 配置
├── frontend/                   # 前端项目
│   ├── Dockerfile
│   ├── nginx.conf
│   └── dist/                   # 编译后的静态文件
├── backend/                    # 后端项目
│   ├── Dockerfile
│   ├── main.go                 # (如果是 Go)
│   └── go.mod
└── database/                   # 数据库初始化脚本
    └── init.sql
```

### 第三步：编写配置文件

#### 1. Dockerfile - 前端

```dockerfile
FROM nginx:1.25-alpine

# 安装依赖
RUN apk add --no-cache ca-certificates

# 移除默认配置
RUN rm -rf /usr/share/nginx/html/*

# 复制前端文件
COPY dist /usr/share/nginx/html

# 复制 nginx 配置
COPY nginx.conf /etc/nginx/nginx.conf

# 暴露端口
EXPOSE 80

# 启动 nginx
CMD ["nginx", "-g", "daemon off;"]
```

#### 2. Dockerfile - 后端

```dockerfile
# 编译阶段
FROM golang:1.21-alpine AS builder

WORKDIR /app

COPY . .

# 编译二进制
RUN go mod download && \
    CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o hr-backend .

# 运行阶段
FROM alpine:3.18

WORKDIR /app

# 复制编译好的二进制
COPY --from=builder /app/hr-backend .

EXPOSE 8081

CMD ["./hr-backend"]
```

#### 3. nginx.conf - 前端配置

```nginx
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;

    # 代理到后端
    upstream backend {
        server backend:8081;
    }

    server {
        listen 80;
        server_name _;

        location / {
            root /usr/share/nginx/html;
            index index.html;
            try_files $uri $uri/ /index.html;
        }

        # 代理 API 请求到后端
        location /api/ {
            proxy_pass http://backend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }
    }
}
```

#### 4. docker-compose.yml - 完整配置

```yaml
version: '3.8'

services:
  # 前端服务
  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    container_name: hr-frontend
    ports:
      - "80:80"
    depends_on:
      - backend
    networks:
      - app-network
    environment:
      - BACKEND_URL=http://backend:8081
    restart: always

  # 后端服务
  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    container_name: hr-backend
    ports:
      - "8081:8081"
    depends_on:
      - db
    networks:
      - app-network
    environment:
      - DB_HOST=db
      - DB_PORT=5432
      - DB_USER=postgres
      - DB_PASSWORD=secret123
      - DB_NAME=hrdb
      - LOG_LEVEL=info
    volumes:
      - ./backend/logs:/app/logs
    restart: always
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8081/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  # 数据库服务
  db:
    image: postgres:15-alpine
    container_name: hr-db
    networks:
      - app-network
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=secret123
      - POSTGRES_DB=hrdb
    volumes:
      - db-data:/var/lib/postgresql/data
      - ./database/init.sql:/docker-entrypoint-initdb.d/init.sql
    restart: always
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5

# 定义网络
networks:
  app-network:
    driver: bridge

# 定义数据卷
volumes:
  db-data:
    driver: local
```

#### 5. database/init.sql - 数据库初始化

```sql
-- 创建用户表
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 创建部门表
CREATE TABLE IF NOT EXISTS departments (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 插入测试数据
INSERT INTO users (username, email) VALUES 
    ('admin', 'admin@example.com'),
    ('user1', 'user1@example.com');

INSERT INTO departments (name, description) VALUES 
    ('IT', '信息技术部'),
    ('HR', '人力资源部');
```

### 第四步：本地测试

```bash
# 进入项目目录
cd ~/hr-deployment-learning

# 构建镜像
docker-compose build

# 启动容器
docker-compose up -d

# 查看容器状态
docker-compose ps

# 查看日志
docker-compose logs -f

# 测试服务
curl http://localhost
curl http://localhost:8081/api/health
curl http://localhost:8081/api/users
```

### 第五步：部署到服务器

#### 1. 上传文件到服务器

```bash
# 在本地
scp -r ~/hr-deployment-learning user@server-ip:/home/user/

# 或使用 git
git clone https://github.com/username/hr-deployment-learning.git
cd hr-deployment-learning
```

#### 2. 在服务器上启动

```bash
# SSH 进入服务器
ssh user@server-ip

# 进入项目目录
cd ~/hr-deployment-learning

# 启动容器
docker-compose up -d

# 检查状态
docker-compose ps

# 查看日志
docker-compose logs -f
```

#### 3. 验证部署

```bash
# 检查容器是否运行
docker-compose ps

# 检查网络连接
docker-compose exec backend curl http://localhost:8081/health

# 查看数据库连接
docker-compose exec db psql -U postgres -d hrdb -c "SELECT * FROM users;"
```

### 第六步：维护和监控

#### 查看日志

```bash
# 查看所有服务的日志
docker-compose logs

# 查看某个服务的日志
docker-compose logs backend

# 实时查看日志
docker-compose logs -f backend

# 查看最后 100 行
docker-compose logs --tail=100 backend
```

#### 更新应用

```bash
# 重新构建镜像
docker-compose build --no-cache

# 重启容器
docker-compose up -d

# 或一步到位
docker-compose up -d --build
```

#### 备份数据

```bash
# 备份数据卷
docker run --rm -v hr-deployment-learning_db-data:/data -v $(pwd):/backup \
  alpine tar czf /backup/db-backup.tar.gz -C /data .

# 恢复数据卷
docker run --rm -v hr-deployment-learning_db-data:/data -v $(pwd):/backup \
  alpine tar xzf /backup/db-backup.tar.gz -C /data
```

## 常见问题排查

### 问题 1：容器无法启动
```bash
docker-compose logs backend
# 查看错误日志，检查 Dockerfile 或环境变量
```

### 问题 2：数据库连接失败
```bash
# 进入后端容器测试连接
docker-compose exec backend nc -zv db 5432
```

### 问题 3：前后端无法通信
```bash
# 进入前端容器检查网络
docker-compose exec frontend ping backend
```

### 问题 4：性能问题
```bash
# 查看容器资源使用
docker stats

# 查看磁盘占用
docker system df

# 清理未使用的资源
docker system prune
```

## 总结

1. ✅ 准备好所有源文件和配置文件
2. ✅ 编写 Dockerfile（前端、后端）
3. ✅ 编写 docker-compose.yml
4. ✅ 本地测试确认无误
5. ✅ 上传到服务器
6. ✅ 启动容器并验证
7. ✅ 配置监控和备份

恭喜！你已经完成了完整的 Docker 容器化部署！
