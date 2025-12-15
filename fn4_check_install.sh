#!/bin/bash

# 检查 pipenv 安装状态的辅助脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/pipenv_install.log"
PID_FILE="${SCRIPT_DIR}/pipenv_install.pid"

echo "=========================================="
echo "findNeighbour4 安装状态检查"
echo "=========================================="
echo ""

# 检查 PID 文件
if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    echo "安装进程 PID: $PID"
    
    if ps -p "$PID" > /dev/null 2>&1; then
        echo "状态: ✓ 正在运行"
        echo ""
        echo "进程信息:"
        ps -p "$PID" -o pid,etime,cmd --no-headers
    else
        echo "状态: ✗ 进程已结束"
        rm -f "$PID_FILE"
    fi
else
    echo "状态: 未找到安装进程"
fi

echo ""

# 检查日志文件
if [ -f "$LOG_FILE" ]; then
    echo "日志文件: $LOG_FILE"
    echo "文件大小: $(du -h "$LOG_FILE" | cut -f1)"
    echo "最后修改: $(stat -c %y "$LOG_FILE" 2>/dev/null || stat -f %Sm "$LOG_FILE" 2>/dev/null)"
    echo ""
    echo "=== 日志最后 20 行 ==="
    tail -20 "$LOG_FILE"
    echo ""
else
    echo "日志文件不存在: $LOG_FILE"
fi

echo ""

# 检查 networkit 是否已安装
echo "=== 检查 networkit 安装状态 ==="
if pipenv run python3 -c "import networkit as nk; print('✓ networkit 已安装，版本:', nk.__version__)" 2>/dev/null; then
    echo ""
else
    echo "✗ networkit 未安装或导入失败"
    echo ""
fi

echo "=========================================="

