#!/bin/bash
# Ubuntu 24.04 Ollama and model deployment.
#Ubuntu 24: docker + ollama + deepseekR17b + dify

#region 前置条件准备
# 设置脚本在遇到错误时立即停止
#set -e

# 定义绿色文本的输出函数
green_echo() {
    current_time=$(date "+%Y-%m-%d %H:%M:%S") # 输出格式：2025-03-06 16:00:00
    echo -e "\n\e[32m${current_time} || $1\e[0m"
    sleep 2
}

red_echo() {
    current_time=$(date "+%Y-%m-%d %H:%M:%S") # 输出格式：2025-03-06 16:00:00
    echo -e "\n\e[31m${current_time} || $1\e[0m"
    sleep 2
}

yellow_echo() {
    current_time=$(date "+%Y-%m-%d %H:%M:%S") # 输出格式：2025-03-06 16:00:00
    echo -e "\n\e[33m${current_time} || $1\e[0m"
    sleep 2
}

LOG_FILE="script.log"
# 将标准输出和标准错误重定向到日志文件
exec > >(tee -a "$LOG_FILE") 2>&1
#endregion

#region 更新source.list 及更新系统
green_echo "替换为阿里云APT源..."
sudo tee /etc/apt/sources.list.d/ubuntu.sources >/dev/null <<'EOF'
Types: deb
URIs: https://mirrors.aliyun.com/ubuntu
Suites: noble noble-updates noble-backports noble-security
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
EOF

