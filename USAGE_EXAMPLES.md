# 使用示例

本文档提供 model-manager.sh 的实际使用示例。

## 示例 1: 日常对话流程

```bash
# 1. 查看可用模型
./model-manager.sh ls

# 2. 启动快速响应的 9B 模型
./model-manager.sh start qwen9b-oups

# 3. 等待启动完成（看到 "HTTP server listening"）
# 按 Ctrl+C 退出日志查看

# 4. 测试对话
curl http://localhost:18080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-4",
    "messages": [
      {"role": "user", "content": "你好，请介绍一下你自己"}
    ]
  }'

# 5. 查看运行状态
./model-manager.sh status

# 6. 使用完毕，停止模型
./model-manager.sh stop
```

## 示例 2: 编程辅助

```bash
# 启动推理能力更强的 27B 模型
./model-manager.sh start qwen27b-oups

# 代码优化请求
curl http://localhost:18080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-4",
    "messages": [
      {
        "role": "user", 
        "content": "请优化以下 Python 代码，使其更高效：\n\ndef find_duplicates(arr):\n    result = []\n    for i in range(len(arr)):\n        for j in range(i+1, len(arr)):\n            if arr[i] == arr[j] and arr[i] not in result:\n                result.append(arr[i])\n    return result"
      }
    ]
  }'

# 代码解释
curl http://localhost:18080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-4",
    "messages": [
      {
        "role": "user", 
        "content": "解释以下 JavaScript 代码的作用：\n\nconst arr = [1, 2, 3, 4, 5];\nconst doubled = arr.map(x => x * 2);"
      }
    ]
  }'
```

## 示例 3: 模型切换

```bash
# 当前运行的是 qwen9b-oups
./model-manager.sh status

# 需要更强的推理能力，切换到 27B 模型
./model-manager.sh use qwen27b-oups
# 自动停止当前模型，然后启动新模型

# 切换回小模型
./model-manager.sh use qwen9b-oups
```

## 示例 4: 查看和调整配置

```bash
# 查看当前模型配置
./model-manager.sh config qwen27b-oups

# 输出：
# [INFO] 模型配置: qwen27b-oups
# 
# 模型名称: qwen27b-oups
# 显示名称: Qwen 3.5 27B Claude 4.6 Opus
# GGUF 文件: Qwen3.5-27B-Claude-4.6-Opus-Reasoning-Distilled.gguf
# 
# 参数覆盖:
#   [server]
#     gpu_layers: 999
#     cache_type_k: q8_0
#     cache_type_v: q8_0
#     enable_thinking: True

# 如需调整配置，直接编辑 YAML 文件
vim configs/models/qwen27b-oups.yaml

# 例如降低 GPU 使用：
# overrides:
#   server:
#     gpu_layers: 50  # 从 999 降低到 50
```

## 示例 5: 调试问题

```bash
# 模型启动失败，查看详细日志
./model-manager.sh logs

# 常见问题：
# 
# 1. 显存不足
# 日志显示：CUDA out of memory
# 解决：编辑模型配置，降低 gpu_layers
# 
# 2. 端口冲突
# 日志显示：port is already allocated
# 解决：修改 configs/default.yaml 中的 host_port
# 
# 3. 模型文件不存在
# 日志显示：cannot access model file
# 解决：检查 gguf_file 路径是否正确

# 查看当前状态确认问题已解决
./model-manager.sh status
```

## 示例 6: 添加新模型

```bash
# 1. 复制配置模板
cp configs/models/template.yaml configs/models/my-new-model.yaml

# 2. 编辑配置
vim configs/models/my-new-model.yaml

# 修改以下字段：
# model:
#   name: my-new-model
#   display_name: "My New Model"
#   gguf_file: My-New-Model-Q4_K_M.gguf
# 
# overrides:
#   server:
#     ctx_size: 65536
#     gpu_layers: 50

# 3. 确认模型文件存在
ls ../qwen3.5/My-New-Model-Q4_K_M.gguf

# 4. 列出所有模型（应该包含新模型）
./model-manager.sh ls

# 5. 启动新模型
./model-manager.sh start my-new-model
```

## 示例 7: 批处理测试

```bash
# 启动模型
./model-manager.sh start qwen9b-oups

# 批量测试多个请求
for i in {1..5}; do
  echo "请求 $i:"
  curl -s http://localhost:18080/v1/chat/completions \
    -H "Content-Type: application/json" \
    -d "{
      \"model\": \"gpt-4\",
      \"messages\": [{\"role\": \"user\", \"content\": \"请生成第 $i 个问候语\"}]
    }" | python3 -c "import sys, json; print(json.load(sys.stdin)['choices'][0]['message']['content'])"
  echo ""
done

# 查看日志，观察批处理效果
./model-manager.sh logs
```

## 示例 8: 性能对比

```bash
# 测试不同模型的性能

echo "=== 测试 qwen9b-oups ==="
./model-manager.sh use qwen9b-oups
time curl -s http://localhost:18080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model": "gpt-4", "messages": [{"role": "user", "content": "写一首短诗"}]}'

echo ""
echo "=== 测试 qwen27b-oups ==="
./model-manager.sh use qwen27b-oups
time curl -s http://localhost:18080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model": "gpt-4", "messages": [{"role": "user", "content": "写一首短诗"}]}'
```

## 示例 9: 集成到脚本

```bash
#!/bin/bash
# script_with_model.sh: 使用模型的脚本示例

# 启动模型
./model-manager.sh start qwen9b-oups > /dev/null 2>&1

# 等待模型就绪
echo "等待模型启动..."
sleep 30

# 检查模型状态
if ! ./model-manager.sh status | grep -q "运行中"; then
    echo "模型启动失败"
    exit 1
fi

# 使用模型
response=$(curl -s http://localhost:18080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-4",
    "messages": [{"role": "user", "content": "分析这段文本"}]
  }')

# 处理响应
echo "$response" | python3 -c "import sys, json; print(json.load(sys.stdin)['choices'][0]['message']['content'])"

# 清理
./model-manager.sh stop
```

## 示例 10: 与 OpenAI SDK 集成

```python
# test_model.py: Python 客户端示例
import openai

# 配置客户端
client = openai.OpenAI(
    base_url="http://localhost:18080/v1",
    api_key="dummy"
)

# 测试连接
try:
    # 列出模型
    models = client.models.list()
    print("可用模型:", models.data[0].id)
    
    # 发送聊天请求
    response = client.chat.completions.create(
        model="gpt-4",
        messages=[
            {"role": "user", "content": "你好，请介绍一下你自己"}
        ],
        temperature=0.7,
        max_tokens=1000
    )
    
    print("\n助手回复:")
    print(response.choices[0].message.content)
    
except Exception as e:
    print(f"错误: {e}")
```

运行：

```bash
# 启动模型
./model-manager.sh start qwen27b-oups

# 等待启动后运行 Python 脚本
python3 test_model.py
```

## 提示

1. **首次使用**：先查看 `./model-manager.sh ls` 了解可用模型
2. **快速测试**：使用小模型（qwen9b-oups）
3. **生产使用**：使用大模型（qwen27b-oups 或 qwen35b-a3b）
4. **调试问题**：使用 `./model-manager.sh logs` 查看详细日志
5. **切换模型**：使用 `use` 命令自动停止和启动

## 更多资源

- 完整文档：`cat README.md`
- 快速开始：`cat QUICKSTART.md`
- 迁移指南：`cat MIGRATION.md`
- 帮助信息：`./model-manager.sh help`
