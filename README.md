# llama.cpp 模型管理脚本

> 🐳 **基于 Docker 的 llama.cpp 模型管理工具** | 支持 GPU 加速、多模型配置、一键部署

通过 Docker 容器化运行 llama.cpp 模型，提供统一的管理脚本和 YAML 配置方案，让本地 AI 模型部署变得简单高效。

## 📖 项目简介

本项目是一个专门为 **llama.cpp + Docker** 设计的模型管理工具，特别适合需要：

- 🐳 **容器化部署**：完全基于 Docker 运行，环境隔离，跨平台兼容
- 🔄 **频繁切换模型**：在不同大小和类型的模型间快速切换
- ⚙️ **灵活调整参数**：为每个模型定制不同的运行参数
- 🎯 **生产级使用**：支持 NVIDIA GPU 加速、大上下文、高性能配置

本项目提供了一个简单而强大的解决方案来管理 llama.cpp 模型，特别适合需要：

- 🔄 **频繁切换模型**：在不同大小和类型的模型间快速切换
- ⚙️ **灵活调整参数**：为每个模型定制不同的运行参数
- 🐳 **Docker 部署**：容器化运行，环境隔离，一键部署
- 🎯 **生产级使用**：支持 GPU 加速、大上下文、高性能配置

### 核心优势

| 特性 | 说明 |
|------|------|
| 🐳 **Docker 驱动** | 基于 llama.cpp 官方 Docker 镜像，GPU 加速，开箱即用 |
| 📝 **YAML 配置** | 声明式配置，易读易维护，支持参数继承 |
| 🎮 **统一管理** | 一个脚本管理所有模型，无需记忆复杂 docker 命令 |
| 🚀 **开箱即用** | 内置优化的参数配置，覆盖常见使用场景 |
| 🔧 **灵活扩展** | 轻松添加新模型，支持参数覆盖和定制 |
| 🛡️ **安全可靠** | 启动前检查、冲突检测、详细日志 |

### 适用场景

- 💻 **本地开发**：快速测试不同模型的效果
- 🏢 **私有部署**：在服务器上部署本地 AI 服务
- 🔬 **模型对比**：对比不同模型在同一任务上的表现
- 📚 **学习研究**：研究 llama.cpp 的参数调优
- 🎨 **AI 应用**：为应用提供可切换的后端模型

## 快速开始

```bash
# 查看所有可用模型
./model-manager.sh ls

# 启动一个模型
./model-manager.sh start qwen27b-opus

# 查看运行状态
./model-manager.sh status

# 停止当前模型
./model-manager.sh stop
```

## 功能特性

- ✅ **统一管理**: 一个脚本管理所有模型配置
- ✅ **YAML 配置**: 易读易维护的配置文件
- ✅ **单模型运行**: 自动检测，避免冲突
- ✅ **参数继承**: 默认配置 + 模型特定覆盖
- ✅ **实时日志**: 启动后自动显示日志
- ✅ **快速切换**: 一键在不同模型间切换

## 镜像管理

### 拉取镜像

首次使用前需要拉取 llama.cpp Docker 镜像：

```bash
# 拉取 CUDA 版本（推荐，支持 GPU 加速）
docker pull ghcr.io/ggml-org/llama.cpp:server-cuda

# 查看已拉取的镜像
docker images | grep llama.cpp
```

### 镜像说明

| 镜像标签 | 说明 | 适用场景 |
|---------|------|---------|
| `server-cuda` | CUDA 版本，支持 NVIDIA GPU 加速 | 生产环境推荐 |
| `server` | 基础版本，包含所有 backend | 兼容性最好 |
| `server-cublas` | cuBLAS 优化版本（可能需要特定构建） | 需要最佳性能 |
| `server-basic` | CPU only 版本 | 测试或无 GPU 环境 |

### 更新镜像

```bash
# 拉取最新版本
docker pull ghcr.io/ggml-org/llama.cpp:server-cuda

# 查看本地镜像版本
docker images ghcr.io/ggml-org/llama.cpp
```

## 目录结构

```
scripts/
├── model-manager.sh              # 主管理脚本
├── configs/
│   ├── default.yaml             # 默认配置
│   └── models/                  # 模型配置目录
│       ├── qwen27b-opus.yaml    # 示例配置（Qwen 3.5-27B-Claude-4.6-Opus-Distilled）
│       └── template.yaml        # 配置模板
└── README.md                    # 本文档
```

## 使用方法

### 1. 列出所有模型

```bash
./model-manager.sh ls
```

