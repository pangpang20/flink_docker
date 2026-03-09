-- 创建源表连接器，用于读取 MySQL 中的政府个人信息表
CREATE TABLE source_gov_person_info (
    id INT,
    name STRING,
    gender STRING,
    id_card STRING,
    birth_date DATE,
    -- 定义主键约束
    WATERMARK FOR birth_date AS birth_date
) WITH (
    'connector' = 'jdbc',
    'url' = 'jdbc:mysql://mysql:3306/gov_db',
    'table-name' = 'gov_person_info',
    'username' = 'flink_user',
    'password' = 'flink_password',
    'driver' = 'com.mysql.cj.jdbc.Driver'
);

-- 创建异议数据表连接器，用于存储性别字段不符合标准的数据
CREATE TABLE sink_invalid_gender (
    id INT,
    name STRING,
    gender STRING,
    id_card STRING,
    birth_date DATE,
    invalid_reason STRING,
    processed_time TIMESTAMP(3)
) WITH (
    'connector' = 'jdbc',
    'url' = 'jdbc:mysql://mysql:3306/gov_db',
    'table-name' = 'gov_person_invalid_gender',
    'username' = 'flink_user',
    'password' = 'flink_password',
    'driver' = 'com.mysql.cj.jdbc.Driver',
    -- 设置写入模式为 append，表示追加数据
    'sink.buffer-flush.max-rows' = '1000',
    'sink.buffer-flush.interval' = '2s'
);

-- 创建标准化结果表连接器，用于存储经过标准化处理的数据
CREATE TABLE sink_standardized_person (
    id INT,
    name STRING,
    gender STRING,
    id_card STRING,
    birth_date DATE,
    processed_time TIMESTAMP(3)
) WITH (
    'connector' = 'jdbc',
    'url' = 'jdbc:mysql://mysql:3306/gov_db',
    'table-name' = 'gov_person_standardized',
    'username' = 'flink_user',
    'password' = 'flink_password',
    'driver' = 'com.mysql.cj.jdbc.Driver',
    -- 设置写入性能优化参数
    'sink.buffer-flush.max-rows' = '1000',
    'sink.buffer-flush.interval' = '2s'
);

-- 第一步：数据质量稽查，筛选出性别字段不在标准范围内的记录
-- 标准范围定义为：'男','女','M','F' (大小写敏感)
-- 将不符合标准的记录写入异议表
INSERT INTO sink_invalid_gender
SELECT
    id,
    name,
    gender,
    id_card,
    birth_date,
    '性别字段不在标准范围内' AS invalid_reason,
    PROCTIME() AS processed_time
FROM source_gov_person_info
WHERE gender NOT IN ('男', '女', 'M', 'F');

-- 第二步：数据标准化处理，将性别字段转换为统一格式
-- 规则：'男'和'M'统一转换为'M'，'女'和'F'统一转换为'F'
-- 对于不符合标准的记录不进行转换，保持原值以便后续处理
INSERT INTO sink_standardized_person
SELECT
    id,
    name,
    CASE
        WHEN gender IN ('男', 'M') THEN 'M'      -- 男性统一转换为 'M'
        WHEN gender IN ('女', 'F') THEN 'F'      -- 女性统一转换为 'F'
        ELSE gender                              -- 其他情况保持原值
    END AS gender,
    id_card,
    birth_date,
    PROCTIME() AS processed_time
FROM source_gov_person_info;