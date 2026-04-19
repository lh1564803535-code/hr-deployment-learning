# Docker 常见问题排查指南

## 容器相关问题

### 问题 1：容器无法启动

**症状：** `docker-compose up` 后容器立即退出

**排查步骤：**

```bash
# 查看容器日志
docker-compose logs backend

# 查看详细错误信息
docker-compose up backend

# 检查 Dockerfile 是否有错误
docker build -t test-image .
```

**常见原因：**
- ❌ 基础镜像不存在
- ❌ 启动命令错误
- ❌ 依赖文件不存在
- ❌ 权限不足

**解决方案：**
- ✅ 检查 Dockerfile 中的 FROM 是否正确
- ✅ 检查 CMD/ENTRYPOINT 是否正确
- ✅ 检查 COPY 的文件是否存在
- ✅ 使用 RUN chmod 改权限

---

### 问题 2：容器启动后立即停止

**症状：** `docker ps` 看不到容器，但 `docker ps -a` 能看到

**排查步骤：**

```bash
# 查看停止原因
docker logs container-name

# 查看容器详细信息
docker inspect container-name

# 用 --rm 参数前台运行查看输出
docker run -it --rm myapp:1.0
```

**常见原因：**
- ❌ 启动命令执行失败
- ❌ 应用直接退出
- ❌ 找不到依赖库

**解决方案：**
- ✅ 查看日志了解退出原因
- ✅ 检查是否缺少依赖
- ✅ 使用 `sleep infinity` 临时保活调试

---

### 问题 3：容器持续重启

**症状：** 容器启动后不断重启，`docker ps` 中状态不稳定

**排查步骤：**

```bash
# 查看容器重启日志
docker logs --tail=50 container-name

# 查看重启次数
docker inspect container-name | grep RestartCount

# 禁用自动重启临时调试
docker update --restart=no container-name
```

**常见原因：**
- ❌ 应用进程异常退出
- ❌ 健康检查失败
- ❌ 内存不足导致 OOM

**解决方案：**
- ✅ 查看应用日志了解异常
- ✅ 调整健康检查参数
- ✅ 增加容器内存限制

---

## 网络相关问题

### 问题 4：前后端容器无法通信

**症状：** 前端无法访问后端 API，返回 `Connection refused`

**排查步骤：**

```bash
# 进入前端容器测试连接
docker-compose exec frontend curl http://backend:8081

# 进入前端容器 ping 后端
docker-compose exec frontend ping backend

# 查看网络配置
docker network inspect app-network

# 检查防火墙
docker-compose exec backend telnet localhost 8081
```

**常见原因：**
- ❌ 容器不在同一网络中
- ❌ 后端容器未启动
- ❌ 后端服务未监听正确端口
- ❌ 容器间通信被阻止

**解决方案：**
- ✅ 检查 docker-compose.yml 的 networks 配置
- ✅ 确保所有容器在同一网络
- ✅ 使用容器名而非 localhost
- ✅ 检查防火墙规则

---

### 问题 5：无法从主机访问容器

**症状：** `localhost:8081` 无法访问后端服务

**排查步骤：**

```bash
# 检查端口映射
docker-compose ps

# 检查容器是否监听该端口
docker-compose exec backend netstat -tlnp

# 从主机检查端口
netstat -tlnp | grep 8081
ss -tlnp | grep 8081

# 测试连接
curl http://127.0.0.1:8081
curl http://localhost:8081
```

**常见原因：**
- ❌ 端口映射配置错误
- ❌ 容器内应用未监听端口
- ❌ 防火墙阻止了访问
- ❌ 端口被其他进程占用

**解决方案：**
- ✅ 检查 `docker-compose.yml` 的 ports 配置
- ✅ 检查应用是否真正监听该端口
- ✅ 检查防火墙规则：`sudo ufw status`
- ✅ 释放占用的端口

```bash
# 查找占用端口的进程
sudo lsof -i :8081

# 杀死进程
sudo kill -9 <PID>
```

---

## 数据卷和存储问题

### 问题 6：数据无法持久化

**症状：** 容器删除后数据丢失

**排查步骤：**

```bash
# 检查数据卷
docker volume ls

# 查看数据卷详情
docker volume inspect db-data

# 检查容器的数据卷挂载
docker inspect container-name | grep -A 10 Mounts
```

**常见原因：**
- ❌ 忘记配置 volumes
- ❌ 数据卷挂载路径不对
- ❌ 数据库未正确保存到数据卷

