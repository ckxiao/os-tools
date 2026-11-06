#!/usr/bin/env bash
# Ubuntu 24.04 host hardening.
script_name=$(basename "$0" .sh)      # 示例：原脚本名称为 deploy.sh 会变成 deploy
current_time=$(date "+%Y%m%d-%H%M%S") # 获取当前时间戳用于备份文件
# 日志目录与 common.sh 保持一致；不可写时回退当前目录
LOG_DIR="${DSH_LOG_DIR:-/var/log/dsh-tools}"
mkdir -p "$LOG_DIR" 2>/dev/null || LOG_DIR="."
LOG_FILE="$LOG_DIR/log_${script_name}_${current_time}.log"

# 无人值守：关闭 debconf 提问与 needrestart 的服务重启交互
export DEBIAN_FRONTEND=noninteractive
export DEBCONF_NONINTERACTIVE_SEEN=true
export APT_LISTCHANGES_FRONTEND=none
export NEEDRESTART_MODE=a

###############################
#        配置参数区域         #
###############################
# 密码策略相关配置
PASS_MAX_DAYS=90                # 设置密码最大有效期(天)
PASS_MIN_DAYS=0                 # 设置密码最小有效期(天)
PASS_WARN_AGE=14                # 设置密码过期前警告天数
PASS_MIN_LEN=8                  # 设置密码最小长度
PAM_PWQUALITY="yes"             # 是否启用密码复杂度检查(yes/no)
FORCE_PASSWORD_CHANGE="no"      # 是否强制用户 (针对UID>=1000且非nobady用户) 在下次登录时更改密码(yes/no)
FORCE_ROOT_PASSWORD_CHANGE="no" # 是否强制root用户在下次登录时更改密码(yes/no)

# SSH安全配置
SSH_PORT=22                 # 设置SSH服务端口号
PERMIT_ROOT_LOGIN="no"      # 是否允许root用户SSH登录(yes/no)
PERMIT_EMPTY_PASSWORDS="no" # 是否允许空密码登录(yes/no)
PERMIT_PASSWD_LOGIN="no"    # 是否运行使用密码SSH登录
X11_FORWARDING="no"         # 是否启用X11转发(yes/no)
FAILED_LOGIN_ATTEMPTS=5     # 设置登录失败尝试次数限制
UNLOCK_TIME=300             # 设置普通用户账户锁定时间(秒)
ROOT_UNLOCK_TIME=600        # 设置root账户锁定时间(秒)
# SSH 来源白名单：留空表示不启用 hosts.allow 限制（公开仓库的安全默认值）
# 需要限制来源时用 --allow-hosts="10.0.0.5,10.0.0.6" 传入，不要直接改这里
SSH_LOGIN_HOSTS=()
OPS_USER="ck"

# Shell会话管理设置
TMOUT=900     # 设置Shell会话超时时间(秒)
HISTSIZE=1000 # 设置命令历史记录条数

# 文件保护设置
LOCK_FILES="no"                                                                # 是否锁定重要系统文件(yes/no)
IMPORTANT_FILES="/etc/passwd /etc/shadow /etc/group /etc/gshadow /etc/sudoers" # 定义重要系统文件列表

# 防火墙开放的端口范围
FIREWALL_PORTS=(
    "22"
    "53"
    "80/tcp"
)

# 系统审计配置
ENABLE_AUDITD="yes" # 是否启用auditd审计服务(yes/no)

# 内核加固配置
ENABLE_SYSCTL_HARDENING="yes" # 是否启用内核参数加固(yes/no)
declare -A SYSCTL_PARAMS=(
    # 网络和安全相关参数
    # IPv4网络参数
    ["net.ipv4.conf.all.accept_redirects"]="0"     # 禁止所有接口接受ICMP重定向报文(安全加固)
    ["net.ipv4.conf.default.accept_redirects"]="0" # 禁止默认接口接受ICMP重定向报文(安全加固)
    ["net.ipv4.conf.all.send_redirects"]="0"       # 禁止所有接口发送ICMP重定向报文(安全加固)
    ["net.ipv4.conf.default.send_redirects"]="0"   # 禁止默认接口发送ICMP重定向报文(安全加固)
    ["net.ipv4.icmp_echo_ignore_broadcasts"]="1"   # 忽略ICMP广播请求，防止SMURF攻击
    ["net.ipv4.conf.all.accept_source_route"]="0"  # 拒绝IPv4源路由包(安全加固)
    ["net.ipv6.conf.all.accept_source_route"]="0"  # 拒绝IPv6源路由包(安全加固)

    # 内核安全参数
    ["kernel.randomize_va_space"]="2" # 完全启用ASLR(地址空间布局随机化)保护
    ["fs.suid_dumpable"]="0"          # 禁止SUID程序产生core dump(安全加固)

    # TCP防护和优化参数
    ["net.ipv4.tcp_syncookies"]="1"         # 启用SYN Cookie防御SYN洪水攻击
    ["net.ipv4.tcp_tw_reuse"]="1"           # 允许TIME-WAIT套接字重用(TCP性能优化)
    ["net.ipv4.tcp_fin_timeout"]="60"       # FIN超时时间60秒(默认60)
    ["net.ipv4.tcp_synack_retries"]="1"     # SYN-ACK重试次数减少到1次(防御SYN攻击)
    ["net.ipv4.tcp_syn_retries"]="1"        # SYN重试次数减少到1次(防御SYN攻击)
    ["net.ipv4.tcp_timestamps"]="0"         # 禁用TCP时间戳(某些环境下可防NAT问题)
    ["net.ipv4.tcp_window_scaling"]="1"     # 启用TCP窗口缩放(支持高延迟高带宽网络)
    ["net.ipv4.tcp_sack"]="1"               # 启用选择性确认(TCP性能优化)
    ["net.ipv4.tcp_mtu_probing"]="1"        # 启用路径MTU发现(优化网络性能)
    ["net.ipv4.tcp_max_orphans"]="32768"    # 最大孤儿套接字数量限制
    ["net.ipv4.tcp_retries2"]="5"           # TCP数据包最大重传次数
    ["net.ipv4.tcp_keepalive_intvl"]="30"   # keepalive探测间隔30秒
    ["net.ipv4.tcp_keepalive_probes"]="5"   # keepalive探测次数5次
    ["net.ipv4.tcp_fastopen"]="3"           # 启用TCP Fast Open支持(RFC7413)
    ["net.ipv4.tcp_keepalive_time"]="1200"  # TCP连接空闲1200秒后开始发送keepalive探测包
    ["net.ipv4.tcp_max_syn_backlog"]="8192" # SYN队列最大长度8192
    ["net.ipv4.tcp_max_tw_buckets"]="5000"  # TIME_WAIT状态套接字最大数量限制

    # IP端口范围设置
    ["net.ipv4.ip_local_port_range"]="1024 65535" # TCP/UDP本地临时端口范围

    # 内核网络核心参数
    ["net.core.netdev_max_backlog"]="8192" # NIC接收数据包的队列长度上限
    ["net.core.somaxconn"]="8192"          # listen()的backlog上限设置

    # Socket缓冲区设置 (单位:字节)
    ["net.core.rmem_max"]="12582912"    # socket接收缓冲区最大值12MB
    ["net.core.wmem_max"]="12582912"    # socket发送缓冲区最大值12MB
    ["net.core.rmem_default"]="6291456" # socket接收缓冲区默认值6MB
    ["net.core.wmem_default"]="6291456" # socket发送缓冲区默认值6MB
)

