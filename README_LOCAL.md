# 阿旺·本地 AI 去水印系统 (Wm-Remover)

本仓库包含了经过“破晓行动”重构后的本地去水印全套系统，彻底摆脱了对外部 AI API 的依赖，实现 100% 本地化运行。

## 🏗️ 项目架构

项目采用 **Node.js (指挥官) + Python (本地特工)** 的协同架构：

### 1. 指挥部 (Node.js 后端 - 5004 端口)
- **位置**: `projects/wm-remover/watermark-remover/backend`
- **职责**: 处理前端上传、任务分发、结果存储与分发。
- **状态**: 监听 `0.0.0.0:5004`，支持公网访问。

### 2. 特工行动组 (Python AI 引擎 - 5005 端口)
- **位置**: `projects/wm-remover/ai-engine`
- **核心引擎**: 基于 **Lama (Resolution-robust inpainting)** 的本地化实现。
- **职责**: 执行像素级的无痕修复逻辑。
- **状态**: 监听 `127.0.0.1:5005`，仅供后端内网调用，极速响应。

## 📂 目录结构描述

```text
/home/admin/clawd/projects/wm-remover/
├── ai-engine/                  # 🚀 本地 AI 引擎组 (Python)
│   ├── lama_service.py         # AI 推理核心服务 (Flask)
│   ├── lama_runner.py          # 引擎启动器
│   ├── models/                 # 预训练权重存放处 (Lama-Core)
│   └── venv/                   # Python 独立虚拟环境
│
├── watermark-remover/          # 🏰 指挥指挥部 (Node.js + 前端)
│   ├── backend/                # 后端服务
│   │   ├── src/                # 源码
│   │   ├── dist/               # 运行环境 (已配置本地 AI 转发)
│   │   ├── public/             # 前端静态页面 (index.html)
│   │   └── uploads/            # 图片处理仓库
│   └── frontend/               # 前端源码 (React/Vite)
│
└── scripts/                    # 🛠️ 系统维护与自动化工具
```

## 🚀 启动与运行

1. **AI 引擎**: 运行 `ai-engine/venv/bin/python3 lama_service.py`
2. **后端服务**: 运行 `watermark-remover/backend/dist/index.js`

---
*阿旺提示：该系统现已全面自给自足，告别 410 Gone 报错！* 🤟🐕
