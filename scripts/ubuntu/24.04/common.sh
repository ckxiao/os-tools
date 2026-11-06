#!/usr/bin/env bash
#
# 共享库：被同目录的原子脚本 source，不单独执行。
#
# 提供：日志与配色、APT 换源、Docker 安装、容器启动、幂等步骤控制。
# 只定义函数与默认变量，不改动调用方的 set -e / IFS 等全局状态。

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    echo "common.sh 是共享库，不能直接执行；请运行同目录下的具体脚本。" >&2
    exit 1
fi

# ---------------------------------------------------------------- 可配置项

DSH_STATE_DIR="${DSH_STATE_DIR:-/var/lib/dsh-tools/state}"
DSH_LOG_DIR="${DSH_LOG_DIR:-/var/log/dsh-tools}"
DSH_LOG_SLEEP="${DSH_LOG_SLEEP:-2}"

APT_MIRROR="${DSH_TOOLS_APT_MIRROR:-https://mirrors.aliyun.com/ubuntu}"
DOCKER_REPO_BASE="${DSH_TOOLS_DOCKER_REPO:-https://mirrors.aliyun.com/docker-ce/linux/ubuntu}"
DOCKER_REGISTRY_MIRRORS="${DSH_TOOLS_DOCKER_MIRRORS:-https://docker.1panel.live,https://hub.rat.dev,https://docker.m.daocloud.io,https://dockerproxy.cn}"

# ---------------------------------------------------------------- 日志

_now() { date "+%Y-%m-%d %H:%M:%S"; }

_dsh_color_echo() {
    local color="$1"
    shift
    printf '\n\e[%sm%s || %s\e[0m\n' "$color" "$(_now)" "$*"
    if [ -t 1 ] && [ "${DSH_LOG_SLEEP:-0}" -gt 0 ] 2>/dev/null; then
        sleep "$DSH_LOG_SLEEP"
    fi
}

green_echo() { _dsh_color_echo 32 "$@"; }
red_echo() { _dsh_color_echo 31 "$@"; }
yellow_echo() { _dsh_color_echo 33 "$@"; }
blue_echo() { _dsh_color_echo 34 "$@"; }

# 把标准输出与标准错误同时写入日志文件；目录不可写时退化到当前目录
init_logging() {
    local name="${1:-script}"
    local ts log_file
    ts="$(date "+%Y%m%d-%H%M%S")"
    log_file="$DSH_LOG_DIR/log_${name}_${ts}.log"

    if ! mkdir -p "$DSH_LOG_DIR" 2>/dev/null; then
        log_file="./log_${name}_${ts}.log"
    fi

    exec > >(tee -a "$log_file") 2>&1
    echo "日志文件: $log_file"
}

# ---------------------------------------------------------------- 前置检查

require_root() {
    if [ "$(id -u)" -ne 0 ]; then
        red_echo "请使用 root 或 sudo 执行本脚本"
        exit 1
    fi
}

has_command() { command -v "$1" >/dev/null 2>&1; }

# ---------------------------------------------------------------- 幂等步骤

# run_step <步骤名> <函数> [参数...]
# 成功后写入状态标记，重复执行时跳过；DSH_TOOLS_FORCE=1 可强制重跑。
run_step() {
    local name="$1"
    shift
    local marker="$DSH_STATE_DIR/$name.done"

    if [ -f "$marker" ] && [ "${DSH_TOOLS_FORCE:-0}" != "1" ]; then
        yellow_echo "跳过已完成步骤: $name（DSH_TOOLS_FORCE=1 可强制重跑）"
        return 0
    fi

    if ! "$@"; then
        red_echo "步骤执行失败: $name"
        return 1
    fi

    mkdir -p "$DSH_STATE_DIR" 2>/dev/null && : >"$marker"
    return 0
}

# ---------------------------------------------------------------- APT 换源

