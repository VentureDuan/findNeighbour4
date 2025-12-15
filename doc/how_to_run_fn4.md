## 总览

本文档说明如何在一台新服务器上部署、启动并验证 **findNeighbour4（fn4）** 服务，以及如何通过命令行客户端进行简单访问。

假设代码路径为 `/data/luanjingjie/software/findNeighbour4`，如有不同请自行替换。

---

## 环境准备

### 必要组件

- **操作系统**: Linux（推荐 Ubuntu / Debian 系列）
- **运行环境**:
  - Python 3.9（通过 pipenv 使用）
  - `pipenv`
  - MongoDB（本地地址 `mongodb://127.0.0.1`）
  - C/C++ 编译工具、`cmake`（用于 catwalk 等组件）

Python 依赖由 `Pipfile` 统一管理，其中包括：

- `networkit`
- `bokeh==2.4.3`
- 以及其他 fn4 所需库

### 1. 安装系统依赖（以 Ubuntu 为例）

```bash
sudo apt-get update
sudo apt-get install -y build-essential cmake git \
    python3.9 python3.9-dev python3-pip \
    libomp-dev
```

### 2. 安装并启动 MongoDB

详细说明见项目内 `doc/mongoinstall.md`。这里给出一个简单示例（以系统自带包为例，具体以官方文档为准）：

```bash
sudo apt-get install -y mongodb
sudo systemctl enable mongod
sudo systemctl start mongod

# 简单检查
mongo --eval 'db.runCommand({ ping: 1 })'
```

确保 MongoDB 在 `127.0.0.1:27017` 正常监听，fn4 默认使用 `mongodb://127.0.0.1`。

---

## 创建虚拟环境并安装依赖

### 1. 进入项目目录

```bash
cd /data/luanjingjie/software/findNeighbour4
```

### 2. 使用安装脚本安装依赖

项目提供自动安装脚本 `fn4_install_deps.sh`，会在后台执行：

```bash
pipenv install -e . --skip-lock --python 3.9
```

并将输出写入日志：

```bash
./fn4_install_deps.sh
```

- **日志文件**: `pipenv_install.log`
- **进程 PID 文件**: `pipenv_install.pid`

查看安装进度：

```bash
tail -f pipenv_install.log
```

### 3. 检查关键依赖（networkit）

使用提供的检查脚本：

```bash
./fn4_check_install.sh
```

该脚本会：

- 检查依赖安装后台进程是否仍在运行
- 显示 `pipenv_install.log` 的最后若干行
- 测试 `networkit` 是否可正常导入

若输出中包含：

```text
✓ networkit 已安装，版本: X.Y.Z
```

则说明关键依赖安装成功。

---

## 启动 fn4 服务

### 1. 启动前检查

- MongoDB 已启动并可连接
- 端口 `5020` 未被其他服务占用
- `catwalk/cw_server` 存在且可执行

### 2. 使用默认测试配置启动

项目包含一个默认测试配置文件：`config/default_test_config.json`，使用本地 MongoDB 存储，并监听 `127.0.0.1:5020`。

在项目根目录执行：

```bash
cd /data/luanjingjie/software/findNeighbour4
./fn4_startup.sh config/default_test_config.json
```

该脚本将：

- 根据配置生成临时的 gunicorn 启动脚本
- 启动 gunicorn + Flask Web 服务（当前默认 1 个 worker）
- 启动 catwalk 服务
- 启动锁管理、dbmanager、clustering、localstore 等后台进程

日志目录由配置文件中的 `LOGFILE` 决定（默认在 `/tmp`），典型文件包括：

- gunicorn 错误日志: `gunicorn_error_logging_<SERVERNAME>_<REST_PORT>.log`
- gunicorn 访问日志: `gunicorn_access_logging_<SERVERNAME>_<REST_PORT>.log`
- 其他 nohup 输出: `nohup_fn4_server_*.out` 等

---

## 验证服务是否启动成功

### 1. 检查 gunicorn 进程

```bash
ps aux | grep "gunicorn wsgi:app" | grep -v grep
```

如果能看到类似：

```text
... gunicorn wsgi:app --bind 127.0.0.1:5020 ...
```

说明 Web 服务已在运行。

### 2. 测试端口连通性

基础测试：

```bash
curl http://127.0.0.1:5020/status
```

如果返回：

```json
{"error":"Not found (custom error handler for mis-routing)"}
```

说明：

- 5020 端口的 HTTP 服务正常
- `/status` 路由不存在（自定义 404），但 gunicorn + Flask 已工作

