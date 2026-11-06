#!/usr/bin/env bash
#
# 网络管理子模块，由 mgt-god.sh source 加载，不单独执行。
# 依赖 mgt-god.sh 中定义的 GREEN_echo / blue_echo / red_echo / check_command 等函数。

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    echo "network.sh 是 mgt-god.sh 的子模块，不能直接执行。" >&2
    exit 1
fi

#region 3) 网络管理
NETWORK_MGMT() {
    while true; do
        GREEN_echo "==========网络管理=========="
        GREEN_echo "  1. 显示网络状态"
        GREEN_echo "  2. 网络流量监控"
        GREEN_echo "  3. 修改计算机名"
        GREEN_echo "  4. 修改HOSTS记录"
        GREEN_echo "  5. 修改IP地址"
        GREEN_echo "  6. 防火墙管理"
        GREEN_echo "  7. 网络诊断工具"
        GREEN_echo "  0. 返回主菜单"
        read -p "请输入选择: " choice

        case $choice in
        1) echo "" && display_network_status ;;
        2) echo "" && monitor_network_traffic ;;
        3) echo "" && modify_host_name ;;
        4) echo "" && modify_hosts_record ;;
        5) echo "" && modify_ip_address ;;
        6) echo "" && firewall_management ;;
        7) echo "" && network_diagnostics ;;
        0) break ;;
        *) YELLOW_echo "无效选择,请重新输入" ;;
        esac
        echo
    done
}

### 网络状态显示函数
display_network_status() {
    BLUE_echo "------------------------------------------------------"
    GREEN_echo "正在显示网络状态信息..."

    # 1. 显示所有网络接口信息
    YELLOW_echo "\n===== 网络接口信息 ====="
    ip addr
    check_command "获取网络接口信息"

    # 2. 显示路由表
    YELLOW_echo "\n===== 路由表信息 ====="
    ip route
    check_command "获取路由表信息"

    # 3. 显示DNS配置
    YELLOW_echo "\n===== DNS配置信息 ====="
    if [ -f /etc/resolv.conf ]; then
        cat /etc/resolv.conf
        check_command "获取DNS配置"
    else
        red_echo "警告:/etc/resolv.conf 文件不存在"
    fi

    # 4. 显示当前网络连接
    YELLOW_echo "\n===== 活动网络连接 ====="
    if command -v ss &>/dev/null; then
        ss -tulnp
        check_command "获取网络连接状态"
    else
        red_echo "警告:ss 命令不可用,尝试使用 netstat"
        if command -v netstat &>/dev/null; then
            netstat -tulnp
            check_command "获取网络连接状态(使用netstat)"
        else
            red_echo "错误:ss 和 netstat 命令均不可用"
        fi
    fi

    # 5. 显示ARP缓存
    YELLOW_echo "\n===== ARP缓存表 ====="
    ip neigh
    check_command "获取ARP缓存信息"

    BLUE_echo "------------------------------------------------------"
    green_echo "网络状态显示完成"
}

### 网络流量监控函数
monitor_network_traffic() {
    # 用户输入模块
    BLUE_echo "------------------------------------------------------"
    GREEN_echo "网络流量监控选项:"
    GREEN_echo "  1. 实时监控接口流量(iftop)"
    GREEN_echo "  2. 实时监控接口流量(nload)"
    GREEN_echo "  3. 显示接口带宽统计"
    GREEN_echo "  4. 显示网络连接统计"
    GREEN_echo "  5. 保存监控日志到文件"
    GREEN_echo "  0. 返回上一级"
    BLUE_echo "------------------------------------------------------"

    read -p "请输入监控选项[0-5]: " traffic_choice

    case $traffic_choice in
    1) _monitor_with_iftop ;;
    2) _monitor_with_nload ;;
    3) _show_interface_stats ;;
    4) _show_connection_stats ;;
    5) _save_traffic_log ;;
    0) return ;;
    *)
        red_echo "无效选项"
        monitor_network_traffic
        ;;
    esac
    read -p "按任意键继续..." -n1 -s
    #clear
}