# 覆盖式写入阿里云源，并按 /etc/os-release 的代号生成 Suites
ensure_apt_mirror() {
    local codename="noble"

    if [ -r /etc/os-release ]; then
        codename="$(
            . /etc/os-release
            printf '%s' "${VERSION_CODENAME:-noble}"
        )"
    fi

    green_echo "配置 APT 源: $APT_MIRROR (codename: $codename)"

    sudo tee /etc/apt/sources.list.d/ubuntu.sources >/dev/null <<EOF
Types: deb
URIs: $APT_MIRROR
Suites: $codename $codename-updates $codename-backports $codename-security
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
EOF

    green_echo "清理官方源残留..."
    sudo rm -f /etc/apt/sources.list
    sudo rm -f /etc/apt/sources.list.d/*docker*.list
    sudo rm -f /etc/apt/sources.list.d/*{security,archive}*.list

    green_echo "刷新软件源元数据..."
    sudo apt-get update || return 1
}

# ---------------------------------------------------------------- Docker

# 配置 /etc/docker/daemon.json 的镜像加速器
configure_docker_mirrors() {
    local -a mirrors=()
    local mirror body=""

    IFS=',' read -r -a mirrors <<<"$DOCKER_REGISTRY_MIRRORS"
    for mirror in "${mirrors[@]}"; do
        [ -z "$mirror" ] && continue
        body+="    \"$mirror\","$'\n'
    done
    body="${body%,$'\n'}"

    sudo mkdir -p /etc/docker
    sudo tee /etc/docker/daemon.json >/dev/null <<EOF
{
  "registry-mirrors": [
$body
  ]
}
EOF

    sudo systemctl daemon-reload
    sudo systemctl restart docker
}

# 安装 Docker CE，GPG 获取失败时最多重试 10 次
install_docker() {
    green_echo "安装 Docker 依赖包..."
    sudo apt-get install -y apt-transport-https ca-certificates curl gnupg \
        software-properties-common || return 1

    green_echo "添加 Docker 仓库密钥..."
    local attempt=0
    while true; do
        if curl -fsSL "$DOCKER_REPO_BASE/gpg" |
            sudo gpg --yes --dearmor -o /usr/share/keyrings/docker-aliyun-keyring.gpg; then
            break
        fi
        attempt=$((attempt + 1))
        if [ "$attempt" -ge 10 ]; then
            red_echo "Docker GPG 密钥获取失败，已达到最大重试次数"
            return 1
        fi
        yellow_echo "网络异常，5 秒后重试 ($attempt/10)"
        sleep 5
    done

    green_echo "添加 Docker 仓库..."
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-aliyun-keyring.gpg] $DOCKER_REPO_BASE $(lsb_release -cs) stable" |
        sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

    sudo apt-get update || return 1

    green_echo "安装 Docker 引擎..."
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io || return 1

    sudo systemctl enable --now docker
    sudo docker --version

    # 配置镜像加速器并重启服务
    configure_docker_mirrors || return 1

    # 把真实调用者加入 docker 组（sudo 场景下 $USER 是 root）
    if [ -n "${SUDO_USER:-}" ]; then
        sudo usermod -aG docker "$SUDO_USER"
        green_echo "已将 $SUDO_USER 加入 docker 组，重新登录后生效"
    fi

    return 0
}

# 启动所有处于 Exited / Created 状态的容器
start_stopped_containers() {
    green_echo "检查容器状态..."
    sudo docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Status}}"

    local id status started=0
    while IFS=$'\t' read -r id status; do
        case "$status" in
        Exited* | Created*)
            echo "启动容器: $id ($status)"
            if sudo docker start "$id" >/dev/null 2>&1; then
                started=$((started + 1))
            fi
            ;;
        esac
    done < <(sudo docker ps -a --format "{{.ID}}\t{{.Status}}")

    if [ "$started" -gt 0 ]; then
        green_echo "已启动 $started 个容器"
    else
        green_echo "没有已停止的容器需要启动"
    fi
}
