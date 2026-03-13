#!/bin/bash
# llama.cpp 模型管理脚本
# 使用方法: ./model-manager.sh <command> [model-name]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${SCRIPT_DIR}/configs"
DEFAULT_CONFIG="${CONFIG_DIR}/default.yaml"
MODELS_DIR="${CONFIG_DIR}/models"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 日志函数
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 检查依赖
check_dependencies() {
    if ! command -v python3 &> /dev/null; then
        log_error "Python3 未安装"
        exit 1
    fi
    
    if ! python3 -c "import yaml" 2>/dev/null; then
        log_error "PyYAML 未安装，请运行: pip install pyyaml"
        exit 1
    fi
}

# 检查 Docker 是否运行
check_docker() {
    if ! docker info &> /dev/null; then
        log_error "Docker 未运行"
        exit 1
    fi
}

# 解析 YAML 配置
parse_config() {
    local config_file=$1
    local key=$2
    
    python3 -c "
import yaml
import sys

with open('${config_file}', 'r') as f:
    config = yaml.safe_load(f)

# 支持嵌套键访问，如 'docker.image'
keys = '${key}'.split('.')
value = config
for k in keys:
    if isinstance(value, dict):
        value = value.get(k)
    else:
        value = None
        break

if value is None:
    sys.exit(1)
elif isinstance(value, bool):
    print('true' if value else 'false')
elif isinstance(value, list):
    print(' '.join(map(str, value)))
else:
    print(value)
" 2>/dev/null
}

# 获取嵌套配置值
get_config_value() {
    local model_name=$1
    local key=$2
    local default_value=$3
    
    # 先尝试从模型配置的 overrides 中获取
    local model_config="${MODELS_DIR}/${model_name}.yaml"
    
    if [[ -f "$model_config" ]]; then
        # 尝试从 overrides 获取
        local override_value=$(parse_config "$model_config" "overrides.${key}")
        if [[ -n "$override_value" ]]; then
            echo "$override_value"
            return
        fi
        
        # 尝试从 model 配置获取
        local model_value=$(parse_config "$model_config" "model.${key}")
        if [[ -n "$model_value" ]]; then
            echo "$model_value"
            return
        fi
    fi
    
    # 从默认配置获取
    local default=$(parse_config "$DEFAULT_CONFIG" "$key")
    if [[ -n "$default" ]]; then
        echo "$default"
    else
        echo "$default_value"
    fi
}

# 获取完整的配置（合并后）
get_full_config() {
    local model_name=$1
    
    cat << 'EOF' | python3 - "$model_name" "$DEFAULT_CONFIG" "$MODELS_DIR"
import yaml
import sys

model_name = sys.argv[1]
default_config = sys.argv[2]
models_dir = sys.argv[3]

# 加载默认配置
with open(default_config, 'r') as f:
    config = yaml.safe_load(f)

# 加载模型配置并合并
model_config_file = f"{models_dir}/{model_name}.yaml"
with open(model_config_file, 'r') as f:
    model_config = yaml.safe_load(f)

# 添加模型信息
config['model'] = model_config.get('model', {})

# 应用 overrides
if 'overrides' in model_config:
    for section, values in model_config['overrides'].items():
        if section not in config:
            config[section] = {}
        config[section].update(values)

# 输出为可以 eval 的格式
print(config)
EOF
}

