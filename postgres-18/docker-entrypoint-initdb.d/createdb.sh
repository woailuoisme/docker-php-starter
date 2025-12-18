#!/usr/bin/env bash

#
# Copy createdb.sh.example to createdb.sh
# then uncomment then set database name and username to create you need databases
#
# example: .env POSTGRES_USER=appuser and need db name is myshop_db
#
#    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
#        CREATE USER myuser WITH PASSWORD 'mypassword';
#        CREATE DATABASE myshop_db;
#        GRANT ALL PRIVILEGES ON DATABASE myshop_db TO myuser;
#    EOSQL
#
# this sh script will auto run when the postgres container starts and the $DATA_PATH_HOST/postgres not found.
#
#

#psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
#	CREATE USER docker;
#	CREATE DATABASE docker;
#	GRANT ALL PRIVILEGES ON DATABASE docker TO docker;
#EOSQL

# 创建 lunchbox 数据库
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE DATABASE lunchbox;
    GRANT ALL PRIVILEGES ON DATABASE lunchbox TO $POSTGRES_USER;
EOSQL

# 为 lunchbox 数据库启用 PostGIS 扩展
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "lunchbox" <<-EOSQL
    CREATE EXTENSION IF NOT EXISTS uuid-ossp;
    CREATE EXTENSION IF NOT EXISTS vector;
    CREATE EXTENSION IF NOT EXISTS postgis;
    CREATE EXTENSION IF NOT EXISTS postgis_topology;
    CREATE EXTENSION IF NOT EXISTS postgis_raster;
    CREATE EXTENSION IF NOT EXISTS fuzzystrmatch;
EOSQL

# 创建 shop 数据库
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE DATABASE shop;
    GRANT ALL PRIVILEGES ON DATABASE shop TO $POSTGRES_USER;
EOSQL

# 为 shop 数据库启用 PostGIS 扩展
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "shop" <<-EOSQL
    CREATE EXTENSION IF NOT EXISTS postgis;
    CREATE EXTENSION IF NOT EXISTS postgis_topology;
    CREATE EXTENSION IF NOT EXISTS postgis_raster;
    CREATE EXTENSION IF NOT EXISTS fuzzystrmatch;
EOSQL

# 创建 domost 数据库
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE DATABASE domost;
    GRANT ALL PRIVILEGES ON DATABASE domost TO $POSTGRES_USER;
EOSQL

# 创建 authelia 数据库
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE DATABASE authelia;
    GRANT ALL PRIVILEGES ON DATABASE authelia TO $POSTGRES_USER;
EOSQL

# 注意：默认数据库 ($POSTGRES_DB) 的 PostGIS 扩展已在前面安装
# 这里不再重复安装
