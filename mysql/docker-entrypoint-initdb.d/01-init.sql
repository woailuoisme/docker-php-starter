-- MySQL 初始化脚本
-- 此脚本在容器首次启动时自动执行

-- 创建示例数据库（可选）
-- CREATE DATABASE IF NOT EXISTS lunchbox CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 创建应用用户（建议使用环境变量配置）
-- CREATE USER IF NOT EXISTS 'appuser'@'%' IDENTIFIED BY 'your_password_here';
-- GRANT ALL PRIVILEGES ON lunchbox.* TO 'appuser'@'%';

-- 刷新权限
-- FLUSH PRIVILEGES;

-- 显示配置信息
-- SELECT 'MySQL 初始化完成' AS status;

CREATE DATABASE IF NOT EXISTS lunchbox CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
