#!/bin/bash

# 完成任务进度跟踪
# 用法：./complete-progress.sh <progress-id>

PROGRESS_ID="$1"

if [ -z "$PROGRESS_ID" ]; then
  echo "Usage: $0 <progress-id>"
  echo ""
  echo "可用方法："
  echo "  1. 使用 PROGRESS_ID 环境变量：./complete-progress.sh \$PROGRESS_ID"
  echo "  2. 直接指定ID：./complete-progress.sh \"task-name-123456\""
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

# 更新状态为完成
jq -r "
  .status = \"completed\" |
  .endTime = \"$(date -Iseconds)\" |
  .lastUpdate = \"$(date -Iseconds)\"
" "$PROGRESS_FILE" > "${PROGRESS_FILE}.tmp"

if [ $? -eq 0 ]; then
  mv "${PROGRESS_FILE}.tmp" "$PROGRESS_FILE"
  echo "✅ 任务状态已更新为：完成"
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

# 生成完成报告
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

# 生成步骤列表
STEPS_LIST=$(jq -r '.steps[] | "\(.step). \(.description) - \(.status)"' "$PROGRESS_FILE" | paste -sd '\n')

# 构建完成消息
COMPLETION_MESSAGE="✅ 任务完成：${TASK_NAME}

📊 统计信息：
- 开始时间：${START_TIME}
- 结束时间：${END_TIME}
- 总耗时：${DURATION_STR}
- 完成步骤数：${COMPLETED_STEPS}/${TOTAL_STEPS}

📝 完成步骤：
${STEPS_LIST}"

# 发送完成通知
moltbot gateway wake --text "$COMPLETION_MESSAGE" --mode now 2>/dev/null

if [ $? -eq 0 ]; then
  echo "✅ 完成通知已发送"
else
  echo "⚠️ 发送完成通知失败"
fi

echo ""
echo "🎉 任务 \"$TASK_NAME\" 已完成！"
echo "📁 进度文件：$PROGRESS_FILE"
