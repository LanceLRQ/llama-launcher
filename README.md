# llama.cpp 模型管理脚本

统一管理多个 llama.cpp 模型的启动、停止、切换等操作。

## 快速开始

```bash
# 查看所有可用模型
./model-manager.sh ls

# 启动一个模型
./model-manager.sh start qwen27b-oups

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

## 目录结构

```
scripts/
├── model-manager.sh              # 主管理脚本
├── configs/
│   ├── default.yaml             # 默认配置
│   └── models/                  # 模型配置目录
│       ├── qwen27b-oups.yaml
│       ├── qwen35b-a3b.yaml
│       └── qwen9b-oups.yaml
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

  • qwen27b-oups
    显示名称: Qwen 3.5 27B Claude 4.6 Opus
    模型文件: Qwen3.5-27B-Claude-4.6-Opus-Reasoning-Distilled.gguf

  • qwen35b-a3b
    显示名称: Qwen 3.5 35B A3B
    模型文件: Qwen3.5-35B-A3B-Q4_K_M.gguf
```

### 2. 启动模型

```bash
./model-manager.sh start qwen27b-oups
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
  运行模型: Qwen 3.5 27B Claude 4.6 Opus (qwen27b-oups)
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
./model-manager.sh config qwen27b-oups
```

输出示例：
```
[INFO] 模型配置: qwen27b-oups

模型名称: qwen27b-oups
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
./model-manager.sh restart qwen27b-oups
```

### 8. 切换模型

```bash
./model-manager.sh use qwen9b-oups
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
  name: qwen27b-oups
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
