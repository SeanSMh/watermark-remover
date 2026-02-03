#!/bin/bash

# 添加步骤到进度跟踪
# 用法：./add-step.sh <progress-id> "步骤描述"

PROGRESS_ID="$1"
STEP_DESCRIPTION="$2"

if [ -z "$PROGRESS_ID" ]; then
  echo "Usage: $0 <progress-id> \"step-description\""
  echo ""
  echo "可用方法："
  echo "  1. 使用 PROGRESS_ID 环境变量：./add-step.sh \$PROGRESS_ID \"步骤描述\""
  echo "  2. 直接指定ID：./add-step.sh \"task-name-123456\" \"步骤描述\""
  exit 1
fi

if [ -z "$STEP_DESCRIPTION" ]; then
  echo "Error: 步骤描述不能为空"
  echo "Usage: $0 <progress-id> \"step-description\""
  exit 1
fi

# 查找进度文件
PROGRESS_FILE="/home/admin/clawd/progress/${PROGRESS_ID}.json"

if [ ! -f "$PROGRESS_FILE" ]; then
  echo "❌ 未找到进度文件：$PROGRESS_FILE"
  echo "   请检查进度ID是否正确"
  exit 1
fi

# 获取当前步骤数
CURRENT_STEP=$(jq '.steps | length + 1' "$PROGRESS_FILE" 2>/dev/null)

# 更新进度文件 - 使用更简单的方法
jq "
  .lastUpdate = \"$(date -Iseconds)\" |
  .steps = .steps + [{
    \"step\": $CURRENT_STEP,
    \"description\": \"$STEP_DESCRIPTION\",
    \"status\": \"completed\",
    \"time\": \"$(date -Iseconds)\"
  }]
" "$PROGRESS_FILE" > "${PROGRESS_FILE}.tmp"

if [ $? -eq 0 ]; then
  mv "${PROGRESS_FILE}.tmp" "$PROGRESS_FILE"
  echo "✅ 已添加步骤：$STEP_DESCRIPTION"
  echo "📊 当前步骤数：$CURRENT_STEP"
  echo "📁 进度文件：$PROGRESS_FILE"

  # 可选：立即汇报进度
  # /home/admin/clawd/scripts/report-progress.sh "$PROGRESS_FILE"
else
  echo "❌ 添加步骤失败"
  rm -f "${PROGRESS_FILE}.tmp"
  exit 1
fi
