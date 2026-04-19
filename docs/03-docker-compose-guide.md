# Docker Compose 完全指南

## 什么是 Docker Compose？

Docker Compose 是一个工具，用来定义和运行**多个 Docker 容器**。

通过一个 YAML 文件，可以：
- 定义多个服务（Web、数据库等）
- 一键启动所有容器
- 配置容器间的网络通信
- 定义数据卷持久化

## docker-compose.yml 基本结构

```yaml
version: '3.8'

services:
  # 服务名称
  web:
    # Docker 镜像
    image: nginx:1.25-alpine
    # 容器名
    container_name: my-web
    # 端口映射
    ports:
      - "80:80"
    # 环境变量
    environment:
      - NODE_ENV=production
    # 数据卷
    volumes:
      - ./html:/usr/share/nginx/html

  db:
    image: postgres:15
    container_name: my-db
    environment:
      - POSTGRES_PASSWORD=secret
    volumes:
      - db-data:/var/lib/postgresql/data

# 定义共享的数据卷
volumes:
  db-data:
```

## 核心指令

### version - 版本号
```yaml
version: '3.8'  # 推荐使用 3.8+
```

### services - 服务定义
```yaml
services:
  service_name:
    # 服务配置
```

### image - 镜像
```yaml
# 使用预构建镜像
image: nginx:1.25-alpine

# 或使用本地 Dockerfile
build: ./frontend/
```

### build - 构建镜像
```yaml
services:
  web:
    build:
      context: ./frontend
      dockerfile: Dockerfile
      args:
        - BUILD_DATE=2024-01-01
```

### container_name - 容器名
```yaml
container_name: my-web
```

### ports - 端口映射
```yaml
ports:
  - "80:80"           # 主机:容器
  - "8080:8080"
  - "127.0.0.1:8001:8001"  # 只对本地开放
```

### environment - 环境变量
```yaml
# 方式1：列表
environment:
  - NODE_ENV=production
  - PORT=3000

# 方式2：字典
environment:
  NODE_ENV: production
  PORT: 3000

# 方式3：.env 文件
env_file: .env
```

### volumes - 数据卷
```yaml
volumes:
  # 命名卷
  - db-data:/var/lib/postgresql/data
  
  # 绑定挂载（主机路径:容器路径）
  - ./config:/etc/config
  - ./logs:/app/logs:ro  # 只读

# 顶级 volumes 定义
volumes:
  db-data:
    driver: local
```

### depends_on - 依赖关系
```yaml
services:
  web:
    image: nginx
    depends_on:
      - db
  
  db:
    image: postgres
```

**注意：** 只保证启动顺序，不保证服务就绪

### links - 容器链接（已废弃）
```yaml
services:
  web:
    links:
      - db:database
```

**建议：** 使用 networks 替代

### networks - 网络配置
```yaml
services:
  web:
    networks:
      - frontend

  db:
    networks:
      - backend

networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge
```

### restart - 重启策略
```yaml
restart_policy:
  condition: on-failure
  max_attempts: 5

# 或简化写法
restart: always
```

## 完整示例：三层应用

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
      - DB_PASSWORD=secret
      - DB_NAME=hrdb
    volumes:
      - ./backend/logs:/app/logs

  # 数据库服务
  db:
    image: postgres:15
    container_name: hr-db
    networks:
      - app-network
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=secret
      - POSTGRES_DB=hrdb
    volumes:
      - db-data:/var/lib/postgresql/data
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql
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

## 常用命令

### 启动服务

```bash
# 后台启动
docker-compose up -d

# 重新构建并启动
docker-compose up --build -d

# 只启动某个服务
docker-compose up -d frontend
```

### 查看状态

```bash
# 查看运行的容器
docker-compose ps

# 查看日志
docker-compose logs

# 持续查看日志
docker-compose logs -f backend

# 查看最后 100 行
docker-compose logs --tail=100 backend
```

### 停止和删除

```bash
# 停止所有容器
docker-compose stop

# 停止并删除容器
docker-compose down

# 删除数据卷
docker-compose down -v

# 删除镜像
docker-compose down --rmi all
```

### 执行命令

```bash
# 在运行的容器中执行命令
docker-compose exec backend sh

# 在运行的容器中执行命令
docker-compose exec db psql -U postgres -d hrdb
```

### 进入容器

```bash
docker-compose exec backend bash
docker-compose exec db bash
```

## .env 文件

创建 `.env` 文件管理敏感信息：

```bash
# .env
POSTGRES_PASSWORD=secret123
POSTGRES_USER=admin
BACKEND_PORT=8081
```

在 `docker-compose.yml` 中使用：

```yaml
environment:
  - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
  - POSTGRES_USER=${POSTGRES_USER}
```

## 常见问题

### Q1：容器无法互联？
**A：** 确保它们在同一网络中，或使用 `depends_on` 和环境变量

### Q2：数据无法持久化？
**A：** 检查 volumes 配置是否正确

### Q3：端口被占用？
**A：** 修改端口映射或停止占用该端口的容器

### Q4：容器启动后立即退出？
**A：** 查看日志：`docker-compose logs backend`

## 部署到生产环境

### 检查清单

- [ ] 敏感信息放在 `.env` 文件中
- [ ] 使用固定的镜像版本号（不要用 `latest`）
- [ ] 配置健康检查
- [ ] 设置重启策略
- [ ] 配置资源限制
- [ ] 使用具名卷而非绑定挂载
- [ ] 备份数据库数据

### 生产环境最佳实践

```yaml
version: '3.8'

services:
  backend:
    image: myapp:1.0.0           # 固定版本
    deploy:
      replicas: 3                 # 副本数
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 256M
    restart_policy:
      condition: on-failure
      max_attempts: 5
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8081/health"]
      interval: 30s
      timeout: 10s
      retries: 3
```

## 下一步

学习完整的部署流程。参考：`04-deployment-process.md`
