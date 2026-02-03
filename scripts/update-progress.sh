#!/bin/bash

# 更新进度
# 用法: ./update-progress.sh "进度文件路径" "步骤描述"

PROGRESS_FILE="$1"
STEP_DESC="$2"

if [ -z "$PROGRESS_FILE" ] || [ -z "$STEP_DESC" ]; then
  echo "❌ 参数不完整"
  echo "用法: $0 \"进度文件路径\" \"步骤描述\""
  exit 1
fi

if [ ! -f "$PROGRESS_FILE" ]; then
  echo "❌ 进度文件不存在: $PROGRESS_FILE"
  exit 1
fi

# 计算步骤编号
STEP_NUM=$(jq '.steps | length + 1' "$PROGRESS_FILE")

# 更新进度文件
jq -r "
  .lastUpdate = \"$(date -Iseconds)\" |
  .steps += {\"step\": $STEP_NUM, \"description\": \"$STEP_DESC\", \"status\": \"completed\", \"time\": \"$(date -Iseconds)\"}
" "$PROGRESS_FILE" > "${PROGRESS_FILE}.tmp" && mv "${PROGRESS_FILE}.tmp" "$PROGRESS_FILE"

echo "✅ 进度已更新"
echo "📝 步骤 $STEP_NUM: $STEP_DESC"
echo "💡 发送即时汇报..."
/home/admin/clawd/scripts/report-progress.sh "$PROGRESS_FILE"
