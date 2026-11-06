#!/usr/bin/env bash
# Ubuntu 24.04 Docker 安装：换源 → 安装 Docker CE → 配置镜像加速 → 启动已停止容器。

set -o pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
. "$SCRIPT_DIR/common.sh"

usage() {
    cat <<EOF
用法: bash init_docker.sh [选项]

安装 Docker CE 并配置镜像加速器，随后启动所有处于 Exited/Created 状态的容器。

选项（均有默认值，可省略）:
  --apt-mirror=URL        APT 镜像地址，默认 $APT_MIRROR
  --docker-repo=URL       Docker CE 仓库地址，默认 $DOCKER_REPO_BASE
  --registry-mirrors=URLs 镜像加速器，逗号分隔，默认内置列表
  -h, --help              显示帮助

环境变量与选项等价:
  DSH_TOOLS_APT_MIRROR / DSH_TOOLS_DOCKER_REPO / DSH_TOOLS_DOCKER_MIRRORS
  DSH_TOOLS_FORCE=1       忽略已完成步骤，强制重跑
EOF
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
    usage
    exit 0
fi

parse_env_opts \
    "apt-mirror=DSH_TOOLS_APT_MIRROR" \
    "docker-repo=DSH_TOOLS_DOCKER_REPO" \
    "registry-mirrors=DSH_TOOLS_DOCKER_MIRRORS" \
    -- "$@" || {
    usage >&2
    exit 2
}

require_root
init_logging init_docker

run_step apt-mirror ensure_apt_mirror || exit 1
run_step docker-install install_docker || exit 1
start_stopped_containers

green_echo "Docker 安装完成"
echo "验证: sudo docker --version && sudo docker ps"
echo "提示: 新加入 docker 组的账号需要重新登录后才免 sudo"
