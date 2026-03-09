# Flink Docker 部署指南 - 网络问题解决方案

## 问题描述
在尝试启动 Flink 和 MySQL 容器时遇到网络超时问题：
```
Error Get "https://registry-1.docker.io/v2/": dial tcp 157.240.0.35:443: i/o timeout
```

## 解决方案

### 1. 配置 Docker 镜像加速器
为了加速镜像下载并避免网络超时，建议配置国内镜像加速器：

```bash
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<EOF
{
  "registry-mirrors": [
    "https://hub-mirror.c.163.com",
    "https://docker.mirrors.ustc.edu.cn",
    "https://mirror.baidubce.com"
  ]
}
EOF

sudo systemctl restart docker
```

### 2. 手动预拉取所需镜像
在配置好镜像加速器后，手动拉取所需镜像：

```bash
docker pull mysql:8.0
docker pull flink:1.17.1-scala_2.12-java8
```

### 3. 启动服务
配置完成后，在项目目录中执行：

```bash
cd /opt/flink_docker/docker
docker compose up -d
```

### 4. 验证部署
验证服务是否正常运行：

```bash
# 检查容器状态
docker compose ps

# 查看日志
docker compose logs mysql
docker compose logs jobmanager
docker compose logs taskmanager

# 验证 MySQL 连接
docker exec -it mysql-server mysql -u flink_user -p gov_db -e "SHOW TABLES;"

# 验证 Flink Web UI 可访问
curl -I http://localhost:8081
```

### 5. 执行 Flink SQL 任务
一旦所有服务正常运行，可以执行数据处理任务：

```bash
# 进入 JobManager 容器
docker exec -it flink-jobmanager bash

# 运行 SQL 脚本
./bin/sql-client.sh -f /opt/flink/sql/process_person_data.sql
```

## 项目状态
所有配置文件、SQL 脚本和初始化数据均已准备就绪：
- `/opt/flink_docker/docker/docker-compose.yml` - Docker Compose 配置
- `/opt/flink_docker/init/init.sql` - MySQL 初始化脚本
- `/opt/flink_docker/sql/process_person_data.sql` - Flink SQL 处理逻辑
- `/opt/flink_docker/lib/` - 包含必要的连接器 JAR 包