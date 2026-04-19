# 📅 每日学习日志

## 2026-04-19（第1天）

### ✅ 今天完成
- ✓ Docker 基础概念学习
- ✓ 镜像（Image）和容器（Container）的区别
- ✓ 创建学习仓库
- ✓ 推送到 GitHub

### 📝 学习重点
**Docker 三大核心概念：**
1. **镜像（Image）** - 应用的蓝图，包含代码和依赖
2. **容器（Container）** - 镜像的运行实例，隔离的环境
3. **仓库（Registry）** - 存放镜像的地方，如 Docker Hub

**关键命令：**
```bash
docker images           # 查看镜像
docker ps              # 查看容器
docker pull nginx      # 拉取镜像
docker run nginx       # 运行容器
```

### 🎯 心得体会
- Docker 的核心思想就是"一次构建，处处运行"
- 容器比虚拟机轻量级得多，启动速度秒级
- 镜像是分层的，这样可以提高复用性和存储效率

### 🐛 遇到的问题
1. **权限问题** - `Permission denied: /var/run/docker.sock`
   - ✅ 解决：用户添加到 docker 组
   ```bash
   sudo usermod -aG docker $USER
   newgrp docker
   ```

### ⏳ 明天计划
- [ ] Dockerfile 基础学习
- [ ] 编写第一个 Dockerfile
- [ ] 用 docker build 构建镜像
- [ ] 运行自己构建的容器

---

## 2026-04-20（第2天）

### ✅ 今天完成
- ✓ Dockerfile 基础学习
- ✓ 编写前端 Dockerfile
- ✓ 编写后端 Dockerfile

### 📝 学习重点
**Dockerfile 核心指令：**

| 指令 | 作用 | 例子 |
|-----|------|------|
| FROM | 基础镜像 | FROM nginx:1.25 |
| RUN | 执行命令 | RUN apt-get install curl |
| COPY | 复制文件 | COPY app.js /app/ |
| EXPOSE | 声明端口 | EXPOSE 80 |
| CMD | 启动命令 | CMD ["nginx", "-g", "daemon off;"] |

**最佳实践：**
- 使用轻量级基础镜像（alpine）
- 合并 RUN 命令减少镜像层数
- 先复制依赖文件，再复制代码

### 🎯 心得体会
- 每条 Dockerfile 指令都会创建一个新层
- 镜像大小很关键，alpine 镜像只有几十 MB
- 多阶段构建可以显著减小最终镜像

### 🐛 遇到的问题
1. **镜像构建失败** - `COPY failed: file not found`
   - ✅ 解决：检查相对路径，文件必须在 Dockerfile 同级目录

### ⏳ 明天计划
- [ ] Docker Compose 学习
- [ ] 编写 docker-compose.yml
- [ ] 一键启动三层应用

---

## 2026-04-19（第1天 - 自动打卡演示）

### ✅ 今天完成
- ✓ Docker基础概念学习
- ✓ GitHub仓库创建和配置
- ✓ 详细学习文档编写
- ✓ 自动化打卡脚本开发
- ✓ 完整的项目骨架搭建

### 📝 学习重点
**Docker 核心三概念:**
1. 镜像（Image）- 应用蓝图
2. 容器（Container）- 运行实例  
3. 仓库（Registry）- 镜像存放地

**关键命令速查:**
```bash
docker images              # 查看镜像
docker ps -a              # 查看容器
docker pull nginx          # 拉取镜像
docker run -d nginx        # 运行容器
docker logs container-id   # 查看日志
```

### 🎯 心得体会
- Docker 的核心思想"一次构建，处处运行"非常强大
- 比起虚拟机，Docker 容器轻量级得多，启动速度秒级
- 镜像分层设计提高了复用性和存储效率
- GitHub 打卡机制很好地监督学习进度

### 🐛 遇到的问题
1. **目录权限问题** - 创建项目时权限不足
   - ✅ 解决：使用用户主目录而非 D:\MyProjects
   
2. **PowerShell 编码问题** - 脚本中 Emoji 显示乱码
   - ✅ 解决：创建简化的批处理版本

### ⏳ 明天计划
- [ ] 学习 Dockerfile 编写
- [ ] 编写前端和后端镜像
- [ ] 实践本地镜像构建和运行

---

## 🔄 如何使用这个文件

每天学完后，按照以下步骤更新：

1. 编辑这个文件，添加你的学习内容
2. 记录完成、重点、心得、问题、明天计划
3. 提交和推送到 GitHub

```bash
git add learning-notes/daily-notes.md
git commit -m "📚 Day N: [学习内容总结]"
git push origin main
```

---

## 📊 学习统计

- 📈 总学习天数：2 天
- 📚 完成章节：Docker 基础 + Dockerfile
- 🎯 下一个目标：Docker Compose