**解决方案：**
- ✅ 在 docker-compose.yml 中配置 volumes
- ✅ 使用具名卷而非绑定挂载
- ✅ 备份重要数据

```bash
# 备份数据卷
docker run --rm -v db-data:/data -v $(pwd):/backup \
  alpine tar czf /backup/backup.tar.gz -C /data .
```

---

### 问题 7：权限问题：Permission denied

**症状：** 容器无法读写文件，报 `Permission denied`

**排查步骤：**

```bash
# 查看文件权限
ls -la ./data/

# 进入容器查看文件权限
docker-compose exec backend ls -la /app/

# 查看容器运行用户
docker-compose exec backend whoami

# 查看容器内文件所有者
docker-compose exec backend ls -n /app/
```

**常见原因：**
- ❌ 宿主机文件权限不足
- ❌ 容器运行用户没有权限
- ❌ 数据卷挂载时权限不匹配

**解决方案：**
- ✅ 修改宿主机文件权限
```bash
chmod 777 ./data/
```

- ✅ 修改 Dockerfile，以正确用户运行
```dockerfile
RUN adduser -D -u 1000 app
USER app
```

- ✅ 在 docker-compose.yml 中指定用户
```yaml
user: "1000:1000"
```

---

## 性能和资源问题

### 问题 8：容器 CPU/内存占用过高

**症状：** 系统变慢，容器占用大量资源

**排查步骤：**

```bash
# 查看所有容器的资源占用
docker stats

# 查看特定容器的详细信息
docker inspect container-name | grep -A 10 HostConfig

# 查看历史资源使用
docker container ls --format "table {{.ID}}\t{{.Names}}\t{{.Status}}" --all
```

**常见原因：**
- ❌ 应用无限循环或内存泄漏
- ❌ 容器资源限制设置太高
- ❌ 日志文件过大

**解决方案：**
- ✅ 限制容器资源
```yaml
services:
  backend:
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
```

- ✅ 清理日志
```bash
docker exec container-name sh -c 'truncate -s 0 /var/log/app.log'
```

---

### 问题 9：磁盘空间不足

**症状：** Docker 报错说磁盘满了

**排查步骤：**

```bash
# 查看 Docker 占用空间
docker system df

# 查看所有镜像大小
docker images --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}"

# 查看所有容器
docker ps -a

# 查看所有数据卷
docker volume ls
```

**解决方案：**
- ✅ 删除未使用的镜像
```bash
docker image prune -a
```

- ✅ 删除未使用的容器
```bash
docker container prune
```

- ✅ 删除未使用的数据卷
```bash
docker volume prune
```

- ✅ 一次性清理所有未使用的资源
```bash
docker system prune -a --volumes
```

---

## 日志和调试

### 查看日志的完整指南

```bash
# 查看所有服务的日志
docker-compose logs

# 查看特定服务的日志
docker-compose logs backend

# 实时查看日志（类似 tail -f）
docker-compose logs -f backend

# 查看最后 100 行
docker-compose logs --tail=100 backend

# 查看最近 1 小时的日志
docker-compose logs --since 1h backend

# 带时间戳
docker-compose logs -t backend

# 输出到文件
docker-compose logs backend > backend.log 2>&1
```

### 进入容器调试

```bash
# 进入正在运行的容器
docker-compose exec backend bash

# 查看进程
ps aux

# 查看网络连接
netstat -tlnp
ss -tlnp

# 查看环境变量
env | grep DB

# 执行单个命令
docker-compose exec backend curl http://localhost:8081/health
```

---

## 快速修复命令速查

```bash
# 重启所有服务
docker-compose restart

# 重启特定服务
docker-compose restart backend

# 重新构建并启动
docker-compose up -d --build

# 完全清理并重新开始
docker-compose down -v
docker-compose up -d --build

# 查看配置是否有错误
docker-compose config

# 测试数据库连接
docker-compose exec backend pg_isready -h db -U postgres

# 导出日志以便分享给他人
docker-compose logs > debug.log
```

---

## 总结

| 问题类型 | 常用命令 |
|---------|---------|
| 查看日志 | `docker-compose logs -f service-name` |
| 进入容器 | `docker-compose exec service-name bash` |
| 查看资源 | `docker stats` |
| 检查网络 | `docker-compose exec service-name ping other-service` |
| 清理资源 | `docker system prune -a` |
| 完全重启 | `docker-compose down -v && docker-compose up -d` |

记住：**大多数问题都可以通过查看日志来解决！** 🎯
