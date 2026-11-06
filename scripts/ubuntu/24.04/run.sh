#!/usr/bin/env bash
#
# Ubuntu 24.04 参数中间脚本。
#
# 职责边界：
#   1. 声明本版本目录下每个原子脚本需要哪些位置参数、是否必填、默认值与校验规则
#   2. 交互式补齐缺失参数；非交互环境下缺必填参数则直接失败
#   3. 输出校验通过的参数列表（每行一个）
#
# 不负责：下载、校验、提权与实际执行，这些由 menu.sh 统一处理。
#
# 用法：
#   bash run.sh --list                         列出本目录脚本及其参数要求
#   bash run.sh --describe <script>             打印指定脚本的参数说明
#   bash run.sh --collect <script> [args...]    校验并输出参数（每行一个）
#
# 退出码：
#   0  成功
#   2  用法错误或脚本不存在
#   3  缺少必填参数
#   4  参数校验失败

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

readonly EXIT_USAGE=2
readonly EXIT_MISSING=3
readonly EXIT_INVALID=4

err() { printf '[参数错误] %s\n' "$*" >&2; }
die() {
    err "$*"
    exit "$EXIT_USAGE"
}

# ---------------------------------------------------------------- 校验函数

validate_hostname() {
    local value="$1"
    [[ "$value" =~ ^[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?$ ]] || return 1
    [ "${#value}" -le 63 ] || return 1
    return 0
}

validate_ipv4() {
    local value="$1"
    local octet
    local -a parts=()
    [[ "$value" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || return 1
    IFS='.' read -r -a parts <<<"$value"
    for octet in "${parts[@]}"; do
        [ "$octet" -ge 0 ] && [ "$octet" -le 255 ] || return 1
    done
    return 0
}

validate_ipv4_prefix() {
    local value="$1"
    local ip="$1"
    local prefix=""

    # 允许留空，表示沿用当前地址
    [ -z "$value" ] && return 0

    if [[ "$value" == */* ]]; then
        ip="${value%%/*}"
        prefix="${value##*/}"
        [ -n "$prefix" ] || return 1
        [[ "$prefix" =~ ^[0-9]{1,2}$ ]] || return 1
        [ "$prefix" -ge 1 ] && [ "$prefix" -le 32 ] || return 1
    fi

    validate_ipv4 "$ip" || return 1
    return 0
}

validate_dns() {
    local value="$1"
    # 允许留空，表示使用网关地址
    [ -z "$value" ] && return 0
    if validate_ipv4 "$value"; then
        return 0
    fi
    if validate_hostname "$value"; then
        return 0
    fi
    return 1
}

# ---------------------------------------------------------------- 参数契约

PARAM_MODE="passthrough"
PARAM_NAME=()
PARAM_PROMPT=()
PARAM_REQUIRED=()
PARAM_DEFAULT=()
PARAM_VALIDATOR=()

reset_spec() {
    PARAM_MODE="passthrough"
    PARAM_NAME=()
    PARAM_PROMPT=()
    PARAM_REQUIRED=()
    PARAM_DEFAULT=()
    PARAM_VALIDATOR=()
}

add_param() {
    PARAM_NAME+=("$1")
    PARAM_PROMPT+=("$2")
    PARAM_REQUIRED+=("$3")
    PARAM_DEFAULT+=("$4")
    PARAM_VALIDATOR+=("$5")
}

# 新增脚本或新增参数时，只需在此登记，menu.sh 无需改动
load_spec() {
    local script="$1"
    reset_spec

    case "$script" in
    init-os.sh)
        PARAM_MODE="params"
        add_param hostname \
            "目标主机名，例如 node01" \
            required "" validate_hostname
        add_param ip_prefix \
            "静态地址及前缀，例如 192.168.1.20/24（留空沿用当前地址）" \
            optional "" validate_ipv4_prefix
        add_param dns \
            "DNS 地址，留空则使用网关（例如 223.5.5.5）" \
            optional "" validate_dns
        ;;
    opt.sh)
        # getopts 示例脚本，需要 -h/-a 形式的选项，由调用方直接给出
        PARAM_MODE="passthrough"
        ;;
    mgt-god.sh)
        # 无参进入交互菜单；带参时按 `函数名 [参数...]` 直接调用
        PARAM_MODE="passthrough"
        ;;
    init_docker.sh | init_llm.sh | init_dify.sh | hardening-os.sh)
        PARAM_MODE="passthrough"
        ;;
    *)
        PARAM_MODE="passthrough"
        ;;
    esac
}

# ---------------------------------------------------------------- 辅助命令

script_exists() { [ -f "$SCRIPT_DIR/$1" ]; }

