#!/usr/bin/env bash
# Ubuntu 24.04 Dify 部署：Docker → 拉取 dify 仓库 → docker compose 启动/更新。

set -o pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
. "$SCRIPT_DIR/common.sh"

usage() {
    cat <<EOF
用法: bash init_dify.sh

安装 Docker，拉取 dify 仓库并通过 docker compose 启动或更新服务。
更新流程会先执行 docker compose down，正在运行的应用会短暂中断。

环境变量:
  DSH_TOOLS_APT_MIRROR        APT 镜像地址
  DSH_TOOLS_DOCKER_REPO       Docker CE 仓库地址
  DSH_TOOLS_DOCKER_MIRRORS    镜像加速器地址，逗号分隔
  DSH_TOOLS_DIFY_REPO         Dify 仓库地址，默认官方仓库
  DSH_TOOLS_FORCE=1           忽略已完成步骤，强制重跑
EOF
}

case "${1:-}" in
-h | --help)
    usage
    exit 0
    ;;
"") ;;
*)
    echo "未知参数: $1" >&2
    usage
    exit 2
    ;;
esac

require_root
init_logging init_dify

run_step apt-mirror ensure_apt_mirror || exit 1
run_step docker-install install_docker || exit 1
start_stopped_containers

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
        git clone "${DSH_TOOLS_DIFY_REPO:-https://github.com/langgenius/dify.git}"

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

