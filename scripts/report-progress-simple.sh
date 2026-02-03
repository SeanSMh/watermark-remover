#!/bin/bash

PROGRESS_FILE=$1

if [ -z "$PROGRESS_FILE" ]; then
  echo "Usage: $0 <progress-file-path>"
  exit 1
fi

if [ ! -f "$PROGRESS_FILE" ]; then
  echo "Progress file not found: $PROGRESS_FILE"
  exit 1
fi

# 读取进度信息
TASK_NAME=$(jq -r '.taskName' "$PROGRESS_FILE" 2>/dev/null)
STATUS=$(jq -r '.status' "$PROGRESS_FILE" 2>/dev/null)
START_TIME=$(jq -r '.startTime' "$PROGRESS_FILE" 2>/dev/null)
CURRENT_TIME=$(date +%s)

# 计算开始时间戳
if [ -n "$START_TIME" ]; then
  START_TIME_SIMPLE=$(echo "$START_TIME" | sed 's/T/ /' | cut -d'+' -f1 | cut -d'.' -f1)
  START_TIMESTAMP=$(date -d "$START_TIME_SIMPLE" +%s 2>/dev/null || echo "$CURRENT_TIME")
else
  START_TIMESTAMP="$CURRENT_TIME"
fi

# 如果解析失败，使用当前时间减去一个估计值
if [ -z "$START_TIMESTAMP" ] || [ "$START_TIMESTAMP" = "$CURRENT_TIME" ]; then
  START_TIMESTAMP=$((CURRENT_TIME - 60))
fi

# 计算运行时间（秒）
DURATION=$((CURRENT_TIME - START_TIMESTAMP))

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

# 获取最新完成的步骤
LAST_COMPLETED_STEP=$(jq -r '.steps[] | select(.status == "completed") | .description' "$PROGRESS_FILE" 2>/dev/null | tail -n 1)

# 获取下一步骤（第一个未完成的）
NEXT_STEP=$(jq -r '.steps[] | select(.status != "completed") | .description' "$PROGRESS_FILE" 2>/dev/null | head -n 1)

# 计算完成步骤数
COMPLETED_STEPS=$(jq '[.steps[] | select(.status == "completed")] | length' "$PROGRESS_FILE" 2>/dev/null || echo "0")
TOTAL_STEPS=$(jq '.steps | length' "$PROGRESS_FILE" 2>/dev/null || echo "0")

# 根据状态构建消息
if [ "$STATUS" = "running" ]; then
  # 任务进行中
  if [ -z "$LAST_COMPLETED_STEP" ]; then
    STEP_INFO="🔄 任务初始化中..."
  else
    STEP_INFO="✅ 最新完成：$LAST_COMPLETED_STEP"
  fi

  NEXT_INFO="📝 下一步：${NEXT_STEP:-"完成中..."}"
  STATUS_INFO="📊 状态：运行中"
elif [ "$STATUS" = "completed" ]; then
  # 任务已完成
  STEP_INFO="✅ 任务已全部完成"
  NEXT_INFO="🎉 所有步骤已完成"
  STATUS_INFO="📊 状态：已完成"
else
  # 任务失败
  ERROR_MSG=$(jq -r '.error' "$PROGRESS_FILE" 2>/dev/null)
  STEP_INFO="❌ 任务失败"
  NEXT_INFO="⚠️ 错误：${ERROR_MSG:-"未知错误"}"
  STATUS_INFO="📊 状态：失败"
fi

# 构建完整消息
MESSAGE="📊 任务进度汇报：${TASK_NAME}

${STEP_INFO}
⏱️ 运行时间：${DURATION_STR}
${NEXT_INFO}
${STATUS_INFO}

📈 进度：${COMPLETED_STEPS}/${TOTAL_STEPS} 步骤完成"

# 输出到标准输出（小弟会读取并汇报给老大）
echo "$MESSAGE" >> /tmp/progress-report-output.txt
