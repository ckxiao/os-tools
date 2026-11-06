#!/usr/bin/env bash
# Ubuntu 24.04 Docker 安装：换源 → 安装 Docker CE → 配置镜像加速 → 启动已停止容器。

set -o pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
. "$SCRIPT_DIR/common.sh"

usage() {
    cat <<EOF
用法: bash init_docker.sh

安装 Docker CE 并配置镜像加速器，随后启动所有处于 Exited/Created 状态的容器。

环境变量:
  DSH_TOOLS_APT_MIRROR        APT 镜像地址
  DSH_TOOLS_DOCKER_REPO       Docker CE 仓库地址
  DSH_TOOLS_DOCKER_MIRRORS    镜像加速器地址，逗号分隔
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
init_logging init_docker

run_step apt-mirror ensure_apt_mirror || exit 1
run_step docker-install install_docker || exit 1
start_stopped_containers

green_echo "Docker 安装完成"
echo "验证: sudo docker --version && sudo docker ps"
echo "提示: 新加入 docker 组的账号需要重新登录后才免 sudo"