### 修改计算机名函数
modify_host_name() {
    if [ $# -gt 0 ]; then
        hostname="$1"
    else
        read -p "请输入新主机名: " hostname
    fi

    blue_echo "-----------------------------------------------------------------"
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
    blue_echo "-----------------------------------------------------------------"

}

### 修改HOSTS记录函数
modify_hosts_record() {
    if [ $# -gt 0 ]; then
        [ $1 = "cat" ] && _show_hosts_content
        [ $1 = "add" ] && ip=$2 && hostname=$3 && _add_hosts_record "$ip" "$hostname"
        [ $1 = "del" ] && line_num=$2 && _delete_hosts_record "$line_num"
        [ $1 = "edit" ] && line_num=$2 && new_content=$3 && _edit_hosts_record "$line_num" "$new_content" #格式: $3 = "IP地址 主机名"
    else
        # 主交互逻辑
        while true; do
            _show_hosts_content

            BLUE_echo "------------------------------------------------------"
            GREEN_echo "HOSTS记录管理选项:"
            GREEN_echo "  1. 添加记录"
            GREEN_echo "  2. 删除记录"
            GREEN_echo "  3. 编辑记录"
            GREEN_echo "  4. 刷新DNS缓存"
            GREEN_echo "  0. 返回"
            BLUE_echo "------------------------------------------------------"

            read -p "请输入选项[0-4]: " choice

            case $choice in
            1)
                WHITE_echo "请输入要添加的记录(格式: IP地址 主机名)"
                read -p "IP地址: " ip
                read -p "主机名: " hostname
                _add_hosts_record "$ip" "$hostname"
                ;;
            2)
                read -p "请输入要删除的行号: " line_num
                _delete_hosts_record "$line_num"
                ;;
            3)
                read -p "请输入要编辑的行号: " line_num
                read -p "请输入新内容(格式: IP地址 主机名): " new_content
                _edit_hosts_record "$line_num" "$new_content"
                ;;
            4)
                _refresh_dns_cache
                ;;
            0)
                return
                ;;
            *)
                red_echo "无效选项"
                ;;
            esac

            read -p "按任意键继续..." -n1 -s
            #clear
        done
    fi
}

### 修改IP地址函数
modify_ip_address() {
    if [ $# -gt 0 ]; then
        [ $1 = "dhcp" ] && selected_interface=$2 && _set_dhcp "$selected_interface"
        [ $1 = "static" ] && selected_interface=$2 && ip=$3 && netmask=$4 && gateway=$5 && dns=$6 && _set_ip_static "$selected_interface" "$ip" "$netmask" "$gateway" "$dns"
        [ $1 = "show" ] && _show_network_config
    else
        # 主交互逻辑
        while true; do
            _show_network_config

            BLUE_echo "------------------------------------------------------"
            GREEN_echo "IP地址管理选项:"
            GREEN_echo "  1. 配置DHCP"
            GREEN_echo "  2. 配置静态IP"
            GREEN_echo "  0. 返回"
            BLUE_echo "------------------------------------------------------"

            read -p "请输入选项[0-2]: " choice

            case $choice in
            1)
                ip addr | grep 'qdisc mq state UP'
                read -p "请输入要配置的网络接口名称: " selected_interface
                _set_dhcp "$selected_interface"
                _apply_network_config
                ;;
            2)
                read -p "请输入IP地址(如:192.168.1.100): " ip
                read -p "请输入DNS服务器(Default:网关DNS): " dns
                _set_ip_static "$ip" $dns
                _apply_network_config
                ;;
            0)
                return
                ;;
            *)
                red_echo "无效选项"
                ;;
            esac

            read -p "按任意键继续..." -n1 -s
            clear
        done
    fi
}

