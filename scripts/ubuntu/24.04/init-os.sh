#!/usr/bin/env bash
# Ubuntu 24.04 host initialization.

#region pre settings
hostname=$1
ipadress=$2
dns=$3

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
    echo -e "\n\e[31m${current_time} || $1\\e[0m"
    sleep 2
}

yellow_echo() {
    current_time=$(date "+%Y-%m-%d %H:%M:%S") # 输出格式：2025-03-06 16:00:00
    echo -e "\n\e[33m${current_time} || $1\\e[0m"
    sleep 2
}

function set_ip_static {
    local IP="${1:-}"
    local DNS="${2:-}" # 新增第二个参数用于接收DNS

    echo "Starting Set Static IP Address:--------------------------------------"

    # 获取当前网络接口名称
    CN=$(ls /sys/class/net | grep -v lo | grep -v docker0 | head -n 1)

    if [ -z "$IP" ]; then
        echo "IP input args is null, will use current IP address to set static IP address"
        IP=$(ip -4 addr show "$CN" | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
        IP_PREFIX=$(ip -4 addr show "$CN" | grep -oP '\d+(\.\d+){3}/\d+')
    else
        echo "Input IP address is $IP, will use this address to set static IP address"
        Profix=$(ip -4 addr show "$CN" | grep -oP '\d+(\.\d+){3}/\d+' | awk -F / '{print $2}')
        IP_PREFIX="${IP}/${Profix}"
    fi

    GW=$(ip route | grep default | grep -oP '(?<=via\s)\d+(\.\d+){3}')
    #DNS=$(grep '^nameserver' /etc/resolv.conf | awk '{print $2}' | tr '\n' ' ')
    if [ -z "$DNS" ]; then
        DNS="$GW"
        echo "Using gateway address as DNS: $DNS"
    else
        echo "Using custom DNS: $DNS"
    fi

    echo "Network interface: [$CN]"
    echo "IP Address is [$IP]"
    echo "Gateway is [$GW]"
    echo "DNS is [$DNS]"

    # 创建或更新Netplan配置文件
    rm /etc/netplan/*.yaml
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

    # 应用Netplan配置
    sudo netplan apply

    echo "Set Static IP Address Completed!!!+++++++++++++++++++++++++++++++++++++++++++++++++++"
}

set_timezone() {
    green_echo "准备设置时区..."
    ln -svf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
    check_command "设置时区"

    date -R
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
sudo apt-get update
green_echo "根据缓存的软件包列表，升级所有可更新的软件包..."
apt upgrade -y
green_echo "系统更新完成..."
#endregion

#region ip and hostname setting
# 设置静态IP地址
green_echo "设置主机名: $hostname"
hostnamectl set-hostname $hostname
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

#快捷键设置
echo "alias clr=clear" >>~/.bashrc
source ~/.bashrc

green_echo "设置静态IP地址: $ipadress"
set_ip_static "$ipadress" "$dns"
ip addr
reboot
#endregion
