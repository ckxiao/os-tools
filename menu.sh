#!/usr/bin/env bash
#
# 多操作系统运维脚本统一入口。
#
# 目录约定：
#   scripts/<os>/<version>/<script>.sh
#
# 菜单只加载体积很小的 catalog.tsv；用户选中某个脚本后，
# 才下载并校验该脚本。可选安装某个 OS 配置下的全部脚本。
#

set -Eeuo pipefail
IFS=$'\n\t'

readonly APP_NAME="dsh-os-tools"
readonly APP_VERSION="1.2.0"
readonly DEFAULT_INSTALL_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/dsh-os-tools"
readonly DEFAULT_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/dsh-os-tools"

INSTALL_DIR="${DSH_TOOLS_HOME:-$DEFAULT_INSTALL_DIR}"
CONFIG_DIR="${DSH_TOOLS_CONFIG_DIR:-$DEFAULT_CONFIG_DIR}"
SCRIPT_DIR="$INSTALL_DIR/scripts"
CONFIG_FILE="$CONFIG_DIR/config"
INSTALLED_CATALOG="$INSTALL_DIR/catalog.tsv"
INSTALLED_MANIFEST="$INSTALL_DIR/SHA256SUMS"
BASE_URL="${DSH_TOOLS_BASE_URL:-}"

CATALOG_PATH=''
REMOTE_MANIFEST=''
WORK_DIR=''
CATALOG_ROWS=()
PROFILE_IDS=()

SOURCE_PATH="${BASH_SOURCE[0]}"
if [[ -f "$SOURCE_PATH" ]]; then
    SOURCE_DIR="$(cd -- "$(dirname -- "$SOURCE_PATH")" && pwd)"
else
    SOURCE_DIR="$PWD"
fi

RED=''
GREEN=''
YELLOW=''
BLUE=''
RESET=''
if [[ -t 1 ]]; then
    RED=$'\033[31m'
    GREEN=$'\033[32m'
    YELLOW=$'\033[33m'
    BLUE=$'\033[34m'
    RESET=$'\033[0m'
fi

info() { printf '%s[信息]%s %s\n' "$BLUE" "$RESET" "$*" >&2; }
success() { printf '%s[成功]%s %s\n' "$GREEN" "$RESET" "$*"; }
warn() { printf '%s[警告]%s %s\n' "$YELLOW" "$RESET" "$*" >&2; }
fail() { printf '%s[错误]%s %s\n' "$RED" "$RESET" "$*" >&2; exit 1; }

cleanup() {
    local status=$?
    if [[ -n "$WORK_DIR" && -d "$WORK_DIR" ]]; then
        rm -rf -- "$WORK_DIR"
    fi
    return "$status"
}
trap cleanup EXIT

usage() {
    cat <<EOF
$APP_NAME $APP_VERSION

用法：
  bash menu.sh
  bash menu.sh --base-url <HTTPS地址>
  bash menu.sh --base-url <HTTPS地址> --profile ubuntu-24.04 --run 1
  bash menu.sh --base-url <HTTPS地址> --profile ubuntu-24.04 --install-profile
  bash menu.sh --list

主要选项：
  --base-url URL      版本化静态文件目录
  --profile ID        OS 配置编号，例如 ubuntu-24.04
  --run N             运行指定 OS 菜单中的脚本编号 N
  --install-profile   下载并安装指定 OS 配置下的全部脚本
  --install-launcher  安装 dsh-tools 启动命令
  --list              列出 OS 配置及脚本
  --set-base-url URL  保存下载站点地址
  --show-base-url     显示当前下载站点地址
  --help              显示帮助
  --version           显示版本

环境变量：
  DSH_TOOLS_BASE_URL  下载站点地址
  DSH_TOOLS_HOME      安装目录，默认：$DEFAULT_INSTALL_DIR
  DSH_TOOLS_YES=1     跳过运行确认（不推荐用于初始化/加固脚本）
  DSH_TOOLS_ALLOW_HTTP=1
                      允许 HTTP；仅建议用于可信内网
  DSH_BASH           显式指定 Bash 可执行文件（可选）
EOF
}

normalize_base_url() {
    local url="${1:-}"
    while [[ "$url" == */ ]]; do
        url="${url%/}"
    done
    printf '%s' "$url"
}