### 防火墙管理函数
firewall_management() {
    if [ $# -gt 0 ]; then
        [ $1 = "start" ] && _start_firewall
        [ $1 = "stop" ] && _stop_firewall
        [ $1 = "save" ] && _save_firewall_config
        [ $1 = "add" ] && port=$2 && protocol=$3 && policy=$4 && _add_firewall_port_rule "$port" "$protocol" "$policy" && _save_firewall_config
        [ $1 = "del" ] && rule_num=$2 && _delete_firewall_port_rule "$rule_num" && _save_firewall_config
        [ $1 = "addsvc" ] && service=$2 && policy=$3 && _add_firewall_service_rule "$service" "$policy" && _save_firewall_config
        [ $1 = "show" ] && _show_firewall_status && _list_firewall_open_ports
    else
        # 主交互逻辑
        while true; do
            _show_firewall_status

            BLUE_echo "------------------------------------------------------"
            GREEN_echo "防火墙管理选项:"
            GREEN_echo "  1. 查看开放端口列表"
            GREEN_echo "  2. 添加端口规则"
            GREEN_echo "  3. 删除端口规则"
            GREEN_echo "  4. 添加服务规则"
            GREEN_echo "  5. 查看活跃防火墙规则"
            GREEN_echo "  6. 保存防火墙配置"
            GREEN_echo "  7. 启动防火墙"
            GREEN_echo "  8. 关闭防火墙"
            GREEN_echo "  0. 返回"
            BLUE_echo "------------------------------------------------------"

            read -p "请输入选项[0-8]: " choice

            case $choice in
            1)
                _list_firewall_open_ports
                ;;
            2)
                read -p "请输入端口号: " port
                read -p "请输入协议(tcp/udp): " protocol
                read -p "请输入策略(allow/deny): " policy
                _add_firewall_port_rule "$port" "$protocol" "$policy"
                _save_firewall_config
                ;;
            3)
                _list_firewall_open_ports
                read -p "请输入要删除的规则编号: " rule_num
                _delete_firewall_port_rule "$rule_num"
                _save_firewall_config
                ;;
            4)
                read -p "请输入服务名称(如ssh/http): " service
                read -p "请输入策略(allow/deny): " policy
                _add_firewall_service_rule "$service" "$policy"
                _save_firewall_config
                ;;
            5)
                _show_firewall_active_rules
                ;;
            6)
                _save_firewall_config
                ;;
            7)
                _start_firewall
                ;;
            8)
                _stop_firewall
                ;;

            0)
                return
                ;;
            *)
                RED_echo "无效选项"
                ;;
            esac

            read -p "按任意键继续..." -n1 -s
            clear
        done
    fi
}