###############################
#        命令行参数           #
###############################
usage() {
    cat <<EOF
用法: bash hardening-os.sh [选项]

  --ssh-port=PORT         SSH 监听端口，默认 22
  --allow-hosts=IP[,IP]   允许 SSH 登录的来源 IP，留空表示不做限制
  --ops-user=NAME         运维账号名，默认 ck

密码与登录策略（均有默认值）:
  --pass-min-len=N        密码最小长度，默认 8
  --pass-max-days=N       密码最长有效期（天），默认 90
  --pass-min-days=N       密码最短有效期（天），默认 0
  --pass-warn-age=N       过期前警告天数，默认 14
  --failed-attempts=N     登录失败锁定阈值，默认 5
  --unlock-time=N         账户锁定时间（秒），默认 300
  --permit-root-login=Y   是否允许 root 直接登录，默认 no
  --permit-password-login=Y 是否允许密码登录，默认 no
  -h, --help              显示帮助

说明:
  只有显式传入 --allow-hosts 才会写入 /etc/hosts.allow 与 /etc/hosts.deny 白名单；
  hosts.allow 依赖 sshd 的 libwrap 支持，未编译该特性时不生效，建议配合 ufw 限制来源。

环境变量:
  HARDENING_SSH_PORT / HARDENING_ALLOW_HOSTS / HARDENING_OPS_USER
  HARDENING_PASS_MIN_LEN / HARDENING_PASS_MAX_DAYS / HARDENING_PASS_MIN_DAYS
  HARDENING_PASS_WARN_AGE / HARDENING_FAILED_ATTEMPTS / HARDENING_UNLOCK_TIME
  HARDENING_PERMIT_ROOT_LOGIN / HARDENING_PERMIT_PASSWORD_LOGIN
  HARDENING_ALLOW_NO_KEY=1   未部署 SSH 公钥时仍强制继续（默认中止，防止锁死）
EOF
}

# 策略类选项统一由这里映射到变量，避免每个选项写两遍分支
simple_opt_var() {
    case "$1" in
    pass-min-len) echo PASS_MIN_LEN ;;
    pass-max-days) echo PASS_MAX_DAYS ;;
    pass-min-days) echo PASS_MIN_DAYS ;;
    pass-warn-age) echo PASS_WARN_AGE ;;
    failed-attempts) echo FAILED_LOGIN_ATTEMPTS ;;
    unlock-time) echo UNLOCK_TIME ;;
    permit-root-login) echo PERMIT_ROOT_LOGIN ;;
    permit-password-login) echo PERMIT_PASSWD_LOGIN ;;
    *) return 1 ;;
    esac
}