### 3. 使用内置状态接口做健康检查

文档 `doc/rest-routes.md` 定义了可用路由。常用健康检查接口包括：

```bash
# 简易状态页（HTML）
curl http://127.0.0.1:5020/ui/info

# 服务器内存使用情况（JSON）
curl http://127.0.0.1:5020/api/v2/server_memory_usage/1

# 数据库使用情况（JSON）
curl http://127.0.0.1:5020/api/v2/server_database_usage/1
```

如果上述接口返回 200 且带有合理内容，即可认为服务已健康运行。

---

## 使用 Python 客户端访问 fn4

项目提供 `fn4client.py` 作为 Python 客户端，可通过 pipenv 调用。

### 1. 示例：使用客户端检查 server_time

```bash
cd /data/luanjingjie/software/findNeighbour4

pipenv run python3 - << 'PY'
from fn4client import fn4Client

# 默认连接到 http://127.0.0.1:5020
client = fn4Client()

print("连接成功，服务器时间:", client.server_time())
PY
```

如输出包含服务器时间（例如 `server_time` 字段），说明：

- 客户端可以通过 REST 正常访问 fn4 服务
- 服务可用于后续插入序列、查询邻居等操作（详见 `doc/rest-routes.md`）

---

## 常见问题与排查

### 1. 端口 5020 无法连接

使用项目自带的故障排查脚本：

```bash
cd /data/luanjingjie/software/findNeighbour4
./fn4_troubleshoot.sh
```

该脚本会检查：

- 配置文件是否存在
- 端口 5020 是否被占用
- gunicorn 是否运行
- MongoDB 是否运行及连接是否正常
- pipenv 环境是否可用

### 2. catwalk（5999 端口）连接失败

如果日志中报错类似：

```text
HTTPConnection(host='localhost', port=5999): Failed to establish a new connection
```

可以手动检查：

```bash
ps -ef | grep cw_server
lsof -i :5999

curl http://localhost:5999/info
curl http://localhost:5999/list_samples
```

若 `info` 和 `list_samples` 返回 200，说明 catwalk 正常；否则需检查：

- `catwalk/cw_server` 是否存在且可执行
- `reference/TB-ref.fasta` 与 `reference/TB-exclude-adaptive.txt` 是否存在、路径是否正确

更多排查建议参考 `doc/Troubleshooting.md`。

---

## 停止 fn4 服务

### 1. 使用配置工具生成关闭命令

```bash
cd /data/luanjingjie/software/findNeighbour4

pipenv run python3 fn4_configure.py config/default_test_config.json --shutdown
```

该命令会在标准输出打印一条 `pkill -f "gunicorn wsgi:app ..."` 命令，将其复制执行即可关闭 gunicorn。

### 2. 手动清理相关进程

如有需要，也可以直接按进程名停止：

```bash
# 停止 gunicorn
pkill -f "gunicorn wsgi:app"

# 停止 catwalk
pkill -f cw_server

# 停止其它 fn4 相关后台进程
pkill -f findNeighbour4_dbmanager
pkill -f findNeighbour4_clustering
pkill -f findNeighbour4_lsmanager
pkill -f findNeighbour4_lockmanager
```

---

## 给新同事的快速上手步骤

1. **进入项目目录**  
   ```bash
   cd /data/luanjingjie/software/findNeighbour4
   ```

2. **安装系统依赖 & MongoDB**（参照上文或公司内部规范）。

3. **安装 Python 依赖**  
   ```bash
   ./fn4_install_deps.sh
   ./fn4_check_install.sh
   ```

4. **启动服务**  
   ```bash
   ./fn4_startup.sh config/default_test_config.json
   ```

5. **验证服务**  
   ```bash
   curl http://127.0.0.1:5020/ui/info
   curl http://127.0.0.1:5020/api/v2/server_memory_usage/1
   ```

6. **使用 Python 客户端测试**  
   ```bash
   pipenv run python3 - << 'PY'
from fn4client import fn4Client
c = fn4Client()
print(c.server_time())
PY
   ```

7. **停止服务**  
   ```bash
   pipenv run python3 fn4_configure.py config/default_test_config.json --shutdown
   # 或使用 pkill 方式手动终止相关进程
   ```

按照以上步骤，即可在一台新服务器上完成 fn4 的部署、启动和基础验证。若遇到问题，优先查看 `/tmp` 下的 gunicorn 日志及 `doc/Troubleshooting.md`。
