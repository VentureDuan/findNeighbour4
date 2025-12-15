# findNeighbour4 故障排查指南

## 问题：服务无法连接 (curl: Failed to connect to 127.0.0.1:5020)

### 快速排查步骤

#### 1. 运行自动排查脚本
```bash
./fn4_troubleshoot.sh config/default_test_config.json
```

#### 2. 手动检查清单

##### 检查 1: 确认服务是否正在运行
```bash
# 检查 gunicorn 进程
ps aux | grep gunicorn

# 检查端口监听
netstat -tuln | grep 5020
# 或
ss -tuln | grep 5020
# 或
lsof -i :5020
```

##### 检查 2: MongoDB 是否运行
```bash
# 检查 MongoDB 进程
ps aux | grep mongod

# 如果使用 Docker Compose
docker-compose ps

# 启动 MongoDB (如果未运行)
docker-compose up -d mongodb
```

##### 检查 3: 查看启动日志
```bash
# 查找日志目录
python3 get_log_dir_from_config_file.py config/default_test_config.json

# 查看 gunicorn 错误日志
ls -lt /tmp/gunicorn_error_logging_*.log | head -1 | xargs tail -50

# 查看 nohup 输出
ls -lt /tmp/nohup_fn4_server_*.out | head -1 | xargs tail -50
```

##### 检查 4: 验证配置文件
```bash
# 检查配置文件是否存在且有效
cat config/default_test_config.json | python3 -m json.tool

# 检查关键配置项
python3 -c "
import json
with open('config/default_test_config.json') as f:
    config = json.load(f)
    print('REST_PORT:', config.get('REST_PORT'))
    print('SERVERNAME:', config.get('SERVERNAME'))
    print('FNPERSISTENCE_CONNSTRING:', config.get('FNPERSISTENCE_CONNSTRING'))
"
```

##### 检查 5: 测试手动启动
```bash
# 生成启动命令
pipenv run python3 fn4_configure.py config/default_test_config.json --startup --n_workers 1

# 手动执行启动命令（将上面的输出复制执行）
# 例如：
# nohup pipenv run gunicorn wsgi:app --bind 127.0.0.1:5020 --log-level info --workers 1 --error-logfile ... --access-logfile ... --timeout 150 > ... &
```

##### 检查 6: 检查依赖和环境
```bash
# 检查 pipenv 环境
pipenv --version
pipenv install

# 检查 Python 版本
python3 --version

# 检查必要的 Python 包
pipenv run python3 -c "import flask, gunicorn, pymongo; print('依赖检查通过')"
```

### 常见问题及解决方案

#### 问题 1: 端口已被占用
**症状**: 启动时提示端口被占用

**解决**:
```bash
# 查找占用端口的进程
lsof -i :5020
# 或
netstat -tulpn | grep 5020

# 终止占用端口的进程
kill -9 <PID>

# 或者使用 shutdown 脚本
./fn4_shutdown.sh config/default_test_config.json
```

#### 问题 2: MongoDB 未运行
**症状**: 日志中显示 MongoDB 连接错误

**解决**:
```bash
# 启动 MongoDB
docker-compose up -d mongodb

# 等待 MongoDB 完全启动
sleep 5

# 验证连接
python3 -c "import pymongo; pymongo.MongoClient('mongodb://127.0.0.1').server_info()"
```

#### 问题 3: 配置文件路径错误
**症状**: 启动脚本提示配置文件不存在

**解决**:
```bash
# 确认配置文件路径
ls -la config/default_test_config.json

# 使用绝对路径
./fn4_startup.sh $(pwd)/config/default_test_config.json
```

#### 问题 4: 参考文件不存在
**症状**: 日志中显示找不到参考文件

**解决**:
```bash
# 检查参考文件是否存在
python3 -c "
import json
with open('config/default_test_config.json') as f:
    config = json.load(f)
    ref_file = config.get('INPUTREF')
    print(f'参考文件: {ref_file}')
    import os
    print(f'存在: {os.path.exists(ref_file)}')
"
```

#### 问题 5: gunicorn 进程启动后立即退出
**症状**: 进程启动但很快消失

**解决**:
```bash
# 查看详细错误日志
tail -100 /tmp/gunicorn_error_logging_*.log

# 尝试使用单 worker 模式启动
pipenv run python3 fn4_configure.py config/default_test_config.json --startup --n_workers 1

# 或者直接使用 Flask 开发服务器测试
pipenv run python3 findNeighbour4_server.py config/default_test_config.json
```

#### 问题 6: 权限问题
**症状**: 无法写入日志文件或创建文件

**解决**:
```bash
# 检查日志目录权限
python3 get_log_dir_from_config_file.py config/default_test_config.json
# 确保目录可写
chmod -R 755 /tmp  # 或相应的日志目录
```

### 调试模式启动

如果上述方法都无法解决问题，可以尝试使用 Flask 开发服务器直接启动（不使用 gunicorn）：

```bash
pipenv run python3 findNeighbour4_server.py config/default_test_config.json
```

这将使用 Flask 内置的开发服务器，更容易看到错误信息。

### 获取帮助

如果问题仍然存在，请收集以下信息：

1. 完整的启动命令输出
2. 最新的错误日志文件内容
3. 配置文件内容（隐藏敏感信息）
4. 系统信息：
   ```bash
   uname -a
   python3 --version
   pipenv --version
   docker --version
   ```

### 相关文件

- 启动脚本: `fn4_startup.sh`
- 配置脚本: `fn4_configure.py`
- 关闭脚本: `fn4_shutdown.sh`
- 排查脚本: `fn4_troubleshoot.sh`

