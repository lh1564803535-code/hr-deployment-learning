FROM nginx:1.25-alpine

# 设置镜像源（可选，用于加速）
RUN echo "https://mirrors.aliyun.com/alpine/v3.18/main" > /etc/apk/repositories && \
    echo "https://mirrors.aliyun.com/alpine/v3.18/community" >> /etc/apk/repositories

# 安装必要工具
RUN apk add --no-cache ca-certificates && \
    rm -rf /usr/share/nginx/html/*

# 复制 nginx 配置文件
COPY nginx.conf /etc/nginx/nginx.conf

# 复制前端文件（假设是 tar 包）
COPY dist.tar /tmp/

# 解压并设置权限
RUN cd /usr/share/nginx/html && \
    tar -xf /tmp/dist.tar && \
    rm /tmp/dist.tar && \
    chown -R nginx:nginx /usr/share/nginx/html && \
    chmod -R 755 /usr/share/nginx/html

# 暴露端口
EXPOSE 80

# 启动 nginx
CMD ["nginx", "-g", "daemon off;"]