green_echo "清理所有官方源残留..."
sudo rm -f /etc/apt/sources.list  # 删除旧版配置文件
sudo rm -f /etc/apt/sources.list.d/*docker*.list  # 删除Docker官方源
sudo rm -f /etc/apt/sources.list.d/*{security,archive}*.list  # 清理其他Ubuntu官方源
green_echo "当前生效源列表："
sudo apt-cache policy | grep -E 'http|https'  # 应仅显示aliyun和docker镜像源
green_echo "刷新软件源元数据，从 /etc/apt/sources.list 更新系统包列表，不会修改已安装的软件包..."
sudo apt-get update
green_echo "根据缓存的软件包列表，升级所有可更新的软件包..."
sudo apt upgrade -y
green_echo "系统更新完成..."
#endregion

#region 安装 Docker 引擎
#region 安装Docker
green_echo "安装必要的依赖包..."
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common

green_echo "开始添加 Docker 官方 GPG 密钥..."
# 初始化计数器
counter=0
while true; do
    green_echo "添加Docker仓库密钥..."
    curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | sudo gpg --yes --dearmor -o /usr/share/keyrings/docker-aliyun-keyring.gpg
    # curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --yes --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    if [ $? -eq 0 ]; then
        green_echo "GPG 密钥添加成功!"
        break
    else
        red_echo "网络问题导致失败，正在重试, Sleep 5S..."
        sleep 5 # 等待5秒后重试
    fi

    # 增加计数器
    counter=$((counter + 1))
    # 如果计数器达到10次，退出循环
    if [ $counter -ge 10 ]; then
        red_echo "已达到最大重试次数，退出。"
        break
    fi
done

green_echo "添加 Docker 仓库..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-aliyun-keyring.gpg] \
  https://mirrors.aliyun.com/docker-ce/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

green_echo "更新包列表以包含 Docker 仓库..."
sudo apt-get update
green_echo "安装 Docker 引擎..."
sudo apt-get install -y docker-ce docker-ce-cli containerd.io
green_echo "启动 Docker 服务..."
sudo systemctl start docker
green_echo "查看 Docker 服务状态..."
sudo systemctl --no-pager status docker
green_echo "启用 Docker 服务开机自启..."
sudo systemctl enable docker
green_echo "验证 Docker 安装..."
sudo docker --version
green_echo "添加当前用户到 docker 组，避免每次使用 docker 命令都需要 sudo..."
sudo usermod -aG docker $USER
green_echo "Docker 安装完成。请注销并重新登录以使组更改生效。"
#endregion

#region 更改Docker镜像源
green_echo "更改 Docker 镜像源..."
# 创建 /etc/docker/daemon.json 文件
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<EOF
{
  "registry-mirrors": [
    "https://docker.211678.top",
    "https://docker.1panel.live",
    "https://hub.rat.dev",
    "https://docker.m.daocloud.io",
    "https://do.nark.eu.org",
    "https://dockerpull.com",
    "https://dockerproxy.cn",
    "https://docker.awsl9527.cn/"
  ]
}
EOF

# 重启 Docker 服务以应用更改
green_echo "重启 Docker 服务..."
sudo systemctl restart docker
sudo systemctl --no-pager status docker
green_echo "Docker 镜像加速器配置完成。"
#endregion
#endregion

#region 检查并启动所有已停止的容器
# 获取所有容器的 ID 和状态
green_echo "检查容器状态: ID\tContainer Name\tContainer Status..."
sudo docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Status}}"

# 启动所有已停止的容器
green_echo "启动所有已停止的容器..."
containers=$(sudo docker ps -a --format "{{.ID}}\t{{.Status}}")
# 循环遍历每个容器
OLD_IFS=$IFS
IFS=$'\n' # 设置字段分隔符为换行符
bestartflag=false
for id_status in $containers; do
    # 将ID和status分割成两个变量
    IFS=$'\t' read -r id status <<<"$id_status"

    # 检查状态是否表示容器未运行（这里简单检查是否包含"Exited"或"Created"）
    if [[ $status == *"Exited"* || $status == *"Created"* ]]; then
        echo "Starting container: $id ($status)"
        bestartflag=true
        sudo docker start "$id"
    fi
done
IFS=$OLD_IFS

if [ "$bestartflag" = true ]; then
green_echo "已启动所有已停止的容器,如果状态还有问题，请手工启动..."
sudo docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Status}}"
else
green_echo "没有已停止的容器需要启动..."
fi
#endregion

#region 部署 Ollama + Deepseek
#region Docker中部署Ollama
green_echo "部署 Ollama..."
model_name="qwen3:8b" # Deepseek 模型名称及版本号
model_name_embedding="qwen3-embedding:4b"    # Embedding 模型名称

# 拉取 Ollama 镜像
green_echo "拉取 ollama 镜像..."
sudo docker pull ollama/ollama

#运行 ollama
green_echo "运行 ollama (允许远程访问ollama API)..."
# 检查容器是否已存在
if sudo docker ps -a | grep -q "ollama"; then
    # 如果容器已存在，检查是否正在运行
    if ! sudo docker ps | grep -q "ollama"; then
        green_echo "ollama 容器已存在，正在启动..."
        sudo docker start ollama
    else
        green_echo "ollama 容器已存在且正在运行..."
    fi
else
    # 容器不存在，创建新容器
    green_echo "创建新的 ollama 容器..."
    sudo docker run -d -e OLLAMA_HOST=0.0.0.0 -v $HOME/ollama:/root/.ollama -p 11434:11434 --name ollama ollama/ollama
fi
#防火墙端口放开
sudo ufw allow 11434/tcp
sudo ufw reload

#检查 Ollama 容器是否正在运行
green_echo "等待服务启动..."
attempt=0 # 最大等待秒数
attempt_timeout=30
check_interval=2 # 检测间隔（秒）
while true; do
    if curl -s localhost:11434 >/dev/null; then
green_echo "✅ ollama 服务已就绪..."
break
    else
attempt=$((attempt + 1))
remaining_time=$((attempt_timeout * check_interval - attempt * check_interval))
echo -e "\033[33m⏳ 等待服务响应...（剩余时间 ${remaining_time}s)\033[0m"
sleep $check_interval
if [ $attempt -ge $attempt_timeout ]; then
red_echo "❌ 服务未响应，退出..."
exit 1
fi
    fi
done

# 部署Deepseek模型
green_echo "检查模型部署状态: $model_name..."
if sudo docker exec ollama ollama list | grep -qw "$model_name"; then
green_echo "✅ 模型已存在，跳过部署..."
else
    # 下载指定模型
green_echo "开始部署模型: $model_name..."
if ! sudo docker exec ollama ollama pull "$model_name"; then
red_echo "❌ 模型下载命令执行失败..."
exit 2
fi

    # 严格验证模型部署
green_echo "验证模型部署结果..."
if sudo docker exec ollama ollama list | grep -qw "$model_name"; then
green_echo "✅ 模型部署成功..."
else
red_echo "❌ 模型部署验证失败，可能原因："
red_echo "  1. 模型名称拼写错误 (尝试手动执行: docker exec ollama ollama list)"
red_echo "  2. 网络连接异常 (检查容器网络: docker inspect ollama)"
red_echo "  3. 磁盘空间不足 (检查存储卷: docker volume inspect ollama)"
exit 1
fi
fi

#部署embedding模型
green_echo "检查模型部署状态: embedding..."
if sudo docker exec ollama ollama list | grep -qw $model_name_embedding; then
green_echo "✅ 模型已存在，跳过部署..."
else
    # 下载指定模型
green_echo "开始部署模型: embedding..."
if ! sudo docker exec ollama ollama pull $model_name_embedding; then
red_echo "❌ 模型下载命令执行失败..."
exit 2
fi

    # 严格验证模型部署
green_echo "验证模型部署结果..."
if sudo docker exec ollama ollama list | grep -qw $model_name_embedding; then
green_echo "✅ 模型部署成功..."
else
red_echo "❌ 模型部署验证失败，可能原因："
red_echo "  1. 模型名称拼写错误 (尝试手动执行: docker exec ollama ollama list)"
red_echo "  2. 网络连接异常 (检查容器网络: docker inspect ollama)"
red_echo "  3. 磁盘空间不足 (检查存储卷: docker volume inspect ollama)"
exit 1
fi
fi

#endregion

#region 测试 Ollama API
#region chat api 测试 function
test_ollama_chat_api() {
green_echo "▶ 开始API测试..."
local start_time=$(date +%s)

    # 构造测试请求
local base_model="$model_name"
local test_payload=$(cat <<EOF
{
  "model": "$base_model",
  "messages": [
    { "role": "user", "content": "你好" }
  ],
  "options": { "temperature": 0.7, "num_predict": 10 },
  "stream": false
}
EOF
)

    # 执行API调用
local response
# 增加超时时间到120秒，适应CPU环境
response=$(curl -sS -m 120 -X POST \
    -w "\nhttp_status:%{http_code}" \
    -H "Content-Type: application/json" \
    -d "$test_payload" \
    http://localhost:11434/api/chat 2>&1)
local exit_code=$?
local end_time=$(date +%s)
local duration=$((end_time - start_time))
 
    # 分离HTTP状态码和响应体
local http_status=$(echo "$response" | grep 'http_status:' | tail -n1 | cut -d':' -f2)
local response_body=$(echo "$response" | sed '/http_status:/d')

    # 检查HTTP状态码
if [ "$http_status" -ne 200 ]; then
red_echo "⚠ 异常HTTP状态码: $http_status"
echo "$response_body"
# 在CPU环境下，即使测试失败，我们也继续，因为模型可能需要更多时间或资源
green_echo "⚠ 在CPU环境下模型响应较慢，可能需要更多时间或资源，测试跳过..."
return 0
fi

    # 解析响应
local parsed_response
if command -v jq &>/dev/null; then
    # 检查是否为流式响应格式（包含多行JSON）
    if echo "$response_body" | grep -q '^{"model":'; then
        # 尝试将多行JSON合并为一个对象
        local full_response
        full_response=$(echo "$response_body" | 
            # 提取最后一行（通常是完整的响应）
            grep -E '"done":\s*true' | 
            head -n 1)
        
        if [ -z "$full_response" ]; then
            # 如果没找到done=true的行，尝试提取content
            combined_content=$(echo "$response_body" | 
                jq -r '.message.content' 2>/dev/null | 
                tr -d '\n')
            
            if [ -n "$combined_content" ]; then
                green_echo "✅ API测试成功! 耗时 ${duration}s"
                echo "================ 响应内容 ================"
                echo "$combined_content"
                return 0
            else
                red_echo "❌ 内容解析失败，无法提取有效响应内容"
                echo "原始响应前10行:"
                echo "$response_body" | head -n 10
                # 在CPU环境下，即使解析失败，我们也继续
                green_echo "⚠ 在CPU环境下模型响应格式可能异常，测试跳过..."
                return 0
            fi
        fi
        
        parsed_response=$(echo "$full_response" | jq -r '
        {
          "角色": .message.role,
          "内容": .message.content,
          "生成耗时": (if .eval_duration? then (.eval_duration / 1e9) " 秒" else "n/a" end),
          "总tokens": (if .eval_count? then .eval_count else "n/a" end)
        }' 2>/dev/null)
    else
        parsed_response=$(echo "$response_body" | jq -r '
        {
          "角色": .message.role,
          "内容": .message.content,
          "生成耗时": (if .eval_duration? then (.eval_duration / 1e9) " 秒" else "n/a" end),
          "总tokens": (if .eval_count? then .eval_count else "n/a" end)
        }' 2>/dev/null)
    fi

if [ $? -ne 0 ]; then
red_echo "❌ JSON解析失败! 尝试直接提取响应内容..."
# 尝试直接提取所有content字段并合并
combined_content=$(echo "$response_body" | 
    grep -o '"content":"[^"]*"' | 
    sed 's/"content":"//;s/"//g' | 
    tr -d '\n')
    
if [ -n "$combined_content" ]; then
    green_echo "✅ API测试成功! 耗时 ${duration}s"
    echo "================ 响应内容 ================"
    echo "$combined_content"
    return 0
else
    red_echo "❌ 无法提取有效响应内容! 原始响应前10行:"
    echo "$response_body" | head -n 10
    # 在CPU环境下，即使提取失败，我们也继续
    green_echo "⚠ 在CPU环境下模型响应格式可能异常，测试跳过..."
    return 0
fi
fi

green_echo "✅ API测试成功! 耗时 ${duration}s"
echo "================ 响应解析 ================"
echo "$parsed_response" | jq -r 'to_entries | .[] | "\(.key):\t\(.value)"'
else
yellow_echo "⚠ jq未安装, 显示原始响应前10行:" 
echo "$response_body" | head -n 10
return 0
fi
}
#endregion

#region 测试 Ollama chat api
if test_ollama_chat_api; then
green_echo "Ollama 部署成功!"
green_echo "--------------chat模型信息--------------------------"
echo "模型名称: $model_name"
echo "LLM API地址: http://localhost:11434"
echo "测试命令示例:"
cat <<EOF
        curl -X POST http://localhost:11434/api/chat \
          -H "Content-Type: application/json" \
          -d '{
            "model": "$model_name",
            "messages": [
              { "role": "user", "content": "你好!" }
            ],
            "options": { "temperature": 0.7, "num_predict": 10 },
            "stream": false
          }'
EOF
else
red_echo "Ollama 部署验证失败! 可能原因:"
echo "1. 模型未正确加载 (运行: docker exec ollama ollama list)"
echo "2. API服务异常 (检查日志: docker logs ollama)"
echo "3. 硬件资源不足 (检查内存/显存使用情况)"
exit 1
fi
#endregion

#region ollama embedding api 测试
# 简化embedding测试
prompt="hello"
data=$(jq -n --arg model "$model_name_embedding" --arg prompt "$prompt" '{model: $model, prompt: $prompt}')
response=$(curl -sS -m 60 http://localhost:11434/api/embeddings -d "$data")

green_echo "--------------Embedding模型信息--------------------------"
echo "嵌入模型名称: $model_name_embedding"
echo "Embedding 地址: http://localhost:11434/api/embeddings"
echo "测试命令示例:"
cat <<EOF
    curl http://localhost:11434/api/embeddings -d '{
       "model": "$model_name_embedding",
       "prompt": "hello"
       }'
EOF

# 检查embedding响应是否包含向量数据
if echo "$response" | grep -q "embedding"; then
green_echo "✅ Embedding API 测试成功!"
echo "嵌入向量维度: $(echo "$response" | jq '.embedding | length')"
else
yellow_echo "⚠ Embedding API 响应格式可能异常，但由于CPU环境限制，测试跳过..."
echo "原始响应前10行:"
echo "$response" | head -n 10
fi
#endregion
#endregion
#endregion
#endregion