parse_args() {
    # 环境变量优先级低于命令行参数
    [ -n "${HARDENING_SSH_PORT:-}" ] && SSH_PORT="$HARDENING_SSH_PORT"
    [ -n "${HARDENING_OPS_USER:-}" ] && OPS_USER="$HARDENING_OPS_USER"
    if [ -n "${HARDENING_ALLOW_HOSTS:-}" ]; then
        IFS=',' read -r -a SSH_LOGIN_HOSTS <<<"$HARDENING_ALLOW_HOSTS"
    fi
    [ -n "${HARDENING_PASS_MIN_LEN:-}" ] && PASS_MIN_LEN="$HARDENING_PASS_MIN_LEN"
    [ -n "${HARDENING_PASS_MAX_DAYS:-}" ] && PASS_MAX_DAYS="$HARDENING_PASS_MAX_DAYS"
    [ -n "${HARDENING_PASS_MIN_DAYS:-}" ] && PASS_MIN_DAYS="$HARDENING_PASS_MIN_DAYS"
    [ -n "${HARDENING_PASS_WARN_AGE:-}" ] && PASS_WARN_AGE="$HARDENING_PASS_WARN_AGE"
    [ -n "${HARDENING_FAILED_ATTEMPTS:-}" ] && FAILED_LOGIN_ATTEMPTS="$HARDENING_FAILED_ATTEMPTS"
    [ -n "${HARDENING_UNLOCK_TIME:-}" ] && UNLOCK_TIME="$HARDENING_UNLOCK_TIME"
    [ -n "${HARDENING_PERMIT_ROOT_LOGIN:-}" ] && PERMIT_ROOT_LOGIN="$HARDENING_PERMIT_ROOT_LOGIN"
    [ -n "${HARDENING_PERMIT_PASSWORD_LOGIN:-}" ] && PERMIT_PASSWD_LOGIN="$HARDENING_PERMIT_PASSWORD_LOGIN"

    local key var
    while [ $# -gt 0 ]; do
        case "$1" in
        --ssh-port=*) SSH_PORT="${1#*=}" ;;
        --ssh-port)
            shift
            SSH_PORT="${1:-}"
            ;;
        --allow-hosts=*) IFS=',' read -r -a SSH_LOGIN_HOSTS <<<"${1#*=}" ;;
        --allow-hosts)
            shift
            IFS=',' read -r -a SSH_LOGIN_HOSTS <<<"${1:-}"
            ;;
        --ops-user=*) OPS_USER="${1#*=}" ;;
        --ops-user)
            shift
            OPS_USER="${1:-}"
            ;;
        -h | --help)
            usage
            exit 0
            ;;
        --*=*)
            key="${1%%=*}"
            key="${key#--}"
            if var="$(simple_opt_var "$key")"; then
                printf -v "$var" '%s' "${1#*=}"
            else
                echo "未知参数: $1（使用 -h 查看帮助）" >&2
                exit 2
            fi
            ;;
        --*)
            key="${1#--}"
            if var="$(simple_opt_var "$key")"; then
                shift
                printf -v "$var" '%s' "${1:-}"
            else
                echo "未知参数: $1（使用 -h 查看帮助）" >&2
                exit 2
            fi
            ;;
        -h | --help)
            usage
            exit 0
            ;;
        *)
            echo "未知参数: $1（使用 -h 查看帮助）" >&2
            exit 2
            ;;
        esac
        shift
    done
}

validate_config() {
    local host

    if ! [[ "$SSH_PORT" =~ ^[0-9]+$ ]] || [ "$SSH_PORT" -lt 1 ] || [ "$SSH_PORT" -gt 65535 ]; then
        echo "[X] SSH 端口非法: ${SSH_PORT}（应为 1-65535）" >&2
        return 1
    fi

    if [ -n "${OPS_USER:-}" ] && ! [[ "$OPS_USER" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
        echo "[X] 运维账号名非法: ${OPS_USER}" >&2
        return 1
    fi

    for host in "${SSH_LOGIN_HOSTS[@]+"${SSH_LOGIN_HOSTS[@]}"}"; do
        if ! [[ "$host" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
            echo "[X] 白名单地址非法: ${host}（当前仅支持 IPv4 单地址）" >&2
            return 1
        fi
    done

    if ! [[ "$PASS_MIN_LEN" =~ ^[0-9]+$ ]] || [ "$PASS_MIN_LEN" -lt 4 ] || [ "$PASS_MIN_LEN" -gt 64 ]; then
        echo "[X] 密码最小长度非法: ${PASS_MIN_LEN}（应为 4-64）" >&2
        return 1
    fi

    if ! [[ "$PASS_MAX_DAYS" =~ ^[0-9]+$ ]] || [ "$PASS_MAX_DAYS" -lt 1 ] || [ "$PASS_MAX_DAYS" -gt 99999 ]; then
        echo "[X] 密码最长有效期非法: ${PASS_MAX_DAYS}（应为 1-99999）" >&2
        return 1
    fi

    if ! [[ "$PASS_MIN_DAYS" =~ ^[0-9]+$ ]] || [ "$PASS_MIN_DAYS" -gt "$PASS_MAX_DAYS" ]; then
        echo "[X] 密码最短有效期非法: ${PASS_MIN_DAYS}（应为 0 且不超过最长有效期）" >&2
        return 1
    fi

    if ! [[ "$PASS_WARN_AGE" =~ ^[0-9]+$ ]]; then
        echo "[X] 警告天数非法: ${PASS_WARN_AGE}" >&2
        return 1
    fi

    if ! [[ "$FAILED_LOGIN_ATTEMPTS" =~ ^[0-9]+$ ]] || [ "$FAILED_LOGIN_ATTEMPTS" -lt 1 ] || [ "$FAILED_LOGIN_ATTEMPTS" -gt 20 ]; then
        echo "[X] 登录失败阈值非法: ${FAILED_LOGIN_ATTEMPTS}（应为 1-20）" >&2
        return 1
    fi

    if ! [[ "$UNLOCK_TIME" =~ ^[0-9]+$ ]] || [ "$UNLOCK_TIME" -lt 30 ]; then
        echo "[X] 账户锁定时间非法: ${UNLOCK_TIME}（应不小于 30 秒）" >&2
        return 1
    fi

    case "$PERMIT_ROOT_LOGIN" in
    yes | no) ;;
    *)
        echo "[X] permit-root-login 只能是 yes 或 no: ${PERMIT_ROOT_LOGIN}" >&2
        return 1
        ;;
    esac

    case "$PERMIT_PASSWD_LOGIN" in
    yes | no) ;;
    *)
        echo "[X] permit-password-login 只能是 yes 或 no: ${PERMIT_PASSWD_LOGIN}" >&2
        return 1
        ;;
    esac

    return 0
}