### 网络诊断工具函数
network_diagnostics() {
    if [ $# -gt 0 ]; then
        [ $1 = "ping" ] && target=$2 && count=${3:-4} && _ping_test "$target" "$count"
        [ $1 = "trace" ] && target=$2 && _traceroute_test "$target"
        [ $1 = "dns" ] && domain=$2 && dns_server=${3:-"8.8.8.8"} && _dns_test "$domain" "$dns_server"
        [ $1 = "port" ] && host=$2 && port=$3 && protocol=${4:-"tcp"} && _port_test "$host" "$port" "$protocol"
        [ $1 = "speed" ] && url=${2:-"http://speedtest.tele2.net/10MB.zip"} && _speed_test "$url"
        [ $1 = "quality" ] && target=${2:-"8.8.8.8"} && _quality_test "$target"
    else
        # 主交互逻辑
        while true; do
            BLUE_echo "------------------------------------------------------"
            GREEN_echo "网络诊断工具选项:"
            GREEN_echo "  1. Ping测试"
            GREEN_echo "  2. Traceroute跟踪"
            GREEN_echo "  3. DNS查询测试"
            GREEN_echo "  4. 端口连通性测试"
            GREEN_echo "  5. 下载速度测试"
            GREEN_echo "  6. 网络质量测试"
            GREEN_echo "  0. 返回"
            BLUE_echo "------------------------------------------------------"

            read -p "请输入选项[0-6]: " choice

            case $choice in
            1)
                read -p "请输入测试目标(IP/域名): " target
                read -p "请输入Ping次数(默认4): " count
                _ping_test "${target}" "${count:-4}"
                ;;
            2)
                read -p "请输入跟踪目标(IP/域名): " target
                _traceroute_test "$target"
                ;;
            3)
                read -p "请输入查询域名: " domain
                read -p "请输入DNS服务器(可选): " dns_server
                _dns_test "$domain" "$dns_server"
                ;;
            4)
                read -p "请输入主机地址: " host
                read -p "请输入端口号: " port
                read -p "请输入协议(tcp/udp,默认tcp): " protocol
                _port_test "$host" "$port" "$protocol"
                ;;
            5)
                read -p "请输入测试URL(默认http://speedtest.tele2.net/10MB.zip): " test_url
                _speed_test "${test_url:-"http://speedtest.tele2.net/10MB.zip"}"
                ;;
            6)
                read -p "请输入测试地址(默认8.8.8.8): " target
                _quality_test "$target"
                ;;
            0)
                return
                ;;
            *)
                RED_echo "无效选项"
                ;;
            esac

            read -p "按任意键继续..." -n1 -s
            clear
        done
    fi
}

#region 原子函数
### 使用iftop监控流量(子函数)
_monitor_with_iftop() {
    blue_echo "启动iftop流量监控(按q退出)..."

    # 检查iftop是否安装
    if ! command -v iftop &>/dev/null; then
        red_echo "iftop未安装,尝试安装..."
        if [ -f /etc/redhat-release ]; then
            sudo yum install -y iftop || {
                red_echo "iftop安装失败"
                return 1
            }
        else
            apt_get install -y iftop || {
                red_echo "iftop安装失败"
                return 1
            }
        fi
    fi

    # 获取所有网络接口
    interfaces=$(ip -o link show | awk -F': ' '{print $2}' | grep -v lo)

    BLUE_echo "------------------------------------------------------"
    GREEN_echo "可用网络接口:"
    echo "$interfaces" | nl
    BLUE_echo "------------------------------------------------------"

    read -p "选择监控接口(编号)或直接回车监控所有接口: " iface_num

    if [ -n "$iface_num" ]; then
        iface=$(echo "$interfaces" | sed -n "${iface_num}p")
        sudo iftop -i "$iface"
    else
        sudo iftop
    fi

    green_echo "iftop监控已结束"
}

### 使用nload监控流量(子函数)
_monitor_with_nload() {
    blue_echo "启动nload流量监控(按q退出)..."

    # 检查nload是否安装
    if ! command -v nload &>/dev/null; then
        red_echo "nload未安装,尝试安装..."
        if [ -f /etc/redhat-release ]; then
            sudo yum install -y nload || {
                red_echo "nload安装失败"
                return 1
            }
        else
            apt_get install -y nload || {
                red_echo "nload安装失败"
                return 1
            }
        fi
    fi

    # 获取所有网络接口
    interfaces=$(ip -o link show | awk -F': ' '{print $2}' | grep -v lo)

    BLUE_echo "------------------------------------------------------"
    GREEN_echo "可用网络接口:"
    echo "$interfaces" | nl
    BLUE_echo "------------------------------------------------------"

    read -p "选择监控接口(编号)或直接回车监控所有接口: " iface_num

    if [ -n "$iface_num" ]; then
        iface=$(echo "$interfaces" | sed -n "${iface_num}p")
        nload "$iface"
    else
        nload
    fi

    green_echo "nload监控已结束"
}

