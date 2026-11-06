#!/bin/bash
# Ubuntu 24.04 Dify deployment.
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
    echo -e "\n\e[31m${current_time} || $1\\e[0m"
    sleep 2
}

yellow_echo() {
    current_time=$(date "+%Y-%m-%d %H:%M:%S") # 输出格式：2025-03-06 16:00:00
    echo -e "\n\e[33m${current_time} || $1\\e[0m"
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
apt-cache policy | grep -E 'http|https'  # 应仅显示aliyun和docker镜像源

green_echo "刷新软件源元数据，从 /etc/apt/sources.list 更新系统包列表，不会修改已安装的软件包..."
sudo apt-get update
green_echo "根据缓存的软件包列表，升级所有可更新的软件包..."
apt upgrade -y
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
systemctl --no-pager status docker

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
mkdir -p /etc/docker
tee /etc/docker/daemon.json <<EOF
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
systemctl restart docker
systemctl --no-pager status docker
green_echo "Docker 镜像加速器配置完成。"
#endregion
#endregion

#region 检查并启动所有已停止的容器
# 获取所有容器的 ID 和状态
green_echo "检查容器状态: ID\tContainer Name\tContainer Status..."
docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Status}}"

# 启动所有已停止的容器
green_echo "启动所有已停止的容器..."
containers=$(docker ps -a --format "{{.ID}}\t{{.Status}}")
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
        docker start "$id"
    fi
done
IFS=$OLD_IFS

if [ "$bestartflag" = true ]; then
    green_echo "已启动所有已停止的容器,如果状态还有问题，请手工启动..."
    docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Status}}"
else
    green_echo "没有已停止的容器需要启动..."
fi
#endregion

#region 部署dify
#region 部署 dify
green_echo "开始部署 dify..."
# 拉取 dify 代码
green_echo "获取 dify 代码状态..."
cd ~
if [ -d "dify" ]; then
    green_echo "dify 代码已经存在，跳过拉取..."
else
    retryflag_max=10
    retryflag=0
    while true ; do
        retryflag=$((retryflag + 1))
        green_echo "从 Github 拉取 dify 代码..."
        git clone https://github.com/langgenius/dify.git

        # 检查 git clone 命令是否成功
        if [ $? -eq 0 ]; then
            green_echo "dify 代码拉取完成..."
            break
        else
            red_echo "dify 代码拉取失败,正在重试(重试次数:$retryflag)..."
            if [ "$retryflag" -eq "$retryflag_max" ]; then
                red_echo "dify 代码拉取失败,达到最大重试次数, 退出脚本..."
                exit 1
            fi
        fi
        sleep 3
    done
fi
#endregion
#region 更新 dify
cd dify/docker

green_echo "停止并删除 dify 服务..."
docker compose down

green_echo "拉取最新的 dify 代码..."
git pull origin main

green_echo "更新 dify 服务..."
docker compose pull
docker compose up -d
#endregion

#region 检查 dify 部署情况
green_echo "检查 dify 部署情况 ..."
# 定义要检查的容器名称
CONTAINER_NAME="docker-api-1"
# 检查容器是否正在运行
if [ -n "$(docker ps -a -f "name=$CONTAINER_NAME" --quiet)" ]; then
    green_echo "dify 已经部署并正在运行..."
else
    green_echo "dify 未部署, 现在开始部署 dify..."

    # 切换到 docker 目录
    cd dify/docker || {
        green_echo "无法切换到 dify/docker 目录"
        exit 1
    }

    #复制环境配置文件
    cp .env.example .env

    # 使用 docker compose 启动服务
    docker compose up -d || {
        echo "Docker Compose 启动失败"
        exit 1
    }

    # 可选：检查容器日志的最后 100 行（用于调试或确认）
    docker logs --tail 100 $CONTAINER_NAME
fi
green_echo "请访问 dify 地址: http://localhost"
#endregion
#endregion