###############################
#        主程序入口           #
###############################
main() {
    parse_args "$@"
    validate_config || return 1

    # 参数解析完成后再开启日志重定向，保证 -h 与错误提示直接输出到终端
    exec > >(tee -a "$LOG_FILE") 2>&1
    echo "日志文件: $LOG_FILE"

    echo "████████████████████████████████ 开始应用Ubuntu系统安全配置 ████████████████████████████████"

    if [ "$(id -u)" -ne 0 ]; then
        echo "[X] 请使用 root 或 sudo 执行本脚本"
        return 1
    fi

    # 调用各配置函数
    firewall_setting
    configure_password_policy
    configure_user_audit
    set_important_permissions
    if ! configure_ssh_security; then
        echo ""
        echo "[X] SSH 加固未完成，为避免远程失联已中止后续步骤。"
        echo "    请根据上方提示部署公钥或调整配置后重新执行。"
        return 1
    fi
    configure_shell_session
    setup_ssh_banner
    configure_auditd
    configure_sysctl_hardening
    configure_file_protection
    force_password_change
    other_hardening
    restart_services

    # 显示完成信息
    echo "+---------------------------------------------------------+"
    echo "| 所有安全设置已成功应用到当前系统中!                     |"
    echo "| 建议重启系统以确保所有更改生效。                        |"
    echo "+---------------------------------------------------------+"
    echo "████████████████████████████████ 完成应用Ubuntu系统安全配置 ████████████████████████████████"

    #reboot
}

firewall_setting() {
    echo ""
    echo "=========== 配置防火墙设置 <函数: firewall_setting> ==========="
    for port in "${FIREWALL_PORTS[@]}"; do
        ufw allow $port
        echo "    开放防火墙端口: $port"
    done
    echo "y" | sudo ufw enable
    echo "防火墙规则状态:" && ufw status
    ufw reload
    echo "重载防火墙规则"
}

# 配置密码策略函数
configure_password_policy() {
    echo ""
    echo "=========== 配置密码策略 <函数: configure_password_policy> ==========="
    echo "配置密码策略..."

    LOGINDEFS="/etc/login.defs" # 登录配置文件路径

    # 备份原始文件
    cp $LOGINDEFS ${LOGINDEFS}.bak.$(date +%Y%m%d) 2>/dev/null
    # 配置密码有效期设置
    # Configure password aging settings in login.defs
    for setting in "PASS_MAX_DAYS" "PASS_MIN_DAYS" "PASS_WARN_AGE"; do
        value=$(eval echo "\$$setting")
        if grep -q "^${setting}[[:space:]]" "$LOGINDEFS"; then
            # Update existing setting (使用制表符保持一致性)
            sed -i "s/^${setting}[[:space:]].*/${setting}\t${value}/" "$LOGINDEFS"
        else
            # Add new setting at end of file (使用制表符保持一致性)
            echo -e "${setting}\t${value}" >>"$LOGINDEFS"
        fi
    done

    # 应用密码策略到现有用户
    #for user in $(getent passwd | cut -d: -f1); do
    #    chage --maxdays $PASS_MAX_DAYS \
    #        --mindays $PASS_MIN_DAYS \
    #        --warndays $PASS_WARN_AGE $user
    #done

    # 配置密码复杂度要求
    # Configure password complexity requirements if enabled
    # 备份原始文件
    PAM_COMMON_PASSWORD="/etc/pam.d/common-password" # PAM密码配置文件路径
    cp $PAM_COMMON_PASSWORD ${PAM_COMMON_PASSWORD}.bak.$(date +%Y%m%d) 2>/dev/null
    if [ "$PAM_PWQUALITY" = "yes" ]; then
        echo "配置密码复杂度检查..."
        # Ubuntu 22.04 起默认使用 pam_pwquality，旧版本为 pam_cracklib，两者分别处理
        if grep -q 'pam_pwquality\.so' "$PAM_COMMON_PASSWORD"; then
            PWQ_CONF="/etc/security/pwquality.conf"
            if [ ! -f "$PWQ_CONF" ]; then
                echo "    未找到 $PWQ_CONF，尝试安装 libpam-pwquality..."
                apt-get install -y libpam-pwquality >/dev/null 2>&1
            fi
            if [ -f "$PWQ_CONF" ]; then
                cp "$PWQ_CONF" "${PWQ_CONF}.bak.$(date +%Y%m%d)" 2>/dev/null
                for item in \
                    "minlen = $PASS_MIN_LEN" \
                    "ucredit = -1" \
                    "lcredit = -1" \
                    "dcredit = -1" \
                    "ocredit = -1" \
                    "retry = 3" \
                    "difok = 3"; do
                    key="${item%% =*}"
                    if grep -qE "^[[:space:]]*#?[[:space:]]*${key}[[:space:]]*=" "$PWQ_CONF"; then
                        sed -i -E "s|^[[:space:]]*#?[[:space:]]*${key}[[:space:]]*=.*|${item}|" "$PWQ_CONF"
                    else
                        echo "$item" >>"$PWQ_CONF"
                    fi
                done
                echo "    已写入 $PWQ_CONF (minlen=$PASS_MIN_LEN, 四类字符各至少 1 个)"
            else
                echo "    [!] pam_pwquality 不可用，跳过密码复杂度配置"
            fi
        elif grep -q 'pam_cracklib\.so' "$PAM_COMMON_PASSWORD"; then
            sed -i -E "s|^[[:space:]]*password[[:space:]]+.*pam_cracklib\.so.*$|password    requisite           pam_cracklib.so retry=3 minlen=${PASS_MIN_LEN} ucredit=-1 lcredit=-1 dcredit=-1 ocredit=-1 difok=3|" "$PAM_COMMON_PASSWORD" || {
                echo "修改密码复杂度设置失败"
                exit 1
            }
            echo "    已通过 pam_cracklib.so 配置密码复杂度"
        else
            echo "    [!] 未识别到密码复杂度模块(pam_pwquality/pam_cracklib)，跳过"
        fi

        # 确保密码哈希算法为 sha512 且记录最近 3 次密码
        if grep -qE 'pam_unix\.so.*sha512' "$PAM_COMMON_PASSWORD" &&
            grep -qE 'pam_unix\.so.*remember=3' "$PAM_COMMON_PASSWORD"; then
            echo "密码哈希设置已正确配置，无需修改"
        else
            sed -i -E 's|^[[:space:]]*password[[:space:]]+.*pam_unix\.so.*$|password    [success=1 default=ignore]      pam_unix.so obscure use_authtok try_first_pass sha512 remember=3|' "$PAM_COMMON_PASSWORD" || {
                echo "修改密码哈希设置失败"
                exit 1
            }
            echo "    已更新 pam_unix 哈希算法为 sha512"
        fi
    fi

    # 输出结果
    echo "    [+] 密码策略配置完成:"
    echo "        - 密码最大有效期: $PASS_MAX_DAYS 天"
    echo "        - 密码最小有效期: $PASS_MIN_DAYS 天"
    echo "        - 密码过期警告天数: $PASS_WARN_AGE 天"
    [ "$PAM_PWQUALITY" = "yes" ] &&
        echo "        - 密码复杂度要求: 最小长度 $PASS_MIN_LEN, 包含大小写字母、数字和特殊字符"
}

