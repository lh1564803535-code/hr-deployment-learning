# Docker 基础知识

## 什么是 Docker？

Docker 是一个**容器化平台**，可以把应用及其依赖打包成一个独立的"容器"。

### 核心概念

#### 1. **镜像（Image）**
- 应用的蓝图/模板
- 包含代码、依赖、配置
- 可以上传到 Docker Hub
- 不可变的、只读的

#### 2. **容器（Container）**
- 镜像的运行实例
- 独立的、隔离的执行环境
- 每个容器都是独立的
- 可以随时创建、启动、停止、删除

#### 3. **仓库（Registry）**
- 存放镜像的地方
- Docker Hub 是官方仓库
- 可以创建私有仓库

### 为什么要用 Docker？

✅ **一致性** - 开发、测试、生产环境完全一致  
✅ **快速部署** - 秒级启动应用  
✅ **资源高效** - 比虚拟机轻量得多  
✅ **易于扩展** - 快速创建多个容器副本  
✅ **依赖隔离** - 不同应用的依赖互不影响  
✅ **版本控制** - 镜像版本化管理

## Docker 架构

```
┌─────────────────────────────────────┐
│         Docker Client CLI           │
└──────────────┬──────────────────────┘
               │ (docker build/run)
┌──────────────▼──────────────────────┐
│        Docker Daemon (server)       │
│  - Container Management             │
│  - Image Management                 │
│  - Network Management               │
└──────────────┬──────────────────────┘
               │
       ┌───────┴────────┐
       │                │
   ┌───▼───┐      ┌───▼────┐
   │ Image │      │Container│
   └───────┘      └────────┘
```

## 常用命令

| 命令 | 作用 |
|------|------|
| `docker ps` | 查看运行中的容器 |
| `docker ps -a` | 查看所有容器 |
| `docker images` | 查看本地镜像 |
| `docker build -t 镜像名 .` | 构建镜像 |
| `docker run -p 80:80 镜像名` | 运行容器 |
| `docker logs 容器名` | 查看容器日志 |
| `docker stop 容器名` | 停止容器 |
| `docker rm 容器名` | 删除容器 |
| `docker exec -it 容器名 bash` | 进入容器 |

## 实战示例

### 1. 拉取官方镜像
```bash
# 拉取 nginx 镜像
docker pull nginx:1.25-alpine

# 查看镜像
docker images
```

### 2. 运行一个容器
```bash
# 后台运行 nginx，访问本地 80 端口映射到容器 80 端口
docker run -d -p 80:80 --name my-nginx nginx:1.25-alpine

# 查看容器
docker ps

# 访问
curl http://localhost
```

### 3. 查看容器日志
```bash
docker logs -f my-nginx
```

### 4. 停止和删除容器
```bash
docker stop my-nginx
docker rm my-nginx
```

## 镜像分层原理

Docker 镜像是分层的，每个指令都创建一个新的层：

```dockerfile
FROM ubuntu:20.04           # 第1层：基础镜像
RUN apt-get update          # 第2层：执行命令
RUN apt-get install -y curl # 第3层：执行命令
COPY app.py /app/           # 第4层：复制文件
CMD ["python", "app.py"]    # 第5层：启动命令
```

**优势：**
- 缓存复用：不变的层不需要重新构建
- 存储优化：相同的层只存储一次
- 快速部署：基础层可以被多个镜像共享

## 网络隔离

Docker 容器有自己的网络命名空间：

```bash
# 每个容器都有独立的网络
docker run -d --name container1 nginx
docker run -d --name container2 nginx

# 可以通过容器名通信
docker exec container1 ping container2

# 映射端口到宿主机
docker run -d -p 8080:80 nginx
```

## 存储卷

Docker 有两种方式持久化数据：

### 1. Volumes（推荐）
```bash
docker volume create my-volume
docker run -d -v my-volume:/data nginx
```

### 2. Bind Mounts
```bash
docker run -d -v /host/path:/container/path nginx
```

## 下一步

学习如何编写 Dockerfile 来构建自己的镜像。参考：`02-dockerfile-guide.md`