### 显示接口带宽统计(子函数)
_show_interface_stats() {
    blue_echo "当前网络接口带宽统计:"
    BLUE_echo "------------------------------------------------------"

    # 获取并显示详细的接口统计信息
    local stats=$(ip -s link show)

    # 解析并格式化输出
    echo "$stats" | awk '
        /^[0-9]+:/ {
            if (iface) print_stats()
            iface = $2
            rx_bytes = 0; tx_bytes = 0
        }
        /RX:.*bytes/ { getline; rx_bytes = $1 }
        /TX:.*bytes/ { getline; tx_bytes = $1 }
        END { if (iface) print_stats() }
        
        function print_stats() {
            printf "\n接口: %s\n", iface
            printf "接收(RX): %.2f MB (%d bytes)\n", rx_bytes/1048576, rx_bytes
            printf "发送(TX): %.2f MB (%d bytes)\n", tx_bytes/1048576, tx_bytes
        }
    '

    # 显示总流量统计
    BLUE_echo "------------------------------------------------------"
    green_echo "总流量统计:"
    awk '
        BEGIN { printf "%-10s %12s %12s\n", "接口", "RX(MB)", "TX(MB)" }
        /^[0-9]+:/ { iface = $2 }
        /RX:.*bytes/ { getline; rx = $1 }
        /TX:.*bytes/ { getline; tx = $1; printf "%-10s %12.2f %12.2f\n", iface, rx/1048576, tx/1048576 }
    ' <(ip -s link show)

    BLUE_echo "------------------------------------------------------"
}
### 显示网络连接统计(子函数)
_show_connection_stats() {
    blue_echo "网络连接统计信息:"
    BLUE_echo "------------------------------------------------------"

    # 检查ss命令是否可用
    if ! command -v ss &>/dev/null; then
        red_echo "错误: 'ss' 命令未找到,请安装iproute2包"
        return 1
    fi

    # 获取当前时间戳
    green_echo "ss -s :"
    ss -s
    # TCP连接统计
    green_echo "当前TCP连接数:"
    ss -s | awk '/^TCP:/ {print "TCP:   " $2 " (estab " $4 ", closed " $6 ", orphaned " $8 ")"}'

    # UDP连接统计
    green_echo "当前UDP连接数:"
    ss -s | awk '/^UDP:/ {print "UDP:   " $2}'

    # 网络协议统计
    green_echo "网络协议统计:"
    ss -s | awk '
        /^Total:/ {print "总连接数: " $2}
        /^TCP:/ {print "TCP内存: " $10 " (r/w " $12 ")"}
    '

    # 显示活动连接摘要
    green_echo "活动连接摘要:"
    ss -tulnp | awk '
        BEGIN {printf "%-7s %-20s %-20s %-15s\n", "协议", "本地地址", "远程地址", "状态/进程"}
        NR>1 {printf "%-7s %-20s %-20s %-15s\n", $1, $4, $5, $6}
    ' | head -n 10

    BLUE_echo "------------------------------------------------------"
}

### 保存监控日志到文件(子函数)
_save_traffic_log() {
    local log_file="network_traffic_$(date +%Y%m%d_%H%M%S).log"

    BLUE_echo "------------------------------------------------------"
    GREEN_echo "将保存监控日志到: $log_file"
    BLUE_echo "------------------------------------------------------"

    {
        echo "====== 网络接口统计 ======"
        ip -s link show
        echo -e "\n====== 连接统计 ======"
        ss -s
        echo -e "\n====== 网络协议统计 ======"
        netstat -s
    } >"$log_file"

    if [ $? -eq 0 ]; then
        green_echo "监控日志已保存到 $log_file"
    else
        red_echo "保存监控日志失败"
    fi
}

# 显示当前HOSTS内容
_show_hosts_content() {
    BLUE_echo "------------------------------------------------------"
    GREEN_echo "当前/etc/hosts内容:"
    WHITE_echo "$(nl -b a /etc/hosts)"
    BLUE_echo "------------------------------------------------------"
}