param_summary() {
    local i
    local -a required=() optional=()
    for i in "${!PARAM_NAME[@]}"; do
        if [ "${PARAM_REQUIRED[$i]}" = "required" ]; then
            required+=("${PARAM_NAME[$i]}")
        else
            optional+=("${PARAM_NAME[$i]}")
        fi
    done

    local required_text="" optional_text="" item first
    first=1
    for item in "${required[@]}"; do
        [ $first -eq 1 ] || required_text+=", "
        required_text+="$item"
        first=0
    done
    first=1
    for item in "${optional[@]}"; do
        [ $first -eq 1 ] || optional_text+=", "
        optional_text+="$item"
        first=0
    done

    if [ -n "$required_text" ]; then
        printf '必填: %s' "$required_text"
    fi
    if [ -n "$optional_text" ]; then
        [ -n "$required_text" ] && printf ' | '
        printf '可选: %s' "$optional_text"
    fi
}

list_scripts() {
    local file base
    for file in "$SCRIPT_DIR"/*.sh; do
        [ -e "$file" ] || continue
        base="$(basename "$file")"
        [ "$base" = "run.sh" ] && continue
        load_spec "$base"
        if [ "$PARAM_MODE" = "params" ]; then
            printf '%-20s %s\n' "$base" "$(param_summary)"
        else
            printf '%-20s %s\n' "$base" "无位置参数（参数原样透传）"
        fi
    done
}

describe_script() {
    local script="$1"
    local i tag
    script_exists "$script" || die "脚本不存在: $script"
    load_spec "$script"

    printf '%s\n' "$script"
    if [ "$PARAM_MODE" != "params" ]; then
        printf '  无位置参数，命令行参数将原样传递给脚本\n'
        return 0
    fi

    for i in "${!PARAM_NAME[@]}"; do
        if [ "${PARAM_REQUIRED[$i]}" = "required" ]; then
            tag="必填"
        else
            tag="可选"
        fi
        printf '  %-12s %-4s %s\n' "${PARAM_NAME[$i]}" "$tag" "${PARAM_PROMPT[$i]}"
    done
}

collect_params() {
    local script="$1"
    shift
    local -a provided=("$@")
    local -a result=()
    local i value

    load_spec "$script"

    # 无参数契约：原样透传，未传参数时不输出任何内容
    if [ "$PARAM_MODE" != "params" ]; then
        if [ ${#provided[@]} -gt 0 ]; then
            printf '%s\n' "${provided[@]}"
        fi
        return 0
    fi

    for i in "${!PARAM_NAME[@]}"; do
        value="${provided[$i]:-}"
        if [ -z "$value" ]; then
            value="${PARAM_DEFAULT[$i]}"
        fi

        if [ -z "$value" ] && [ -t 0 ]; then
            if [ "${PARAM_REQUIRED[$i]}" = "required" ]; then
                while [ -z "$value" ]; do
                    if ! read -r -p "${PARAM_PROMPT[$i]}: " value; then
                        err "读取输入失败，缺少必填参数: ${PARAM_NAME[$i]}"
                        exit "$EXIT_MISSING"
                    fi
                    [ -n "$value" ] || err "该项为必填，请重新输入"
                done
            else
                read -r -p "${PARAM_PROMPT[$i]} [可留空]: " value || true
            fi
        fi

        if [ -z "$value" ] && [ "${PARAM_REQUIRED[$i]}" = "required" ]; then
            err "缺少必填参数: ${PARAM_NAME[$i]}（${PARAM_PROMPT[$i]}）"
            exit "$EXIT_MISSING"
        fi

        # 非空值必须通过校验
        if [ -n "$value" ]; then
            if ! "${PARAM_VALIDATOR[$i]}" "$value"; then
                err "参数 ${PARAM_NAME[$i]} 不合法: $value"
                exit "$EXIT_INVALID"
            fi
        fi

        result+=("$value")
    done

    printf '%s\n' "${result[@]}"
}

usage() {
    cat <<EOF
Ubuntu 24.04 参数中间脚本

用法：
  bash run.sh --list
  bash run.sh --describe <脚本名>
  bash run.sh --collect <脚本名> [参数...]

说明：
  本脚本只负责参数声明、采集与校验，不执行原子脚本。
  menu.sh 会先调用 --collect 取得参数，再以 sudo 执行目标脚本。

退出码：0 成功 / 2 用法错误 / 3 缺少必填参数 / 4 参数校验失败
EOF
}

main() {
    local command="${1:-}"

    case "$command" in
    --list)
        list_scripts
        ;;
    --describe)
        [ $# -ge 2 ] || die "--describe 需要脚本名"
        describe_script "$2"
        ;;
    --collect)
        [ $# -ge 2 ] || die "--collect 需要脚本名"
        local target="$2"
        shift 2
        script_exists "$target" || die "脚本不存在: $target"
        collect_params "$target" "$@"
        ;;
    -h | --help | help)
        usage
        ;;
    "")
        usage
        ;;
    *)
        die "未知命令: $command（使用 --help 查看帮助）"
        ;;
    esac
}

main "$@"
