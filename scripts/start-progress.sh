#!/bin/bash

# 快速启动进度跟踪
# 用法: ./start-progress.sh "任务名称"

TASK_NAME="$1"

if [ -z "$TASK_NAME" ]; then
  echo "❌ 请提供任务名称"
  echo "用法: $0 \"任务名称\""
  exit 1
fi

# 生成唯一ID
PROGRESS_ID="${TASK_NAME}-$(date +%s)"
PROGRESS_FILE="/home/admin/clawd/progress/${PROGRESS_ID}.json"

# 创建进度目录（如果不存在）
mkdir -p /home/admin/clawd/progress

# 初始化进度文件
cat > "$PROGRESS_FILE" << EOF
{
  "taskId": "$PROGRESS_ID",
  "taskName": "$TASK_NAME",
  "status": "running",
  "startTime": "$(date -Iseconds)",
  "lastUpdate": "$(date -Iseconds)",
  "steps": [
    {"step": 1, "description": "启动任务", "status": "completed", "time": "$(date -Iseconds)"}
  ]
}
EOF

# 在后台启动进度汇报（每3分钟）
nohup bash -c "
  while true; do
    sleep 180
    /home/admin/clawd/scripts/report-progress.sh '$PROGRESS_FILE'
  done
" > /tmp/progress-${PROGRESS_ID}.log 2>&1 &

PROGRESS_PID=$!
echo "$PROGRESS_PID" > /tmp/progress-${PROGRESS_ID}.pid

echo "✅ 进度跟踪已启动"
echo "📁 进度文件: $PROGRESS_FILE"
echo "🔄 进程 PID: $PROGRESS_PID"
echo "⏱️ 将每 3 分钟汇报一次进度"
echo ""
echo "更新进度的命令："
echo "  /home/admin/clawd/scripts/update-progress.sh \"$PROGRESS_FILE\" \"步骤描述\""
echo ""
echo "停止进度的命令："
echo "  /home/admin/clawd/scripts/stop-progress.sh \"$PROGRESS_FILE\""
