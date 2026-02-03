#!/bin/bash

# 标记任务失败
# 用法：./fail-progress.sh <progress-id> "错误原因"

PROGRESS_ID="$1"
ERROR_MESSAGE="$2"

if [ -z "$PROGRESS_ID" ]; then
  echo "Usage: $0 <progress-id> \"error-message\""
  echo ""
  echo "可用方法："
  echo "  1. 使用 PROGRESS_ID 环境变量：./fail-progress.sh \$PROGRESS_ID \"错误原因\""
  echo "  2. 直接指定ID：./fail-progress.sh \"task-name-123456\" \"错误原因\""
  exit 1
fi

if [ -z "$ERROR_MESSAGE" ]; then
  echo "Error: 错误消息不能为空"
  echo "Usage: $0 <progress-id> \"error-message\""
  exit 1
fi

# 查找进度文件
PROGRESS_FILE="/home/admin/clawd/progress/${PROGRESS_ID}.json"

if [ ! -f "$PROGRESS_FILE" ]; then
  echo "❌ 未找到进度文件：$PROGRESS_FILE"
  echo "   请检查进度ID是否正确"
  exit 1
fi

# PID 文件
PID_FILE="/tmp/progress-${PROGRESS_ID}.pid"

# 更新状态为失败
jq -r "
  .status = \"failed\" |
  .error = \"$ERROR_MESSAGE\" |
  .endTime = \"$(date -Iseconds)\" |
  .lastUpdate = \"$(date -Iseconds)\"
" "$PROGRESS_FILE" > "${PROGRESS_FILE}.tmp"

if [ $? -eq 0 ]; then
  mv "${PROGRESS_FILE}.tmp" "$PROGRESS_FILE"
  echo "✅ 任务状态已更新为：失败"
  echo "❌ 错误：$ERROR_MESSAGE"
else
  echo "❌ 更新状态失败"
  rm -f "${PROGRESS_FILE}.tmp"
  exit 1
fi

# 停止进度汇报进程
if [ -f "$PID_FILE" ]; then
  PROGRESS_PID=$(cat "$PID_FILE")
  if ps -p "$PROGRESS_PID" > /dev/null 2>&1; then
    kill "$PROGRESS_PID" 2>/dev/null
    echo "✅ 进度汇报进程已停止（PID: $PROGRESS_PID）"
  fi
  rm -f "$PID_FILE"
fi

# 生成失败报告
TASK_NAME=$(jq -r '.taskName' "$PROGRESS_FILE")
START_TIME=$(jq -r '.startTime' "$PROGRESS_FILE" | sed 's/T/ /' | cut -d'.' -f1)
END_TIME=$(jq -r '.endTime' "$PROGRESS_FILE" | sed 's/T/ /' | cut -d'.' -f1)

# 计算耗时
START_TIMESTAMP=$(date -d "$START_TIME" +%s 2>/dev/null || echo "0")
END_TIMESTAMP=$(date -d "$END_TIME" +%s 2>/dev/null || echo "0")
DURATION=$((END_TIMESTAMP - START_TIMESTAMP))

# 转换为易读格式
if [ $DURATION -lt 60 ]; then
  DURATION_STR="${DURATION}秒"
elif [ $DURATION -lt 3600 ]; then
  MINUTES=$((DURATION / 60))
  SECONDS=$((DURATION % 60))
  DURATION_STR="${MINUTES}分${SECONDS}秒"
else
  HOURS=$((DURATION / 3600))
  MINUTES=$(((DURATION % 3600) / 60))
  DURATION_STR="${HOURS}小时${MINUTES}分"
fi

# 获取步骤数
TOTAL_STEPS=$(jq '.steps | length' "$PROGRESS_FILE")
COMPLETED_STEPS=$(jq '[.steps[] | select(.status == "completed")] | length' "$PROGRESS_FILE")

# 构建失败消息
FAILURE_MESSAGE="❌ 任务失败：${TASK_NAME}

⚠️ 错误：${ERROR_MESSAGE}

📊 任务信息：
- 开始时间：${START_TIME}
- 失败时间：${END_TIME}
- 总耗时：${DURATION_STR}
- 已完成步骤：${COMPLETED_STEPS}/${TOTAL_STEPS}

需要我重试或修复问题吗？"

# 发送失败通知
moltbot gateway wake --text "$FAILURE_MESSAGE" --mode now 2>/dev/null

if [ $? -eq 0 ]; then
  echo "✅ 失败通知已发送"
else
  echo "⚠️ 发送失败通知失败"
fi

echo ""
echo "💡 建议：检查日志文件 /tmp/progress-${PROGRESS_ID}.log 了解详细错误信息"
