# Flink Government Person Info Processing

基于 Flink 的政府个人信息处理系统，用于数据质量稽查和标准化转换。

## 项目背景

政府信息系统中存在大量个人信息数据，由于历史原因和录入规范不一致，导致数据格式不统一。本项目旨在构建一个高效的数据处理系统，实现对个人基本信息的标准化处理。

## 技术栈

- Apache Flink 1.17.1
- MySQL 8.0
- Docker & Docker Compose
- Java 8+

## 目录结构

```
.
├── docker/                 # Docker 相关配置
├── init/                   # 数据库初始化脚本
├── sql/                    # Flink SQL 脚本
├── lib/                    # 依赖 JAR 包
└── data/                   # 数据持久化目录
```

## 快速启动

1. 克隆仓库并进入项目目录
2. 创建必要的目录结构
3. 下载 Flink JDBC 连接器 JAR 包到 lib 目录
4. 启动服务：`cd docker && docker-compose up -d`
5. 执行 SQL 处理逻辑
6. 验证结果

## 注意事项

- 确保系统有足够的内存资源（推荐 4GB+）
- 数据库密码请在生产环境中使用更安全的设置
- 定期备份处理结果数据
- 监控 Flink 任务执行状态，确保数据处理正常