# 列出所有可用模型
list_models() {
    log_info "可用模型列表："
    echo ""
    
    for config_file in "${MODELS_DIR}"/*.yaml; do
        if [[ -f "$config_file" ]]; then
            local model_name=$(parse_config "$config_file" "model.name")
            local display_name=$(parse_config "$config_file" "model.display_name")
            local gguf_file=$(parse_config "$config_file" "model.gguf_file")
            
            if [[ -n "$model_name" ]]; then
                echo -e "  ${GREEN}•${NC} ${model_name}"
                echo -e "    显示名称: ${display_name}"
                echo -e "    模型文件: ${gguf_file}"
                echo ""
            fi
        fi
    done
}

# 检查模型是否正在运行
is_model_running() {
    local container_name=$(parse_config "$DEFAULT_CONFIG" "docker.container_name")
    docker ps --format '{{.Names}}' | grep -q "^${container_name}$"
}

# 获取当前运行的模型
get_running_model() {
    local container_name=$(parse_config "$DEFAULT_CONFIG" "docker.container_name")
    if docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then
        local model_label=$(docker inspect --format '{{index .Config.Labels "model_name"}}' "$container_name" 2>/dev/null || echo "")
        echo "$model_label"
    fi
}

# 查看状态
show_status() {
    local container_name=$(parse_config "$DEFAULT_CONFIG" "docker.container_name")
    
    echo ""
    log_info "模型运行状态："
    echo ""
    
    if docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then
        local model_name=$(get_running_model)
        local status=$(docker inspect --format '{{.State.Status}}' "$container_name")
        local uptime=$(docker inspect --format '{{.State.StartedAt}}' "$container_name")
        
        echo -e "  容器名称: ${GREEN}${container_name}${NC}"
        
        if [[ -n "$model_name" ]]; then
            local model_config="${MODELS_DIR}/${model_name}.yaml"
            local display_name=$(parse_config "$model_config" "model.display_name")
            echo -e "  运行模型: ${GREEN}${display_name}${NC} (${model_name})"
        else
            echo -e "  运行模型: ${YELLOW}未知${NC}"
        fi
        
        echo -e "  运行状态: ${GREEN}运行中${NC}"
        echo -e "  启动时间: ${uptime}"
    else
        echo -e "  容器名称: ${container_name}"
        echo -e "  运行状态: ${YELLOW}未运行${NC}"
    fi
    
    echo ""
}

# 查看模型配置
show_model_config() {
    local model_name=$1
    
    if [[ -z "$model_name" ]]; then
        log_error "请指定模型名称"
        echo "使用方法: $0 config <model-name>"
        exit 1
    fi
    
    local model_config="${MODELS_DIR}/${model_name}.yaml"
    
    if [[ ! -f "$model_config" ]]; then
        log_error "模型配置不存在: ${model_name}"
        exit 1
    fi
    
    log_info "模型配置: ${model_name}"
    echo ""
    
    cat << 'EOF' | python3 - "$model_config"
import yaml
import sys

config_file = sys.argv[1]
with open(config_file, 'r') as f:
    config = yaml.safe_load(f)

print(f"模型名称: {config.get('model', {}).get('name')}")
print(f"显示名称: {config.get('model', {}).get('display_name')}")
print(f"GGUF 文件: {config.get('model', {}).get('gguf_file')}")
print("")
print("参数覆盖:")
if 'overrides' in config:
    for section, values in config['overrides'].items():
        print(f"  [{section}]")
        for key, value in values.items():
            print(f"    {key}: {value}")
EOF
}

# 启动模型
start_model() {
    local model_name=$1
    
    if [[ -z "$model_name" ]]; then
        log_error "请指定模型名称"
        echo "使用方法: $0 start <model-name>"
        echo "提示: 使用 '$0 ls' 查看所有可用模型"
        exit 1
    fi
    
    local model_config="${MODELS_DIR}/${model_name}.yaml"
    
    if [[ ! -f "$model_config" ]]; then
        log_error "模型配置不存在: ${model_name}"
        exit 1
    fi
    
    # 检查是否已有模型在运行
    if is_model_running; then
        local running_model=$(get_running_model)
        log_warning "已有模型正在运行: ${running_model}"
        echo "请先运行 '$0 stop' 停止当前模型"
        exit 1
    fi
    
    # 检查模型文件是否存在
    local model_volume=$(parse_config "$DEFAULT_CONFIG" "docker.model_volume")
    local volume_path="${model_volume%:*}"  # 获取主机路径
    local gguf_file=$(parse_config "$model_config" "model.gguf_file")
    local full_model_path="${SCRIPT_DIR}/${volume_path}/${gguf_file}"
    
    if [[ ! -f "$full_model_path" ]]; then
        log_error "模型文件不存在: ${full_model_path}"
        exit 1
    fi
    
    log_info "启动模型: ${model_name}"
    
    # 获取配置参数
    local docker_image=$(parse_config "$DEFAULT_CONFIG" "docker.image")
    local container_name=$(parse_config "$DEFAULT_CONFIG" "docker.container_name")
    local host_port=$(parse_config "$DEFAULT_CONFIG" "docker.host_port")
    local container_port=$(parse_config "$DEFAULT_CONFIG" "docker.container_port")
    local gpu_devices=$(parse_config "$DEFAULT_CONFIG" "docker.gpu_devices")
    
    local model_path="/models/${gguf_file}"
    local mmproj_file=$(parse_config "$model_config" "model.mmproj_file" 2>/dev/null || echo "")
    local host=$(get_config_value "$model_name" "server.host")
    local ctx_size=$(get_config_value "$model_name" "server.ctx_size")
    local gpu_layers=$(get_config_value "$model_name" "server.gpu_layers")
    local flash_attn=$(get_config_value "$model_name" "server.flash_attention")
    local batch_size=$(get_config_value "$model_name" "server.batch_size")
    local ubatch_size=$(get_config_value "$model_name" "server.ubatch_size")
    local cont_batching=$(get_config_value "$model_name" "server.cont_batching")
    local cache_type_k=$(get_config_value "$model_name" "server.cache_type_k")
    local cache_type_v=$(get_config_value "$model_name" "server.cache_type_v")
    local enable_thinking=$(get_config_value "$model_name" "server.enable_thinking")
    local repeat_penalty=$(get_config_value "$model_name" "server.repeat_penalty")
    local presence_penalty=$(get_config_value "$model_name" "server.presence_penalty")
    local min_p=$(get_config_value "$model_name" "server.min_p")
    local top_k=$(get_config_value "$model_name" "server.top_k")
    local top_p=$(get_config_value "$model_name" "server.top_p")
    local temp=$(get_config_value "$model_name" "server.temp")
    
    # 构建容器名参数
    if [[ "$gpu_devices" == "all" ]]; then
        local gpu_param="--gpus all"
    else
        local gpu_param="--gpus \"device=${gpu_devices}\""
    fi
    
    # 构建 cont-batching 参数
    local cont_batching_param=""
    if [[ "$cont_batching" == "true" ]]; then
        cont_batching_param="--cont-batching"
    fi
    
    # 构建 cache type 参数
    local cache_params=""
    if [[ -n "$cache_type_k" ]]; then
        cache_params="-ctk ${cache_type_k}"
    fi
    if [[ -n "$cache_type_v" ]]; then
        cache_params="${cache_params} -ctv ${cache_type_v}"
    fi
    
    # 构建 mmproj 参数
    local mmproj_params=""
    if [[ -n "$mmproj_file" ]]; then
        mmproj_params="--mmproj /models/${mmproj_file}"
    fi
    
    # 将相对路径转换为绝对路径
    local volume_path="${model_volume%:*}"
    local container_path="${model_volume#*:}"
    local absolute_volume_path="${SCRIPT_DIR}/${volume_path}"
    
    log_info "容器名称: ${container_name}"
    log_info "端口映射: ${host_port}:${container_port}"
    log_info "模型文件: ${gguf_file}"
    echo ""
    
    # 启动容器
    local container_id=$(docker run -d --rm \
      --name "${container_name}" \
      --gpus all \
      -e LLAMA_CHAT_TEMPLATE_KWARGS='{"enable_thinking":'"${enable_thinking}"'}' \
      -p "${host_port}:${container_port}" \
      -v "${absolute_volume_path}:${container_path}" \
      --label "model_name=${model_name}" \
      "${docker_image}" \
      -m "${model_path}" \
      --host "${host}" \
      --ctx-size "${ctx_size}" \
      --gpu-layers "${gpu_layers}" \
      --flash-attn "${flash_attn}" \
      --batch-size "${batch_size}" \
      --ubatch-size "${ubatch_size}" \
      ${cache_params} \
      ${cont_batching_param} \
      ${mmproj_params} \
      --repeat-penalty "${repeat_penalty}" \
      --presence-penalty "${presence_penalty}" \
      --min-p "${min_p}" \
      --top-k "${top_k}" \
      --top-p "${top_p}" \
      --temp "${temp}")
    
    local exit_code=$?
    
    if [[ $exit_code -ne 0 ]]; then
        log_error "Docker 命令执行失败，退出码: ${exit_code}"
        exit 1
    fi
    
    # 等待容器启动并检查状态
    sleep 5
    
    if ! docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then
        log_error "容器启动后立即退出"
        echo "请查看容器日志了解详情："
        echo "docker logs ${container_name}"
        echo ""
        docker logs --tail 30 "${container_name}" 2>&1 || true
        docker rm -f "${container_name}" > /dev/null 2>&1 || true
        exit 1
    fi
    
    log_success "模型启动成功！"
    echo ""
    log_info "查看日志: $0 logs"
    log_info "停止模型: $0 stop"
    echo ""
    log_info "正在显示日志（Ctrl+C 退出不停止容器）..."
    echo ""
    docker logs -f "${container_name}"
}

# 停止模型
stop_model() {
    local container_name=$(parse_config "$DEFAULT_CONFIG" "docker.container_name")
    
    if ! is_model_running; then
        log_warning "没有正在运行的模型"
        exit 0
    fi
    
    local running_model=$(get_running_model)
    
    if [[ -n "$running_model" ]]; then
        log_info "停止模型: ${running_model}"
    else
        log_info "停止模型"
    fi
    
    docker kill "${container_name}" > /dev/null 2>&1
    
    if [[ $? -eq 0 ]]; then
        log_success "模型已停止"
    else
        log_error "停止模型失败"
        exit 1
    fi
}

# 重启模型
restart_model() {
    local model_name=$1
    
    if [[ -z "$model_name" ]]; then
        log_error "请指定模型名称"
        echo "使用方法: $0 restart <model-name>"
        exit 1
    fi
    
    if is_model_running; then
        stop_model
        sleep 2
    fi
    
    start_model "$model_name"
}

# 查看日志
show_logs() {
    local container_name=$(parse_config "$DEFAULT_CONFIG" "docker.container_name")
    
    if ! is_model_running; then
        log_warning "没有正在运行的模型"
        exit 0
    fi
    
    docker logs -f "${container_name}"
}

# 切换模型
use_model() {
    local model_name=$1
    
    if [[ -z "$model_name" ]]; then
        log_error "请指定模型名称"
        echo "使用方法: $0 use <model-name>"
        exit 1
    fi
    
    if is_model_running; then
        log_info "切换到模型: ${model_name}"
        stop_model
        sleep 2
    fi
    
    start_model "$model_name"
}

# 显示帮助
show_help() {
    cat << EOF
llama.cpp 模型管理脚本

使用方法:
  $0 <command> [model-name]

命令:
  start <model-name>    启动指定模型
  stop                  停止当前运行的模型
  restart <model-name>  重启模型
  status                查看当前运行状态
  logs                  查看模型日志
  ls                    列出所有可用模型
  config <model-name>   查看模型配置详情
  use <model-name>      切换到指定模型（先停止再启动）
  help                  显示此帮助信息

示例:
  $0 ls                                    # 列出所有模型
  $0 start qwen27b-oups                    # 启动 qwen27b-oups 模型
  $0 status                                # 查看状态
  $0 logs                                  # 查看日志
  $0 stop                                  # 停止当前模型
  $0 use qwen9b-oups                       # 切换到 qwen9b-oups 模型

配置文件位置:
  默认配置: configs/default.yaml
  模型配置: configs/models/<model-name>.yaml

EOF
}

# 主函数
main() {
    check_dependencies
    
    if [[ $# -eq 0 ]]; then
        show_help
        exit 0
    fi
    
    local command=$1
    shift
    
    case "$command" in
        start)
            check_docker
            start_model "$@"
            ;;
        stop)
            check_docker
            stop_model
            ;;
        restart)
            check_docker
            restart_model "$@"
            ;;
        status)
            check_docker
            show_status
            ;;
        logs)
            check_docker
            show_logs
            ;;
        ls)
            list_models
            ;;
        config)
            show_model_config "$@"
            ;;
        use)
            check_docker
            use_model "$@"
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "未知命令: ${command}"
            echo "使用 '$0 help' 查看帮助信息"
            exit 1
            ;;
    esac
}

main "$@"
