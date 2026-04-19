# HR 系统 Docker 容器化部署学习记录

## 📚 项目简介

这是一个关于 **Docker 容器化部署**的完整学习项目。  
通过部署一个真实的三层应用（前端 + 后端 + 数据库），从零到一学会容器化技术。

## 🎯 学习目标

- ✅ 理解 Docker 的核心概念
- ✅ 学会编写 Dockerfile
- ✅ 掌握 docker-compose 多容器编排
- ✅ 完成一个真实应用的容器化部署
- ✅ 学会常见的故障排查方法

## 📂 项目结构

### 文档（Docs）
- `01-docker-basics.md` - Docker 基础知识
- `02-dockerfile-guide.md` - 如何编写 Dockerfile
- `03-docker-compose-guide.md` - docker-compose 配置指南
- `04-deployment-process.md` - 完整部署流程演示

### 实例代码（Examples）
- `frontend/Dockerfile` - Nginx 前端镜像
- `backend/Dockerfile` - Go 后端镜像
- `docker-compose.yml` - 完整容器编排配置

### 学习笔记（Learning Notes）
- `troubleshooting.md` - 常见问题和解决方案

## 🚀 快速开始

### 前提条件
- Docker 已安装
- docker-compose 已安装
- Linux 服务器或虚拟机

### 部署步骤

1. **克隆仓库**
```bash
git clone https://github.com/你的用户名/hr-deployment-learning.git
cd hr-deployment-learning
```

2. **准备文件**
```bash
mkdir -p {backend,frontend,database}
# 复制你的文件到相应目录
```

3. **启动应用**
```bash
docker-compose up --build -d
```

4. **访问应用**
```
http://localhost
用户名：admin
密码：admin123
```

## 📖 学习内容概览

### Docker 核心概念
- **镜像（Image）** - 打包的应用模板
- **容器（Container）** - 运行中的镜像实例
- **Dockerfile** - 镜像构建脚本
- **docker-compose** - 多容器编排工具

### 关键命令速查
```bash
# 构建镜像
docker build -t image-name .

# 运行容器
docker run -p 80:80 image-name

# 查看容器
docker ps -a

# 启动 compose
docker-compose up --build -d

# 查看日志
docker-compose logs -f
```

## 💡 学习心得

### 遇到的问题和解决方案
- **权限问题** → chmod 777
- **文件找不到** → 检查目录结构
- **版本不兼容** → 修改 compose 版本号
- **构建失败** → 查看 COPY 路径

## 🎓 下一步学习路线

- 📦 Kubernetes（K8s）- 高级容器编排
- 🔄 CI/CD 流程 - 自动化构建和部署
- ⚡ Docker 镜像优化 - 减小镜像大小
- 📊 容器监控 - Prometheus + Grafana
- 🏢 私有镜像仓库 - Docker Registry

## 📞 关键资源

- [Docker 官方文档](https://docs.docker.com/)
- [docker-compose 官方文档](https://docs.docker.com/compose/)
- [Dockerfile 最佳实践](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)

## 📝 许可证

MIT License

---

⭐ **如果这个项目对你有帮助，请 Star 一下！**
