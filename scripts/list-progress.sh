#!/bin/bash

# 列出所有正在进行的任务

PROGRESS_DIR="/home/admin/clawd/progress"

if [ ! -d "$PROGRESS_DIR" ]; then
  echo "📁 进度目录不存在：$PROGRESS_DIR"
  exit 0
fi

# 查找所有进度文件
PROGRESS_FILES=("$PROGRESS_DIR"/*.json)

if [ ${#PROGRESS_FILES[@]} -eq 0 ] || [ ! -f "${PROGRESS_FILES[0]}" ]; then
  echo "📭 当前没有正在进行的任务"
  exit 0
fi

echo "📊 正在进行的任务列表："
echo ""

# 遍历所有进度文件
for PROGRESS_FILE in "${PROGRESS_FILES[@]}"; do
  if [ ! -f "$PROGRESS_FILE" ]; then
    continue
  fi

  # 读取任务信息
  TASK_ID=$(jq -r '.taskId' "$PROGRESS_FILE" 2>/dev/null)
  TASK_NAME=$(jq -r '.taskName' "$PROGRESS_FILE" 2>/dev/null)
  STATUS=$(jq -r '.status' "$PROGRESS_FILE" 2>/dev/null)
  START_TIME=$(jq -r '.startTime' "$PROGRESS_FILE" 2>/dev/null | sed 's/T/ /' | cut -d'+' -f1 | cut -d'.' -f1)

  # 计算运行时间
  START_TIMESTAMP=$(date -d "$START_TIME" +%s 2>/dev/null || echo "0")
  CURRENT_TIMESTAMP=$(date +%s)
  DURATION=$((CURRENT_TIMESTAMP - START_TIMESTAMP))

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

  # 根据状态显示不同符号
  if [ "$STATUS" = "running" ]; then
    STATUS_ICON="🔄"
  elif [ "$STATUS" = "completed" ]; then
    STATUS_ICON="✅"
  else
    STATUS_ICON="❌"
  fi

  # 获取步骤数
  TOTAL_STEPS=$(jq '.steps | length' "$PROGRESS_FILE" 2>/dev/null || echo "0")
  COMPLETED_STEPS=$(jq '[.steps[] | select(.status == "completed")] | length' "$PROGRESS_FILE" 2>/dev/null || echo "0")

  # 显示任务信息
  echo "${STATUS_ICON} ${TASK_NAME}"
  echo "   🆔 ID: ${TASK_ID}"
  echo "   📅 开始: ${START_TIME}"
  echo "   ⏱️ 运行: ${DURATION_STR}"
  echo "   📈 进度: ${COMPLETED_STEPS}/${TOTAL_STEPS} 步骤"
  echo ""
done

# 统计信息
RUNNING_COUNT=$(grep -l '"status": "running"' "${PROGRESS_FILES[@]}" 2>/dev/null | wc -l)
COMPLETED_COUNT=$(grep -l '"status": "completed"' "${PROGRESS_FILES[@]}" 2>/dev/null | wc -l)
FAILED_COUNT=$(grep -l '"status": "failed"' "${PROGRESS_FILES[@]}" 2>/dev/null | wc -l)

echo "📊 统计："
echo "  🔄 运行中: $RUNNING_COUNT"
echo "  ✅ 已完成: $COMPLETED_COUNT"
echo "  ❌ 已失败: $FAILED_COUNT"
echo "  📋 总计: $((RUNNING_COUNT + COMPLETED_COUNT + FAILED_COUNT))"

# 提示
echo ""
echo "💡 查看详细进度："
echo "   ./show-progress.sh <task-id>"
echo ""
echo "💡 查看特定任务："
echo "   cat ${PROGRESS_DIR}/<task-id>.json | jq ."
