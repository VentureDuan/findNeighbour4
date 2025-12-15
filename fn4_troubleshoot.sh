#!/bin/bash

# findNeighbour4 故障排查脚本
# 用于诊断服务无法启动的问题

echo "=========================================="
echo "findNeighbour4 故障排查工具"
echo "=========================================="
echo ""

# 1. 检查配置文件是否存在
CONFIG_FILE="${1:-config/default_test_config.json}"
echo "1. 检查配置文件: $CONFIG_FILE"
if [ -f "$CONFIG_FILE" ]; then
    echo "   ✓ 配置文件存在"
else
    echo "   ✗ 配置文件不存在: $CONFIG_FILE"
    exit 1
fi
echo ""

# 2. 检查端口是否被占用
echo "2. 检查端口 5020 是否被占用"
PORT_CHECK=$(netstat -tuln 2>/dev/null | grep :5020 || ss -tuln 2>/dev/null | grep :5020 || lsof -i :5020 2>/dev/null)
if [ -z "$PORT_CHECK" ]; then
    echo "   ✓ 端口 5020 未被占用"
else
    echo "   ⚠ 端口 5020 可能被占用:"
    echo "$PORT_CHECK"
fi
echo ""

# 3. 检查 gunicorn 进程是否运行
echo "3. 检查 gunicorn 进程"
GUNICORN_PIDS=$(pgrep -f "gunicorn wsgi:app" || echo "")
if [ -z "$GUNICORN_PIDS" ]; then
    echo "   ✗ 未找到运行中的 gunicorn 进程"
else
    echo "   ✓ 找到 gunicorn 进程: $GUNICORN_PIDS"
    ps -p $GUNICORN_PIDS -o pid,cmd --no-headers
fi
echo ""

# 4. 检查 MongoDB 是否运行
echo "4. 检查 MongoDB 服务"
MONGO_CHECK=$(pgrep -f mongod || echo "")
if [ -z "$MONGO_CHECK" ]; then
    echo "   ⚠ 未找到运行中的 MongoDB 进程"
    echo "   提示: 请确保 MongoDB 已启动 (可以使用 docker-compose up -d mongodb)"
else
    echo "   ✓ MongoDB 进程运行中: $MONGO_CHECK"
fi

# 检查 MongoDB 连接
echo "   测试 MongoDB 连接..."
python3 -c "
import pymongo
try:
    client = pymongo.MongoClient('mongodb://127.0.0.1', serverSelectionTimeoutMS=2000)
    client.server_info()
    print('   ✓ MongoDB 连接成功')
except Exception as e:
    print(f'   ✗ MongoDB 连接失败: {e}')
" 2>/dev/null || echo "   ⚠ 无法测试 MongoDB 连接 (可能需要安装 pymongo)"
echo ""

# 5. 检查 pipenv 环境
echo "5. 检查 pipenv 环境"
if command -v pipenv &> /dev/null; then
    echo "   ✓ pipenv 已安装"
    if [ -f "Pipfile" ]; then
        echo "   ✓ Pipfile 存在"
    else
        echo "   ✗ Pipfile 不存在"
    fi
else
    echo "   ✗ pipenv 未安装"
fi
echo ""

# 6. 检查日志文件
echo "6. 查找最近的日志文件"
# 从配置文件获取日志目录
LOGDIR=$(python3 -c "
import json
import sys
try:
    with open('$CONFIG_FILE', 'r') as f:
        config = json.load(f)
    logfile = config.get('LOGFILE', '/tmp/logfile_unittesting.log')
    import os
    logdir = os.path.dirname(logfile)
    if not logdir:
        logdir = '/tmp'
    print(logdir)
except Exception as e:
    print('/tmp')
" 2>/dev/null)

echo "   日志目录: $LOGDIR"

# 查找 gunicorn 相关日志
echo "   查找 gunicorn 日志文件..."
find "$LOGDIR" -name "*gunicorn*.log" -type f -mtime -1 2>/dev/null | head -5 | while read logfile; do
    echo "   - $logfile"
    if [ -f "$logfile" ]; then
        echo "     最后 10 行:"
        tail -10 "$logfile" | sed 's/^/     /'
    fi
done

# 查找 nohup 输出文件
echo "   查找 nohup 输出文件..."
find "$LOGDIR" -name "nohup_fn4_server_*.out" -type f -mtime -1 2>/dev/null | head -3 | while read logfile; do
    echo "   - $logfile"
    if [ -f "$logfile" ]; then
        echo "     最后 10 行:"
        tail -10 "$logfile" | sed 's/^/     /'
    fi
done
echo ""

# 7. 检查配置文件中的关键设置
echo "7. 检查配置文件关键设置"
python3 -c "
import json
import sys
try:
    with open('$CONFIG_FILE', 'r') as f:
        config = json.load(f)
    print(f\"   服务器名称: {config.get('SERVERNAME', 'N/A')}\")
    print(f\"   REST 端口: {config.get('REST_PORT', 'N/A')}\")
    print(f\"   监听地址: {config.get('LISTEN_TO', '127.0.0.1 (默认)')}\")
    print(f\"   MongoDB 连接: {config.get('FNPERSISTENCE_CONNSTRING', 'N/A')}\")
    print(f\"   参考文件: {config.get('INPUTREF', 'N/A')}\")
    if 'INPUTREF' in config:
        import os
        ref_file = config['INPUTREF']
        if os.path.exists(ref_file):
            print(f\"   ✓ 参考文件存在\")
        else:
            print(f\"   ✗ 参考文件不存在: {ref_file}\")
except Exception as e:
    print(f\"   ✗ 无法读取配置文件: {e}\")
" 2>/dev/null
echo ""

# 8. 尝试手动启动测试
echo "8. 建议的排查步骤:"
echo "   a) 检查启动脚本是否成功执行:"
echo "      ./fn4_startup.sh $CONFIG_FILE"
echo ""
echo "   b) 查看生成的启动脚本内容:"
echo "      pipenv run python3 fn4_configure.py $CONFIG_FILE --startup --n_workers 1"
echo ""
echo "   c) 手动测试 gunicorn 启动:"
echo "      pipenv run gunicorn wsgi:app --workers 1 --bind 127.0.0.1:5020"
echo ""
echo "   d) 检查所有相关进程:"
echo "      ps aux | grep -E '(gunicorn|findNeighbour)'"
echo ""
echo "   e) 检查系统日志:"
echo "      journalctl -xe (如果使用 systemd)"
echo ""

echo "=========================================="
echo "排查完成"
echo "=========================================="