# 添加记录
_add_hosts_record() {
    local ip="$1"
    local hostname="$2"

    if grep -q "^${ip}\s" /etc/hosts; then
        red_echo "该IP地址已存在记录"
        return 1
    fi

    sudo bash -c "echo '${ip} ${hostname}' >> /etc/hosts"
    check_command "添加HOSTS记录 ${ip} ${hostname}"

    green_echo "已添加记录: ${ip} ${hostname}"
    echo "[$(date "+%Y-%m-%d %H:%M:%S")] 添加HOSTS记录: ${ip} ${hostname}" >>"$pre_log_file"
}

# 删除记录
_delete_hosts_record() {
    local line_num="$1"
    local original_content=$(sed -n "${line_num}p" /etc/hosts)

    sudo sed -i "${line_num}d" /etc/hosts
    check_command "删除HOSTS记录第${line_num}行"

    green_echo "已删除记录: ${original_content}"
    echo "[$(date "+%Y-%m-%d %H:%M:%S")] 删除HOSTS记录: ${original_content}" >>"$pre_log_file"
}

# 编辑记录
_edit_hosts_record() {
    local line_num="$1"
    local new_content="$2"
    local original_content=$(sed -n "${line_num}p" /etc/hosts)

    sudo sed -i "${line_num}c\\${new_content}" /etc/hosts
    check_command "编辑HOSTS记录第${line_num}行"

    green_echo "已修改记录:"
    green_echo "原内容: ${original_content}"
    green_echo "新内容: ${new_content}"
    echo "[$(date "+%Y-%m-%d %H:%M:%S")] 修改HOSTS记录: ${original_content} -> ${new_content}" >>"$pre_log_file"
}

# 刷新DNS缓存
_refresh_dns_cache() {
    blue_echo "刷新DNS缓存..."
    if command -v systemd-resolve &>/dev/null; then
        sudo systemd-resolve --flush-caches
    fi
    if command -v nscd &>/dev/null; then
        sudo nscd -i hosts
    fi
    green_echo "DNS缓存已刷新"
    echo "[$(date "+%Y-%m-%d %H:%M:%S")] 刷新DNS缓存" >>"$pre_log_file"
}

# 显示当前网络配置
_show_network_config() {
    BLUE_echo "------------------------------------------------------"
    GREEN_echo "当前网络接口配置:"
    WHITE_echo "$(ip -c -br addr)"
    BLUE_echo "------------------------------------------------------"
    GREEN_echo "当前路由配置:"
    WHITE_echo "$(ip -c route)"
    BLUE_echo "------------------------------------------------------"
}

# 配置DHCP模式
_set_dhcp() {
    local interface="$1"
    local config_file="/etc/netplan/01-netcfg.yaml"

    blue_echo "正在配置 ${interface} 为DHCP模式..."

    sudo bash -c "cat > ${config_file}" <<EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    ${interface}:
      dhcp4: true
EOF

    check_command "配置DHCP模式"
    echo "[$(date "+%Y-%m-%d %H:%M:%S")] 配置接口 ${interface} 为DHCP模式" >>"$pre_log_file"
}

