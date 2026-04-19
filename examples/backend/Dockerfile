# 第一阶段：编译
FROM golang:1.21-alpine AS builder

WORKDIR /app

# 设置 go mod 代理加速
RUN go env -w GO111MODULE=on && \
    go env -w GOPROXY=https://goproxy.cn,direct

# 复制源代码
COPY . .

# 编译二进制文件
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o hr_backend .

# 第二阶段：运行时
FROM alpine:3.18

WORKDIR /app

# 安装必要的工具
RUN apk add --no-cache ca-certificates

# 从编译阶段复制二进制文件
COPY --from=builder /app/hr_backend .

# 暴露端口
EXPOSE 8081

# 启动应用
CMD ["./hr_backend"]
