#!/usr/bin/env bash
# Ubuntu 24.04 host initialization.

#region pre settings
# 参数均有默认值：主机名取当前主机名，IP 留空沿用当前地址，DNS 留空使用网关
hostname="${1:-$(hostname -s 2>/dev/null || hostname)}"
ipadress="${2:-}"
dns="${3:-}"

script_name=$(basename "$0" .sh) # 示例：原脚本名称为 deploy.sh 会变成 deploy
current_time=$(date "+%Y%m%d-%H%M%S")
LOG_FILE="log_${script_name}_${current_time}.log"
# 将标准输出和标准错误重定向到日志文件
exec > >(tee -a "$LOG_FILE") 2>&1
#endregion

#region functions
green_echo() {
    current_time=$(date "+%Y-%m-%d %H:%M:%S") # 输出格式：2025-03-06 16:00:00
    echo -e "\n\e[32m${current_time} || $1\e[0m"
    sleep 2
}

red_echo() {
    current_time=$(date "+%Y-%m-%d %H:%M:%S") # 输出格式：2025-03-06 16:00:00
    echo -e "\n\e[31m${current_time} || $1\e[0m"
    sleep 2
}

yellow_echo() {
    current_time=$(date "+%Y-%m-%d %H:%M:%S") # 输出格式：2025-03-06 16:00:00
    echo -e "\n\e[33m${current_time} || $1\e[0m"
    sleep 2
}

# 检查上一条命令的执行结果
check_command() {
    if [ $? -ne 0 ]; then
        red_echo "错误: $1 失败!!!"
        return 1
    else
        green_echo "$1 成功!!!"
        return 0
    fi
}

usage() {
    cat <<EOF
用法: bash init-os.sh <hostname> [ip/prefix] [dns]

  hostname    必填, 目标主机名, 例如 node01
  ip/prefix   可选, 静态地址, 例如 192.168.1.20/24
              省略或留空时沿用当前地址与前缀
  dns         可选, 留空则使用网关地址

环境变量:
  DSH_NO_REBOOT=1   完成后不自动重启(默认重启)

安全提示: 本脚本会替换 APT 源、覆盖 Netplan 配置并重启主机。
EOF
}