# 配置静态IP
_set_ip_static() {
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

# 应用网络配置
_apply_network_config() {
    blue_echo "正在应用网络配置..."
    sudo netplan apply
    check_command "应用网络配置"
    echo "[$(date "+%Y-%m-%d %H:%M:%S")] 应用网络配置变更" >>"$pre_log_file"

    # 验证配置
    sleep 3
    blue_echo "验证新配置..."
    WHITE_echo "$(ip -c -br addr show ${selected_interface})"
    WHITE_echo "$(ip -c route show dev ${selected_interface})"
}

# 显示防火墙状态
_show_firewall_status() {
    BLUE_echo "------------------------------------------------------"
    GREEN_echo "当前防火墙状态:"
    WHITE_echo "$(sudo ufw status verbose)"
    BLUE_echo "------------------------------------------------------"
}

# 启动防火墙
_start_firewall() {
    blue_echo "正在启动防火墙..."
    echo y | sudo ufw enable
    check_command "启动防火墙"
    echo "[$(date "+%Y-%m-%d %H:%M:%S")] 启动防火墙" >>"$pre_log_file"
}

#关闭防火墙
_stop_firewall() {
    blue_echo "正在关闭防火墙..."
    echo y | sudo ufw disable
    check_command "关闭防火墙"
    echo "[$(date "+%Y-%m-%d %H:%M:%S")] 关闭防火墙" >>"$pre_log_file"
}

# 查看开放端口列表
_list_firewall_open_ports() {
    BLUE_echo "------------------------------------------------------"
    GREEN_echo "当前开放端口列表:"
    sudo ufw status numbered
    BLUE_echo "------------------------------------------------------"
}

# 添加端口规则
_add_firewall_port_rule() {
    local port="$1"
    local protocol="$2"
    local policy="$3"

    blue_echo "正在添加端口规则: ${port}/${protocol} ${policy}..."
    sudo ufw allow "${port}/${protocol}" comment "Added at $(date "+%Y-%m-%d %H:%M:%S")"
    check_command "添加端口 ${port}/${protocol} ${policy} 规则"
    echo "[$(date "+%Y-%m-%d %H:%M:%S")] 添加端口规则: ${port}/${protocol} ${policy}" >>"$pre_log_file"
}

# 删除端口规则
_delete_firewall_port_rule() {
    local rule_num="$1"

    blue_echo "正在删除规则编号: ${rule_num}..."
    echo "y" | sudo ufw delete "$rule_num"
    check_command "删除防火墙规则 ${rule_num}"
    echo "[$(date "+%Y-%m-%d %H:%M:%S")] 删除防火墙规则: ${rule_num}" >>"$pre_log_file"
}

# 添加服务规则
_add_firewall_service_rule() {
    local service="$1"
    local policy="$2"

    blue_echo "正在添加服务规则: ${service} ${policy}..."
    sudo ufw allow "$service" comment "Added at $(date "+%Y-%m-%d %H:%M:%S")"
    check_command "添加服务 ${service} ${policy} 规则"
    echo "[$(date "+%Y-%m-%d %H:%M:%S")] 添加服务规则: ${service} ${policy}" >>"$pre_log_file"
}

# 查看活跃规则
_show_firewall_active_rules() {
    BLUE_echo "------------------------------------------------------"
    GREEN_echo "当前活跃防火墙规则:"
    WHITE_echo "$(sudo ufw show raw)"
    BLUE_echo "------------------------------------------------------"
}

# 保存防火墙配置
_save_firewall_config() {
    blue_echo "正在保存防火墙配置..."
    sudo ufw reload
    check_command "保存防火墙配置"
    echo "[$(date "+%Y-%m-%d %H:%M:%S")] 保存防火墙配置" >>"$pre_log_file"
}

# 执行Ping测试
_ping_test() {
    local target="$1"
    local count="$2"

    blue_echo "正在执行Ping测试: ${target} (次数: ${count})..."
    ping -c "$count" "$target"
    check_command "Ping测试 ${target}"
    echo "[$(date "+%Y-%m-%d %H:%M:%S")] 执行Ping测试: ${target} (次数: ${count})" >>"$pre_log_file"
}

# 执行Traceroute跟踪
_traceroute_test() {
    local target="$1"

    if ! command -v traceroute &>/dev/null; then
        blue_echo "正在安装traceroute..."
        apt_get install traceroute || red_echo "traceroute 安装失败!!!"
    fi
    green_echo "正在执行Traceroute跟踪: ${target}..."
    traceroute "$target"
    check_command "Traceroute跟踪 ${target}"
    echo "[$(date "+%Y-%m-%d %H:%M:%S")] 执行Traceroute跟踪: ${target}" >>"$pre_log_file"
}

# 执行DNS查询测试
_dns_test() {
    local domain="$1"
    local dns_server="${2:-"8.8.8.8"}"

    blue_echo "正在执行DNS查询测试: ${domain} (DNS服务器: ${dns_server})..."
    dig @"${dns_server}" "$domain" +short
    check_command "DNS查询测试 ${domain}"
    echo "[$(date "+%Y-%m-%d %H:%M:%S")] 执行DNS查询测试: ${domain} (DNS服务器: ${dns_server:-默认})" >>"$pre_log_file"
}

# 执行端口连通性测试
_port_test() {
    local host="$1"
    local port="$2"
    local protocol="${3:-tcp}" # 默认为TCP协议

    blue_echo "正在测试${protocol^^}端口连通性: ${host}:${port}..."

    if [[ $protocol == "udp" ]]; then
        # 使用nc测试UDP端口(需确保系统已安装netcat)
        if timeout 3 nc -vzu "$host" "$port" 2>&1 | grep -q "succeeded"; then
            green_echo "端口 ${port} 可达(UDP)"
        else
            red_echo "端口 ${port} 不可达(UDP)"
        fi
    else
        # 原有TCP测试逻辑
        timeout 3 bash -c "cat < /dev/null > /dev/tcp/${host}/${port}" 2>/dev/null
        if [ $? -eq 0 ]; then
            green_echo "端口 ${port} 可达(TCP)"
        else
            red_echo "端口 ${port} 不可达(TCP)"
        fi
    fi

    echo "[$(date "+%Y-%m-%d %H:%M:%S")] 测试${protocol^^}端口连通性: ${host}:${port}" >>"$pre_log_file"
}

# 执行下载速度测试
_speed_test() {
    local test_url="$1"
    local test_file="speedtest_$(date +%s).tmp"

    blue_echo "正在执行下载速度测试..."
    GREEN_echo "测试URL: ${test_url}"

    start_time=$(date +%s)
    curl -o "$test_file" -L "$test_url" --progress-bar
    end_time=$(date +%s)

    file_size=$(du -h "$test_file" | cut -f1)
    duration=$((end_time - start_time))
    speed=$(($(stat -c %s "$test_file") / duration / 1024))

    green_echo "下载完成: 文件大小 ${file_size}, 耗时 ${duration}秒, 平均速度 ${speed} KB/s"
    rm -f "$test_file"
    echo "[$(date "+%Y-%m-%d %H:%M:%S")] 下载速度测试: ${speed} KB/s (URL: ${test_url})" >>"$pre_log_file"
}

# 执行网络质量测试
_quality_test() {
    local target=${1:-"8.8.8.8"}

    blue_echo "正在执行网络质量测试(目标地址: ${target})..."
    GREEN_echo "将执行以下测试:"
    GREEN_echo "1. 延迟测试"
    GREEN_echo "2. 抖动测试"
    GREEN_echo "3. 丢包率测试"

    # 延迟测试
    local avg_ping=$(ping -c 5 "$target" | tail -1 | awk -F '/' '{print $5}')
    green_echo "平均延迟: ${avg_ping} ms"

    # 抖动测试
    local jitter=$(ping -c 10 "$target" | grep "time=" | awk -F '=' '{print $4}' | awk '{print $1}' | sort -n | awk '{a[NR]=$0}END{print (a[10]-a[1])/2}')
    green_echo "网络抖动: ${jitter} ms"

    # 丢包率测试
    local loss=$(ping -c 20 "$target" | grep "packet loss" | awk -F ',' '{print $3}' | awk '{print $1}')
    green_echo "丢包率: ${loss}"

    echo "[$(date "+%Y-%m-%d %H:%M:%S")] 网络质量测试: 延迟 ${avg_ping}ms, 抖动 ${jitter}ms, 丢包率 ${loss}" >>"$pre_log_file"
}
#endregion
# endregion