输出示例：
```
[INFO] 可用模型列表：

  • qwen27b-opus
    显示名称: Qwen 3.5 27B Claude 4.6 Opus
    模型文件: Qwen3.5-27B-Claude-4.6-Opus-Reasoning-Distilled.gguf
```

**注意：** `template.yaml` 是配置模板文件，不会被 `ls` 命令显示。复制此文件创建新模型配置即可。

### 2. 启动模型

```bash
./model-manager.sh start qwen27b-opus
```

- 自动检查是否有模型正在运行
- 验证模型文件是否存在
- 启动后自动显示日志（Ctrl+C 退出日志查看，不影响模型运行）

### 3. 查看状态

```bash
./model-manager.sh status
```

输出示例：
```
[INFO] 模型运行状态：

  容器名称: qwen-llama-server
  运行模型: Qwen 3.5 27B Claude 4.6 Opus (qwen27b-opus)
  运行状态: 运行中
  启动时间: 2026-03-13 10:30:00
```

### 4. 停止模型

```bash
./model-manager.sh stop
```

### 5. 查看日志

```bash
./model-manager.sh logs
```

实时显示当前运行模型的日志。

### 6. 查看模型配置

```bash
./model-manager.sh config qwen27b-opus
```

输出示例：
```
[INFO] 模型配置: qwen27b-opus

模型名称: qwen27b-opus
显示名称: Qwen 3.5 27B Claude 4.6 Opus
GGUF 文件: Qwen3.5-27B-Claude-4.6-Opus-Reasoning-Distilled.gguf

参数覆盖:
  [server]
    gpu_layers: 999
    cache_type_k: q8_0
    cache_type_v: q8_0
    enable_thinking: true
```

### 7. 重启模型

```bash
./model-manager.sh restart qwen27b-opus
```

### 8. 切换模型

```bash
./model-manager.sh use <model-name>
```

自动停止当前模型，然后启动新模型。

## 配置文件说明

### 默认配置 (configs/default.yaml)

包含所有 llama.cpp 参数的默认值，所有模型共享：

```yaml
docker:
  image: ghcr.io/ggml-org/llama.cpp:server-cuda
  container_name: qwen-llama-server
  model_volume: models/qwen3.5:/models
  host_port: 18080
  container_port: 8080

server:
  host: "0.0.0.0"
  ctx_size: 131072
  gpu_layers: 99
  flash_attention: "on"
  # ... 更多参数
```

### 模型配置 (configs/models/<model-name>.yaml)

每个模型一个配置文件，只需定义特定的覆盖参数：

```yaml
model:
  name: qwen27b-opus
  display_name: "Qwen 3.5 27B Claude 4.6 Opus"
  gguf_file: Qwen3.5-27B-Claude-4.6-Opus-Reasoning-Distilled.gguf

overrides:
  server:
    gpu_layers: 999
    cache_type_k: "q8_0"
    cache_type_v: "q8_0"
    enable_thinking: true
```

## 添加新模型

1. 将 GGUF 模型文件放到 `models/qwen3.5/` 目录
2. 创建新的配置文件 `configs/models/<model-name>.yaml`：

```yaml
model:
  name: my-new-model
  display_name: "My New Model"
  gguf_file: My-New-Model.gguf

overrides:
  server:
    ctx_size: 65536
    gpu_layers: 50
    temp: 0.8
```

3. 使用新模型：

```bash
./model-manager.sh start my-new-model
```

## 常见问题

### Q: 如何同时运行多个模型？

A: 当前设计只支持单模型运行。如需多模型并发，需要：
- 为每个模型分配不同的容器名和端口
- 修改配置文件结构
- 欢迎提交 PR 或提出建议

### Q: 端口冲突怎么办？

A: 在 `configs/default.yaml` 中修改 `host_port`：

```yaml
docker:
  host_port: 18081  # 改为其他端口
```

### Q: 如何调整 GPU 使用？

A: 在模型配置中调整 `gpu_layers`：

```yaml
overrides:
  server:
    gpu_layers: 50  # 降低 GPU 层数
```

### Q: 如何修改采样参数？

A: 在模型配置中添加采样参数覆盖：

```yaml
overrides:
  server:
    temp: 0.5          # 温度
    top_p: 0.9         # Top-p 采样
    top_k: 40          # Top-k 采样
    repeat_penalty: 1.1
```

## 技术细节

### 配置合并逻辑

1. 加载 `configs/default.yaml` 作为基础
2. 加载 `configs/models/<model-name>.yaml`
3. 将 `model` 字段合并到配置
4. 将 `overrides` 字段递归合并到对应 sections
5. 最终配置用于生成 Docker 命令

### Docker 命令生成

脚本自动将 YAML 配置转换为 llama.cpp 参数：

