#!/bin/bash

# 停止进度跟踪并发送完成通知
# 用法: ./stop-progress.sh "进度文件路径" [completed|failed] [错误信息]

PROGRESS_FILE="$1"
STATUS="${2:-completed}"
ERROR_MSG="$3"

if [ -z "$PROGRESS_FILE" ]; then
  echo "❌ 请提供进度文件路径"
  echo "用法: $0 \"进度文件路径\" [completed|failed] [错误信息]"
  exit 1
fi

if [ ! -f "$PROGRESS_FILE" ]; then
  echo "❌ 进度文件不存在: $PROGRESS_FILE"
  exit 1
fi

# 读取任务信息
TASK_NAME=$(jq -r '.taskName' "$PROGRESS_FILE")
PROGRESS_ID=$(jq -r '.taskId' "$PROGRESS_FILE")

# 更新状态
if [ "$STATUS" = "failed" ]; then
  jq -r "
    .status = \"failed\" |
    .error = \"$ERROR_MSG\" |
    .endTime = \"$(date -Iseconds)\" |
    .lastUpdate = \"$(date -Iseconds)\"
  " "$PROGRESS_FILE" > "${PROGRESS_FILE}.tmp" && mv "${PROGRESS_FILE}.tmp" "$PROGRESS_FILE"
else
  jq -r "
    .status = \"completed\" |
    .endTime = \"$(date -Iseconds)\" |
    .lastUpdate = \"$(date -Iseconds)\"
  " "$PROGRESS_FILE" > "${PROGRESS_FILE}.tmp" && mv "${PROGRESS_FILE}.tmp" "$PROGRESS_FILE"
fi

# 停止进度汇报进程
PROGRESS_PID=$(cat /tmp/progress-${PROGRESS_ID}.pid 2>/dev/null)
if [ ! -z "$PROGRESS_PID" ]; then
  kill "$PROGRESS_PID" 2>/dev/null
  rm -f /tmp/progress-${PROGRESS_ID}.pid
  echo "✅ 后台汇报进程已停止 (PID: $PROGRESS_PID)"
fi

# 发送最终通知
/home/admin/clawd/scripts/report-progress.sh "$PROGRESS_FILE"

echo "✅ 任务已标记为 $STATUS"
echo "📁 进度文件: $PROGRESS_FILE"