function set_ip_static {
    local IP="${1:-}"
    local DNS="${2:-}" # 新增第二个参数用于接收DNS

    echo "Starting Set Static IP Address:--------------------------------------"

    # 优先选择默认路由所在网卡；多网卡机器上按字母序取第一个会配错接口导致失联
    CN=$(ip route show default 2>/dev/null | awk '{print $5; exit}')
    if [ -z "$CN" ]; then
        CN=$(ls /sys/class/net | grep -vE '^(lo|docker0|veth|br-)' | head -n 1)
        echo "未检测到默认路由，回退到第一个非虚拟网卡: ${CN:-<none>}"
    fi
    if [ -z "$CN" ]; then
        red_echo "无法识别可用网卡，已放弃修改网络配置"
        return 1
    fi

    if [ -z "$IP" ]; then
        echo "IP input args is null, will use current IP address to set static IP address"
        IP_PREFIX=$(ip -4 addr show "$CN" | grep -oP '\d+(\.\d+){3}/\d+' | head -n 1)
        IP="${IP_PREFIX%%/*}"
    else
        echo "Input IP address is $IP, will use this address to set static IP address"
        if [[ "$IP" == */* ]]; then
            # 已携带前缀长度，直接使用
            IP_PREFIX="$IP"
            IP="${IP%%/*}"
        else
            # 未携带前缀，沿用当前接口前缀
            Profix=$(ip -4 addr show "$CN" | grep -oP '\d+(\.\d+){3}/\d+' | head -n 1 | awk -F / '{print $2}')
            IP_PREFIX="${IP}/${Profix}"
        fi
    fi

    # 网关取所选网卡的默认路由，避免多网卡时取到别的接口的网关
    GW=$(ip route show default dev "$CN" 2>/dev/null | grep -oP '(?<=via\s)\d+(\.\d+){3}' | head -n 1)
    if [ -z "$GW" ]; then
        GW=$(ip route | grep default | grep -oP '(?<=via\s)\d+(\.\d+){3}' | head -n 1)
    fi

    # 校验必要信息，避免生成不可用的 Netplan 配置后失联
    if ! [[ "$IP" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        red_echo "IP 地址格式无效: [$IP]"
        return 1
    fi
    if [ -z "$GW" ]; then
        red_echo "未检测到默认网关，无法生成静态路由，已放弃修改网络配置"
        return 1
    fi
    if [ -z "$IP_PREFIX" ] || ! [[ "$IP_PREFIX" == */* ]]; then
        red_echo "无法确定 IP 前缀长度(例如 /24)，已放弃修改网络配置"
        return 1
    fi

    #DNS=$(grep '^nameserver' /etc/resolv.conf | awk '{print $2}' | tr '\n' ' ')
    if [ -z "$DNS" ]; then
        DNS="$GW"
        echo "Using gateway address as DNS: $DNS"
    else
        echo "Using custom DNS: $DNS"
    fi

    echo "Network interface: [$CN]"
    echo "IP Address is [$IP]"
    echo "IP Prefix is [$IP_PREFIX]"
    echo "Gateway is [$GW]"
    echo "DNS is [$DNS]"

    # 创建或更新Netplan配置文件(先备份原有配置，失败可回滚)
    NETPLAN_BACKUP="/root/netplan-backup-$(date +%Y%m%d-%H%M%S)"
    if compgen -G "/etc/netplan/*.yaml" >/dev/null; then
        mkdir -p "$NETPLAN_BACKUP"
        cp -a /etc/netplan/*.yaml "$NETPLAN_BACKUP"/ 2>/dev/null
        echo "原有 Netplan 配置已备份至: $NETPLAN_BACKUP"
    fi
    rm -f /etc/netplan/*.yaml
    NETPLAN_FILE="/etc/netplan/01-netcfg.yaml"
    cat <<EOF | tee "$NETPLAN_FILE" >/dev/null
network:
  version: 2
  ethernets:
    $CN:
      dhcp4: no
      addresses: [$IP_PREFIX]
      routes:
        - to: default
          via: $GW
      nameservers:
        addresses: [$DNS]
EOF

    # 应用Netplan配置，失败时回滚备份
    if sudo netplan apply; then
        echo "Set Static IP Address Completed!!!+++++++++++++++++++++++++++++++++++++++++++++++++++"
        return 0
    else
        red_echo "netplan apply 失败，尝试回滚原有配置"
        if [ -d "$NETPLAN_BACKUP" ]; then
            rm -f /etc/netplan/*.yaml
            cp -a "$NETPLAN_BACKUP"/*.yaml /etc/netplan/ 2>/dev/null
            sudo netplan apply
            yellow_echo "已回滚至原有网络配置"
        fi
        return 1
    fi
}

set_timezone() {
    green_echo "准备设置时区..."
    ln -svf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
    check_command "设置时区"

    date -R
}
#endregion

#region 参数校验
if [ -z "$hostname" ]; then
    red_echo "缺少主机名参数"
    usage
    exit 1
fi

if ! [[ "$hostname" =~ ^[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?$ ]]; then
    red_echo "主机名不合法: [$hostname]，仅允许字母、数字、连字符，且不能以连字符开头或结尾"
    exit 1
fi

if [ -n "$ipadress" ] && ! [[ "$ipadress" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}(/[0-9]{1,2})?$ ]]; then
    red_echo "IP 参数不合法: [$ipadress]，示例: 192.168.1.20/24"
    exit 1
fi

if [ -n "$dns" ] && ! [[ "$dns" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
    red_echo "DNS 参数不合法: [$dns]，示例: 223.5.5.5"
    exit 1
fi

if [ "$(id -u)" -ne 0 ]; then
    red_echo "请使用 root 或 sudo 执行本脚本"
    exit 1
fi

printf '\n本次将使用以下参数（可直接回车使用默认值）：\n'
printf '  主机名    : %s\n' "$hostname"
printf '  静态地址  : %s\n' "${ipadress:-（沿用当前地址）}"
printf '  DNS       : %s\n\n' "${dns:-（使用网关）}"
#endregion

#region 无人值守设置
# 初始化过程不允许停在 TUI 对话框上：关闭 debconf 提问、apt 变更列表分页，
# 以及 Ubuntu 24.04 上 needrestart 的"是否重启服务"交互
export DEBIAN_FRONTEND=noninteractive
export DEBCONF_NONINTERACTIVE_SEEN=true
export APT_LISTCHANGES_FRONTEND=none
export NEEDRESTART_MODE=a

# 预置键盘与区域设置，避免 keyboard-configuration/tzdata 升级时弹出选择界面。
# 取值与脚本后续设定的时区保持一致。
if command -v debconf-set-selections >/dev/null 2>&1; then
    debconf-set-selections <<'PRESEED'
keyboard-configuration keyboard-configuration/layoutcode string us
keyboard-configuration keyboard-configuration/modelcode string pc105
keyboard-configuration keyboard-configuration/variantcode string
console-setup console-setup/charmap47 select UTF-8
tzdata tzdata/Areas select Asia
tzdata tzdata/Zones/Asia select Shanghai
PRESEED
fi

# 统一 apt-get 调用；本脚本已强制 root，无需 sudo
apt_get() {
    DEBIAN_FRONTEND=noninteractive \
    DEBCONF_NONINTERACTIVE_SEEN=true \
    APT_LISTCHANGES_FRONTEND=none \
    NEEDRESTART_MODE=a \
        apt-get -o Dpkg::Options::=--force-confdef \
                -o Dpkg::Options::=--force-confold "$@"
}
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
sudo rm -f /etc/apt/sources.list                             # 删除旧版配置文件
sudo rm -f /etc/apt/sources.list.d/*docker*.list             # 删除Docker官方源
sudo rm -f /etc/apt/sources.list.d/*{security,archive}*.list # 清理其他Ubuntu官方源

green_echo "当前生效源列表："
apt-cache policy | grep -E 'http|https' # 应仅显示aliyun和docker镜像源

green_echo "刷新软件源元数据，从 /etc/apt/sources.list 更新系统包列表，不会修改已安装的软件包..."
apt_get update
green_echo "根据缓存的软件包列表，升级所有可更新的软件包..."
apt_get upgrade -y
green_echo "系统更新完成..."
#endregion

#region ip and hostname setting
# 设置静态IP地址
green_echo "设置主机名: $hostname"
hostnamectl set-hostname "$hostname"
cp /etc/hosts /etc/hosts.bak
if grep -q "^127\.0\.1\.1" /etc/hosts; then
    sudo sed -i "/^127\.0\.1\.1/c\127.0.1.1 $hostname" /etc/hosts
else
    echo "127.0.1.1 $hostname" | sudo tee -a /etc/hosts >/dev/null
fi

sudo systemctl restart systemd-resolved 2>/dev/null
sudo systemctl restart nscd 2>/dev/null

green_echo "设置时区: Asia/Shanghai"
TIMEZONE="Asia/Shanghai"
set_timezone

#快捷键设置(幂等写入，避免重复追加)
if ! grep -qs '^alias clr=clear$' ~/.bashrc; then
    echo "alias clr=clear" >>~/.bashrc
fi

green_echo "设置静态IP地址: ${ipadress:-<沿用当前地址>}"
if ! set_ip_static "$ipadress" "$dns"; then
    red_echo "静态 IP 配置失败，为避免失联已跳过重启；请检查网络参数后重试"
    exit 1
fi
ip addr

if [ "${DSH_NO_REBOOT:-0}" = "1" ]; then
    yellow_echo "已设置 DSH_NO_REBOOT=1，跳过重启；请手工执行 reboot 使配置完全生效"
else
    green_echo "5 秒后重启主机以应用配置，如需取消请立即按 Ctrl+C"
    sleep 5
    reboot
fi
#endregion