validate_base_url() {
    local url="${1:-}"
    [[ -n "$url" ]] || fail "下载站点地址不能为空"
    [[ "$url" != *[[:space:]]* ]] || fail "下载站点地址不能包含空白字符"
    [[ "$url" == https://* ]] && return 0
    [[ "${DSH_TOOLS_ALLOW_HTTP:-0}" == "1" && "$url" == http://127.0.0.1:* ]] && return 0
    [[ "${DSH_TOOLS_ALLOW_HTTP:-0}" == "1" && "$url" == http://localhost:* ]] && return 0
    if [[ "${DSH_TOOLS_ALLOW_HTTP:-0}" == "1" && "$url" == http://* ]]; then
        warn "正在使用非 HTTPS 下载地址"
        return 0
    fi
    fail "只允许 HTTPS 下载地址；可信内网可设置 DSH_TOOLS_ALLOW_HTTP=1"
}

load_saved_base_url() {
    [[ -n "$BASE_URL" ]] && return 0
    if [[ -r "$CONFIG_FILE" ]]; then
        # shellcheck disable=SC1090
        source "$CONFIG_FILE"
        BASE_URL="${BASE_URL:-}"
    fi
}

save_base_url() {
    local url
    url="$(normalize_base_url "$1")"
    validate_base_url "$url"
    mkdir -p -- "$CONFIG_DIR"
    umask 077
    printf 'BASE_URL=%q\n' "$url" >"$CONFIG_FILE"
    BASE_URL="$url"
    REMOTE_MANIFEST=''
    success "下载站点已保存：$BASE_URL"
}

interactive_set_base_url() {
    local url
    [[ -t 0 ]] || fail "请使用 --set-base-url 设置下载站点"
    read -r -p "请输入版本化 HTTPS 下载地址: " url
    save_base_url "$url"
}

resolve_base_url() {
    load_saved_base_url
    if [[ -z "$BASE_URL" ]]; then
        [[ -t 0 ]] || fail "未配置下载站点，请使用 --base-url 参数"
        read -r -p "请输入版本化 HTTPS 下载地址: " BASE_URL
        save_base_url "$BASE_URL"
    else
        BASE_URL="$(normalize_base_url "$BASE_URL")"
        validate_base_url "$BASE_URL"
    fi
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || fail "缺少命令：$1"
}

bash_binary() {
    if [[ -n "${DSH_BASH:-}" && -x "$DSH_BASH" ]]; then
        printf '%s' "$DSH_BASH"
    elif command -v bash >/dev/null 2>&1; then
        command -v bash
    elif [[ -n "${BASH:-}" && -x "$BASH" ]]; then
        printf '%s' "$BASH"
    else
        return 1
    fi
}

syntax_check() {
    local runner
    runner="$(bash_binary)" || fail "找不到 Bash，无法检查脚本语法"
    "$runner" -n "$1"
}

copy_with_mode() {
    local mode="$1"
    local source_file="$2"
    local destination="$3"
    local destination_dir
    destination_dir="$(dirname -- "$destination")"
    mkdir -p -- "$destination_dir"
    if command -v install >/dev/null 2>&1; then
        install -m "$mode" "$source_file" "$destination"
    else
        cp -f -- "$source_file" "$destination"
        if command -v chmod >/dev/null 2>&1; then
            chmod "$mode" "$destination"
        fi
    fi
}

sha256_file() {
    local file="$1"
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$file" | awk '{print $1}'
    elif command -v shasum >/dev/null 2>&1; then
        shasum -a 256 "$file" | awk '{print $1}'
    elif command -v openssl >/dev/null 2>&1; then
        openssl dgst -sha256 "$file" | awk '{print $NF}'
    elif command -v certutil >/dev/null 2>&1; then
        certutil -hashfile "$file" SHA256 2>/dev/null |
            awk '/^[[:space:]]*[0-9a-fA-F]+[[:space:]]*$/ {gsub(/[[:space:]]/, ""); print tolower($0); exit}'
    else
        return 1
    fi
}

write_sha256_manifest() {
    local file hash
    for file in "$@"; do
        hash="$(sha256_file "$file")" || return 1
        [[ "$hash" =~ ^[0-9a-fA-F]{64}$ ]] || return 1
        printf '%s  %s\n' "$hash" "$file"
    done
}

ensure_layout() {
    mkdir -p -- "$INSTALL_DIR" "$SCRIPT_DIR"
}

ensure_work_dir() {
    if [[ -z "$WORK_DIR" || ! -d "$WORK_DIR" ]]; then
        WORK_DIR="$(mktemp -d)"
    fi
}

download_raw() {
    local relative_path="$1"
    local output_file="$2"
    local url="$BASE_URL/$relative_path"
    local -a curl_args=(
        --fail
        --silent
        --show-error
        --location
        --retry 3
        --retry-delay 2
        --connect-timeout 15
        --output "$output_file"
    )

    require_command curl
    if [[ "$url" == https://* ]]; then
        curl_args+=(--proto '=https' --tlsv1.2)
    fi

    info "下载：$url"
    curl "${curl_args[@]}" "$url"
}

expected_sha256() {
    local manifest="$1"
    local relative_path="$2"
    awk -v wanted="$relative_path" '
        {
            path = $2
            sub(/^\*/, "", path)
            sub(/^\.\//, "", path)
            if (path == wanted) {
                print $1
                exit
            }
        }
    ' "$manifest"
}

verify_file() {
    local file="$1"
    local relative_path="$2"
    local manifest="$3"
    local expected actual

    [[ -f "$file" && -r "$manifest" ]] || {
        warn "无法校验：$relative_path"
        return 1
    }

    expected="$(expected_sha256 "$manifest" "$relative_path")"
    if [[ ! "$expected" =~ ^[0-9a-fA-F]{64}$ ]]; then
        warn "校验清单中缺少：$relative_path"
        return 1
    fi

    actual="$(sha256_file "$file")" || {
        warn "无法计算 SHA-256：$relative_path"
        return 1
    }
    if [[ "$actual" != "$expected" ]]; then
        warn "SHA-256 校验失败：$relative_path"
        return 1
    fi
}

load_remote_manifest() {
    [[ -n "$BASE_URL" ]] || resolve_base_url
    ensure_work_dir
    REMOTE_MANIFEST="$WORK_DIR/SHA256SUMS"
    if [[ ! -s "$REMOTE_MANIFEST" ]]; then
        download_raw "SHA256SUMS" "$REMOTE_MANIFEST" ||
            return 1
    fi
    [[ -s "$REMOTE_MANIFEST" ]] || return 1
}

load_catalog_file() {
    local path="$1"
    local line profile_id

    [[ -r "$path" ]] || fail "目录文件不可读：$path"
    CATALOG_ROWS=()
    PROFILE_IDS=()

    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -z "${line//[[:space:]]/}" ]] && continue
        [[ "$line" == \#* ]] && continue
        IFS='|' read -r profile_id _ _ _ _ _ _ _ _ _ _ _ <<<"$line"
        [[ -n "$profile_id" ]] || fail "目录中存在无效行：$line"
        CATALOG_ROWS+=("$line")
        if [[ " ${PROFILE_IDS[*]} " != *" $profile_id "* ]]; then
            PROFILE_IDS+=("$profile_id")
        fi
    done <"$path"

    [[ ${#CATALOG_ROWS[@]} -gt 0 ]] || fail "目录中没有可用脚本"
    CATALOG_PATH="$path"
}

try_load_remote_catalog() {
    local tmp_catalog
    [[ -n "$BASE_URL" ]] || return 1
    load_remote_manifest || return 1
    ensure_work_dir
    tmp_catalog="$WORK_DIR/catalog.tsv"
    download_raw "catalog.tsv" "$tmp_catalog" || return 1
    verify_file "$tmp_catalog" "catalog.tsv" "$REMOTE_MANIFEST" || return 1

    ensure_layout
    copy_with_mode 0644 "$tmp_catalog" "$INSTALLED_CATALOG"
    copy_with_mode 0644 "$REMOTE_MANIFEST" "$INSTALLED_MANIFEST"
    CATALOG_PATH="$INSTALLED_CATALOG"
    return 0
}

try_load_installed_catalog() {
    [[ -f "$INSTALLED_CATALOG" && -f "$INSTALLED_MANIFEST" ]] || return 1
    verify_file "$INSTALLED_CATALOG" "catalog.tsv" "$INSTALLED_MANIFEST" ||
        return 1
    CATALOG_PATH="$INSTALLED_CATALOG"
}

initialize_catalog() {
    local local_catalog="$SOURCE_DIR/catalog.tsv"

    if [[ -f "$local_catalog" && -d "$SOURCE_DIR/scripts" ]]; then
        load_catalog_file "$local_catalog"
        return 0
    fi

    if try_load_remote_catalog; then
        load_catalog_file "$CATALOG_PATH"
        return 0
    fi

    if try_load_installed_catalog; then
        warn "远程目录获取失败，使用上一次已校验的目录缓存"
        load_catalog_file "$CATALOG_PATH"
        return 0
    fi

    fail "没有可用的 catalog.tsv；请提供 --base-url，或先安装脚本"
}

profile_exists() {
    local wanted="$1"
    local profile
    for profile in "${PROFILE_IDS[@]}"; do
        [[ "$profile" == "$wanted" ]] && return 0
    done
    return 1
}

profile_title() {
    local wanted="$1"
    local line id family version path title _rest
    for line in "${CATALOG_ROWS[@]}"; do
        IFS='|' read -r id family version path title _rest <<<"$line"
        if [[ "$id" == "$wanted" ]]; then
            printf '%s' "$title"
            return 0
        fi
    done
    printf '%s' "$wanted"
}

profile_script_count() {
    local wanted="$1"
    local line count=0
    for line in "${CATALOG_ROWS[@]}"; do
        [[ "${line%%|*}" == "$wanted" ]] && ((count += 1))
    done
    printf '%s' "$count"
}

profile_id_by_number() {
    local number="$1"
    [[ "$number" =~ ^[0-9]+$ ]] || return 1
    ((number >= 1 && number <= ${#PROFILE_IDS[@]})) || return 1
    printf '%s' "${PROFILE_IDS[number - 1]}"
}

get_script_entry() {
    local wanted_profile="$1"
    local wanted_id="$2"
    local line id family version path title script_id file script_title desc risk root args
    for line in "${CATALOG_ROWS[@]}"; do
        IFS='|' read -r id family version path title script_id file script_title desc risk root args <<<"$line"
        if [[ "$id" == "$wanted_profile" && "$script_id" == "$wanted_id" ]]; then
            printf '%s' "$line"
            return 0
        fi
    done
    return 1
}

parse_script_entry() {
    IFS='|' read -r ENTRY_PROFILE ENTRY_FAMILY ENTRY_VERSION ENTRY_OS_PATH \
        ENTRY_PROFILE_TITLE ENTRY_ID ENTRY_FILE ENTRY_TITLE ENTRY_DESC \
        ENTRY_RISK ENTRY_ROOT ENTRY_ARG_MODE <<<"$1"
}

list_profiles() {
    local index=1 profile title count
    printf '\n%s============= %s %s =============%s\n\n' \
        "$BLUE" "$APP_NAME" "$APP_VERSION" "$RESET"
    printf '%-5s %-20s %-28s %s\n' "编号" "OS 配置ID" "操作系统" "脚本数"
    printf '%s%s%s\n' "$BLUE" \
        "--------------------------------------------------------------------------------" "$RESET"
    for profile in "${PROFILE_IDS[@]}"; do
        title="$(profile_title "$profile")"
        count="$(profile_script_count "$profile")"
        printf '%-5s %-20s %-28s %s\n' "$index" "$profile" "$title" "$count"
        ((index += 1))
    done
    printf '%s%s%s\n' "$BLUE" \
        "--------------------------------------------------------------------------------" "$RESET"
    printf '%-5s %s\n' "9" "设置脚本下载站点"
    printf '%-5s %s\n' "10" "安装 dsh-tools 启动命令"
    printf '%-5s %s\n' "0" "退出"
    printf '\n当前下载站点：%s\n' "${BASE_URL:-未配置}"
    printf '安装目录：%s\n\n' "$INSTALL_DIR"
}

list_scripts() {
    local wanted="$1"
    local line id family version path profile_name script_id file script_title desc risk root args
    local title
    title="$(profile_title "$wanted")"
    printf '\n%s========== %s ==========%s\n\n' "$BLUE" "$title" "$RESET"
    printf '%-5s %-24s %-20s %s\n' "编号" "脚本" "名称" "用途"
    printf '%s%s%s\n' "$BLUE" \
        "--------------------------------------------------------------------------------" "$RESET"
    for line in "${CATALOG_ROWS[@]}"; do
        IFS='|' read -r id family version path profile_name script_id file script_title desc risk root args <<<"$line"
        [[ "$id" == "$wanted" ]] || continue
        printf '%-5s %-24s %-20s %s\n' "$script_id" "$file" "$script_title" "$desc"
    done
    printf '%s%s%s\n' "$BLUE" \
        "--------------------------------------------------------------------------------" "$RESET"
    printf '%-5s %s\n' "96" "安装/更新本 OS 配置下的全部脚本"
    printf '%-5s %s\n' "99" "设置脚本下载站点"
    printf '%-5s %s\n' "0" "返回 OS 选择"
    printf '\n单脚本模式：只有选择具体编号后，才会下载对应脚本。\n\n'
}

is_local_bundle() {
    [[ -f "$SOURCE_DIR/catalog.tsv" && -d "$SOURCE_DIR/scripts" ]]
}

find_local_script() {
    local wanted_profile="$1"
    local os_path="$2"
    local file="$3"
    local source_script="$SOURCE_DIR/scripts/$os_path/$file"
    local installed_script="$SCRIPT_DIR/$os_path/$file"

    if is_local_bundle && [[ -f "$source_script" ]]; then
        printf '%s' "$source_script"
        return 0
    fi

    if [[ -f "$installed_script" ]]; then
        if [[ -f "$INSTALLED_MANIFEST" ]] &&
            verify_file "$installed_script" "scripts/$os_path/$file" "$INSTALLED_MANIFEST"; then
            printf '%s' "$installed_script"
            return 0
        fi
        warn "本地脚本校验失败或缺少清单，将重新下载：$file"
    fi
    return 1
}

download_script() {
    local wanted_profile="$1"
    local os_path="$2"
    local file="$3"
    local relative_path="scripts/$os_path/$file"
    local tmp_file destination

    load_remote_manifest || fail "无法获取 SHA256SUMS"
    ensure_work_dir
    download_raw "$relative_path" "$WORK_DIR/$file" ||
        fail "下载失败：$relative_path"
    verify_file "$WORK_DIR/$file" "$relative_path" "$REMOTE_MANIFEST" ||
        fail "校验失败：$relative_path"
    syntax_check "$WORK_DIR/$file" || fail "脚本语法检查失败：$relative_path"

    destination="$SCRIPT_DIR/$os_path/$file"
    mkdir -p -- "$(dirname -- "$destination")"
    tmp_file="$(mktemp "$(dirname -- "$destination")/.${file}.XXXXXX")"
    copy_with_mode 0755 "$WORK_DIR/$file" "$tmp_file"
    mv -f -- "$tmp_file" "$destination"
    copy_with_mode 0644 "$REMOTE_MANIFEST" "$INSTALLED_MANIFEST"
    printf '%s' "$destination"
}

ensure_script() {
    local wanted_profile="$1"
    local os_path="$2"
    local file="$3"

    if find_local_script "$wanted_profile" "$os_path" "$file"; then
        return 0
    fi
    [[ -n "$BASE_URL" ]] || resolve_base_url
    download_script "$wanted_profile" "$os_path" "$file"
}

confirm_run() {
    local title="$1"
    local risk="$2"
    local answer
    printf '\n%s目标：%s%s\n' "$YELLOW" "$title" "$RESET"
    printf '%s风险：%s%s\n' "$YELLOW" "$risk" "$RESET"
    if [[ "${DSH_TOOLS_YES:-0}" == "1" ]]; then
        warn "DSH_TOOLS_YES=1，已跳过确认"
        return 0
    fi
    [[ -t 0 ]] || fail "非交互执行必须设置 DSH_TOOLS_YES=1"
    read -r -p "确认继续？[y/N]: " answer
    [[ "$answer" =~ ^[Yy]$ ]]
}

collect_init_os_args() {
    local hostname_value ip_address dns_server
    if [[ $# -gt 0 ]]; then
        printf '%s\n' "$@"
        return 0
    fi
    [[ -t 0 ]] || fail "init-os.sh 需要参数：hostname ip dns"
    read -r -p "主机名: " hostname_value
    read -r -p "静态 IP/前缀，例如 192.168.1.20/24: " ip_address
    read -r -p "DNS 地址，留空则使用网关: " dns_server
    [[ -n "$hostname_value" && -n "$ip_address" ]] ||
        fail "主机名和 IP 不能为空"
    printf '%s\n%s\n%s\n' "$hostname_value" "$ip_address" "$dns_server"
}

run_tool() {
    local wanted_profile="$1"
    local script_id="$2"
    shift 2
    local entry script_path
    local -a script_args=()

    entry="$(get_script_entry "$wanted_profile" "$script_id")" ||
        fail "OS 配置 $wanted_profile 中不存在脚本编号：$script_id"
    parse_script_entry "$entry"

    if [[ "$ENTRY_ARG_MODE" == "init_os" ]]; then
        mapfile -t script_args < <(collect_init_os_args "$@")
    else
        script_args=("$@")
    fi

    script_path="$(ensure_script "$ENTRY_PROFILE" "$ENTRY_OS_PATH" "$ENTRY_FILE")"
    confirm_run "$ENTRY_TITLE" "$ENTRY_RISK" || {
        info "已取消"
        return 0
    }

    info "运行：$script_path"
    local bash_runner
    bash_runner="$(bash_binary)" || fail "找不到 Bash，无法运行脚本"
    if [[ "$ENTRY_ROOT" == "yes" && "$EUID" -ne 0 ]]; then
        require_command sudo
        sudo -- "$bash_runner" "$script_path" "${script_args[@]}"
    else
        "$bash_runner" "$script_path" "${script_args[@]}"
    fi
}

install_profile_from_source() {
    local wanted_profile="$1"
    local line id os_path file count=0
    for line in "${CATALOG_ROWS[@]}"; do
        IFS='|' read -r id _ _ os_path _ _ file _ _ _ _ _ <<<"$line"
        [[ "$id" == "$wanted_profile" ]] || continue
        [[ -f "$SOURCE_DIR/scripts/$os_path/$file" ]] ||
            fail "源码中缺少脚本：scripts/$os_path/$file"
        syntax_check "$SOURCE_DIR/scripts/$os_path/$file" ||
            fail "语法检查失败：$file"
        mkdir -p -- "$SCRIPT_DIR/$os_path"
        copy_with_mode 0755 "$SOURCE_DIR/scripts/$os_path/$file" \
            "$SCRIPT_DIR/$os_path/$file"
        ((count += 1))
    done
    copy_with_mode 0755 "$SOURCE_DIR/menu.sh" "$INSTALL_DIR/menu.sh"
    copy_with_mode 0644 "$SOURCE_DIR/catalog.tsv" "$INSTALLED_CATALOG"
    (
        cd -- "$INSTALL_DIR"
        write_sha256_manifest menu.sh catalog.tsv scripts/*/*/*.sh >SHA256SUMS
    )
    success "已安装 $count 个脚本：$wanted_profile"
}

install_profile_from_remote() {
    local wanted_profile="$1"
    local line id os_path file relative_path count=0
    local stage_dir

    [[ -n "$BASE_URL" ]] || resolve_base_url
    load_remote_manifest || fail "无法获取 SHA256SUMS"
    ensure_work_dir
    stage_dir="$WORK_DIR/install-$wanted_profile"
    mkdir -p -- "$stage_dir/scripts"

    download_raw "menu.sh" "$stage_dir/menu.sh" ||
        fail "无法下载 menu.sh"
    download_raw "catalog.tsv" "$stage_dir/catalog.tsv" ||
        fail "无法下载 catalog.tsv"
    verify_file "$stage_dir/menu.sh" "menu.sh" "$REMOTE_MANIFEST" ||
        fail "menu.sh 校验失败"
    verify_file "$stage_dir/catalog.tsv" "catalog.tsv" "$REMOTE_MANIFEST" ||
        fail "catalog.tsv 校验失败"

    for line in "${CATALOG_ROWS[@]}"; do
        IFS='|' read -r id _ _ os_path _ _ file _ _ _ _ _ <<<"$line"
        [[ "$id" == "$wanted_profile" ]] || continue
        relative_path="scripts/$os_path/$file"
        mkdir -p -- "$stage_dir/scripts/$os_path"
        download_raw "$relative_path" "$stage_dir/$relative_path" ||
            fail "下载失败：$relative_path"
        verify_file "$stage_dir/$relative_path" "$relative_path" "$REMOTE_MANIFEST" ||
            fail "校验失败：$relative_path"
        syntax_check "$stage_dir/$relative_path" ||
            fail "语法检查失败：$relative_path"
        ((count += 1))
    done

    ensure_layout
    copy_with_mode 0755 "$stage_dir/menu.sh" "$INSTALL_DIR/menu.sh"
    copy_with_mode 0644 "$stage_dir/catalog.tsv" "$INSTALLED_CATALOG"
    copy_with_mode 0644 "$REMOTE_MANIFEST" "$INSTALLED_MANIFEST"
    for line in "${CATALOG_ROWS[@]}"; do
        IFS='|' read -r id _ _ os_path _ _ file _ _ _ _ _ <<<"$line"
        [[ "$id" == "$wanted_profile" ]] || continue
        mkdir -p -- "$SCRIPT_DIR/$os_path"
        copy_with_mode 0755 "$stage_dir/scripts/$os_path/$file" \
            "$SCRIPT_DIR/$os_path/$file"
    done
    success "已安装 $count 个脚本：$wanted_profile"
}

install_profile() {
    local wanted_profile="$1"
    profile_exists "$wanted_profile" || fail "未知 OS 配置：$wanted_profile"
    if is_local_bundle; then
        install_profile_from_source "$wanted_profile"
    else
        install_profile_from_remote "$wanted_profile"
    fi
}

install_menu_from_source() {
    ensure_layout
    copy_with_mode 0755 "$SOURCE_DIR/menu.sh" "$INSTALL_DIR/menu.sh"
    copy_with_mode 0644 "$SOURCE_DIR/catalog.tsv" "$INSTALLED_CATALOG"
    (
        cd -- "$INSTALL_DIR"
        if compgen -G "scripts/*/*/*.sh" >/dev/null; then
            write_sha256_manifest menu.sh catalog.tsv scripts/*/*/*.sh >SHA256SUMS
        else
            write_sha256_manifest menu.sh catalog.tsv >SHA256SUMS
        fi
    )
}

install_menu_from_remote() {
    local tmp_menu tmp_catalog
    [[ -n "$BASE_URL" ]] || resolve_base_url
    load_remote_manifest || fail "无法获取 SHA256SUMS"
    ensure_work_dir
    tmp_menu="$WORK_DIR/menu.sh"
    tmp_catalog="$WORK_DIR/catalog.tsv"
    download_raw "menu.sh" "$tmp_menu" || fail "无法下载 menu.sh"
    download_raw "catalog.tsv" "$tmp_catalog" || fail "无法下载 catalog.tsv"
    verify_file "$tmp_menu" "menu.sh" "$REMOTE_MANIFEST" ||
        fail "menu.sh 校验失败"
    verify_file "$tmp_catalog" "catalog.tsv" "$REMOTE_MANIFEST" ||
        fail "catalog.tsv 校验失败"
    syntax_check "$tmp_menu" || fail "menu.sh 语法检查失败"
    ensure_layout
    copy_with_mode 0755 "$tmp_menu" "$INSTALL_DIR/menu.sh"
    copy_with_mode 0644 "$tmp_catalog" "$INSTALLED_CATALOG"
    copy_with_mode 0644 "$REMOTE_MANIFEST" "$INSTALLED_MANIFEST"
}

install_launcher() {
    local bin_dir="$HOME/.local/bin"
    local launcher="$bin_dir/dsh-tools"
    local installed_menu="$INSTALL_DIR/menu.sh"

    if [[ ! -f "$installed_menu" ]]; then
        if is_local_bundle; then
            install_menu_from_source
        else
            install_menu_from_remote
        fi
    fi
    mkdir -p -- "$bin_dir"
    ln -sfn -- "$installed_menu" "$launcher"
    success "已创建命令：$launcher"
    if [[ ":$PATH:" != *":$bin_dir:"* ]]; then
        warn "$bin_dir 不在 PATH 中，请将它加入 PATH"
    fi
}

profile_menu() {
    local choice profile
    while true; do
        clear 2>/dev/null || true
        list_profiles
        read -r -p "请选择 OS 编号: " choice
        case "$choice" in
        0 | q | Q) return 0 ;;
        9) interactive_set_base_url ;;
        10) install_launcher ;;
        *)
            if profile="$(profile_id_by_number "$choice")"; then
                script_menu "$profile"
            else
                warn "无效编号：$choice"
            fi
            ;;
        esac
        echo
        read -r -p "按 Enter 返回 OS 菜单..." _
    done
}

script_menu() {
    local wanted_profile="$1"
    local choice
    while true; do
        clear 2>/dev/null || true
        list_scripts "$wanted_profile"
        read -r -p "请选择脚本编号: " choice
        case "$choice" in
        0 | q | Q) return 0 ;;
        96) install_profile "$wanted_profile" ;;
        99) interactive_set_base_url ;;
        *)
            if get_script_entry "$wanted_profile" "$choice" >/dev/null; then
                run_tool "$wanted_profile" "$choice"
            else
                warn "无效脚本编号：$choice"
            fi
            ;;
        esac
        echo
        read -r -p "按 Enter 返回脚本菜单..." _
    done
}

list_everything() {
    local profile
    list_profiles
    for profile in "${PROFILE_IDS[@]}"; do
        list_scripts "$profile"
    done
}

main() {
    local base_url_arg=''
    local requested_profile=''
    local run_id=''
    local install_profile_requested=0
    local install_launcher_requested=0
    local list_requested=0
    local set_base_url_arg=''
    local show_base_url=0
    local -a run_args=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
        --base-url)
            [[ $# -ge 2 ]] || fail "--base-url 需要参数"
            base_url_arg="$2"
            shift 2
            ;;
        --profile)
            [[ $# -ge 2 ]] || fail "--profile 需要参数"
            requested_profile="$2"
            shift 2
            ;;
        --run)
            [[ $# -ge 2 ]] || fail "--run 需要编号"
            run_id="$2"
            shift 2
            run_args=("$@")
            break
            ;;
        --install-profile)
            install_profile_requested=1
            shift
            ;;
        --install-launcher)
            install_launcher_requested=1
            shift
            ;;
        --list)
            list_requested=1
            shift
            ;;
        --set-base-url)
            [[ $# -ge 2 ]] || fail "--set-base-url 需要参数"
            set_base_url_arg="$2"
            shift 2
            ;;
        --show-base-url)
            show_base_url=1
            shift
            ;;
        --help | -h)
            usage
            return 0
            ;;
        --version | -V)
            printf '%s %s\n' "$APP_NAME" "$APP_VERSION"
            return 0
            ;;
        *)
            fail "未知参数：$1（使用 --help 查看帮助）"
            ;;
        esac
    done

    if [[ -n "$base_url_arg" ]]; then
        BASE_URL="$(normalize_base_url "$base_url_arg")"
        validate_base_url "$BASE_URL"
    else
        load_saved_base_url
    fi

    if [[ -n "$set_base_url_arg" ]]; then
        save_base_url "$set_base_url_arg"
    fi
    if [[ "$show_base_url" -eq 1 ]]; then
        printf '%s\n' "${BASE_URL:-未配置}"
        return 0
    fi

    if [[ "$install_launcher_requested" -eq 1 && -z "$requested_profile" &&
        -z "$run_id" && "$list_requested" -eq 0 ]]; then
        ensure_work_dir
        install_launcher
        return 0
    fi

    initialize_catalog

    if [[ -n "$requested_profile" ]]; then
        profile_exists "$requested_profile" ||
            fail "未知 OS 配置：$requested_profile"
    fi

    if [[ "$list_requested" -eq 1 ]]; then
        list_everything
        return 0
    fi
    if [[ "$install_profile_requested" -eq 1 ]]; then
        [[ -n "$requested_profile" ]] || fail "--install-profile 需要同时指定 --profile"
        install_profile "$requested_profile"
        return 0
    fi
    if [[ "$install_launcher_requested" -eq 1 ]]; then
        ensure_work_dir
        install_launcher
        return 0
    fi
    if [[ -n "$run_id" ]]; then
        [[ -n "$requested_profile" ]] || fail "--run 需要同时指定 --profile"
        if [[ "$run_id" == "1" && ${#run_args[@]} -eq 0 ]] &&
            get_script_entry "$requested_profile" "$run_id" | grep -q '|init_os$'; then
            mapfile -t run_args < <(collect_init_os_args)
        fi
        run_tool "$requested_profile" "$run_id" "${run_args[@]}"
        return 0
    fi

    profile_menu
}

main "$@"
