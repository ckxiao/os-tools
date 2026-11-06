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

validate_port() {
    local value="$1"
    [[ "$value" =~ ^[0-9]{1,5}$ ]] || return 1
    [ "$value" -ge 1 ] && [ "$value" -le 65535 ] || return 1
    return 0
}

validate_username() {
    local value="$1"
    [[ "$value" =~ ^[a-z_][a-z0-9_-]*$ ]] || return 1
    [ "${#value}" -le 32 ] || return 1
    return 0
}

validate_hostlist() {
    local value="$1"
    local host
    local -a hosts=()

    # 允许留空，表示不限制来源
    [ -z "$value" ] && return 0
    IFS=',' read -r -a hosts <<<"$value"
    for host in "${hosts[@]}"; do
        validate_ipv4 "$host" || return 1
    done
    return 0
}

# ---------------------------------------------------------------- 参数契约

# 默认值支持运行时取值，避免把本机信息写死进仓库：
#   @hostname   当前主机名
#   @ip_prefix  当前首个全局 IPv4 地址/前缀
#   @gateway    默认网关
# 其余按字面量返回
param_default() {
    local raw="$1"
    local out=""
    case "$raw" in
    @hostname)
        out="$({ hostname -s 2>/dev/null || hostname 2>/dev/null; } | head -1)" || true
        ;;
    @ip_prefix)
        out="$(ip -4 -o addr show scope global 2>/dev/null | awk 'NR==1{print $4}')" || true
        ;;
    @gateway)
        out="$(ip route 2>/dev/null | awk '/^default /{print $3; exit}')" || true
        ;;
    *)
        out="$raw"
        ;;
    esac
    printf '%s' "$out"
}

PARAM_MODE="passthrough"
PARAM_NAME=()
PARAM_PROMPT=()
PARAM_REQUIRED=()
PARAM_DEFAULT=()
PARAM_VALIDATOR=()
PARAM_FLAG=()

reset_spec() {
    PARAM_MODE="passthrough"
    PARAM_NAME=()
    PARAM_PROMPT=()
    PARAM_REQUIRED=()
    PARAM_DEFAULT=()
    PARAM_VALIDATOR=()
    PARAM_FLAG=()
}

# add_param 名称 提示 是否必填 默认值 校验函数 [选项名]
# 第 6 个参数为空表示位置参数，非空表示以 --选项名=值 的形式输出
add_param() {
    PARAM_NAME+=("$1")
    PARAM_PROMPT+=("$2")
    PARAM_REQUIRED+=("$3")
    PARAM_DEFAULT+=("$4")
    PARAM_VALIDATOR+=("$5")
    PARAM_FLAG+=("${6:-}")
}

# 新增脚本或新增参数时，只需在此登记，menu.sh 无需改动
load_spec() {
    local script="$1"
    reset_spec

    case "$script" in
    init-os.sh)
        PARAM_MODE="params"
        add_param hostname \
            "目标主机名，默认沿用当前主机名" \
            required "@hostname" validate_hostname
        add_param ip_prefix \
            "静态地址及前缀，默认沿用当前地址，例如 192.168.1.20/24" \
            optional "@ip_prefix" validate_ipv4_prefix
        add_param dns \
            "DNS 地址，默认使用网关，例如 223.5.5.5" \
            optional "@gateway" validate_dns
        ;;
    mgt-god.sh)
        # 无参进入交互菜单；带参时按 `函数名 [参数...]` 直接调用
        PARAM_MODE="passthrough"
        ;;
    hardening-os.sh)
        PARAM_MODE="params"
        add_param ssh_port \
            "SSH 监听端口" \
            optional "22" validate_port "ssh-port"
        add_param allow_hosts \
            "允许 SSH 登录的来源 IPv4，逗号分隔（留空表示不限制）" \
            optional "" validate_hostlist "allow-hosts"
        add_param ops_user \
            "运维账号名，加入默认用户白名单" \
            optional "ck" validate_username "ops-user"
        ;;
    init_docker.sh | init_llm.sh | init_dify.sh)
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
        case "$base" in
        run.sh | common.sh) continue ;;
        esac
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
        local label="${PARAM_NAME[$i]}"
        if [ -n "${PARAM_FLAG[$i]}" ]; then
            label="--${PARAM_FLAG[$i]}"
        fi
        printf '  %-16s %-4s %s\n' "$label" "$tag" "${PARAM_PROMPT[$i]}"
    done
}

