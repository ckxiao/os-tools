#!/usr/bin/env bash
#
# 远程开发通道：在 Windows 上编辑，在真实 Linux 上验证。
#
#   tools/remote-dev.sh check            测试机：语法 + shellcheck + 单元测试
#   tools/remote-dev.sh check --dev      开发机：只跑语法与单测（不装工具）
#   tools/remote-dev.sh container        测试机：在 ubuntu:24.04 容器里跑测试
#   tools/remote-dev.sh e2e              测试机：容器内跑 debconf 端到端用例
#   tools/remote-dev.sh shell [--test]   同步后打开交互式 shell（默认开发机）
#   tools/remote-dev.sh exec [--test] -- <命令...>
#   tools/remote-dev.sh sync  [--test]   只同步（默认开发机）
#
# 主机默认取 ssh 配置里的别名，可用环境变量覆盖：
#   DSH_DEV_HOST   默认 dsh-dev
#   DSH_TEST_HOST  默认 dsh-test
#   DSH_REMOTE_DIR 远端工作目录（相对 $HOME），默认 dsh-os-tools-dev
#
# 约定：开发机只做同步与只读检查；需要安装工具、跑容器、做破坏性验证时，
#       一律走测试机（--test）。

set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
DEV_HOST="${DSH_DEV_HOST:-dsh-dev}"
TEST_HOST="${DSH_TEST_HOST:-dsh-test}"
REMOTE_DIR="${DSH_REMOTE_DIR:-dsh-os-tools-dev}"

SSH_OPTS=(-o BatchMode=yes -o ConnectTimeout=10 -o ServerAliveInterval=15)

die() {
    printf '[错误] %s\n' "$*" >&2
    exit 1
}

info() {
    printf '[信息] %s\n' "$*"
}

usage() {
    sed -n '2,28p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

pick_host() {
    local flag="${1:-}" fallback="${2:-dev}"
    case "$flag" in
    --test) printf '%s' "$TEST_HOST" ;;
    --dev) printf '%s' "$DEV_HOST" ;;
    "" | --)
        if [ "$fallback" = "test" ]; then
            printf '%s' "$TEST_HOST"
        else
            printf '%s' "$DEV_HOST"
        fi
        ;;
    *)
        die "未知主机选项：$flag（用 --dev 或 --test）"
        ;;
    esac
}

require_host() {
    local host="$1"
    ssh "${SSH_OPTS[@]}" -o StrictHostKeyChecking=accept-new "$host" true 2>/dev/null ||
        die "无法连接 $host。检查 ssh 配置或 Tailscale 状态：ssh $host true"
}

sync_repo() {
    local host="$1"
    require_host "$host"
    info "同步到 $host:~/$REMOTE_DIR"
    tar -czf - \
        --exclude=.git \
        --exclude=.workbuddy \
        --exclude='log_*.log' \
        -C "$ROOT" . |
        ssh "${SSH_OPTS[@]}" "$host" "
            set -e
            rm -rf \"\$HOME/$REMOTE_DIR\"
            mkdir -p \"\$HOME/$REMOTE_DIR\"
            tar -xzf - -C \"\$HOME/$REMOTE_DIR\"
        "
    info "同步完成"
}

run_check() {
    local host="$1"
    sync_repo "$host"
    info "在 $host 上执行检查"
    ssh "${SSH_OPTS[@]}" "$host" "cd \"\$HOME/$REMOTE_DIR\" && bash -s" <<'REMOTE'
set -uo pipefail
fail=0

echo "== 1/3 语法 =="
shopt -s globstar nullglob
for f in menu.sh tests/run-tests.sh scripts/**/*.sh tools/*.sh; do
    bash -n "$f" || { echo "FAIL $f"; fail=1; }
done
[ "$fail" -eq 0 ] && echo "全部通过"

echo "== 2/3 shellcheck =="
if command -v shellcheck >/dev/null 2>&1; then
    if shellcheck --severity=error --shell=bash menu.sh tests/run-tests.sh \
        scripts/*/*/*.sh tools/*.sh; then
        echo "无 error"
    else
        fail=1
    fi
else
    echo "未安装，跳过"
fi

echo "== 3/3 单元测试 =="
bash tests/run-tests.sh || fail=1

exit "$fail"
REMOTE
}

run_container() {
    local host="$1"
    sync_repo "$host"
    info "在 $host 的 ubuntu:24.04 容器内验证"
    ssh "${SSH_OPTS[@]}" "$host" "cd \"\$HOME/$REMOTE_DIR\" && docker run --rm -i -v \"\$PWD\":/w -w /w ubuntu:24.04 bash -s" <<'REMOTE'
set -uo pipefail
echo "== 容器内 =="
grep PRETTY /etc/os-release
echo "== 语法 =="
shopt -s globstar nullglob
for f in menu.sh tests/run-tests.sh scripts/**/*.sh tools/*.sh; do
    bash -n "$f" || exit 1
done
echo "全部通过"
echo "== 单元测试 =="
bash tests/run-tests.sh
REMOTE
}

run_e2e() {
    local host="$1"
    sync_repo "$host"
    info "在 $host 的 ubuntu:24.04 容器内跑端到端用例"
    # 用 script 在容器内造一个 pty：debconf 只有在有终端时才会真正弹框，
    # 没有 pty 的测试是假通过。这样无需从外层分配 TTY。
    ssh "${SSH_OPTS[@]}" "$host" "cd \"\$HOME/$REMOTE_DIR\" && docker run --rm -i -v \"\$PWD\":/w -w /w ubuntu:24.04 bash -c 'apt-get update -qq >/dev/null 2>&1; script -qec \"bash tests/e2e-debconf.sh\" /dev/null'" 2>&1 | tr -d '\r'
}

main() {
    local cmd="${1:-}"
    shift || true
    case "$cmd" in
    check)
        run_check "$(pick_host "${1:-}" test)"
        ;;
    container)
        run_container "$(pick_host "${1:-}" test)"
        ;;
    e2e)
        run_e2e "$(pick_host "${1:-}" test)"
        ;;
    sync)
        sync_repo "$(pick_host "${1:-}" dev)"
        ;;
    shell)
        local host
        host="$(pick_host "${1:-}" dev)"
        sync_repo "$host"
        info "进入 $host:~/$REMOTE_DIR"
        exec ssh "${SSH_OPTS[@]}" -t "$host" "cd \"\$HOME/$REMOTE_DIR\" && exec bash -l"
        ;;
    exec)
        local host
        host="$(pick_host "${1:-}" dev)"
        shift || true
        [[ "${1:-}" == "--" ]] && shift
        [[ $# -gt 0 ]] || die "exec 需要命令，例如：exec -- ls -l"
        sync_repo "$host"
        ssh "${SSH_OPTS[@]}" "$host" "cd \"\$HOME/$REMOTE_DIR\" && $(printf '%q ' "$@")"
        ;;
    -h | --help | help | "")
        usage
        ;;
    *)
        die "未知子命令：$cmd（用 --help 查看用法）"
        ;;
    esac
}

main "$@"
