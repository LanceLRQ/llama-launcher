# 从旧脚本迁移到新配置管理指南

本指南帮助你从旧的独立脚本方式迁移到新的统一配置管理方式。

## 对比旧方式 vs 新方式

### 旧方式（独立脚本）

```bash
# 启动模型
./qwen3.5-27b-oups4.6.sh

# 查看日志
./log.sh

# 停止模型
./stop.sh
```

**缺点：**
- 每个模型一个脚本，代码重复
- 参数硬编码，难以维护
- 只能运行一个模型
- 无统一管理接口

### 新方式（配置管理）

```bash
# 列出所有模型
./model-manager.sh ls

# 启动模型
./model-manager.sh start qwen27b-oups

# 查看日志
./model-manager.sh logs

# 停止模型
./model-manager.sh stop

# 切换模型
./model-manager.sh use qwen9b-oups
```

**优点：**
- 统一管理，一个脚本控制所有模型
- YAML 配置，易读易维护
- 参数继承，避免重复
- 功能更丰富（状态查看、配置查看等）

## 迁移步骤

### 1. 备份旧脚本（可选）

```bash
mkdir -p old_scripts
mv qwen3.5-*.sh old_scripts/
mv log.sh old_scripts/
mv stop.sh old_scripts/
```

### 2. 验证新系统

```bash
# 查看所有可用模型
./model-manager.sh ls

# 查看某个模型的配置
./model-manager.sh config qwen27b-oups

# 查看当前状态
./model-manager.sh status
```

### 3. 启动第一个模型

```bash
# 启动模型
./model-manager.sh start qwen27b-oups

# 等待启动完成，自动显示日志
# 按 Ctrl+C 退出日志查看（模型继续运行）
```

### 4. 验证模型运行

```bash
# 查看状态
./model-manager.sh status

# 测试 API（新开一个终端）
curl http://localhost:18080/v1/models
```

### 5. 习惯新工作流

```bash
# 日常使用
./model-manager.sh start qwen27b-oups    # 启动
./model-manager.sh logs                  # 查看日志
./model-manager.sh stop                  # 停止
./model-manager.sh use qwen9b-oups       # 切换模型
```

## 旧脚本与新配置对照表

| 旧脚本 | 新命令 | 配置文件 |
|--------|--------|----------|
| `qwen3.5-27b-oups4.6.sh` | `./model-manager.sh start qwen27b-oups` | `configs/models/qwen27b-oups.yaml` |
| `qwen3.5-35b-a3b.sh` | `./model-manager.sh start qwen35b-a3b` | `configs/models/qwen35b-a3b.yaml` |
| `qwen3.5-9b-oups4.6.sh` | `./model-manager.sh start qwen9b-oups` | `configs/models/qwen9b-oups.yaml` |
| `log.sh` | `./model-manager.sh logs` | - |
| `stop.sh` | `./model-manager.sh stop` | - |

## 参数迁移示例

### 旧脚本参数（qwen3.5-27b-oups4.6.sh）

```bash
docker run -d --rm \
  --name qwen-35-llama-server \
  --gpus all \
  -p 18080:8080 \
  -v ../qwen3.5:/models \
  ghcr.io/ggml-org/llama.cpp:server-cuda \
  -m /models/Qwen3.5-27B-Claude-4.6-Opus-Reasoning-Distilled.gguf \
  --ctx-size 131072 \
  --gpu-layers 999 \
  --cache-type-k q8_0 \
  --cache-type-v q8_0 \
  --temp 0.7
```

### 新配置文件（configs/models/qwen27b-oups.yaml）

```yaml
model:
  name: qwen27b-oups
  display_name: "Qwen 3.5 27B Claude 4.6 Opus"
  gguf_file: Qwen3.5-27B-Claude-4.6-Opus-Reasoning-Distilled.gguf

overrides:
  server:
    gpu_layers: 999        # 覆盖默认值 99
    cache_type_k: "q8_0"   # 覆盖默认值 q4_0
    cache_type_v: "q8_0"   # 覆盖默认值 q4_0
    enable_thinking: true  # 启用思考模式
```

## 常见迁移问题

### Q1: 我需要立即删除旧脚本吗？

A: 不需要。新旧系统可以共存，建议：
1. 先测试新系统
2. 确认一切正常后
3. 再删除旧脚本

### Q2: 如何添加旧脚本中没有的新模型？

A: 使用模板创建新配置：

```bash
# 复制模板
cp configs/models/template.yaml configs/models/my-new-model.yaml

# 编辑配置
vim configs/models/my-new-model.yaml

# 启动新模型
./model-manager.sh start my-new-model
```

### Q3: 旧脚本的参数如何迁移到配置？

A: 对应关系：
- `-m /models/xxx.gguf` → `model.gguf_file: xxx.gguf`
- `--ctx-size 131072` → `server.ctx_size: 131072`
- `--gpu-layers 999` → `server.gpu_layers: 999`
- `--temp 0.7` → `server.temp: 0.7`
- `--chat-template-kwargs '{"enable_thinking": true}'` → `server.enable_thinking: true`

### Q4: 端口和其他 Docker 参数怎么改？

A: 编辑 `configs/default.yaml`：

```yaml
docker:
  host_port: 18080        # 修改端口
  container_name: qwen-llama-server  # 修改容器名
  gpu_devices: all        # 修改 GPU 设备
```

## 优势总结

迁移到新配置管理后，你将获得：

1. **更好的可维护性**
   - 所有配置集中在一个地方
   - YAML 格式易读易改
   - 参数继承减少重复

2. **更丰富的功能**
   - 列出所有模型
   - 查看运行状态
   - 查看模型配置
   - 快速切换模型

3. **更好的扩展性**
   - 添加新模型只需创建 YAML 文件
   - 无需编写新脚本
   - 配置模板帮助快速上手

4. **更安全的操作**
   - 启动前检查模型文件
   - 自动检测冲突
   - 清晰的错误提示

## 需要帮助？

如果迁移过程中遇到问题：

1. 查看配置文件：`./model-manager.sh config <model-name>`
2. 查看运行状态：`./model-manager.sh status`
3. 查看日志：`./model-manager.sh logs`
4. 查看帮助：`./model-manager.sh help`
5. 阅读 README.md

祝迁移顺利！🎉
