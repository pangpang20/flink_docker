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

## 详细使用说明

### 1. 环境准备

在开始之前，请确保您的系统已安装以下软件：

- Docker (版本 20.10.0 或更高)
- Docker Compose (版本 2.0.0 或更高)
- Git

### 2. 项目克隆与初始化

```bash
# 克隆项目
git clone <repository-url>
cd flink_docker

# 创建必要的目录结构
mkdir -p lib
mkdir -p data

# 下载必要的 Flink 连接器
# 下载 Flink JDBC 连接器到 lib 目录
wget -P lib/ https://repo.maven.apache.org/maven2/org/apache/flink/flink-connector-jdbc/3.1.1-1.17/flink-connector-jdbc-3.1.1-1.17.jar
wget -P lib/ https://repo.maven.apache.org/maven2/mysql/mysql-connector-java/8.0.33/mysql-connector-java-8.0.33.jar
```

### 3. 启动服务

```bash
# 启动所有服务
cd docker && docker-compose up -d

# 检查服务状态
docker-compose ps
```

### 4. Flink Web UI 使用

Flink Web UI 提供了图形界面来监控和管理 Flink 作业：

- 访问地址：http://localhost:8081
- 可以在此界面提交、管理和监控 Flink 作业
- 查看任务执行详情和性能指标

### 5. 数据库访问

MySQL 数据库提供存储处理后的数据：

- 地址：localhost:3306
- 用户名：flinkuser
- 密码：flinkpass
- 数据库名：flink_database

### 6. 执行数据处理任务

#### 方法一：通过 Flink SQL Client

```bash
# 进入 Flink 容器
docker exec -it docker_taskmanager_1 /bin/bash

# 切换到 Flink 目录并启动 SQL Client
cd $FLINK_HOME
./bin/sql-client.sh -j /lib/flink-connector-jdbc_2.12-3.1.1-1.17.jar -j /lib/mysql-connector-java-8.0.33.jar
```

在 SQL Client 中执行 SQL 脚本：

```sql
-- 从源表读取原始数据
CREATE TABLE source_person_data (
    id BIGINT,
    name STRING,
    age INT,
    gender STRING,
    phone STRING,
    email STRING,
    address STRING,
    birthday DATE,
    create_time TIMESTAMP(3),
    update_time TIMESTAMP(3)
) WITH (
    'connector' = 'jdbc',
    'url' = 'jdbc:mysql://mysql:3306/flink_database',
    'table-name' = 'raw_person_data',
    'username' = 'flinkuser',
    'password' = 'flinkpass',
    'driver' = 'com.mysql.cj.jdbc.Driver'
);

-- 创建目标表存储标准化后的数据
CREATE TABLE standardized_person_data (
    id BIGINT,
    standardized_name STRING,
    standardized_age INT,
    standardized_gender STRING,
    standardized_phone STRING,
    standardized_email STRING,
    standardized_address STRING,
    standardized_birthday DATE,
    processed_time TIMESTAMP(3) DEFAULT CURRENT_TIMESTAMP
) WITH (
    'connector' = 'jdbc',
    'url' = 'jdbc:mysql://mysql:3306/flink_database',
    'table-name' = 'standardized_person_data',
    'username' = 'flinkuser',
    'password' = 'flinkpass',
    'driver' = 'com.mysql.cj.jdbc.Driver'
);

-- 执行数据转换处理
INSERT INTO standardized_person_data
SELECT
    id,
    UPPER(TRIM(name)) AS standardized_name,
    CASE
        WHEN age < 0 OR age > 150 THEN NULL
        ELSE age
    END AS standardized_age,
    CASE
        WHEN LOWER(gender) LIKE '%男%' OR LOWER(gender) = 'm' OR LOWER(gender) = '1' THEN 'M'
        WHEN LOWER(gender) LIKE '%女%' OR LOWER(gender) = 'f' OR LOWER(gender) = '0' THEN 'F'
        ELSE 'U'
    END AS standardized_gender,
    REGEXP_REPLACE(phone, '[^0-9]', '') AS standardized_phone,
    LOWER(TRIM(email)) AS standardized_email,
    TRIM(address) AS standardized_address,
    CASE
        WHEN birthday IS NULL THEN NULL
        WHEN birthday > CURRENT_DATE THEN NULL
        ELSE birthday
    END AS standardized_birthday,
    CURRENT_TIMESTAMP AS processed_time
FROM source_person_data;
```

#### 方法二：通过预定义的 SQL 脚本

执行预先写好的 SQL 处理脚本：

```bash
# 将 SQL 脚本复制到容器内部
docker cp ../sql/person_standardization.sql docker_taskmanager_1:/tmp/person_standardization.sql

# 在 Flink 容器内执行 SQL 脚本
docker exec -it docker_taskmanager_1 /opt/flink/bin/sql-client.sh -f /tmp/person_standardization.sql
```

### 7. 如何查看数据

#### 方式一：直接连接数据库查看

您可以使用任何 MySQL 客户端连接到数据库查看处理后的数据：

```bash
# 使用命令行连接
mysql -h localhost -P 3306 -u flinkuser -pflinkpass flink_database

# 在 MySQL 客户端中查询数据
SHOW TABLES;
SELECT * FROM standardized_person_data LIMIT 10;
SELECT COUNT(*) FROM standardized_person_data;
```

#### 方式二：通过 Flink SQL Client 查看

在 Flink SQL Client 中执行查询语句：

```sql
-- 查询处理后的数据
SELECT * FROM standardized_person_data LIMIT 10;

-- 统计数据量
SELECT COUNT(*) FROM standardized_person_data;

-- 查看特定条件的数据
SELECT * FROM standardized_person_data
WHERE standardized_gender = 'M'
LIMIT 20;
```

#### 方式三：查看原始数据对比

```sql
-- 对比原始数据与标准化后数据
SELECT
    r.name AS original_name,
    s.standardized_name,
    r.phone AS original_phone,
    s.standardized_phone,
    r.gender AS original_gender,
    s.standardized_gender
FROM raw_person_data r
JOIN standardized_person_data s ON r.id = s.id
LIMIT 10;
```

#### 方式四：使用可视化工具

您也可以使用数据库可视化工具（如 MySQL Workbench、DBeaver、Navicat 等）连接数据库进行数据查看和分析：

1. 连接参数：
   - 主机：localhost
   - 端口：3306
   - 用户名：flinkuser
   - 密码：flinkpass
   - 数据库：flink_database

2. 在工具中打开相应的数据表进行浏览和查询

### 8. 停止和清理服务

```bash
# 停止服务
cd docker && docker-compose down

# 停止服务并删除数据卷（警告：这会清除所有数据）
cd docker && docker-compose down -v

# 查看日志
docker-compose logs -f
```

## 注意事项

- 确保系统有足够的内存资源（推荐 4GB+）
- 数据库密码请在生产环境中使用更安全的设置
- 定期备份处理结果数据
- 监控 Flink 任务执行状态，确保数据处理正常