# 配置系统用户核查函数
configure_user_audit() {
    echo ""
    echo "=========== 配置系统用户核查 <函数: configure_user_audit> ==========="
    echo "配置系统用户核查..."
    # 定义默认用户列表
    defaultuser=(root daemon bin sys games man lp mail news uucp proxy
        www-data backup list irc gnats nobody systemd-network
        systemd-resolve systemd-timesync messagebus syslog _apt
        tss uuidd tcpdump landscape pollinate usbmux sshd systemd-coredump
        _chrony sync dhcpcd polkitd fwupd-refresh $OPS_USER)

    # 检查用户终端和非默认用户
    for i in $(cat /etc/passwd | cut -d ":" -f 1,7); do
        flag=0
        name=${i%%:*}
        terminal=${i##*:}
        if [[ "${terminal}" == "/bin/bash" || "${terminal}" == "/bin/sh" ]]; then
            echo "    ${i} 用户, shell终端为 /bin/bash 或者 /bin/sh"
        fi
        for j in "${defaultuser[@]}"; do
            if [[ "${name}" == "${j}" ]]; then
                flag=1
                break
            fi
        done
        if [[ $flag -eq 0 ]]; then
            echo "    ${i} 非默认用户"
        fi
    done

    # 备份 /etc/shadow 文件
    cp /etc/shadow /etc/shadow_$current_time.bak
    cp /etc/passwd /etc/passwd_$current_time.bak

    # 检查用户密码过期时间
    echo "检查用户密码过期时间: "
    for user in $(cut -d: -f1 /etc/passwd); do
        expiry_date=$(chage -l $user | grep "Password expires" | cut -d: -f2)
        echo "    用户: $user, 密码过期时间: $expiry_date"
    done

}

# 设置或恢复重要目录和文件的权限
set_important_permissions() {
    echo ""
    echo "=========== 设置重要文件权限 <函数: set_important_permissions> ==========="
    echo "Setting important file permissions..."
    chmod 755 /etc
    chmod 1777 /tmp # 保留 sticky bit，否则任何用户可删除他人文件
    chmod 700 /etc/inetd.conf &>/dev/null
    chmod 644 /etc/passwd
    chmod 640 /etc/shadow # shadow 必须 640 root:shadow，755 会导致口令哈希全局可读
    chmod 644 /etc/group
    chmod 640 /etc/gshadow
    chmod 755 /etc/security
    chmod 644 /etc/services
    chmod 750 /etc/rc*.d
    chmod 600 ~/.ssh/authorized_keys &>/dev/null
    chown root:shadow /etc/shadow /etc/gshadow 2>/dev/null
    chown root:root /etc/passwd /etc/group 2>/dev/null
    echo "File permissions set."

    # 删除潜在威胁文件
    find / -maxdepth 3 -name hosts.equiv -exec rm -f {} + 2>/dev/null
    find / -maxdepth 3 -name .netrc -exec rm -f {} + 2>/dev/null
    find / -maxdepth 3 -name .rhosts -exec rm -f {} + 2>/dev/null
}

# 配置SSH安全函数
configure_ssh_security() {
    echo ""
    echo "=========== 配置SSH安全 <函数: configure_ssh_security> ==========="
    echo "配置SSH安全..."
    # 备份SSH配置文件
    SSHD_CONFIG="/etc/ssh/sshd_config" # SSH配置文件路径

    cp $SSHD_CONFIG "${SSHD_CONFIG}.bak.${current_time}"

    # 防锁死校验: 同时禁用密码登录与 root 登录前，必须确认存在可用公钥
    if [ "$PERMIT_PASSWD_LOGIN" = "no" ] && [ "$PERMIT_ROOT_LOGIN" = "no" ]; then
        key_found="no"
        check_users="root $(getent group sudo 2>/dev/null | cut -d: -f4 | tr ',' ' ')"
        for u in $check_users; do
            home_dir=$(getent passwd "$u" 2>/dev/null | cut -d: -f6)
            if [ -n "$home_dir" ] && [ -s "$home_dir/.ssh/authorized_keys" ]; then
                key_found="yes"
                echo "    检测到已部署公钥的用户: $u"
                break
            fi
        done
        if [ "$key_found" = "no" ] && [ "${HARDENING_ALLOW_NO_KEY:-0}" != "1" ]; then
            echo "    [X] 未检测到任何可用 SSH 公钥，而本次配置将禁用密码登录与 root 登录。"
            echo "        继续执行会导致无法远程登录，已中止 SSH 加固。"
            echo "        请先部署公钥，或设置 HARDENING_ALLOW_NO_KEY=1 强制继续。"
            return 1
        fi
    fi

    # 修改SSH端口
    #!/bin/bash

    # 定义配置项和对应的值
    declare -A CONFIGURATIONS=( # 声明一个关联数组CONFIGURATIONS用于存储SSH配置项
        ["Port"]="$SSH_PORT"                               # SSH服务监听端口，值来自变量SSH_PORT
        ["PermitRootLogin"]="$PERMIT_ROOT_LOGIN"           # 是否允许root登录，值来自变量PERMIT_ROOT_LOGIN
        ["PermitEmptyPasswords"]="$PERMIT_EMPTY_PASSWORDS" # 是否允许空密码登录，值来自变量PERMIT_EMPTY_PASSWORDS
        ["X11Forwarding"]="$X11_FORWARDING"                # 是否启用X11转发功能，值来自变量X11_FORWARDING
        ["PasswordAuthentication"]="$PERMIT_PASSWD_LOGIN"  # 是否启用密码认证，值来自变量PERMIT_PASSWD_LOGIN
        ["AllowTcpForwarding"]="no"                        # 禁止TCP端口转发（增强安全性）
        ["AllowAgentForwarding"]="no"                      # 禁止SSH代理转发（增强安全性）
        ["X11UseLocalhost"]="yes"                          # X11转发仅绑定到本地回环地址
        ["IgnoreRhosts"]="yes"                             # 忽略.rhosts和.shosts文件（增强安全性）
        ["HostbasedAuthentication"]="no"                   # 禁用基于主机的认证方式（增强安全性）
        ["StrictModes"]="yes"                              # SSH在接受连接前严格检查文件权限和所有权
    )

    # 遍历所有配置项
    for key in "${!CONFIGURATIONS[@]}"; do
        value="${CONFIGURATIONS[$key]}"
        ENTRY="$key = $value"

        # 检查配置项是否存在（以非注释形式）
        if grep -q "^$key" "$SSHD_CONFIG"; then
            sed -i "/^$key/c\\$key $value" "$SSHD_CONFIG"
        else
            # 尝试修改注释掉的配置项，如果失败则追加到文件末尾
            sed -i "/#${key}/c\\$key $value" "$SSHD_CONFIG" ||
                echo "$key $value" >>"$SSHD_CONFIG"
        fi
    done

    # 配置登录失败锁定策略(pam_faillock)
    # 幂等做法: 先删除已有的 faillock 规则，再按 PAM 要求的位置重新插入
    COMMON_AUTH="/etc/pam.d/common-auth"
    COMMON_ACCOUNT="/etc/pam.d/common-account"
    cp "$COMMON_AUTH" "${COMMON_AUTH}.bak.${current_time}"
    cp "$COMMON_ACCOUNT" "${COMMON_ACCOUNT}.bak.${current_time}"

    if [ -f /usr/lib/x86_64-linux-gnu/security/pam_faillock.so ] ||
        [ -f /lib/x86_64-linux-gnu/security/pam_faillock.so ]; then
        sed -i '/pam_faillock\.so/d' "$COMMON_AUTH" "$COMMON_ACCOUNT"

        # preauth 必须在 pam_unix 之前，authfail 紧跟其后
        auth_line=$(grep -nE '^auth[[:space:]].*pam_unix\.so' "$COMMON_AUTH" | head -n 1 | cut -d: -f1)
        if [ -n "$auth_line" ]; then
            sed -i "${auth_line}i auth    required            pam_faillock.so preauth silent deny=${FAILED_LOGIN_ATTEMPTS} unlock_time=${UNLOCK_TIME}" "$COMMON_AUTH"
            sed -i "$((auth_line + 1))a auth    [default=die]       pam_faillock.so authfail deny=${FAILED_LOGIN_ATTEMPTS} unlock_time=${UNLOCK_TIME}" "$COMMON_AUTH"
            echo "    [+] 已写入 pam_faillock 认证规则(deny=$FAILED_LOGIN_ATTEMPTS, unlock_time=${UNLOCK_TIME}s)"
        else
            echo "    [!] common-auth 中未找到 pam_unix 认证行，跳过 faillock 配置"
        fi

        # account 段规则必须写入 common-account，而不是 sshd_config
        account_line=$(grep -nE '^account[[:space:]].*pam_unix\.so' "$COMMON_ACCOUNT" | head -n 1 | cut -d: -f1)
        if [ -n "$account_line" ]; then
            sed -i "${account_line}i account required            pam_faillock.so" "$COMMON_ACCOUNT"
        else
            echo "account required            pam_faillock.so" >>"$COMMON_ACCOUNT"
        fi
    else
        echo "    [!] 未找到 pam_faillock.so，跳过登录失败锁定配置"
    fi

    # 配置 allow / deny 列表（仅在显式指定 --allow-hosts 时启用）
    if [ ${#SSH_LOGIN_HOSTS[@]} -eq 0 ]; then
        echo "    [信息] 未指定 --allow-hosts，跳过 sshd 来源白名单配置"
    else
        for host_now in "${SSH_LOGIN_HOSTS[@]}"; do
            if ! grep -q "^sshd:$host_now" /etc/hosts.allow 2>/dev/null; then
                echo "sshd:$host_now:allow" >>/etc/hosts.allow
            fi
        done

        if ! grep -q "^sshd:ALL" /etc/hosts.deny 2>/dev/null; then
            echo sshd:ALL >>/etc/hosts.deny
        fi
        echo "    [!] hosts.allow 依赖 sshd 的 libwrap 支持，未编译该特性时不生效，建议同时用 ufw 限制来源"
    fi

    #result
    echo "    [+] SSH安全配置已更新:"
    echo "        端口号: $SSH_PORT"
    echo "        允许Root登录: $PERMIT_ROOT_LOGIN"
    echo "        允许空密码登录: $PERMIT_EMPTY_PASSWORDS"
    echo "        X11转发: $X11_FORWARDING"
    echo "        密码认证: $PERMIT_PASSWD_LOGIN"
    echo "        TCP转发: no"
    echo "        代理转发: no"
    if grep -q "^auth required pam_faillock.so" /etc/pam.d/common-auth; then
        echo "    [+] PAM登录失败策略已设置 (尝试次数限制:$FAILED_LOGIN_ATTEMPTS,解锁时间:$UNLOCK_TIME 秒)"
    fi
    for host_now in "${SSH_LOGIN_HOSTS[@]+"${SSH_LOGIN_HOSTS[@]}"}"; do
        echo "    [+] SSH访问白名单: $host_now"
    done
}

# 配置Shell会话管理函数
configure_shell_session() {
    echo ""
    echo "=========== 配置Shell会话管理 <函数: configure_shell_session> ==========="
    echo "配置Shell会话管理..."
    # 设置会话超时时间
    if ! grep -q "export TMOUT=$TMOUT" /etc/profile; then
        echo "export TMOUT=$TMOUT" >>/etc/profile
        echo "readonly TMOUT" >>/etc/profile
    fi
    # 设置历史命令记录大小
    if ! grep -q "export HISTSIZE=$HISTSIZE" /etc/profile; then
        echo "export HISTSIZE=$HISTSIZE" >>/etc/profile
        echo "readonly HISTSIZE" >>/etc/profile
    fi

    #result
    grep_result=$(grep TMOUT=900 /etc/profile)
    if [[ ! -z "$grep_result" ]]; then
        echo '    [+] Shell会话超时时间(TMOUT)设置为:'$TMOUT'秒'
    else
        echo '[!] Shell会话超时时间设置失败!' >&2
    fi

    grep_result=$(grep HISTSIZE=1000 /etc/profile)
    if [[ ! -z "$grep_result" ]]; then
        echo '    [+] Shell历史记录条数(HISTSIZE)设置为:'$HISTSIZE
    else
        echo '[!] Shell历史记录条数设置失败!' >&2
    fi

}

setup_ssh_banner() {
    echo ""
    echo "=========== 设置SSH登录Banner <函数: setup_ssh_banner> ==========="
    # 检查并配置SSH Banner路径
    SSHD_CONFIG="/etc/ssh/sshd_config" # SSH配置文件路径

    if egrep -q "^\s*(banner|Banner)\s+\W+.*$" $SSHD_CONFIG; then
        sed -ri "s/^\s*(banner|Banner)\s+\W+.*$/Banner \/etc\/issue/" $SSHD_CONFIG
    else
        echo "Banner /etc/issue" >>$SSHD_CONFIG
    fi

    # 检查操作是否成功
    if [ $? -ne 0 ]; then
        echo "Error: Failed to configure SSH Banner path" >&2
        return 1
    fi

    # 设置登录前警告Banner内容
    sudo tee /etc/issue <<'EOF'
██████████████████* [ (Security Login) ] *██████████████████
Authorized only. All activity will be monitored and reported. By Security Center (ck:ckadmin@msn.cn).
EOF

    # 检查操作是否成功
    if [ $? -ne 0 ]; then
        echo "Error: Failed to setup login banner" >&2
        return 1
    fi

    # 设置登录后提示信息（motd）
    if [ -f /etc/update-motd.d/00-header ] && ! grep -q "(Security Operation) > *" /etc/update-motd.d/00-header; then
        sed -i '/^fi/a\\n\ echo "\\e[1;37;41;5m██████████████████* < (Security Operation) > *██████████████████\\\\e[0m"' /etc/update-motd.d/00-header

        # 检查操作是否成功并应用更改
        if [ $? -eq 0 ]; then
            run-parts /etc/update-motd.d/
            echo "[+] SSH登录前后提示警告Banner设置完成"
            return 0
        else
            echo "Error: Failed to setup post-login message" >&2
            return 1
        fi
    else
        echo "/etc/update-motd.d/00-header 文件没有找到, 或者之前已经设置..." >&2
        return 0
    fi
}

# 配置审计服务函数
configure_auditd() {
    echo ""
    echo "=========== 配置审计服务 <函数: configure_auditd> ==========="
    if [ "$ENABLE_AUDITD" = "yes" ]; then
        echo "启用auditd审计服务..."
        # 安装审计服务
        if ! dpkg -l | grep -q auditd; then
            apt-get install auditd audispd-plugins -y >/dev/null 2>&1
        fi
        # 启用并启动审计服务
        systemctl enable auditd >/dev/null 2>&1
        systemctl start auditd >/dev/null 2>&1

        # 配置审计规则
        if [ ! -f /etc/audit/rules.d/hardening.rules ]; then
            cat >/etc/audit/rules.d/hardening.rules <<EOF
-w /etc/passwd -p wa -k identity 
-w /etc/shadow -p wa -k identity 
-w /etc/gshadow -p wa -k identity 
-w /etc/sudoers -p wa -k sudoers
EOF
            augenrules --load >/dev/null 2>&1
        fi
    else
        echo "[信息] auditd审计服务未启用"
    fi

    #result
    if [ "$ENABLE_AUDITD" = "yes" ]; then
        echo "    [+] auditd审计服务已安装并启用"
        if [ -f /etc/audit/rules.d/hardening.rules ]; then
            echo "    [+] auditd规则已应用:"
            cat /etc/audit/rules.d/hardening.rules | sed 's/^/      &/' #缩进显示规则内容
        fi
    else
        echo "[!] auditd审计服务未启用(按当前配置)"
    fi

}

# 配置内核加固函数
configure_sysctl_hardening() {
    echo ""
    echo "=========== 配置内核加固参数 <函数: configure_sysctl_hardening> ==========="
    local SYSCTL_CONF="/etc/sysctl.conf"

    if [ "$ENABLE_SYSCTL_HARDENING" = "yes" ]; then
        echo "应用内核加固参数..."

        if [ ! -f "$SYSCTL_CONF" ] || [ ! -w "$SYSCTL_CONF" ]; then
            echo "错误: $SYSCTL_CONF 不可写或不存在" >&2
            exit 1
        fi

        cp -f "$SYSCTL_CONF" "$SYSCTL_CONF.bak.$current_time"
        for KEY in "${!SYSCTL_PARAMS[@]}"; do
            VALUE="${SYSCTL_PARAMS[$KEY]}"
            ENTRY="$KEY = $VALUE"
            # 转义正则特殊字符
            ESCAPED_KEY=$(sed 's/[\/&]/\\&/g' <<<"$KEY")

            if grep -q "^[[:space:]]*${KEY}[[:space:]]*=" "$SYSCTL_CONF"; then
                sed -i "s/^[[:space:]]*${ESCAPED_KEY}[[:space:]]*=.*/${ENTRY}/" "$SYSCTL_CONF"
            else
                echo "$ENTRY" >>"$SYSCTL_CONF"
            fi

            # 立即应用参数以捕获错误
            if ! sysctl -w "$KEY=$VALUE" >/dev/null 2>&1; then
                echo "警告: $KEY=$VALUE 设置失败(可能是不支持该参数)" >&2
            fi
        done

        if ! sudo sysctl -p "$SYSCTL_CONF" >/dev/null 2>&1; then
            echo "应用内核参数时出错，已恢复备份..."
            cp -f "$SYSCTL_CONF.bak.$current_time" "$SYSCTL_CONF"
            exit 1
        fi
    else
        echo "[信息] 内核参数加固未启用"
    fi

    # 显示配置结果
    if [ "$ENABLE_SYSCTL_HARDENING" = "yes" ]; then
        echo "    [+] 内核参数加固已应用:"
        sudo sysctl -p | sed 's/^/      /'
    else
        echo "[!] sysctl内核参数加固未启用(按当前配置)"
    fi
}

# 配置文件保护函数
configure_file_protection() {
    echo ""
    echo "=========== 配置文件保护 <函数: configure_file_protection> ==========="
    #IMPORTANT_FILES="/etc/passwd /etc/shadow /etc/group /etc/gshadow /etc/sudoers" # 定义重要系统文件列表

    if [ "$LOCK_FILES" = "yes" ]; then
        for FILE in $IMPORTANT_FILES; do
            #备份文件
            cp $FILE $FILE.bak.$current_time.configure_file_protection
        done
    fi

    if [ "$LOCK_FILES" = "yes" ]; then
        echo "锁定重要系统文件..."
        # 锁定重要文件防止修改
        for FILE in $IMPORTANT_FILES; do
            if ! lsattr "$FILE" | grep -q "\-i-"; then
                chattr +i "$FILE" && echo "    [+] 已锁定文件: $FILE"
            else
                echo "    [信息] 文件已锁定(跳过): $FILE"
            fi

        done
    else
        echo "解锁重要系统文件..."
        # 解锁重要文件
        for FILE in $IMPORTANT_FILES; do
            if lsattr "$FILE" | grep -q "\-i-"; then
                chattr -i "$FILE" && echo "    [+] 已解锁文件: $FILE"
            else
                echo "    [信息] 文件未锁定(跳过): $FILE"
            fi
        done
    fi

    echo "如果有文件被锁定，需要解锁, 是请使用命令:(chattr -i /etc/passwd /etc/shadow /etc/sudoers)"
}

# 强制密码更改函数
force_password_change() {
    echo ""
    echo "=========== 强制密码更改 <函数: force_password_change> ==========="
    if [ "$FORCE_PASSWORD_CHANGE" = "yes" ]; then
        echo "强制用户在下次登录时更改密码..."
        # 强制所有普通用户下次登录修改密码
        for USERNAME in $(awk -F: '($3>=1000)&&($1!="nobody"){print $1}' /etc/passwd); do
            passwd -e "$USERNAME" >/dev/null 2>&1
            echo "用户下次登录必须更改密码: $USERNAME"
        done

        #EXCLUDED_USERS=("nobody" "testuser" "backup") # 定义排除列表
        #for USERNAME in $(awk -F: '($3>=1000){print $1}' /etc/passwd); do
        #    if [[ ! " ${EXCLUDED_USERS[@]} " =~ " $USERNAME " ]]; then # 检查是否在排除列表中
        #        passwd -e "$USERNAME" >/dev/null 2>&1
        #        echo "用户下次登录必须更改密码: $USERNAME"
        #    fi
        #done
    else
        echo "不强制普通用户下次登录更改密码"
    fi

    # 强制root用户下次登录修改密码
    if [ "$FORCE_ROOT_PASSWORD_CHANGE" = "yes" ]; then
        passwd -e root >/dev/null 2>&1
        echo "root用户下次登录必须更改密码"
    else
        echo "不强制root用户下次登录更改密码"
    fi
}

other_hardening() {
    echo ""
    echo "=========== 其他加固 <函数: other_hardening> ==========="
    if [ -f /usr/lib/systemd/system/ctrl-alt-del.target ]; then
        mv /usr/lib/systemd/system/ctrl-alt-del.target /var/log/ctrl-alt-del.target_$current_time.bak
        echo "移动文件: /usr/lib/systemd/system/ctrl-alt-del.target"
    else
    
        echo "文件 ctrl-alt-del.target 不存在，跳过移动操作..."
    fi


    echo "其他加固措施已完成"

}



# 重启服务函数
restart_services() {
    echo ""
    echo "=========== 重启服务 <函数: restart_services> ==========="

    # 重启前校验 sshd 配置，配置非法时重启会直接导致无法登录
    if command -v sshd &>/dev/null; then
        if ! sshd -t 2>/dev/null; then
            echo "    [X] sshd 配置校验失败，已跳过 SSH 重启。请先执行 sshd -t 排查:"
            sshd -t 2>&1 | sed 's/^/        /'
            return 1
        fi
        echo "    [+] sshd 配置校验通过"
    fi

    echo "重启SSH服务..."
    if systemctl restart ssh >/dev/null 2>&1 || service ssh restart >/dev/null 2>&1; then
        echo "    [+] SSH 服务已重启"
    else
        echo "    [!] SSH 服务重启失败，请手工检查: systemctl status ssh"
        return 1
    fi
}

main "$@"