collect_params() {
    local script="$1"
    shift
    local -a provided=("$@")
    local -a positional=()
    local -a result=()
    local i value arg key pos=0

    load_spec "$script"

    # 无参数契约：原样透传，未传参数时不输出任何内容
    if [ "$PARAM_MODE" != "params" ]; then
        if [ ${#provided[@]} -gt 0 ]; then
            printf '%s\n' "${provided[@]}"
        fi
        return 0
    fi

    # 同时接受 --选项名=值 与位置参数两种入参形式
    declare -A named=()
    for arg in "${provided[@]+"${provided[@]}"}"; do
        case "$arg" in
        --*=*)
            key="${arg%%=*}"
            named["${key#--}"]="${arg#*=}"
            ;;
        *)
            positional+=("$arg")
            ;;
        esac
    done

    for i in "${!PARAM_NAME[@]}"; do
        value=""
        if [ -n "${PARAM_FLAG[$i]}" ] && [ -n "${named[${PARAM_FLAG[$i]}]:-}" ]; then
            value="${named[${PARAM_FLAG[$i]}]}"
        else
            value="${positional[$pos]:-}"
            pos=$((pos + 1))
        fi

        if [ -z "$value" ]; then
            value="$(param_default "${PARAM_DEFAULT[$i]}")"
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

        # 选项式参数仅在非空时输出，空值表示沿用脚本自身默认值
        if [ -n "${PARAM_FLAG[$i]}" ]; then
            if [ -n "$value" ]; then
                result+=("--${PARAM_FLAG[$i]}=$value")
            fi
        else
            result+=("$value")
        fi
    done

    printf '%s\n' "${result[@]}"
}

# 输出参数元数据（供 menu.sh 交互复核），每行 5 列、以 0x1f 分隔：
#   名称 / 当前值 / 选项名 / required|optional / 说明
# 用非空白分隔符是为了保留空字段（TAB 属 IFS 空白类，连续会折叠）。
# 默认值已解析，且不做交互提示。
explain_params() {
    local script="$1"
    shift
    local -a provided=("$@")
    local -a positional=()
    local i value arg key pos=0

    script_exists "$script" || die "脚本不存在: $script"
    load_spec "$script"

    if [ "$PARAM_MODE" != "params" ]; then
        return 0
    fi

    declare -A named=()
    for arg in "${provided[@]+"${provided[@]}"}"; do
        case "$arg" in
        --*=*)
            key="${arg%%=*}"
            named["${key#--}"]="${arg#*=}"
            ;;
        *)
            positional+=("$arg")
            ;;
        esac
    done

    for i in "${!PARAM_NAME[@]}"; do
        value=""
        if [ -n "${PARAM_FLAG[$i]}" ] && [ -n "${named[${PARAM_FLAG[$i]}]:-}" ]; then
            value="${named[${PARAM_FLAG[$i]}]}"
        else
            value="${positional[$pos]:-}"
            pos=$((pos + 1))
        fi

        [ -z "$value" ] && value="$(param_default "${PARAM_DEFAULT[$i]}")"

        if [ -n "$value" ] && ! "${PARAM_VALIDATOR[$i]}" "$value"; then
            err "参数 ${PARAM_NAME[$i]} 不合法: $value"
            exit "$EXIT_INVALID"
        fi

        printf '%s\x1f%s\x1f%s\x1f%s\x1f%s\n' \
            "${PARAM_NAME[$i]}" "$value" "${PARAM_FLAG[$i]}" \
            "${PARAM_REQUIRED[$i]}" "${PARAM_PROMPT[$i]}"
    done
}

usage() {
    cat <<EOF
Ubuntu 24.04 参数中间脚本

用法：
  bash run.sh --list
  bash run.sh --describe <脚本名>
  bash run.sh --collect <脚本名> [参数...]
  bash run.sh --explain <脚本名> [参数...]

说明：
  本脚本只负责参数声明、采集与校验，不执行原子脚本。
  menu.sh 会先调用 --collect 取得参数，再以 sudo 执行目标脚本。
  位置参数按声明顺序逐行输出；登记了选项名的参数以 --选项名=值 的形式输出，空值不输出。
  --explain 输出参数元数据（名称/值/选项名/必填性/说明，TAB 分隔），供 menu.sh 做交互复核。
  每个参数都有默认值，留空即采用默认值；默认值在运行时解析，不写死主机信息。

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
    --explain)
        [ $# -ge 2 ] || die "--explain 需要脚本名"
        local explained="$2"
        shift 2
        explain_params "$explained" "$@"
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
