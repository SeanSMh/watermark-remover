#!/bin/bash

# 显示任务进度
# 用法：./show-progress.sh <progress-id>

PROGRESS_ID="$1"

if [ -z "$PROGRESS_ID" ]; then
  echo "Usage: $0 <progress-id>"
  echo ""
  echo "可用方法："
  echo "  1. 使用 PROGRESS_ID 环境变量：./show-progress.sh \$PROGRESS_ID"
  echo "  2. 直接指定ID：./show-progress.sh \"task-name-123456\""
  echo ""
  echo "📋 列出所有任务："
  echo "   ./list-progress.sh"
  exit 1
fi

# 查找进度文件
PROGRESS_FILE="/home/admin/clawd/progress/${PROGRESS_ID}.json"

if [ ! -f "$PROGRESS_FILE" ]; then
  echo "❌ 未找到进度文件：$PROGRESS_FILE"
  echo "   请检查进度ID是否正确"
  exit 1
fi

# 读取进度信息
TASK_NAME=$(jq -r '.taskName' "$PROGRESS_FILE")
STATUS=$(jq -r '.status' "$PROGRESS_FILE")
START_TIME=$(jq -r '.startTime' "$PROGRESS_FILE" | sed 's/T/ /' | cut -d'.' -f1)
END_TIME=$(jq -r '.endTime' "$PROGRESS_FILE" 2>/dev/null | sed 's/T/ /' | cut -d'.' -f1)
ERROR_MSG=$(jq -r '.error' "$PROGRESS_FILE" 2>/dev/null)

# 计算耗时
START_TIMESTAMP=$(date -d "$START_TIME" +%s 2>/dev/null || echo "0")
if [ "$STATUS" = "completed" ] || [ "$STATUS" = "failed" ]; then
  if [ -n "$END_TIME" ]; then
    END_TIMESTAMP=$(date -d "$END_TIME" +%s 2>/dev/null || echo "0")
  else
    END_TIMESTAMP=$(date +%s)
  fi
else
  END_TIMESTAMP=$(date +%s)
fi

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

# 显示进度信息
echo "📊 任务进度：${TASK_NAME}"
echo ""
echo "📋 基本信息："
echo "  任务ID：${PROGRESS_ID}"
echo "  状态：${STATUS}"
echo "  开始时间：${START_TIME}"

if [ "$STATUS" = "completed" ] || [ "$STATUS" = "failed" ]; then
  echo "  结束时间：${END_TIME}"
fi

echo "  运行时间：${DURATION_STR}"
echo "  进度：${COMPLETED_STEPS}/${TOTAL_STEPS} 步骤"
echo ""

# 显示错误信息（如果有）
if [ -n "$ERROR_MSG" ] && [ "$ERROR_MSG" != "null" ]; then
  echo "❌ 错误：$ERROR_MSG"
  echo ""
fi

# 显示步骤列表
if [ $TOTAL_STEPS -gt 0 ]; then
  echo "📝 步骤列表："
  jq -r '.steps[] | "  [\(.step)] \(.description) - \(.status)"' "$PROGRESS_FILE"
  echo ""
fi

# 显示进程信息
PID_FILE="/tmp/progress-${PROGRESS_ID}.pid"
if [ -f "$PID_FILE" ]; then
  PROGRESS_PID=$(cat "$PID_FILE")
  if ps -p "$PROGRESS_PID" > /dev/null 2>&1; then
    echo "🔄 进度汇报进程运行中（PID: $PROGRESS_PID）"
    echo "📄 日志：/tmp/progress-${PROGRESS_ID}.log"
  else
    echo "⚠️ 进度汇报进程已停止"
  fi
fi