```bash
docker run -d --rm \
  --name qwen-llama-server \
  --gpus all \
  -p 18080:8080 \
  -v models/qwen3.5:/models \
  ghcr.io/ggml-org/llama.cpp:server-cuda \
  -m /models/Qwen3.5-27B-... \
  --ctx-size 131072 \
  --gpu-layers 999 \
  # ... 更多参数
```

### 依赖检查

- Python 3+
- PyYAML (`pip install pyyaml`)
- Docker
- NVIDIA Docker Runtime

## 兼容性

向后兼容旧的独立脚本方式：
- 原有的 `qwen3.5-*-*.sh` 脚本仍然可用
- 建议逐步迁移到新的配置管理方式
- 两套系统可以共存

## 许可

MIT License

## 贡献

欢迎提交 Issue 和 Pull Request！

## 附录：llama.cpp 常用参数对照表

| 中文名称 | 英文参数 | 配置字段 | 说明 | 推荐值 |
|---------|---------|---------|------|--------|
| **模型相关** |||||
| 模型文件 | `-m` / `--model` | `gguf_file` | GGUF 模型文件路径 | - |
| 多模态投影 | `--mmproj` | `mmproj_file` | 视觉模型的多模态投影文件 | 可选 |
| **上下文与内存** |||||
| 上下文大小 | `--ctx-size` / `-c` | `ctx_size` | 上下文窗口大小（token 数） | 131072 / 262144 |
| GPU 层数 | `--gpu-layers` / `-ngl` | `gpu_layers` | 加载到 GPU 的模型层数 | 99 / 999 |
| 批处理大小 | `--batch-size` / `-b` | `batch_size` | 批处理大小 | 4096 |
| 微批处理 | `--ubatch-size` / `-ub` | `ubatch_size` | 微批处理大小 | 1024 |
| **性能优化** |||||
| Flash Attention | `--flash-attn` / `-fa` | `flash_attention` | Flash Attention 加速 | on |
| 连续批处理 | `--cont-batching` / `-cb` | `cont_batching` | 连续批处理模式 | true |
| K Cache 类型 | `--cache-type-k` / `-ctk` | `cache_type_k` | K Cache 量化类型 | q8_0 / q4_0 |
| V Cache 类型 | `--cache-type-v` / `-ctv` | `cache_type_v` | V Cache 量化类型 | q8_0 / q4_0 |
| 张量分割 | `--tensor-split` | - | 多 GPU 张量分割 | 1,1 |
| **采样参数** |||||
| 温度 | `--temp` | `temp` | 采样温度，越高越随机 | 0.5 - 1.0 |
| Top-p 采样 | `--top-p` | `top_p` | 核采样阈值 | 0.8 - 0.95 |
| Top-k 采样 | `--top-k` | `top_k` | 保留前 k 个概率 | 20 - 40 |
| 重复惩罚 | `--repeat-penalty` | `repeat_penalty` | 重复文本惩罚 | 1.0 - 1.2 |
| 存在惩罚 | `--presence-penalty` | `presence_penalty` | 新主题鼓励 | 1.0 - 2.0 |
| Min-p 采样 | `--min-p` | `min_p` | 最小概率阈值 | 0.0 - 0.1 |
| **功能开关** |||||
| 思考模式 | `--chat-template-kwargs` | `enable_thinking` | 启用思考模式（扩展推理） | true / false |
| **网络与日志** |||||
| 监听地址 | `--host` | `host` | 服务器监听地址 | 0.0.0.0 |
| 监听端口 | `--port` | `port` | 服务器监听端口 | 8080 |
| **Cache 量化类型说明** |||||
| - | `f16` | - | 半精度，无量化 | 最佳质量 |
| - | `q8_0` | - | 8-bit 量化 | 高质量 |
| - | `q4_0` | - | 4-bit 量化 | 平衡 |
| - | `q4_k` | - | 4-bit K-量化 | 更小体积 |

### 参数选择建议

**注意：** 以下配置中的短选项（如 `-c`, `-ngl`, `-b` 等）主要用于命令行，在 YAML 配置文件中请使用完整字段名。

**小显存（< 8GB）:**
```yaml
gpu_layers: 30-50
cache_type_k: "q4_0"
cache_type_v: "q4_0"
ctx_size: 32768
```

**中等显存（8-16GB）:**
```yaml
gpu_layers: 99
cache_type_k: "q4_0"
cache_type_v: "q4_0"
ctx_size: 131072
```

**大显存（> 16GB）:**
```yaml
gpu_layers: 999
cache_type_k: "q8_0"
cache_type_v: "q8_0"
ctx_size: 262144
```
