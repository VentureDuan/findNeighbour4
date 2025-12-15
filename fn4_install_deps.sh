#!/bin/bash

# findNeighbour4 依赖安装脚本
# 在后台执行 pipenv install，输出保存到日志文件

set -e

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# 日志文件路径
LOG_FILE="${SCRIPT_DIR}/pipenv_install.log"
PID_FILE="${SCRIPT_DIR}/pipenv_install.pid"

echo "=========================================="
echo "findNeighbour4 依赖安装脚本"
echo "=========================================="
echo ""
echo "工作目录: $SCRIPT_DIR"
echo "日志文件: $LOG_FILE"
echo "PID 文件: $PID_FILE"
echo ""

# 检查是否已有安装进程在运行
if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE")
    if ps -p "$OLD_PID" > /dev/null 2>&1; then
        echo "⚠ 警告: 检测到已有安装进程在运行 (PID: $OLD_PID)"
        echo "   如果要重新安装，请先执行: kill $OLD_PID"
        echo "   或者删除 PID 文件: rm $PID_FILE"
        exit 1
    else
        echo "清理旧的 PID 文件..."
        rm -f "$PID_FILE"
    fi
fi

# 启动后台安装
echo "开始后台安装依赖..."
echo "执行命令: pipenv install -e . --skip-lock --python 3.9"
echo ""

nohup pipenv install -e . --skip-lock --python 3.9 > "$LOG_FILE" 2>&1 &
INSTALL_PID=$!

# 保存 PID
echo $INSTALL_PID > "$PID_FILE"

echo "✓ 安装进程已启动"
echo "  进程 ID: $INSTALL_PID"
echo "  日志文件: $LOG_FILE"
echo "  PID 文件: $PID_FILE"
echo ""
echo "查看安装进度:"
echo "  tail -f $LOG_FILE"
echo ""
echo "检查安装状态:"
echo "  ps -p $INSTALL_PID"
echo ""
echo "安装完成后验证:"
echo "  pipenv run python3 -c \"import networkit as nk; print('networkit 安装成功')\""
echo ""
echo "=========================================="

