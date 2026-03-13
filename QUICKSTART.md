# 快速开始指南

5 分钟上手 llama.cpp 模型管理系统。

## 前提条件

- ✅ Docker 已安装并运行
- ✅ NVIDIA Docker Runtime
- ✅ Python 3 + PyYAML
- ✅ GGUF 模型文件已下载

## 30 秒快速启动

```bash
# 1. 列出所有可用模型
./model-manager.sh ls

# 2. 启动一个模型（推荐从 9B 开始）
./model-manager.sh start qwen9b-opus

# 3. 等待启动完成，自动显示日志
# 看到 "HTTP server listening" 即启动成功
# 按 Ctrl+C 退出日志查看（模型继续运行）
```

## 验证模型运行

```bash
# 查看状态
./model-manager.sh status

# 测试 API（新开一个终端）
curl http://localhost:18080/v1/models

# 或者用 OpenAI 客户端测试
python3 -c "
import openai
client = openai.OpenAI(
    base_url='http://localhost:18080/v1',
    api_key='dummy'
)
response = client.chat.completions.create(
    model='gpt-4',
    messages=[{'role': 'user', 'content': '你好，请介绍一下你自己'}]
)
print(response.choices[0].message.content)
"
```

## 日常操作

```bash
# 查看日志（实时）
./model-manager.sh logs

# 停止模型
./model-manager.sh stop

# 切换到其他模型
./model-manager.sh use qwen27b-opus

# 查看模型配置
./model-manager.sh config qwen27b-opus
```

## 模型推荐

### 按性能选择

| 模型 | 显存需求 | 推荐场景 | 启动命令 |
|------|---------|---------|---------|
| qwen9b-opus | ~10GB | 日常对话、快速测试 | `./model-manager.sh start qwen9b-opus` |
| qwen27b-opus | ~18GB | 复杂推理、编程辅助 | `./model-manager.sh start qwen27b-opus` |
| qwen35b-a3b | ~22GB | 深度思考、长文本 | `./model-manager.sh start qwen35b-a3b` |

### 按功能选择

**快速响应**：qwen9b-opus
- 最快启动速度
- 低延迟
- 适合日常对话

**平衡性能**：qwen27b-opus
- 推理能力强
- 上下文大（131K）
- 适合编程、写作

**最强能力**：qwen35b-a3b
- 最强推理
- 更大模型
- 适合复杂任务

## 常用配置调整

### 降低显存占用

编辑模型配置文件（如 `configs/models/qwen27b-opus.yaml`）：

```yaml
overrides:
  server:
    gpu_layers: 50  # 降低 GPU 层数（部分移到 CPU）
```

### 调整输出随机性

```yaml
overrides:
  server:
    temp: 0.3       # 降低随机性（更确定）
    top_p: 0.9      # 调整采样范围
```

### 增加上下文长度

```yaml
overrides:
  server:
    ctx_size: 262144  # 增加到 256K 上下文
```

## 故障排查

### 模型启动失败

```bash
# 查看详细日志
./model-manager.sh logs

# 常见原因：
# 1. 显存不足 → 降低 gpu_layers
# 2. 端口冲突 → 修改 configs/default.yaml 中的 host_port
# 3. 模型文件不存在 → 检查 gguf_file 路径
```

### 响应速度慢

```bash
# 优化建议：
# 1. 增加批处理大小
# 2. 启用 flash-attention（默认已启用）
# 3. 使用更小的模型
```

### 内存溢出

```bash
# 解决方案：
# 1. 降低 gpu_layers
# 2. 减小 batch_size 和 ubatch_size
# 3. 使用更小的模型
```

## 下一步

- 📖 阅读完整文档：`cat README.md`
- 🔄 从旧脚本迁移：`cat MIGRATION.md`
- ⚙️ 添加新模型：参考 `configs/models/template.yaml`
- 🐛 遇到问题：查看日志 `./model-manager.sh logs`

## 示例工作流

### 日常对话

```bash
# 启动快速模型
./model-manager.sh start qwen9b-opus

# 与模型对话
curl http://localhost:18080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-4",
    "messages": [{"role": "user", "content": "写一首关于春天的诗"}]
  }'
```

### 编程辅助

```bash
# 启动推理模型
./model-manager.sh start qwen27b-opus

# 代码补全/优化
curl http://localhost:18080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-4",
    "messages": [{"role": "user", "content": "优化这段 Python 代码：\nfor i in range(len(arr)):\n    print(arr[i])"}]
  }'
```

### 长文本分析

```bash
# 启动大上下文模型
./model-manager.sh start qwen27b-opus

# 分析长文本
cat long_text.txt | curl http://localhost:18080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d @- \
  -d '{
    "model": "gpt-4",
    "messages": [{"role": "user", "content": "总结以上内容"}]
  }'
```

## 提示

1. **首次使用**：从小模型开始（qwen9b-opus）
2. **性能优先**：使用适合你显存的模型
3. **质量优先**：使用更大的模型（qwen27b-opus / qwen35b-a3b）
4. **切换模型**：使用 `use` 命令快速切换
5. **查看日志**：遇到问题先看日志

## 获取帮助

```bash
# 查看所有命令
./model-manager.sh help

# 列出所有模型
./model-manager.sh ls

# 查看模型配置
./model-manager.sh config <model-name>

# 查看当前状态
./model-manager.sh status
```

---

准备好了吗？开始使用：

```bash
./model-manager.sh ls
./model-manager.sh start qwen9b-opus
```

🚀 享受你的 AI 助手！
