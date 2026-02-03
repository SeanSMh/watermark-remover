#!/bin/bash

# 简单进度记录 - 不依赖后台进程
# 我会在对话中直接汇报进度

TASK_NAME="$1"
STEP_DESC="$2"

if [ -z "$TASK_NAME" ]; then
  echo "❌ 用法: $0 \"任务名称\" [步骤描述]"
  exit 1
fi

PROGRESS_FILE="/home/admin/clawd/progress/${TASK_NAME}-$(date +%s).json"
mkdir -p /home/admin/clawd/progress

# 如果是新任务，创建进度文件
if [ ! -f "$PROGRESS_FILE" ]; then
  cat > "$PROGRESS_FILE" << EOF
{
  "taskId": "$(date +%s)",
  "taskName": "$TASK_NAME",
  "status": "running",
  "startTime": "$(date -Iseconds)",
  "lastUpdate": "$(date -Iseconds)",
  "steps": []
}
EOF
fi

# 如果有步骤描述，添加步骤
if [ -n "$STEP_DESC" ]; then
  STEP_NUM=$(jq '.steps | length + 1' "$PROGRESS_FILE")
  jq -r "
    .lastUpdate = \"$(date -Iseconds)\" |
    .steps += [{\"step\": $STEP_NUM, \"description\": \"$STEP_DESC\", \"status\": \"completed\", \"time\": \"$(date -Iseconds)\"}]
  " "$PROGRESS_FILE" > "${PROGRESS_FILE}.tmp" && mv "${PROGRESS_FILE}.tmp" "$PROGRESS_FILE"
fi

# 输出进度文件路径（我会用这个来跟踪进度）
echo "$PROGRESS_FILE"
