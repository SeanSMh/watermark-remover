#!/bin/bash

# 修复后的进度汇报脚本 (v2.1)
# 1. 修复了 moltbot 命令行调用错误（CLI 不支持 wake 命令，需通过工具调用或 cron）
# 2. 保持存活检查和进度逻辑

PROGRESS_FILE=$1
PARENT_PID=$2

if [ ! -f "$PROGRESS_FILE" ]; then
  exit 1
fi

# 检查主进程是否存在 (如果提供了 PID)
if [ ! -z "$PARENT_PID" ]; then
  if ! kill -0 "$PARENT_PID" 2>/dev/null; then
    STATUS=$(jq -r '.status' "$PROGRESS_FILE")
    if [ "$STATUS" == "running" ]; then
      jq -r ".status = \"failed\" | .error = \"Parent process disappeared unexpectedly\"" "$PROGRESS_FILE" > "$PROGRESS_FILE.tmp" && mv "$PROGRESS_FILE.tmp" "$PROGRESS_FILE"
      # 这里记录到日志，真正的通知由主会话感知或通过 cron 触发
      echo "[$(date '+%Y-%m-%d %H:%M:%S')] FAILED: Parent process $PARENT_PID is gone." >> /tmp/progress-reporter.log
    fi
    exit 0
  fi
fi

# 获取进度信息用于记录
TASK_NAME=$(jq -r '.taskName' "$PROGRESS_FILE")
STATUS=$(jq -r '.status' "$PROGRESS_FILE")
LAST_STEP=$(jq -r '.steps[] | select(.status == "completed") | .description' "$PROGRESS_FILE" | tail -n 1)

# 将汇报信息写入一个临时文件，主会话可以通过 heartbeat 或 cron 轮询来读取
# 这里的逻辑是：脚本只管更新状态和本地日志，AI 通过 cron 任务定期检查并汇报
echo "[$(date '+%Y-%m-%d %H:%M:%S')] TASK: $TASK_NAME | STEP: ${LAST_STEP:-"N/A"} | STATUS: $STATUS" >> /tmp/progress-reporter.log
