#!/usr/bin/env bash
# Ubuntu 24.04 operations console.
#region############################################################
# 系统管理工具脚本
#
# 功能:
# 1. 磁盘使用检查 - 显示各挂载点使用情况并预警
# 2. 用户信息查询 - 显示所有用户/查询单个用户详细信息
# 3. 进程管理 - 显示/查询/结束进程
# 4. 支持交互式菜单和命令行直接调用两种模式
#
# 使用方法:
# 1. 交互式模式:
#    sudo bash mgt-god.sh
#    通过菜单选择功能
#
# 2. 命令行模式:
#    sudo bash mgt-god.sh 函数名 [参数]
#    例如:
#    sudo bash mgt-god.sh query_process_details 1234
#    sudo bash mgt-god.sh check_disk_usage
#    sudo bash mgt-god.sh query_single_user testuser
#
# 作者: ck
# 版本: 1.0
# 最后更新: 2023-11-15
#endregion#########################################################

# 脚本所在目录，用于定位同目录的子模块（如 k8s.sh）
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# 共享库可选加载：提供 install_docker / init_logging / run_step 等通用能力。
# 缺失时各调用点会降级并给出提示，不影响其余模块。
if [ -r "$SCRIPT_DIR/common.sh" ]; then
    # shellcheck source=common.sh
    . "$SCRIPT_DIR/common.sh"
fi

#region 主菜单
MAIN_MENU() {
    while true; do
        GREEN_echo "==========系统管理工具=========="
        GREEN_echo "  1.  用户管理"
        GREEN_echo "  2.  进程管理"
        GREEN_echo "  3.  网络管理"
        GREEN_echo "  4.  磁盘管理"
        GREEN_echo "  5.  监控管理"
        GREEN_echo "  6.  服务管理"
        GREEN_echo "  7.  软件包管理"
        GREEN_echo "  8.  日志管理"
        GREEN_echo "  9.  容器管理"
        GREEN_echo "  10. 防火墙管理"
        GREEN_echo "  11. NTP管理"
        GREEN_echo "  12. 存储管理"
        GREEN_echo "  13. OPS SSH密钥管理"
        GREEN_echo "  14. 安全审计"
        GREEN_echo "  15. 备份恢复"
        GREEN_echo "  16. 定时任务"
        GREEN_echo "  17. K8S管理"
        GREEN_echo "  99. 进入Shell终端"
        GREEN_echo "  0.  退出"
        read -p "请输入选择: " choice
        case $choice in
        1) echo "" && USERS_MGMT ;;
        2) echo "" && PROCESS_MGMT ;;
        3) echo "" && NETWORK_MGMT ;;
        4) echo "" && DISK_MGMT ;;
        5) echo "" && MONITORING_MGMT ;;
        6) echo "" && SERVICE_MGMT ;;
        7) echo "" && PACKAGE_MGMT ;;
        8) echo "" && LOG_MGMT ;;
        9) echo "" && CONTAINER_MGMT ;;
        10) echo "" && firewall_management ;;
        11) echo "" && NTP_MGMT ;;
        12) echo "" && STORAGE_MGMT ;;
        13) echo "" && OPS_SSH_KEY_MGMT ;;
        14) echo "" && SECURITY_AUDIT ;;
        15) echo "" && BACKUP_MGMT ;;
        16) echo "" && CRON_MGMT ;;
        17) echo "" && K8S_MGMT ;;
        99 | bash) echo "" && sudo bash ;;
        0 | exit) exit 0 ;;
        *) YELLOW_echo "无效选择,请重新输入" ;;
        esac
        echo
    done
}
#endregion

#region 1) 用户管理（子模块）
# 相关函数已拆分到同目录的 users.sh。
# 缺失时仅该模块不可用，不影响其它模块。
if [ -r "$SCRIPT_DIR/users.sh" ]; then
    # shellcheck source=users.sh
    . "$SCRIPT_DIR/users.sh"
else
    USERS_MGMT() {
        red_echo "未找到 users.sh，用户管理不可用；请重新安装该 OS 配置"
        return 1
    }
fi
# endregion

#region 2) 进程管理
PROCESS_MGMT() {
    # 进程管理菜单
    while true; do
        GREEN_echo "==========进程管理=========="
        GREEN_echo "  1. 显示所有进程"
        GREEN_echo "  2. 查询进程详情"
        GREEN_echo "  3. 结束进程"
        GREEN_echo "  0. 返回主菜单"
        read -p "请输入选择: " choice
        case $choice in
        1) echo "" && display_processes ;;
        2) echo "" && query_process_details ;;
        3) echo "" && kill_process ;;
        0) break ;;
        *) YELLOW_echo "无效选择,请重新输入" ;;
        esac
        echo
    done
}

# 显示所有进程
display_processes() {
    white_echo "正在列出所有进程..."
    white_echo "---------------------------------------------------------------"
    printf "%-8s %-10s %-8s %-8s %-20s\n" "进程ID" "用户" "CPU(%)" "内存(%)" "命令"
    ps -eo pid,user,pcpu,pmem,cmd --sort=-pcpu | head -n 10 | tail -n +2 | while read -r line; do
        fields=($line)
        printf "%-8s %-10s %-8s %-8s %-20s\n" "${fields[0]}" "${fields[1]}" "${fields[2]}" "${fields[3]}" "${fields[4]}"
    done
    white_echo "---------------------------------------------------------------"
}

# 查询进程详情
query_process_details() {
    # 检查是否有参数传入
    if [ $# -gt 0 ]; then
        pid="$1"
    else
        read -p "请输入要查询的进程ID: " pid
    fi

    # 验证PID格式
    if ! [[ "$pid" =~ ^[0-9]+$ ]]; then
        echo "错误: 进程ID必须是数字"
        return 1
    fi

    # 获取进程信息
    process_info=$(ps -p "$pid" -o pid,user,pcpu,pmem,start_time,etime,state,vsize,rss,cmd 2>/dev/null)

    # 检查进程是否存在
    if [ $? -ne "0" ]; then
        echo "进程ID $pid 不存在!"
        return 1
    fi

    # 显示进程详细信息
    echo "--------------------------------"
    echo "进程详细信息:"
    echo "$process_info" | tail -n +2 | while IFS= read -r line; do
        fields=($line)
        echo "进程ID: ${fields[0]}"
        echo "用户: ${fields[1]}"
        echo "CPU使用率: ${fields[2]}%"
        echo "内存使用率: ${fields[3]}%"
        echo "启动时间: ${fields[4]}"
        echo "运行时长: ${fields[5]}"
        echo "状态: ${fields[6]}"
        echo "虚拟内存: $((fields[7] / 1024)) MB" # 转换为MB
        echo "物理内存: $((fields[8] / 1024)) MB" # 转换为MB
        echo "命令: ${fields[*]:9}"
    done
    echo "--------------------------------"
}

# 结束进程
kill_process() {
    if [ $# -gt 0 ]; then
        pid="$1"
    else
        # 检查是否有参数传入
        read -p "请输入要结束的进程ID: " pid
    fi

    if ! [[ "$pid" =~ ^[0-9]+$ ]]; then
        echo "错误: 进程ID必须是数字"
        return
    fi

    if ! ps -p "$pid" >/dev/null 2>&1; then
        echo "进程ID $pid 不存在!"
        return
    fi

    read -p "确认要结束进程 $pid 吗？(y/n): " confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        kill -9 "$pid"
        echo "进程 $pid 已结束"
    else
        echo "操作已取消"
    fi
}

# endregion

#region 3) 网络管理（子模块）
# 相关函数已拆分到同目录的 network.sh。
# 缺失时仅该模块不可用，不影响其它模块。
if [ -r "$SCRIPT_DIR/network.sh" ]; then
    # shellcheck source=network.sh
    . "$SCRIPT_DIR/network.sh"
else
    NETWORK_MGMT() {
        red_echo "未找到 network.sh，网络管理不可用；请重新安装该 OS 配置"
        return 1
    }
    firewall_management() {
        red_echo "未找到 network.sh，该功能不可用；请重新安装该 OS 配置"
        return 1
    }
fi
# endregion

#region 4) 磁盘管理
DISK_MGMT() {
    while true; do
        GREEN_echo "==========磁盘管理=========="
        GREEN_echo "  1. 磁盘使用检查"
        GREEN_echo "  2. 磁盘空间清理"
        GREEN_echo "  3. 磁盘I/O性能测试"
        GREEN_echo "  4. 磁盘坏道检测"
        GREEN_echo "  5. 文件系统检查"
        GREEN_echo "  6. 挂载点管理"
        GREEN_echo "  0. 返回主菜单"
        read -p "请输入选择: " choice
        case $choice in
        1) echo "" && check_disk_usage ;;
        2) echo "" && clear_disk_space ;;
        3) echo "" && disk_io_test ;;
        4) echo "" && bad_block_check ;;
        5) echo "" && filesystem_check ;;
        6) echo "" && mount_point_manage ;;
        0) break ;;
        *) YELLOW_echo "无效选择,请重新输入" ;;
        esac
        echo
    done
}

### 1. 磁盘使用检查
check_disk_usage() {
    if [ $# -gt 0 ]; then
        # 直接调用功能模块
        _check_disk_usage "$1" # 可以没有$1
    else
        # 交互模式
        while true; do
            BLUE_echo "------------------------------------------------------"
            GREEN_echo "磁盘使用检查选项:"
            GREEN_echo "  1. 检查所有磁盘使用情况"
            GREEN_echo "  2. 扫描指定目录大小"
            GREEN_echo "  0. 返回"
            BLUE_echo "------------------------------------------------------"
            read -p "请输入选项[0-2]: " choice

            case $choice in
            1)
                _check_disk_usage
                ;;
            2)
                read -p "请输入要扫描的目录路径: " target_dir
                _check_disk_usage "$target_dir"
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

### 2. 磁盘空间清理
clear_disk_space() {
    if [ $# -gt 0 ]; then
        [ "$1" = "temp" ] && _clear_temp_files
        [ "$1" = "logs" ] && _clear_large_logs
        [ "$1" = "docker" ] && _clear_docker
        [ "$1" = "all" ] && _clear_temp_files && _clear_large_logs && _clear_docker
    else
        # 交互模式
        while true; do
            BLUE_echo "------------------------------------------------------"
            GREEN_echo "磁盘空间清理选项:"
            GREEN_echo "  1. 清理临时文件"
            GREEN_echo "  2. 清理大日志文件"
            GREEN_echo "  3. 清理Docker无用数据"
            GREEN_echo "  4. 清理所有数据"
            GREEN_echo "  0. 返回"
            BLUE_echo "------------------------------------------------------"
            read -p "请输入选项[0-4]: " choice

            case $choice in
            1) _clear_temp_files ;;
            2) _clear_large_logs ;;
            3) _clear_docker ;;
            4) _clear_temp_files && _clear_large_logs && _clear_docker ;;
            0) return ;;
            *) RED_echo "无效选项" ;;
            esac
            read -p "按任意键继续..." -n1 -s
            clear
        done
    fi
}

### 3. 磁盘I/O性能测试
disk_io_test() {
    local test_file="/tmp/io_test_$(date +%s).dat"
    if [ $# -gt 0 ]; then
        [ "$1" = "seq" ] && custom_file=${2:-$test_file} && bs=${3:-1M} && count=${4:-1024} && _test_seq_io "$custom_file" "$bs" "$count"
        [ "$1" = "iops" ] && custom_file=${2:-$test_file} && size=${3:-100M} && _test_random_iops "$custom_file" "$size"
        [ "$1" = "scheduler" ] && _show_disk_scheduler
        [ "$1" = "compare" ] && custom_file=${2:-$test_file} && _compare_block_sizes "$custom_file"
        return
    fi

    # 交互逻辑
    while true; do
        BLUE_echo "------------------------------------------------------"
        GREEN_echo "磁盘I/O性能测试选项:"
        GREEN_echo "  1. 顺序读写速度测试"
        GREEN_echo "  2. 随机IOPS测试"
        GREEN_echo "  3. 显示磁盘调度策略"
        GREEN_echo "  4. 比较不同块大小性能"
        GREEN_echo "  0. 返回"
        BLUE_echo "------------------------------------------------------"

        read -p "请输入选项[0-5]: " choice

        # 准备测试文件路径
        local test_file="/tmp/io_test_$(date +%s).dat"

        case $choice in
        1)
            read -p "请输入测试文件路径(默认: $test_file): " custom_file
            read -p "请输入块大小(默认: 1M): " bs
            read -p "请输入块数量(默认: 1024): " count
            _test_seq_io "${custom_file:-$test_file}" "${bs:-1M}" "${count:-1024}"
            ;;
        2)
            read -p "请输入测试文件路径(默认: $test_file): " custom_file
            read -p "请输入测试文件大小(默认: 100M): " size
            _test_random_iops "${custom_file:-$test_file}" "${size:-100M}"
            ;;
        3)
            _show_disk_scheduler
            ;;
        4)
            read -p "请输入测试文件路径(默认: $test_file): " custom_file
            _compare_block_sizes "${custom_file:-$test_file}"
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
}

### 4. 磁盘坏道检测
bad_block_check() {
    if [ $# -gt 0 ]; then
        [ "$1" = "scan" ] && device="${2:-"/dev/sda1"}" && mode="${3:-readonly}" && _badblocks_scan "$device" "$mode"
        [ "$1" = "smart" ] && device="${2:-"/dev/sda1"}" && _smart_check "$device"
        [ "$1" = "report" ] && device="${2:-"/dev/sda1"}" && _generate_badblock_report "$device"
    else
        # 主交互逻辑
        while true; do
            BLUE_echo "------------------------------------------------------"
            GREEN_echo "磁盘坏道检测选项:"
            GREEN_echo "  1. 坏道扫描(非破坏性)"
            GREEN_echo "  2. 查看SMART健康状态"
            GREEN_echo "  3. 生成检测报告"
            GREEN_echo "  0. 返回"
            BLUE_echo "------------------------------------------------------"
            read -p "请输入选项[0-3]: " choice
            case $choice in
            1)
                sudo fdisk -l
                read -p "请输入磁盘设备(默认: /dev/sda1): " device
                _badblocks_scan "${device:-"/dev/sda1"}" "readonly"
                ;;
            2)
                sudo fdisk -l
                read -p "请输入磁盘设备(默认: /dev/sda1): " device
                _smart_check "${device:-"/dev/sda1"}"
                ;;
            3)
                sudo fdisk -l
                read -p "请输入磁盘设备(默认: /dev/sda1): " device
                _generate_badblock_report "${device:-"/dev/sda1"}"
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

### 5. 文件系统检查
filesystem_check() {
    if [ $# -gt 0 ]; then
        [ "$1" = "type" ] && target=${2:-"/dev/sda1"} && _show_filesystem_type "$target"
        [ "$1" = "inode" ] && target=${2:-"/dev/sda1"} && _check_inode_usage "$target"
        [ "$1" = "repair" ] && target=${2:-"/dev/sda1"} && _repair_filesystem "$target"
    else
        # 主交互逻辑
        while true; do
            BLUE_echo "------------------------------------------------------"
            GREEN_echo "文件系统检查工具选项:"
            GREEN_echo "  1. 显示文件系统类型和挂载选项"
            GREEN_echo "  2. 检查inode使用情况"
            GREEN_echo "  3. 修复文件系统错误"
            GREEN_echo "  0. 返回"
            BLUE_echo "------------------------------------------------------"
            read -p "请输入选项[0-3]: " choice
            case $choice in
            1)
                sudo fdisk -l
                read -p "请输入设备或挂载点(默认:/dev/sda1): " target
                _show_filesystem_type "${target:-"/dev/sda1"}"
                ;;
            2)
                sudo fdisk -l
                read -p "请输入设备或挂载点(默认:/dev/sda1): " target
                _check_inode_usage "${target:-"/dev/sda1"}"
                ;;
            3)
                sudo fdisk -l
                read -p "请输入需要修复的设备(默认:/dev/sda1): " target
                _repair_filesystem "${target:-"/dev/sda1"}"
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

### 6. 挂载点管理
mount_point_manage() {
    if [ $# -gt 0 ]; then
        [ "$1" = "show" ] && _show_mount_info
        [ "$1" = "add" ] && device=$2 && mount_point=$3 && fs_type=${4:-ext4} && options=${5:-defaults} && _add_mount_point "$device" "$mount_point" "$fs_type" "$options"
        [ "$1" = "remove" ] && mount_point=$2 && _remove_mount_point "$mount_point"
        [ "$1" = "modify" ] && mount_point=$2 && new_options=$3 && _modify_mount_options "$mount_point" "$new_options"
        [ "$1" = "persist" ] && device=$2 && mount_point=$3 && fs_type=${4:-ext4} && options=${5:-defaults} && _persist_to_fstab "$device" "$mount_point" "$fs_type" "$options"
        [ "$1" = "visualize" ] && mount_point=$2 && _visualize_usage "$mount_point"
    else
        # 主交互逻辑
        while true; do
            BLUE_echo "------------------------------------------------------"
            GREEN_echo "挂载点管理选项:"
            GREEN_echo "  1. 显示当前挂载信息"
            GREEN_echo "  2. 添加挂载点"
            GREEN_echo "  3. 删除挂载点"
            GREEN_echo "  4. 修改挂载选项"
            GREEN_echo "  5. 持久化挂载配置"
            GREEN_echo "  6. 查看挂载点空间使用"
            GREEN_echo "  0. 返回"
            BLUE_echo "------------------------------------------------------"
            read -p "请输入选项[0-6]: " choice

            case $choice in
            1)
                _show_mount_info
                ;;
            2)
                _show_mount_info
                read -p "请输入设备路径(如/dev/sdb1): " device
                read -p "请输入挂载点路径: " mount_point
                read -p "请输入文件系统类型(如ext4): " fs_type
                read -p "请输入挂载选项(默认defaults): " options
                _add_mount_point "$device" "$mount_point" "${fs_type:-ext4}" "${options:-defaults}"
                ;;
            3)
                _show_mount_info
                read -p "请输入要卸载的挂载点路径: " mount_point
                _remove_mount_point "$mount_point"
                ;;
            4)
                _show_mount_info
                read -p "请输入要修改的挂载点路径: " mount_point
                read -p "请输入新的挂载选项(如ro,rw): " new_options
                _modify_mount_options "$mount_point" "$new_options"
                ;;
            5)
                _show_mount_info
                read -p "请输入设备路径(如/dev/sdb1): " device
                read -p "请输入挂载点路径: " mount_point
                read -p "请输入文件系统类型(如ext4): " fs_type
                read -p "请输入挂载选项(默认defaults): " options
                _persist_to_fstab "$device" "$mount_point" "${fs_type:-ext4}" "${options:-defaults}"
                ;;
            6)
                _show_mount_info
                read -p "请输入要查看的挂载点路径: " mount_point
                _visualize_usage "$mount_point"
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

#region 原子操作
_check_disk_usage() {
    local target_dir="$1"

    # 显示所有磁盘分区使用情况
    BLUE_echo "------------------------------------------------------"
    GREEN_echo "磁盘分区使用情况:"
    df -h
    check_command "获取磁盘分区使用情况"

    # 显示最大目录占用情况
    BLUE_echo "------------------------------------------------------"
    GREEN_echo "根目录下各目录大小排序:"
    du -sh /* 2>/dev/null | sort -hr
    check_command "获取根目录大小排序"

    # 如果指定了目录,扫描该目录大小
    if [ -n "$target_dir" ]; then
        if [ -d "$target_dir" ]; then
            BLUE_echo "------------------------------------------------------"
            GREEN_echo "指定目录大小扫描: $target_dir"
            du -sh "$target_dir"
            check_command "扫描指定目录大小"
        else
            red_echo "错误:目录 $target_dir 不存在"
        fi
    fi
}

# 清理临时文件
_clear_temp_files() {
    local temp_dirs=("/tmp" "$HOME/.cache")
    local total_freed=0

    BLUE_echo "------------------------------------------------------"
    GREEN_echo "开始清理临时文件..."

    for dir in "${temp_dirs[@]}"; do
        if [ -d "$dir" ]; then
            local before=$(du -sh "$dir" 2>/dev/null | awk '{print $1}')
            find "$dir" -type f -atime +7 -delete 2>/dev/null
            local after=$(du -sh "$dir" 2>/dev/null | awk '{print $1}')
            green_echo "清理完成: $dir (${before} → ${after})"
            total_freed=$((total_freed + $(du -s "$dir" 2>/dev/null | awk '{print $1}')))
        else
            yellow_echo "跳过不存在的目录: $dir"
        fi
    done

    green_echo "临时文件清理完成,共释放空间: $(numfmt --to=iec $((total_freed * 1024)))"
    check_command "清理临时文件"
}

# 清理大日志文件
_clear_large_logs() {
    local log_dirs=("/var/log" "/tmp")
    local size_threshold="100M"
    local total_freed=0

    BLUE_echo "------------------------------------------------------"
    GREEN_echo "开始清理大日志文件(>${size_threshold})..."

    for dir in "${log_dirs[@]}"; do
        if [ -d "$dir" ]; then
            local files=$(find "$dir" -type f -name "*.log" -size "+${size_threshold}" 2>/dev/null)
            if [ -n "$files" ]; then
                while IFS= read -r file; do
                    local before=$(du -h "$file" | awk '{print $1}')
                    truncate -s 0 "$file"
                    local after=$(du -h "$file" | awk '{print $1}')
                    green_echo "清空日志文件: $file (${before} → ${after})"
                    total_freed=$((total_freed + $(du -s "$file" | awk '{print $1}')))
                done <<<"$files"
            else
                yellow_echo "未找到大日志文件: $dir"
            fi
        fi
    done

    green_echo "日志文件清理完成,共释放空间: $(numfmt --to=iec $((total_freed * 1024)))"
    check_command "清理大日志文件"
}

# 清理Docker无用数据
_clear_docker() {
    if ! command -v docker &>/dev/null; then
        yellow_echo "未检测到Docker,跳过清理"
        return
    fi

    BLUE_echo "------------------------------------------------------"
    GREEN_echo "开始清理Docker无用数据..."

    local before=$(docker system df | grep "Total space" | awk '{print $4}')
    docker system prune -f
    local after=$(docker system df | grep "Total space" | awk '{print $4}')

    green_echo "Docker清理完成 (${before} → ${after})"
    check_command "清理Docker数据"
}

# 子函数:测试顺序读写速度
_test_seq_io() {
    local test_file="$1"
    local bs="$2"
    local count="$3"

    blue_echo "------------------------------------------------------"
    green_echo "测试顺序读写速度 (块大小: ${bs})..."

    # 测试顺序写速度
    yellow_echo "正在测试顺序写入速度..."
    local write_speed=$(dd if=/dev/zero of="$test_file" bs="$bs" count="$count" oflag=direct 2>&1 | awk '/copied/ {print $(NF-1), $NF}')
    check_command "顺序写入测试"
    green_echo "顺序写入速度: $write_speed"

    # 测试顺序读速度
    yellow_echo "正在测试顺序读取速度..."
    local read_speed=$(dd if="$test_file" of=/dev/null bs="$bs" count="$count" iflag=direct 2>&1 | awk '/copied/ {print $(NF-1), $NF}')
    check_command "顺序读取测试"
    green_echo "顺序读取速度: $read_speed"

    # 清理测试文件
    rm -f "$test_file"
}

# 子函数:测试随机IOPS
_test_random_iops() {
    local test_file="$1"
    local size="$2"

    blue_echo "------------------------------------------------------"
    green_echo "测试随机IOPS..."

    if ! command -v fio &>/dev/null; then
        red_echo "错误:fio工具未安装"
        read -p "是否要安装fio? [y/N] " install_choice
        if [[ "$install_choice" =~ [yY] ]]; then
            apt_get install -y fio || {
                red_echo "fio安装失败"
                return 1
            }
        else
            return 1
        fi
    fi

    yellow_echo "正在运行fio测试..."
    fio --name=random_iops_test \
        --filename="$test_file" \
        --size="$size" \
        --runtime=60s \
        --ioengine=libaio \
        --direct=1 \
        --randrepeat=0 \
        --rw=randrw \
        --rwmixread=70 \
        --bs=4k \
        --iodepth=64 \
        --numjobs=1 \
        --group_reporting \
        --output-format=json >/tmp/fio_result.json

    if [ $? -ne 0 ]; then
        red_echo "fio测试失败"
        return 1
    fi

    local read_iops=$(jq -r '.jobs[0].read.iops' /tmp/fio_result.json)
    local write_iops=$(jq -r '.jobs[0].write.iops' /tmp/fio_result.json)

    # 格式化IOPS数值
    _format_iops() {
        local iops=$(echo "$1" | awk -F '.' '{print $1}') # 取整数部分

        if (($iops >= 1000000)); then
            printf "%.2f M" $(echo "$iops/1000000" | bc -l)
        elif (($iops >= 1000)); then
            printf "%.2f K" $(echo "$iops/1000" | bc -l)
        else
            echo "$iops"
        fi
    }

    green_echo "随机读取IOPS: $(_format_iops $read_iops) IOPS"
    green_echo "随机写入IOPS: $(_format_iops $write_iops) IOPS"

    rm -f "$test_file" /tmp/fio_result.json
}

# 子函数:显示磁盘调度策略
_show_disk_scheduler() {
    blue_echo "------------------------------------------------------"
    green_echo "当前磁盘调度策略:"

    local disks=$(lsblk -d -o NAME | grep -v NAME)
    for disk in $disks; do
        local scheduler_file="/sys/block/$disk/queue/scheduler"
        if [ -f "$scheduler_file" ]; then
            local current_scheduler=$(grep -o '\[.*\]' "$scheduler_file" | tr -d '[]')
            yellow_echo "磁盘 $disk: $current_scheduler"
        fi
    done
}

# 子函数:比较不同块大小的性能
_compare_block_sizes() {
    local test_file="$1"
    local sizes=("512" "1K" "4K" "8K" "16K" "64K" "1M")

    blue_echo "------------------------------------------------------"
    green_echo "比较不同块大小的性能..."

    for bs in "${sizes[@]}"; do
        _test_seq_io "$test_file" "$bs" "1024"
    done
}

### 子函数:执行坏道扫描
_badblocks_scan() {
    local device="$1"
    local mode="$2"

    BLUE_echo "------------------------------------------------------"
    YELLOW_echo "警告:坏道扫描可能需要较长时间,请耐心等待..."
    BLUE_echo "------------------------------------------------------"

    if [ "$mode" = "destructive" ]; then
        RED_echo "高危操作警告:此模式会破坏磁盘数据！"
        read -p "确认继续？(y/n): " confirm
        [ "$confirm" != "y" ] && return
    fi

    local options="-v"
    [ "$mode" = "readonly" ] && options="$options -n"

    blue_echo "开始扫描磁盘 $device (模式: $mode)..."
    badblocks $options "$device"
    check_command "坏道扫描"
}

### 子函数:检查SMART状态
_smart_check() {
    local device="$1"

    if ! command -v smartctl &>/dev/null; then
        red_echo "错误:smartctl工具未安装, 请先安装smartmontools"
        apt_get install -y smartmontools
    fi

    blue_echo "获取 $device 的SMART健康状态..."
    smartctl -H "$device"
    check_command "SMART健康检查"

    blue_echo "显示 $device 的SMART详细信息..."
    smartctl -a "$device"
}

### 子函数:生成坏道检测报告
_generate_badblock_report() {
    local device="$1"
    local report_file="badblock_report_$(date +%Y%m%d_%H%M%S).log"

    BLUE_echo "------------------------------------------------------"
    blue_echo "正在生成磁盘检测报告: $report_file"
    BLUE_echo "------------------------------------------------------"

    {
        echo "===== 磁盘坏道检测报告 ====="
        echo "生成时间: $(date "+%Y-%m-%d %H:%M:%S")"
        echo "检测设备: $device"
        echo ""

        echo "----- SMART健康状态 -----"
        smartctl -H "$device" | tee -a "$report_file"
        echo ""

        echo "----- 坏道扫描结果 -----"
        badblocks -v -n "$device" | tee -a "$report_file"
    } >"$report_file"

    green_echo "报告已生成: $report_file"
}

_show_filesystem_type() {
    local target=${1:-"/dev/sda1"}
    blue_echo "正在检查文件系统类型和挂载选项..."

    if [ -b "$target" ] || [ -d "$target" ]; then
        # 显示文件系统类型
        local fstype=$(lsblk -no FSTYPE "$target" 2>/dev/null || df -T "$target" | awk 'NR==2 {print $2}')
        if [ -n "$fstype" ]; then
            green_echo "文件系统类型: $fstype"
        else
            red_echo "无法确定文件系统类型"
        fi

        # 显示挂载选项
        local mount_options=$(grep "$target" /proc/mounts | awk '{print $4}')
        if [ -n "$mount_options" ]; then
            green_echo "挂载选项: $mount_options"
        else
            red_echo "目标未挂载或无法获取挂载选项"
        fi
    else
        red_echo "错误: 目标不是块设备或目录"
    fi
}

_check_inode_usage() {
    local target=$1
    blue_echo "正在检查inode使用情况..."

    if [ -b "$target" ] || [ -d "$target" ]; then
        df -i "$target" | while read -r line; do
            yellow_echo "$line"
        done
    else
        red_echo "错误: 目标不是块设备或目录"
    fi
}

_repair_filesystem() {
    local device=$1
    blue_echo "准备修复文件系统..."

    if [ ! -b "$device" ]; then
        red_echo "错误: $device 不是块设备"
        return 1
    fi

    # 检查是否已挂载
    if mount | grep -q "$device"; then
        RED_echo "警告: 设备 $device 已挂载,修复需要卸载!"
        read -p "是否继续卸载并修复? (y/n): " confirm
        if [ "$confirm" = "y" ]; then
            umount "$device" || {
                red_echo "卸载失败,无法继续修复"
                return 1
            }
            green_echo "设备已成功卸载"
        else
            yellow_echo "已取消修复操作"
            return
        fi
    fi

    # 执行文件系统检查
    yellow_echo "开始执行文件系统检查(可能需要较长时间)..."
    fsck -y "$device"
    check_command "文件系统修复"
}

# 显示当前挂载点信息
_show_mount_info() {
    BLUE_echo "------------------------------------------------------"
    GREEN_echo "当前挂载点信息:"
    df -hT | WHITE_echo
    BLUE_echo "------------------------------------------------------"
    mount | WHITE_echo
}

# 添加挂载点
_add_mount_point() {
    local device=$1
    local mount_point=$2
    local fs_type=$3
    local options=$4

    [ ! -d "$mount_point" ] && mkdir -p "$mount_point"
    mount -t "$fs_type" -o "$options" "$device" "$mount_point"
    check_command "挂载设备 $device 到 $mount_point"
}

# 删除挂载点
_remove_mount_point() {
    local mount_point=$1
    umount "$mount_point"
    check_command "卸载挂载点 $mount_point"
}

# 修改挂载选项
_modify_mount_options() {
    local mount_point=$1
    local new_options=$2
    mount -o remount,"$new_options" "$mount_point"
    check_command "修改挂载点 $mount_point 的选项为 $new_options"
}

# 持久化修改到/etc/fstab
_persist_to_fstab() {
    local device=$1
    local mount_point=$2
    local fs_type=$3
    local options=$4

    local fstab_entry="$device $mount_point $fs_type $options 0 0"
    echo "$fstab_entry" | tee -a /etc/fstab >/dev/null
    check_command "将挂载配置持久化到 /etc/fstab"
}

# 挂载点空间使用可视化
_visualize_usage() {
    local mount_point=$1
    BLUE_echo "------------------------------------------------------"
    GREEN_echo "挂载点 $mount_point 空间使用情况:"
    df -h "$mount_point" | WHITE_echo
    BLUE_echo "------------------------------------------------------"
    du -sh "$mount_point"/* 2>/dev/null | WHITE_echo || WHITE_echo "无法显示目录内容"
}
#endregion
# endregion

#region 5) 监控管理
MONITORING_MGMT() {
    while true; do
        GREEN_echo "==========监控管理=========="
        GREEN_echo "  1. 系统信息展示"
        GREEN_echo "  2. 系统监控"
        GREEN_echo "  3. 服务监控"
        GREEN_echo "  4. 日志监控"
        GREEN_echo "  5. 告警配置"
        GREEN_echo "  0. 返回主菜单"
        read -p "请输入选择: " choice
        case $choice in
        1) echo "" && _show_system_info ;;
        2) echo "" && system_monitoring ;;
        3) echo "" && service_monitoring ;;
        4) echo "" && log_monitoring ;;
        5) echo "" && alert_configuration ;;
        0) break ;;
        *) YELLOW_echo "无效选择,请重新输入" ;;
        esac
        echo
    done
}

# 1. 系统监控
system_monitoring() {
    #sudo bash mgt-god.sh system_monitoring cpu 5 true
    if [ $# -gt 0 ]; then
        [ "$1" = "cpu" ] && interval=${2:-5} && local detailed=${3:-false} && _cpu_monitor "$interval" "$detailed"
        [ "$1" = "memory" ] && interval=${2:-5} && _memory_monitor "$interval"
        [ "$1" = "disk" ] && interval=${2:-5} && _disk_monitor "$interval"
        [ "$1" = "load" ] && _load_monitor
        [ "$1" = "temp" ] && _temp_monitor
        [ "$1" = "all" ] && interval=${2:-5} && _os_unified_monitor "$interval"

    else
        # 主交互逻辑
        while true; do
            BLUE_echo "------------------------------------------------------"
            GREEN_echo "系统监控选项:"
            GREEN_echo "  1. CPU使用率监控"
            GREEN_echo "  2. 内存使用监控"
            GREEN_echo "  3. 磁盘I/O监控"
            GREEN_echo "  4. 系统负载监控"
            GREEN_echo "  5. 温度监控"
            GREEN_echo "  6. 操作系统统一监控"
            GREEN_echo "  0. 返回"
            BLUE_echo "------------------------------------------------------"
            read -p "请输入选项[0-6]: " choice
            case $choice in
            1)
                read -p "请输入监控间隔(秒,默认5): " interval
                _cpu_monitor "${interval:-5}"
                ;;
            2)
                read -p "请输入监控间隔(秒,默认5): " interval
                _memory_monitor "${interval:-5}"
                ;;
            3)
                read -p "请输入监控间隔(秒,默认5): " interval
                _disk_monitor "${interval:-5}"
                ;;
            4)
                _load_monitor
                ;;
            5)
                _temp_monitor
                ;;
            6)
                read -p "请输入监控间隔(秒,默认5): " interval
                _os_unified_monitor "${interval:-5}"
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

# 服务监控主函数
service_monitoring() {
    if [ $# -gt 0 ]; then
        # 直接执行模式
        [ "$1" = "status" ] && service_name=$2 && _check_service_status "$service_name"
        [ "$1" = "response" ] && service_name=$2 && endpoint=${3:-"/"} && _test_service_response "$service_name" "$endpoint"
        [ "$1" = "resources" ] && service_name=$2 && interval=${3:-5} && _analyze_service_resources "$service_name" "$interval"
        [ "$1" = "dependencies" ] && service_name=$2 && _check_service_dependencies "$service_name"
    else
        # 交互模式
        while true; do
            BLUE_echo "------------------------------------------------------"
            GREEN_echo "服务监控工具选项:"
            GREEN_echo "  1. 服务状态检查"
            GREEN_echo "  2. 服务响应测试(web类)"
            GREEN_echo "  3. 资源占用分析"
            GREEN_echo "  4. 依赖关系检查"
            GREEN_echo "  0. 返回"
            BLUE_echo "------------------------------------------------------"
            read -p "请输入选项[0-5]: " choice

            case $choice in
            1)
                read -p "请输入服务名称: " service_name
                _check_service_status "$service_name"
                ;;
            2)
                read -p "请输入服务名称: " service_name
                read -p "请输入测试端点(默认/): " endpoint
                _test_service_response "$service_name" "${endpoint:-/}"
                ;;
            3)
                read -p "请输入服务名称: " service_name
                read -p "请输入监控间隔(秒,默认5): " interval
                _analyze_service_resources "$service_name" "${interval:-5}"
                ;;
            4)
                read -p "请输入服务名称: " service_name
                _check_service_dependencies "$service_name"
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

# 3. 日志监控
log_monitoring() {
    # 功能点:
    # - 关键日志实时监控(tail -f)
    # - 日志关键词告警
    # - 日志轮转检查
    # - 日志分析报表
    # - 自定义日志路径配置
    :
}

# 4. 告警配置
alert_configuration() {
    # 功能点:
    # - 阈值配置(CPU/内存/磁盘)
    # - 通知方式配置(邮件/短信)
    # - 告警规则管理
    # - 告警历史记录
    # - 告警测试功能
    :
}

#原子操作
# CPU监控子函数
_cpu_monitor() {
    local interval=${1:-5}     # 默认5秒刷新
    local detailed=${2:-false} #true

    blue_echo "开始CPU监控,刷新间隔: ${interval}秒"
    [ "$detailed" = true ] && yellow_echo "详细模式已启用"

    while true; do
        clear
        # 头部信息
        BLUE_echo "------------------------------------------------------"
        WHITE_echo " CPU使用率监控 (按Ctrl+C退出) "
        BLUE_echo "------------------------------------------------------"

        # 获取top命令输出
        local top_output=$(top -b -n 1)

        # 1. 系统摘要信息
        GREEN_echo "[系统摘要]"
        echo "$top_output" | head -n 5
        echo

        # 2. CPU使用详情
        GREEN_echo "[CPU核心使用率]"
        if $detailed; then
            # 详细模式显示所有CPU核心
            echo "$top_output" | grep -A 10 "%Cpu"
        else
            # 精简模式只显示汇总
            echo "$top_output" | grep -m 1 "%Cpu"
        fi
        echo

        # 3. 内存使用情况
        GREEN_echo "[内存状态]"
        echo "$top_output" | grep -A 2 "KiB Mem"
        echo

        # 4. 进程列表 (前10个)
        GREEN_echo "[高CPU进程]"
        echo "$top_output" | grep -A 11 "PID USER" | head -n 10
        echo

        # 5. 详细模式额外信息
        if $detailed; then
            GREEN_echo "[额外统计]"
            # 显示负载均衡信息
            echo "CPU负载均衡:"
            mpstat -P ALL 1 1 | grep -v "Average"
            echo

            # 显示中断统计
            echo "CPU中断统计:"
            cat /proc/interrupts | head -n 5
            echo
        fi

        # 底部状态栏
        BLUE_echo "------------------------------------------------------"
        WHITE_echo " 刷新间隔: ${interval}s | 模式: $([ "$detailed" = true ] && echo "详细" || echo "标准") "
        BLUE_echo "------------------------------------------------------"

        sleep "$interval"
    done
}

# 内存监控子函数
_memory_monitor() {
    local interval=$1
    blue_echo "开始内存监控,间隔${interval}秒..."
    while true; do
        clear
        BLUE_echo "------------------------------------------------------"
        WHITE_echo "内存使用监控 (按Ctrl+C退出)"
        BLUE_echo "------------------------------------------------------"
        free -h
        echo
        vmstat -S M 1 5
        sleep "$interval"
    done
}

_show_system_info() {
    BLUE_echo "------------------------------------------------------"
    GREEN_echo "===== 系统基础信息 ====="
    lsb_release -a 2>/dev/null | grep -E "Description|Codename"
    uname -a

    GREEN_echo "===== 硬件信息 ====="
    lscpu | grep -E "Model name|Socket|Core|Thread"
    free -h
    df -h | grep -v "tmpfs"

    GREEN_echo "===== 网络信息 ====="
    ip a | grep -E "inet |ether"
    netstat -tulnp

    GREEN_echo "===== 用户信息 ====="
    who -u
    grep -E "sudo|admin" /etc/group

    GREEN_echo "===== 服务状态 ====="
    systemctl list-units --type=service --state=running | head -10

    GREEN_echo "===== 安全信息 ====="
    sudo fail2ban-client status 2>/dev/null || echo "Fail2ban not installed"
    sudo ufw status verbose

    GREEN_echo "===== 最近登录 ====="
    last -n 5

    GREEN_echo "===== 进程占用TOP5 ====="
    ps -eo pid,user,%cpu,%mem,cmd --sort=-%cpu | head -6
    BLUE_echo "------------------------------------------------------"
}

# 磁盘监控子函数
_disk_monitor() {
    local interval=$1
    blue_echo "开始磁盘I/O监控,间隔${interval}秒..."
    while true; do
        clear
        BLUE_echo "------------------------------------------------------"
        WHITE_echo "磁盘I/O监控 (按Ctrl+C退出)"
        BLUE_echo "------------------------------------------------------"
        df -h
        echo
        iostat -dxm "$interval" 2
        sleep "$interval"
    done
}

# 系统负载监控子函数
_load_monitor() {
    blue_echo "开始系统负载监控..."
    clear
    BLUE_echo "------------------------------------------------------"
    WHITE_echo "系统负载监控"
    BLUE_echo "------------------------------------------------------"
    uptime
    echo
    cat /proc/loadavg
}

# 温度监控子函数
_temp_monitor() {
    blue_echo "开始温度监控..."
    clear
    BLUE_echo "------------------------------------------------------"
    WHITE_echo "系统温度监控"
    BLUE_echo "------------------------------------------------------"
    if command -v sensors &>/dev/null; then
        sensors
    else
        yellow_echo "正在安装 lm-sensors 软件包"
        apt_get install -y lm-sensors
        sudo sensors-detect --auto
    fi
}

# 综合监控子函数 (优化版)
_os_unified_monitor() {
    local interval=${1:-5} # 默认监控间隔5秒

    # 验证监控间隔是否为数字
    if ! [[ "$interval" =~ ^[0-9]+$ ]]; then
        RED_echo "错误: 监控间隔必须是正整数"
        return 1
    fi

    # 主监控循环
    while true; do
        # 只在第一次循环时显示头部信息
        clear
        BLUE_echo "------------------------------------------------------"
        WHITE_echo "综合系统监控 (按Ctrl+C退出)"
        BLUE_echo "------------------------------------------------------"

        GREEN_echo "1. [CPU使用率监控]"
        top -b -n 1 | grep -A 15 "PID USER"
        echo

        GREEN_echo "2. [内存使用监控]"
        free -h
        GREEN_echo "内存详细状态:"
        vmstat -S M 1 1 | tail -n 1
        echo

        GREEN_echo "3. [磁盘I/O监控]"
        echo "磁盘空间:"
        df -h | grep -v tmpfs
        GREEN_echo "I/O统计:"
        iostat -dxm 1 1 | tail -n +4
        echo

        GREEN_echo "4. [系统负载监控]"
        uptime
        GREEN_echo "详细负载:"
        cat /proc/loadavg
        echo

        GREEN_echo "5. [温度监控]"
        if command -v sensors &>/dev/null; then
            sensors | grep -E "Core|Package"
        else
            yellow_echo "警告: sensors命令不可用"
            apt_get install -y lm-sensors
            sudo sensors-detect --auto
        fi
        echo

        BLUE_echo "刷新间隔: ${interval}s"
        sleep "$interval"
    done
}

# 检查服务状态
_check_service_status() {
    local service_name=$1
    blue_echo "------------------------------------------------------"
    blue_echo "正在检查服务状态: $service_name"

    systemctl is-active "$service_name" >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        green_echo "服务状态: 运行中"
        systemctl status "$service_name" | grep -A 5 "Active:"
    else
        red_echo "服务状态: 未运行"
    fi

    # 检查是否启用开机启动
    systemctl is-enabled "$service_name" >/dev/null 2>&1
    [ $? -eq 0 ] && green_echo "开机启动: 已启用" || yellow_echo "开机启动: 未启用"
    blue_echo "------------------------------------------------------"
}

# 测试服务响应
_test_service_response() {
    local service_name=$1
    local endpoint=$2
    BLUE_echo "------------------------------------------------------"

    blue_echo "测试服务响应: $service_name 端点: $endpoint"

    # 获取服务监听的端口
    local port=$(ss -tulnp | grep "$service_name" | awk '{print $5}' | cut -d':' -f2 | head -n1)

    if [ -z "$port" ]; then
        red_echo "无法确定服务端口"
        return 1
    fi

    green_echo "服务端口: $port"

    # 使用curl测试响应
    if command -v curl &>/dev/null; then
        local start_time=$(date +%s%N)
        curl -s -o /dev/null "http://localhost:$port$endpoint"
        local end_time=$(date +%s%N)
        local response_time=$(((end_time - start_time) / 1000000))
        green_echo "响应时间: ${response_time}ms"
    else
        yellow_echo "未找到curl无法测试响应时间"
    fi
    BLUE_echo "------------------------------------------------------"

}

# 分析服务资源占用
_analyze_service_resources() {
    local service_name=$1
    local interval=$2

    blue_echo "开始监控服务资源占用: $service_name 间隔: ${interval}秒"
    BLUE_echo "------------------------------------------------------"
    WHITE_echo " 按Ctrl+C停止监控 "
    BLUE_echo "------------------------------------------------------"

    while true; do
        clear
        local pid=$(systemctl show --property MainPID "$service_name" | cut -d'=' -f2)

        if [ "$pid" -eq 0 ]; then
            red_echo "服务未运行"
            return 1
        fi

        GREEN_echo "[CPU和内存使用]"
        ps -p "$pid" -o %cpu,%mem,cmd

        GREEN_echo "[线程数]"
        ps -T -p "$pid" | wc -l | awk '{print "线程数: "$1-1}'

        GREEN_echo "[打开文件数]"
        lsof -p "$pid" | wc -l | awk '{print "打开文件数: "$1}'

        BLUE_echo "------------------------------------------------------"
        WHITE_echo " 刷新间隔: ${interval}s | 服务: $service_name "
        BLUE_echo "------------------------------------------------------"

        sleep "$interval"
    done
}

# 检查服务依赖关系
_check_service_dependencies() {
    local service_name=$1

    BLUE_echo "------------------------------------------------------"
    blue_echo "检查服务依赖关系: $service_name"

    GREEN_echo "[必需依赖]"
    systemctl list-dependencies "$service_name" --plain | grep -v "$service_name"

    GREEN_echo "[反向依赖]"
    systemctl list-dependencies --reverse "$service_name" --plain | grep -v "$service_name"
    BLUE_echo "------------------------------------------------------"
}
# endregion

#region 6) 服务管理（子模块）
# 相关函数已拆分到同目录的 service.sh。
# 缺失时仅该模块不可用，不影响其它模块。
if [ -r "$SCRIPT_DIR/service.sh" ]; then
    # shellcheck source=service.sh
    . "$SCRIPT_DIR/service.sh"
else
    SERVICE_MGMT() {
        red_echo "未找到 service.sh，服务管理不可用；请重新安装该 OS 配置"
        return 1
    }
fi
# endregion

#region 7) 软件包管理
PACKAGE_MGMT() {
    while true; do
        GREEN_echo "==========软件包管理=========="
        GREEN_echo "  1. 显示已安装软件包"
        GREEN_echo "  2. 安装/卸载软件包"
        GREEN_echo "  3. 软件包搜索"
        GREEN_echo "  4. 软件包更新"
        GREEN_echo "  5. 软件仓库管理"
        GREEN_echo "  6. 软件包依赖分析"
        GREEN_echo "  7. 软件包缓存清理"
        GREEN_echo "  0. 返回主菜单"
        read -p "请输入选择: " choice
        case $choice in
        1) echo "" && display_installed_packages ;;
        2) echo "" && manage_package ;;
        3) echo "" && search_package ;;
        4) echo "" && update_packages ;;
        5) echo "" && manage_repositories ;;
        6) echo "" && analyze_package_dependencies ;;
        7) echo "" && clean_package_cache ;;
        0) break ;;
        *) YELLOW_echo "无效选择,请重新输入" ;;
        esac
        echo
    done
}

# 1. 显示已安装软件包
display_installed_packages() {
    if [ $# -gt 0 ]; then
        [ "$1" = "list" ] && _list_packages
        [ "$1" = "filter" ] && _list_packages "$2"
        [ "$1" = "export" ] && _list_packages "$2" "$3"
    else
        BLUE_echo "------------------------------------------------------"
        GREEN_echo "已安装软件包管理选项:"
        GREEN_echo "  1. 列出所有软件包"
        GREEN_echo "  2. 按名称过滤"
        GREEN_echo "  3. 导出列表到文件"
        GREEN_echo "  0. 返回"
        BLUE_echo "------------------------------------------------------"

        read -p "请输入选项[0-3]: " choice
        case $choice in
        1) _list_packages ;;
        2)
            read -p "请输入过滤关键词: " filter
            _list_packages "$filter"
            ;;
        3)
            read -p "请输入导出文件名: " filename
            _list_packages "" "$filename"
            ;;
        0) return ;;
        *) RED_echo "无效选项" ;;
        esac
    fi
}

# 2. 安装/卸载软件包
manage_package() {
    if [ $# -gt 0 ]; then
        [ "$1" = "install" ] && _install_pkg "$2"
        [ "$1" = "remove" ] && _remove_pkg "$2"
    else
        BLUE_echo "------------------------------------------------------"
        GREEN_echo "软件包管理选项:"
        GREEN_echo "  1. 安装软件包"
        GREEN_echo "  2. 卸载软件包"
        GREEN_echo "  0. 返回"
        BLUE_echo "------------------------------------------------------"

        read -p "请输入选项[0-2]: " choice
        case $choice in
        1)
            read -p "请输入要安装的软件包名: " pkg
            _install_pkg "$pkg"
            ;;
        2)
            read -p "请输入要卸载的软件包名: " pkg
            _remove_pkg "$pkg"
            ;;
        0) return ;;
        *) RED_echo "无效选项" ;;
        esac
    fi
}

# 3. 软件包搜索
search_package() {
    if [ $# -gt 0 ]; then
        [ "$1" = "search" ] && _search_pkg "$2"
        [ "$1" = "export" ] && _search_pkg "$2" "$3"
    else
        BLUE_echo "------------------------------------------------------"
        GREEN_echo "软件包搜索选项:"
        GREEN_echo "  1. 搜索软件包"
        GREEN_echo "  2. 保存搜索结果"
        GREEN_echo "  0. 返回"
        BLUE_echo "------------------------------------------------------"

        read -p "请输入选项[0-2]: " choice
        case $choice in
        1)
            read -p "请输入搜索关键词: " keyword
            _search_pkg "$keyword"
            ;;
        2)
            read -p "请输入搜索关键词: " keyword
            read -p "请输入保存文件名: " filename
            _search_pkg "$keyword" "$filename"
            ;;
        0) return ;;
        *) RED_echo "无效选项" ;;
        esac
    fi
}

# 4. 软件包更新管理
update_packages() {
    if [ $# -gt 0 ]; then
        [ "$1" = "check" ] && _check_updates
        [ "$1" = "security" ] && _security_updates
        [ "$1" = "update" ] && _perform_update "$2"
        [ "$1" = "log" ] && _view_update_log
    else
        while true; do
            BLUE_echo "------------------------------------------------------"
            GREEN_echo "软件包更新管理选项:"
            GREEN_echo "  1. 检查可用更新"
            GREEN_echo "  2. 筛选安全更新"
            GREEN_echo "  3. 执行更新(single/all)"
            GREEN_echo "  4. 查看更新日志"
            GREEN_echo "  0. 返回"
            BLUE_echo "------------------------------------------------------"
            read -p "请输入选项[0-4]: " choice
            case $choice in
            1) _check_updates ;;
            2) _security_updates ;;
            3)
                read -p "请输入要更新的软件包(留空更新全部): " packages
                _perform_update "$packages"
                ;;
            4) _view_update_log ;;
            0) return ;;
            *) RED_echo "无效选项" ;;
            esac
            read -p "按任意键继续..." -n1 -s
            clear
        done
    fi
}

# 5. 软件仓库管理
manage_repositories() {
    if [ $# -gt 0 ]; then
        [ "$1" = "list" ] && _list_repos
        [ "$1" = "add" ] && _add_repo "$2" "$3" "$4"
        [ "$1" = "remove" ] && _remove_repo "$2"
        [ "$1" = "gpg" ] && _manage_gpg_keys
    else
        while true; do
            BLUE_echo "------------------------------------------------------"
            GREEN_echo "软件仓库管理选项:"
            GREEN_echo "  1. 列出当前仓库"
            GREEN_echo "  2. 添加仓库"
            GREEN_echo "  3. 删除仓库"
            GREEN_echo "  4. GPG密钥管理"
            GREEN_echo "  0. 返回"
            BLUE_echo "------------------------------------------------------"
            read -p "请输入选项[0-4]: " choice
            case $choice in
            1) _list_repos ;;
            2)
                read -p "请输入仓库URL: " repo_url
                read -p "请输入仓库名称: " repo_name
                read -p "请输入GPG密钥(可选): " gpg_key
                _add_repo "$repo_url" "$repo_name" "$gpg_key"
                ;;
            3)
                read -p "请输入要删除的仓库名称: " repo_name
                _remove_repo "$repo_name"
                ;;
            4) _manage_gpg_keys ;;
            0) return ;;
            *) RED_echo "无效选项" ;;
            esac
            read -p "按任意键继续..." -n1 -s
            clear
        done
    fi
}

# 6. 软件包依赖分析
analyze_package_dependencies() {
    if [ $# -gt 0 ]; then
        [ "$1" = "tree" ] && _show_dep_tree "$2"
        [ "$1" = "reverse" ] && _reverse_deps "$2"
        [ "$1" = "conflict" ] && _check_conflicts "$2"
    else
        while true; do
            BLUE_echo "------------------------------------------------------"
            GREEN_echo "软件包依赖分析选项:"
            GREEN_echo "  1. 显示依赖树"
            GREEN_echo "  2. 反向依赖查询"
            GREEN_echo "  3. 冲突检测"
            GREEN_echo "  0. 返回"
            BLUE_echo "------------------------------------------------------"
            read -p "请输入选项[0-3]: " choice
            case $choice in
            1)
                read -p "请输入软件包名称: " package
                _show_dep_tree "$package"
                ;;
            2)
                read -p "请输入软件包名称: " package
                _reverse_deps "$package"
                ;;
            3)
                read -p "请输入软件包名称: " package
                _check_conflicts "$package"
                ;;
            0) return ;;
            *) RED_echo "无效选项" ;;
            esac
            read -p "按任意键继续..." -n1 -s
            clear
        done
    fi
}

# 7. 软件包缓存清理
clean_package_cache() {
    if [ $# -gt 0 ]; then
        [ "$1" = "cache" ] && _clean_download_cache
        [ "$1" = "old" ] && _remove_old_kernels
        [ "$1" = "orphans" ] && _remove_orphans
        [ "$1" = "space" ] && _show_disk_usage
    else
        while true; do
            BLUE_echo "------------------------------------------------------"
            GREEN_echo "软件包缓存清理选项:"
            GREEN_echo "  1. 清理下载缓存"
            GREEN_echo "  2. 删除旧内核"
            GREEN_echo "  3. 清理孤立依赖"
            GREEN_echo "  4. 空间占用统计"
            GREEN_echo "  0. 返回"
            BLUE_echo "------------------------------------------------------"
            read -p "请输入选项[0-4]: " choice
            case $choice in
            1) _clean_download_cache ;;
            2) _remove_old_kernels ;;
            3) _remove_orphans ;;
            4) _show_disk_usage ;;
            0) return ;;
            *) RED_echo "无效选项" ;;
            esac
            read -p "按任意键继续..." -n1 -s
            clear
        done
    fi
}

_check_updates() {
    blue_echo "---------------检查可用更新---------------"
    if command -v apt-get &>/dev/null; then
        apt_get update && apt_get list --upgradable
    elif command -v yum &>/dev/null; then
        yum check-update
    elif command -v dnf &>/dev/null; then
        dnf check-update
    elif command -v zypper &>/dev/null; then
        zypper list-updates
    else
        red_echo "未找到支持的包管理器"
        return 1
    fi
    check_command "检查可用更新"
}

_security_updates() {
    blue_echo "---------------安全更新筛选---------------"
    if command -v apt-get &>/dev/null; then
        apt_get list --upgradable | grep -i security
    elif command -v yum &>/dev/null; then
        yum updateinfo list security
    else
        yellow_echo "当前系统不支持自动筛选安全更新"
    fi
}

_perform_update() {
    local packages=$1
    blue_echo "---------------执行更新---------------"
    if [ -z "$packages" ]; then
        if command -v apt-get &>/dev/null; then
            apt_get upgrade -y
        elif command -v yum &>/dev/null; then
            yum update -y
        elif command -v dnf &>/dev/null; then
            dnf upgrade -y
        elif command -v zypper &>/dev/null; then
            zypper update -y
        fi
    else
        if command -v apt-get &>/dev/null; then
            apt_get install -y $packages
        elif command -v yum &>/dev/null; then
            yum update -y $packages
        elif command -v dnf &>/dev/null; then
            dnf upgrade -y $packages
        elif command -v zypper &>/dev/null; then
            zypper update -y $packages
        fi
    fi
    check_command "软件包更新"
}

_view_update_log() {
    blue_echo "---------------更新日志查看---------------"
    if command -v apt-get &>/dev/null; then
        cat /var/log/apt/history.log | tail -n 20
    elif command -v yum &>/dev/null; then
        cat /var/log/yum.log | tail -n 20
    else
        yellow_echo "当前系统不支持自动查看更新日志"
    fi
}

_list_repos() {
    blue_echo "---------------当前软件仓库---------------"
    if command -v apt-get &>/dev/null; then
        grep -r "^deb " /etc/apt/sources.list /etc/apt/sources.list.d/
    elif command -v yum &>/dev/null; then
        yum repolist all
    elif command -v dnf &>/dev/null; then
        dnf repolist all
    elif command -v zypper &>/dev/null; then
        zypper repos
    else
        red_echo "未找到支持的包管理器"
        return 1
    fi
}

_add_repo() {
    local repo_url=$1
    local repo_name=$2
    local gpg_key=$3

    blue_echo "---------------添加软件仓库---------------"

    if command -v apt-get &>/dev/null; then
        green_echo "准备添加 ${repo_name} 的 apt 仓库..."

        # Add GPG key using recommended method
        if [ -n "$gpg_key" ]; then
            curl -fsSL "$gpg_key" | sudo gpg --dearmor -o "/etc/apt/trusted.gpg.d/${repo_name}.gpg"
            check_command "添加 ${repo_name} GPG 密钥"
        fi

        # Add repository file
        cat <<EOF | sudo tee "/etc/apt/sources.list.d/${repo_name}.list"
deb [arch=amd64] $repo_url
EOF
        check_command "添加 ${repo_name} 仓库"

        # Update package lists
        apt_get update
        check_command "更新软件包列表"

    elif command -v yum &>/dev/null; then
        green_echo "准备添加 ${repo_name} 的 yum 仓库..."
        sudo yum-config-manager --add-repo "$repo_url"
        check_command "添加 ${repo_name} 仓库"

    elif command -v dnf &>/dev/null; then
        green_echo "准备添加 ${repo_name} 的 dnf 仓库..."
        sudo dnf config-manager --add-repo "$repo_url"
        check_command "添加 ${repo_name} 仓库"

    elif command -v zypper &>/dev/null; then
        green_echo "准备添加 ${repo_name} 的 zypper 仓库..."
        sudo zypper addrepo "$repo_url" "$repo_name"
        check_command "添加 ${repo_name} 仓库"
    fi
}

_remove_repo() {
    local repo_name=$1
    blue_echo "---------------删除软件仓库---------------"
    if command -v apt-get &>/dev/null; then
        rm -f "/etc/apt/sources.list.d/${repo_name}.list"
        apt_get update
    elif command -v yum &>/dev/null; then
        yum-config-manager --disable $repo_name
        rm -f "/etc/yum.repos.d/${repo_name}.repo"
    elif command -v dnf &>/dev/null; then
        dnf config-manager --disable $repo_name
        rm -f "/etc/yum.repos.d/${repo_name}.repo"
    elif command -v zypper &>/dev/null; then
        zypper removerepo $repo_name
    fi
    check_command "删除软件仓库"
}

_manage_gpg_keys() {
    blue_echo "---------------GPG密钥管理---------------"
    if command -v apt-get &>/dev/null; then
        apt-key list
    elif command -v rpm &>/dev/null; then
        rpm -qa gpg-pubkey*
    else
        yellow_echo "当前系统不支持自动管理GPG密钥"
    fi
}

_show_dep_tree() {
    local package=$1
    blue_echo "---------------依赖树分析---------------"
    if command -v apt-rdepends &>/dev/null; then
        apt-rdepends $package
    elif command -v rpm &>/dev/null; then
        rpm -q --tree $package
    else
        yellow_echo "当前系统不支持依赖树分析"
    fi
}

_reverse_deps() {
    local package=$1
    blue_echo "---------------反向依赖查询---------------"
    if command -v apt-get &>/dev/null; then
        apt-cache rdepends $package
    elif command -v rpm &>/dev/null; then
        rpm -q --whatrequires $package
    else
        yellow_echo "当前系统不支持反向依赖查询"
    fi
}

_check_conflicts() {
    local package=$1
    blue_echo "---------------冲突检测---------------"
    if command -v apt-get &>/dev/null; then
        apt-cache show $package | grep Conflicts
    elif command -v rpm &>/dev/null; then
        rpm -q --conflicts $package
    else
        yellow_echo "当前系统不支持冲突检测"
    fi
}

_clean_download_cache() {
    blue_echo "---------------清理下载缓存---------------"
    if command -v apt-get &>/dev/null; then
        apt clean
    elif command -v yum &>/dev/null; then
        yum clean all
    elif command -v dnf &>/dev/null; then
        dnf clean all
    elif command -v zypper &>/dev/null; then
        zypper clean
    fi
    check_command "清理下载缓存"
}

_remove_old_kernels() {
    blue_echo "---------------删除旧内核---------------"
    if command -v apt-get &>/dev/null; then
        apt autoremove --purge
    elif command -v yum &>/dev/null; then
        package-cleanup --oldkernels --count=1
    elif command -v dnf &>/dev/null; then
        dnf remove $(dnf repoquery --installonly --latest-limit=-1 -q)
    fi
    check_command "删除旧内核"
}

_remove_orphans() {
    blue_echo "---------------清理孤立依赖---------------"
    if command -v apt-get &>/dev/null; then
        apt autoremove
    elif command -v yum &>/dev/null; then
        package-cleanup --orphans
    elif command -v dnf &>/dev/null; then
        dnf autoremove
    elif command -v pacman &>/dev/null; then
        pacman -Rns $(pacman -Qtdq)
    fi
    check_command "清理孤立依赖"
}

_show_disk_usage() {
    blue_echo "---------------空间占用统计---------------"
    if command -v apt-get &>/dev/null; then
        du -sh /var/cache/apt/archives
    elif command -v yum &>/dev/null; then
        du -sh /var/cache/yum
    elif command -v dnf &>/dev/null; then
        du -sh /var/cache/dnf
    fi
    df -h /
}

_list_packages() {
    local filter=$1
    local output_file=$2

    blue_echo "------------------------------------------------------"
    green_echo "正在列出已安装的软件包..."

    # 检测包管理器
    if command -v dpkg >/dev/null 2>&1; then
        local cmd="dpkg -l"
        local format="%-40s %-20s %-20s\n"
    elif command -v rpm >/dev/null 2>&1; then
        local cmd="rpm -qa --queryformat '%{NAME}\t%{VERSION}\t%{INSTALLTIME:date}\n' | sort -k3"
        local format="%-40s %-20s %-20s\n"
    else
        red_echo "错误:未找到支持的包管理器(dpkg/rpm)"
        return 1
    fi

    # 应用过滤条件
    [ -n "$filter" ] && cmd="$cmd | grep -i \"$filter\""

    # 输出到文件或屏幕
    if [ -n "$output_file" ]; then
        eval "$cmd" >"$output_file"
        green_echo "已导出软件包列表到: $output_file"
    else
        printf "$format" "包名" "版本" "安装时间"
        blue_echo "------------------------------------------------------"
        eval "$cmd" | awk -v fmt="$format" '{printf fmt, $1, $2, $3}'
    fi
}

_install_pkg() {
    local pkg=$1
    blue_echo "正在安装软件包: $pkg..."
    if command -v apt >/dev/null 2>&1; then
        apt_get install -y "$pkg"
    elif command -v yum >/dev/null 2>&1; then
        sudo yum install -y "$pkg"
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y "$pkg"
    else
        red_echo "错误:未找到支持的包管理器"
        return 1
    fi
    check_command "安装软件包 $pkg"
}

_remove_pkg() {
    local pkg=$1
    yellow_echo "警告:即将卸载软件包: $pkg"
    read -p "确认卸载？(y/n): " confirm
    [ "$confirm" != "y" ] && return

    if command -v apt >/dev/null 2>&1; then
        apt_get purge -y "$pkg"
    elif command -v yum >/dev/null 2>&1; then
        sudo yum remove -y "$pkg"
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf remove -y "$pkg"
    else
        red_echo "错误:未找到支持的包管理器"
        return 1
    fi
    check_command "卸载软件包 $pkg"
}

_search_pkg() {
    local pkg=$1
    local save_file=$2
    local search_cmd

    blue_echo "正在搜索软件包: $pkg..."
    if command -v apt >/dev/null 2>&1; then
        search_cmd="apt_get search ^$pkg"
    elif command -v sudo yum >/dev/null 2>&1; then
        search_cmd="sudo yum search $pkg"
    elif command -v sudo dnf >/dev/null 2>&1; then
        search_cmd="sudo dnf search $pkg"
    else
        red_echo "错误:未找到支持的包管理器"
        return 1
    fi

    if [ -n "$save_file" ]; then
        eval "$search_cmd" >"$save_file"
        green_echo "搜索结果已保存到: $save_file"
    else
        eval "$search_cmd"
    fi
}

# endregion

#region 8) 日志管理
LOG_MGMT() {
    while true; do
        GREEN_echo "==========日志管理=========="
        GREEN_echo "  1. 显示系统日志"
        GREEN_echo "  2. 显示服务日志"
        GREEN_echo "  3. 实时监控日志"
        GREEN_echo "  4. 按关键词搜索日志"
        GREEN_echo "  5. 日志文件分析"
        GREEN_echo "  6. 清理日志"
        GREEN_echo "  7. 日志轮转配置"
        GREEN_echo "  0. 返回主菜单"

        read -p "请输入选择: " choice

        case $choice in
        1) echo "" && display_system_logs ;;
        2) echo "" && display_service_logs ;;
        3) echo "" && monitor_logs_realtime ;;
        4) echo "" && search_logs_by_keyword ;;
        5) echo "" && analyze_log_files ;;
        6) echo "" && clear_logs ;;
        7) echo "" && configure_log_rotation ;;
        0) break ;;
        *) YELLOW_echo "无效选择,请重新输入" ;;
        esac
        echo
    done
}

display_system_logs() {
    if [ $# -gt 0 ]; then
        [ "$1" = "less" ] && _display_system_logs "" "less"
        [ "$1" = "time" ] && time_range=$2 && _display_system_logs $time_range "less"
    else
        while true; do
            BLUE_echo "------------------------------------------------------"
            GREEN_echo "系统日志查看选项:"
            GREEN_echo "  1. 查看完整日志(分页)"
            GREEN_echo "  2. 指定时间范围查看"
            GREEN_echo "  0. 返回"
            BLUE_echo "------------------------------------------------------"

            read -p "请输入选项[0-2]: " choice
            case $choice in
            1) _display_system_logs "" "less" ;;
            2)
                read -p "输入时间范围(如'2023-01-01 00:00:00'): " time_range
                [ "$time_range" != "" ] && _display_system_logs "$time_range" "less"
                ;;
            0) return ;;
            *) RED_echo "无效选项" ;;
            esac
        done
    fi
}

display_service_logs() {
    if [ $# -gt 0 ]; then
        _display_service_logs "$1"
    else
        BLUE_echo "------------------------------------------------------"
        GREEN_echo "可用服务列表:"
        _list_available_services
        BLUE_echo "------------------------------------------------------"

        read -p "输入服务名: " service_name
        _display_service_logs "$service_name"
    fi
}

monitor_logs_realtime() {
    if [ $# -gt 0 ]; then
        _monitor_logs "$@"
    else
        read -p "监控类型(1=系统日志 2=服务日志): " log_type
        if [ "$log_type" = "2" ]; then
            display_service_logs
            read -p "输入要监控的服务名: " service_name
        fi

        read -p "输入高亮关键词(可选): " keywords
        read -p "输入刷新间隔(秒，默认2): " interval

        _monitor_logs \
            "${log_type:-syslog}" \
            "${keywords}" \
            "${interval:-2}"
    fi
}

# 按关键词搜索日志
search_logs_by_keyword() {
    if [ $# -gt 0 ]; then
        [ "$1" = "search" ] && keyword=$2 && logfile=$3 && _search_logs "$keyword" "$logfile"
        [ "$1" = "regex" ] && pattern=$2 && logfile=$3 && _search_logs_regex "$pattern" "$logfile"
        [ "$1" = "time" ] && keyword=$2 && logfile=$3 && start_time=$4 && end_time=$5 && _search_logs_time "$keyword" "$logfile" "$start_time" "$end_time"
    else
        while true; do
            BLUE_echo "------------------------------------------------------"
            GREEN_echo "日志搜索选项:"
            GREEN_echo "  1. 关键词搜索"
            GREEN_echo "  2. 正则表达式搜索"
            GREEN_echo "  3. 按时间范围搜索"
            GREEN_echo "  0. 返回"
            BLUE_echo "------------------------------------------------------"
            read -p "请输入选项[0-3]: " choice

            case $choice in
            1)
                read -p "请输入搜索关键词(多个关键词用空格分隔): " keywords
                read -p "请输入日志文件路径: " logfile
                _search_logs "$keywords" "$logfile"
                ;;
            2)
                read -p "请输入正则表达式: " pattern
                read -p "请输入日志文件路径: " logfile
                _search_logs_regex "$pattern" "$logfile"
                ;;
            3)
                read -p "请输入搜索关键词: " keyword
                read -p "请输入日志文件路径: " logfile
                read -p "请输入开始时间(格式:YYYY-MM-DD HH:MM:SS): " start_time
                read -p "请输入结束时间(格式:YYYY-MM-DD HH:MM:SS): " end_time
                _search_logs_time "$keyword" "$logfile" "$start_time" "$end_time"
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

# 日志文件分析
analyze_log_files() {
    if [ $# -gt 0 ]; then
        [ "$1" = "stats" ] && logfile=$2 && _analyze_log_stats "$logfile"
        [ "$1" = "errors" ] && logfile=$2 && _analyze_log_errors "$logfile"
        [ "$1" = "patterns" ] && logfile=$2 && _analyze_log_patterns "$logfile"
    else
        while true; do
            BLUE_echo "------------------------------------------------------"
            GREEN_echo "日志分析选项:"
            GREEN_echo "  1. 基本统计"
            GREEN_echo "  2. 错误分析"
            GREEN_echo "  3. 模式识别"
            GREEN_echo "  0. 返回"
            BLUE_echo "------------------------------------------------------"
            read -p "请输入选项[0-3]: " choice

            case $choice in
            1)
                read -p "请输入日志文件路径: " logfile
                _analyze_log_stats "$logfile"
                ;;
            2)
                read -p "请输入日志文件路径: " logfile
                _analyze_log_errors "$logfile"
                ;;
            3)
                read -p "请输入日志文件路径: " logfile
                _analyze_log_patterns "$logfile"
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

# 清理日志
clear_logs() {
    if [ $# -gt 0 ]; then
        [ "$1" = "time" ] && days=$2 && _clear_logs_by_time "$days"
        [ "$1" = "size" ] && size=$2 && _clear_logs_by_size "$size"
    else
        while true; do
            BLUE_echo "------------------------------------------------------"
            GREEN_echo "日志清理选项:"
            GREEN_echo "  1. 按时间清理"
            GREEN_echo "  2. 按大小清理"
            GREEN_echo "  3. 显示日志大小"
            GREEN_echo "  0. 返回"
            BLUE_echo "------------------------------------------------------"
            read -p "请输入选项[0-3]: " choice

            case $choice in
            1)
                read -p "请输入保留天数(早于此天数的日志将被删除): " days
                _clear_logs_by_time "$days"
                ;;
            2)
                read -p "请输入最大日志大小(MB): " size
                _clear_logs_by_size "$size"
                ;;
            3)
                _show_log_sizes
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

# 配置日志轮转
configure_log_rotation() {
    if [ $# -gt 0 ]; then
        [ "$1" = "show" ] && _show_logrotate_config
        [ "$1" = "days" ] && logname=$2 && days=$3 && _set_logrotate_days "$logname" "$days"
        [ "$1" = "size" ] && logname=$2 && size=$3 && _set_logrotate_size "$logname" "$size"
    else
        while true; do
            BLUE_echo "------------------------------------------------------"
            GREEN_echo "日志轮转配置选项:"
            GREEN_echo "  1. 显示当前配置"
            GREEN_echo "  2. 修改保留天数"
            GREEN_echo "  3. 修改最大大小"
            GREEN_echo "  4. 添加新规则"
            GREEN_echo "  0. 返回"
            BLUE_echo "------------------------------------------------------"
            read -p "请输入选项[0-4]: " choice

            case $choice in
            1)
                _show_logrotate_config
                ;;
            2)
                read -p "请输入日志名称(如syslog): " logname
                read -p "请输入保留天数: " days
                _set_logrotate_days "$logname" "$days"
                ;;
            3)
                read -p "请输入日志名称(如syslog): " logname
                read -p "请输入最大大小(如100M): " size
                _set_logrotate_size "$logname" "$size"
                ;;
            4)
                read -p "请输入新日志名称: " logname
                read -p "请输入保留天数: " days
                read -p "请输入最大大小(如100M): " size
                _add_logrotate_rule "$logname" "$days" "$size"
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

_search_logs() {
    local keywords=$1
    local logfile=$2
    blue_echo "开始在日志文件 $logfile 中搜索关键词: $keywords"

    if [ ! -f "$logfile" ]; then
        red_echo "错误: 日志文件 $logfile 不存在"
        return 1
    fi

    local grep_cmd="grep --color=always"
    for word in $keywords; do
        grep_cmd="$grep_cmd -e \"$word\""
    done

    eval "$grep_cmd" "$logfile" | while read -r line; do
        echo "$line"
    done

    green_echo "搜索完成"
}

_search_logs_regex() {
    local pattern=$1
    local logfile=$2
    blue_echo "开始在日志文件 $logfile 中使用正则表达式搜索: $pattern"

    if [ ! -f "$logfile" ]; then
        red_echo "错误: 日志文件 $logfile 不存在"
        return 1
    fi

    grep -P --color=always "$pattern" "$logfile"
    green_echo "搜索完成"
}

_search_logs_time() {
    local keyword=$1
    local logfile=$2
    local start_time=$3
    local end_time=$4
    blue_echo "开始在日志文件 $logfile 中按时间范围搜索: $start_time 至 $end_time"

    if [ ! -f "$logfile" ]; then
        red_echo "错误: 日志文件 $logfile 不存在"
        return 1
    fi

    awk -v keyword="$keyword" -v start="$start_time" -v end="$end_time" '
    BEGIN {
        gsub(/[-:]/," ",start); start=mktime(start)
        gsub(/[-:]/," ",end); end=mktime(end)
    }
    {
        ts=$1" "$2; gsub(/[-:]/," ",ts); ts=mktime(ts)
        if (ts >= start && ts <= end && $0 ~ keyword) {
            print $0
        }
    }' "$logfile" | grep --color=always "$keyword"

    green_echo "搜索完成"
}

_show_logrotate_config() {
    blue_echo "当前日志轮转配置:"
    cat /etc/logrotate.conf
    echo ""
    yellow_echo "自定义配置:"
    ls /etc/logrotate.d/
}

_set_logrotate_days() {
    local logname=$1
    local days=$2
    blue_echo "设置 $logname 日志保留 $days 天"

    sudo sed -i "/$logname {/,/}/s/rotate [0-9]*/rotate $days/" /etc/logrotate.d/*
    sudo logrotate -vf /etc/logrotate.conf

    green_echo "配置已更新"
}

_analyze_log_stats() {
    local logfile=$1
    blue_echo "开始分析日志文件: $logfile"

    if [ ! -f "$logfile" ]; then
        red_echo "错误: 日志文件 $logfile 不存在"
        return 1
    fi

    local total_lines=$(wc -l <"$logfile")
    local error_count=$(grep -c -i "error" "$logfile")
    local warning_count=$(grep -c -i "warning" "$logfile")

    yellow_echo "日志统计报告:"
    echo "总行数: $total_lines"
    echo "错误数量: $error_count"
    echo "警告数量: $warning_count"

    green_echo "分析完成"
}

_analyze_log_errors() {
    local logfile=$1
    blue_echo "开始分析日志文件中的错误: $logfile"

    if [ ! -f "$logfile" ]; then
        red_echo "错误: 日志文件 $logfile 不存在"
        return 1
    fi

    yellow_echo "常见错误报告:"
    grep -i "error" "$logfile" | sort | uniq -c | sort -nr | head -10

    green_echo "分析完成"
}

_analyze_log_patterns() {
    local logfile=$1
    blue_echo "开始识别日志文件中的高频模式: $logfile"

    if [ ! -f "$logfile" ]; then
        red_echo "错误: 日志文件 $logfile 不存在"
        return 1
    fi

    yellow_echo "高频错误模式:"
    awk '{print $5}' "$logfile" | sort | uniq -c | sort -nr | head -10

    green_echo "分析完成"
}

_set_logrotate_size() {
    local logname=$1
    local size=$2
    blue_echo "设置 $logname 日志最大大小为 $size"

    sudo sed -i "/$logname {/,/}/s/size [0-9]*[MK]/size $size/" /etc/logrotate.d/*
    sudo logrotate -vf /etc/logrotate.conf

    green_echo "配置已更新"
}

_add_logrotate_rule() {
    local logname=$1
    local days=$2
    local size=$3
    blue_echo "添加新的日志轮转规则: $logname"

    cat <<EOF | sudo tee "/etc/logrotate.d/$logname" >/dev/null
/var/log/$logname.log {
    daily
    missingok
    rotate $days
    size $size
    compress
    delaycompress
    notifempty
    create 0640 root root
}
EOF

    sudo logrotate -vf /etc/logrotate.conf
    green_echo "新规则已添加"
}
# 显示系统日志
_display_system_logs() {
    # 参数: $1=时间范围(如"since 1 hour ago"), $2=分页工具(less/more)
    local log_file="/var/log/syslog"
    [ ! -f "$log_file" ] && log_file="/var/log/messages"

    local cmd="cat $log_file"
    [ -n "$1" ] && cmd="$cmd | grep -E '$1'"
    [ -n "$2" ] && cmd="$cmd | $2"

    eval "$cmd"
    check_command "显示系统日志"
}

_clear_logs_by_time() {
    local days=$1
    blue_echo "开始清理超过 $days 天的日志文件"

    find /var/log -type f -name "*.log" -mtime +$days -exec ls -la {} \;
    read -p "确认删除以上文件? [y/N]: " confirm

    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        find /var/log -type f -name "*.log" -mtime +$days -exec rm -v {} \;
        green_echo "清理完成"
    else
        yellow_echo "取消清理操作"
    fi
}

_clear_logs_by_size() {
    local size=$1
    blue_echo "开始清理大于 $size MB的日志文件"

    find /var/log -type f -name "*.log" -size +${size}M -exec ls -la {} \;
    read -p "确认删除以上文件? [y/N]: " confirm

    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        find /var/log -type f -name "*.log" -size +${size}M -exec truncate -s 0 {} \;
        green_echo "清理完成"
    else
        yellow_echo "取消清理操作"
    fi
}

_show_log_sizes() {
    blue_echo "当前日志文件大小:"
    du -sh /var/log/* | sort -hr
}

# 显示特定服务日志
_list_available_services() {
    # 列出所有systemd服务
    systemctl list-unit-files --type=service | grep enabled | awk '{print $1}'
    # 列出常见日志文件
    find /var/log -type f -name "*.log" | sed 's|/var/log/||'
}

_display_service_logs() {
    # 参数: $1=服务名
    if systemctl is-active "$1" &>/dev/null; then
        journalctl -u "$1" -n 50 --no-pager
    else
        local log_path="/var/log/$1"
        [ -f "$log_path" ] && tail -n 50 "$log_path" || cat "$log_path.log"
    fi
}

# 实时监控日志
_monitor_logs() {
    # 参数: $1=日志源(syslog/service), $2=关键词, $3=刷新间隔(秒)
    local monitor_cmd="tail -f"
    [ "$1" = "syslog" ] && monitor_cmd="$monitor_cmd /var/log/syslog" || monitor_cmd="journalctl -u $1 -f"

    if [ -n "$2" ]; then
        monitor_cmd="$monitor_cmd | grep --color=always -E '$2'"
    fi

    eval "$monitor_cmd"
}
# endregion

#region 9) 容器管理（子模块）
# 相关函数已拆分到同目录的 container.sh。
# 缺失时仅该模块不可用，不影响其它模块。
if [ -r "$SCRIPT_DIR/container.sh" ]; then
    # shellcheck source=container.sh
    . "$SCRIPT_DIR/container.sh"
else
    CONTAINER_MGMT() {
        red_echo "未找到 container.sh，容器管理不可用；请重新安装该 OS 配置"
        return 1
    }
fi
# endregion

#region 11) NTP管理
NTP_MGMT() {
    if [ $# -gt 0 ]; then
        [ "$1" = "status" ] && _ntp_mgmt_status
        [ "$1" = "config" ] && server=$2 && _ntp_mgmt_config "$server"
        [ "$1" = "sync" ] && _ntp_mgmt_sync
        [ "$1" = "service" ] && action=$2 && _ntp_mgmt_service "$action"
    else
        # 主交互逻辑
        while true; do
            BLUE_echo "------------------------------------------------------"
            GREEN_echo "NTP时间同步管理选项:"
            GREEN_echo "  1. NTP服务状态检查"
            GREEN_echo "  2. 配置NTP服务器"
            GREEN_echo "  3. 立即同步时间"
            GREEN_echo "  4. 服务管理(启动/停止/重启)"
            GREEN_echo "  5. 时区配置"
            GREEN_echo "  0. 返回"
            BLUE_echo "------------------------------------------------------"
            read -p "请输入选项[0-5]: " choice
            case $choice in
            1)
                _ntp_mgmt_status
                ;;
            2)
                read -p "请输入NTP服务器地址(如: ntp.aliyun.com): " server
                green_echo "输入信息为- NTP服务器: $server"
                read -p "请确认操作(Y|N,default:Y): " areyouok
                areyouok="${areyouok:-Y}"
                [ "$areyouok" = "Y" ] && _ntp_mgmt_config "$server"
                ;;
            3)
                _ntp_mgmt_sync
                ;;
            4)
                BLUE_echo "------------------------------------------------------"
                GREEN_echo "NTP服务管理选项:"
                GREEN_echo "  1. 启动NTP服务"
                GREEN_echo "  2. 停止NTP服务"
                GREEN_echo "  3. 重启NTP服务"
                BLUE_echo "------------------------------------------------------"
                read -p "请输入操作[1-3]: " action_choice
                case $action_choice in
                1) action="start" ;;
                2) action="stop" ;;
                3) action="restart" ;;
                *)
                    RED_echo "无效选项"
                    continue
                    ;;
                esac
                _ntp_mgmt_service "$action"
                ;;
            5)
                read -p "请输入时区(默认: Asia/Shanghai): " TIMEZONE
                green_echo "输入信息:- 时区: ${TIMEZONE:-Asia/Shanghai}"
                _set_timezone "${TIMEZONE:-Asia/Shanghai}"
                _ntp_mgmt_sync
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

_set_timezone() {
    local TIMEZONE=$1
    green_echo "准备设置时区..."
    ln -svf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
    check_command "设置时区"

    date -R
}

_ntp_mgmt_status() {
    blue_echo "检查NTP服务状态..."
    if command -v timedatectl &>/dev/null; then
        timedatectl status
        check_command "获取时间服务状态"
    else
        yellow_echo "timedatectl命令不存在，尝试使用ntpq..."
        ntpq -p
        check_command "获取NTP服务器状态"
    fi
}

_ntp_mgmt_config() {
    local server=$1
    blue_echo "配置NTP服务器为: $server"

    # Ubuntu/Debian
    if [ -f /etc/ntp.conf ]; then
        sudo sed -i "/^pool /d;/^server /d" /etc/ntp.conf
        echo "server $server iburst" | sudo tee -a /etc/ntp.conf
        sudo systemctl restart ntp
        check_command "配置NTP服务器($server)"
    # CentOS/RHEL
    elif [ -f /etc/chrony.conf ]; then
        sudo sed -i "/^server /d" /etc/chrony.conf
        echo "server $server iburst" | sudo tee -a /etc/chrony.conf
        sudo systemctl restart chronyd
        check_command "配置chrony服务器($server)"
    else
        red_echo "未找到NTP或chrony配置文件"
        return 1
    fi
}

_ntp_mgmt_sync() {
    blue_echo "执行时间同步..."
    if command -v chronyc &>/dev/null; then
        sudo chronyc -a makestep
        check_command "chrony强制时间同步"
    elif command -v ntpdate &>/dev/null; then
        sudo ntpdate -u pool.ntp.org
        check_command "ntpdate时间同步"
    else
        red_echo "未找到时间同步工具(chronyc/ntpdate)"
        return 1
    fi
}

_ntp_mgmt_service() {
    local action=$1
    blue_echo "执行NTP服务操作: $action"

    if systemctl list-unit-files | grep -q chronyd; then
        sudo systemctl $action chronyd
        check_command "chronyd服务$action"
    elif systemctl list-unit-files | grep -q ntpd; then
        sudo systemctl $action ntpd
        check_command "ntpd服务$action"
    else
        red_echo "未找到运行的NTP服务"
        return 1
    fi
}
# endregion

#region 12) 存储管理
STORAGE_MGMT() {
    echo "存储管理功能"
    # 待实现: LVM/RAID存储配置
}
# endregion

#region 13) OPS SSH密钥管理
OPS_SSH_KEY_MGMT() {
    while true; do
        GREEN_echo "==========OPS SSH密钥管理=========="
        GREEN_echo "  1. 创建密钥"
        GREEN_echo "  2. 更新密钥到成员服务器"
        GREEN_echo "  3. 配置成员服务器SSH服务"
        GREEN_echo "  4. 连接验证"
        GREEN_echo "  5. 查看证书基本信息"
        GREEN_echo "  0. 返回主菜单"
        read -p "请输入选择: " choice
        case $choice in
        1)
            read -p "生成密钥的路径(默认:"$HOME/.ssh/id_rsa"): " KEY_PATH
            KEY_PATH=${KEY_PATH:-"$HOME/.ssh/id_rsa"} # 密钥存储路径
            green_echo "输入信息为: $KEY_PATH "
            read -p "请确认操作(Y|N,default:Y): " areyouok
            areyouok="${areyouok:-Y}"
            [ "$areyouok" = "Y" ] && generate_key "$KEY_PATH"

            ;;
        2)
            #NODES=(ckk8s01master001 ckk8s01worker001 ckk8s01worker002 dockerck)  # 目标服务器IP
            usernow=$(logname 2>/dev/null || echo "$USER")
            [ "$usernow" = "root" ] && KEY_PATH="root/.ssh/id_rsa.pub" || KEY_PATH="/home/$usernow/.ssh/id_rsa.pub"
            read -p "本地的密钥路径(默认:"$KEY_PATH"): " KEY_PATH
            if [ -z "$KEY_PATH" ]; then
                [ "$usernow" = "root" ] && KEY_PATH="root/.ssh/id_rsa.pub" || KEY_PATH="/home/$usernow/.ssh/id_rsa.pub"
            fi
            read -p "请输入本次操作的用户名: " USERNAME
            read -p "如果第一次上传到成员服务器,请输入密码,如果是后续更新密码,请跳过(输入密码 | Enter跳过): " PASSD
            read -p "请输入成员服务器IP地址(空格分隔): " -a NODES
            green_echo "输入信息为: $USERNAME | $(echo "${NODES[@]}")  | $PASSD"
            read -p "请确认操作(Y|N,default:Y): " areyouok
            areyouok="${areyouok:-Y}"
            [ "$areyouok" = "Y" ] && upload_key "${KEY_PATH:-"$HOME/.ssh/id_rsa.pub"}" "$USERNAME" "$PASSD" "${NODES[@]}"
            ;;
        3)
            read -p "请输入本次操作的用户名: " USERNAME
            read -p "请输入成员服务器IP地址(空格分隔): " -a NODES
            green_echo "输入信息为: $USERNAME | $(echo "${NODES[@]}") "
            read -p "请确认操作(Y|N,default:Y): " areyouok
            areyouok="${areyouok:-Y}"
            [ "$areyouok" = "Y" ] && configure_sshd "$USERNAME" "${NODES[@]}"
            ;;
        4)
            read -p "请输入成员服务器IP地址(空格分隔): " -a NODES
            green_echo "输入信息为: $(echo "${NODES[@]}") "
            read -p "请确认操作(Y|N,default:Y): " areyouok
            areyouok="${areyouok:-Y}"
            [ "$areyouok" = "Y" ] && test_connection "${NODES[@]}"
            ;;
        5)
            usernow=$(logname 2>/dev/null || echo "$USER")
            [ "$usernow" = "root" ] && KEY_PATH="root/.ssh/id_rsa.pub" || KEY_PATH="/home/$usernow/.ssh/id_rsa.pub"
            read -p "请输入证书文件路径(公钥|私钥, 默认:"$KEY_PATH"): " KEY_PATH
            if [ -z "$KEY_PATH" ]; then
                [ "$usernow" = "root" ] && KEY_PATH="root/.ssh/id_rsa.pub" || KEY_PATH="/home/$usernow/.ssh/id_rsa.pub"
            fi
            green_echo "输入信息为: $KEY_PATH "
            read -p "请确认操作(Y|N,default:Y): " areyouok
            areyouok="${areyouok:-Y}"
            [ "$areyouok" = "Y" ] && get_key_info "$KEY_PATH"
            ;;
        0) break ;;
        *) YELLOW_echo "无效选择,请重新输入" ;;
        esac
    done
}

get_key_info() {
    local filepath=$1
    ssh-keygen -lf "$filepath" && green_echo "查看成功($filepath)" || red_echo "查看失败($filepath)"
}

# 1. 生成SSH密钥对
generate_key() {
    local KEY_PATH=$1
    if [ ! -f "$KEY_PATH" ]; then
        ssh-keygen -t rsa -b 4096 -C "auto-generated@$(hostname)" -f "$KEY_PATH" -N ""
        echo "✅ 密钥对已生成:$KEY_PATH.pub"
        chmod 700 $HOME/.ssh
        chmod 600 $KEY_PATH
        chmod 640 $KEY_PATH.pub

    else
        echo "⚠️  密钥已存在，跳过生成步骤"
    fi
}

# 2. 上传公钥到目标服务器
upload_key() {
    local KEY_PATH=$1
    local USERNAME=$2
    local PASSD=$3
    shift 3

    # 安装sshpass(如果需要)
    if ! command -v sshpass &>/dev/null; then
        apt_get install -y sshpass || {
            echo "Error: Failed to install sshpass"
            return 1
        }
    fi
    chmod 600 $KEY_PATH
    sudo usermod -aG root $USERNAME
    for node in "${NODES[@]}"; do
        sudo ssh-keyscan -H $node >>~/.ssh/known_hosts
        if [ -z "$PASSD" ]; then
            #echo "aaaaaaa $node"
            ssh-copy-id -i $KEY_PATH -o StrictHostKeyChecking=no -f $USERNAME@$node || {
                echo "Error: Failed to copy key to $node"
                continue
            }
        else
            #echo "bbbbbbbbb $node"
            sshpass -p "$PASSD" ssh-copy-id -i $KEY_PATH -o StrictHostKeyChecking=no -f $USERNAME@$node || {
                echo "Error: Failed to copy key to $node"
                continue
            }
        fi
        echo "Successfully deployed key to $node"
    done
    return 0
}

# 3. 配置SSH服务端（禁用密码登录）
configure_sshd() {
    local USERNAME=${1:-"ck"} # 从第二个参数获取用户名
    shift 1

    for node in "${NODES[@]}"; do
        #echo "aaaaaaa $node"
        ssh -q -T "$node" /bin/bash <<-EOF
            sudo usermod -aG root "$USERNAME" 2>/dev/null

            # 安全配置 sudoers
            echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/$USERNAME-custom-sudoers > /dev/null
            sudo chmod 0440 /etc/sudoers.d/$USERNAME-custom-sudoers
            sudo chown root:root /etc/sudoers.d/$USERNAME-custom-sudoers

            # 修改 SSH 配置
            sudo sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
            sudo sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config

            # 重启服务
            sudo systemctl restart ssh > /dev/null 2>&1
EOF
        echo "✅ 节点 $node 配置完成"
    done
}

# 4. 验证连接
test_connection() {
    local -a NODES=("${@}") # 正确接收数组参数

    for node in "${NODES[@]}"; do

        if ssh "$node" "echo '连接成功'"; then
            echo "✅ 证书登录验证通过:  $node"
        else
            echo "❌ 连接测试失败，请检查配置: $node"
        fi

    done
    return 0
}

d() {
    SCRIPT_PATH=$(realpath "$0")
    rm -rf "$SCRIPT_PATH"
}
#endregion

#region 14) 安全审计
SECURITY_AUDIT() {
    while true; do
        GREEN_echo "==========安全审计=========="
        GREEN_echo "  1. 显示安全日志"
        GREEN_echo "  2. 扫描系统漏洞"
        GREEN_echo "  0. 返回主菜单"
        read -p "请输入选择: " choice
        case $choice in
        1) echo "" && display_security_logs ;;
        2) echo "" && scan_system_vulnerabilities ;;
        0) break ;;
        *) YELLOW_echo "无效选择,请重新输入" ;;
        esac
        echo
    done
}

# 显示安全日志
display_security_logs() {
    local auth_log="" source_name="" fail_count=0
    for candidate in /var/log/auth.log /var/log/secure; do
        if [ -r "$candidate" ]; then
            auth_log="$candidate"
            break
        fi
    done

    BLUE_echo "------------------------------------------------------"
    if [ -n "$auth_log" ]; then
        source_name="$auth_log"
        GREEN_echo "日志来源: $auth_log"
        fail_count=$(grep -icE "Failed password|Invalid user|authentication failure" "$auth_log" 2>/dev/null)
        echo ""
        echo ">>> SSH 登录失败记录(最近 20 条)"
        grep -iE "Failed password|Invalid user|authentication failure" "$auth_log" 2>/dev/null | tail -n 20 ||
            echo "    无失败记录"
        echo ""
        echo ">>> 成功登录记录(最近 10 条)"
        grep -iE "Accepted (password|publickey)" "$auth_log" 2>/dev/null | tail -n 10 ||
            echo "    无成功记录"
        echo ""
        echo ">>> 提权操作记录(最近 10 条)"
        grep -iE "sudo:.*COMMAND=" "$auth_log" 2>/dev/null | tail -n 10 ||
            echo "    无提权记录"
    elif command -v journalctl &>/dev/null; then
        source_name="journalctl -u ssh"
        GREEN_echo "日志来源: journalctl -u ssh"
        echo ""
        echo ">>> SSH 登录失败记录(最近 20 条)"
        journalctl -u ssh --no-pager -n 500 2>/dev/null |
            grep -iE "Failed password|Invalid user|authentication failure" | tail -n 20 ||
            echo "    无失败记录"
        echo ""
        echo ">>> 成功登录记录(最近 10 条)"
        journalctl -u ssh --no-pager -n 500 2>/dev/null |
            grep -iE "Accepted (password|publickey)" | tail -n 10 ||
            echo "    无成功记录"
    else
        RED_echo "未找到可读的认证日志(auth.log/secure/journalctl 均不可用)"
        return 1
    fi

    BLUE_echo "------------------------------------------------------"
    GREEN_echo "统计: 登录失败累计 $fail_count 条 (来源: $source_name)"
    echo "提示: 失败次数持续增长时, 请检查 /etc/hosts.allow 白名单与 pam_faillock 策略"
    return 0
}

# 扫描系统漏洞(基线检查, 不联网、不修改系统)
scan_system_vulnerabilities() {
    local issue=0
    BLUE_echo "------------------------------------------------------"
    GREEN_echo "开始系统基线检查..."

    # 1. 空密码账户
    echo ""
    echo ">>> 空密码账户检查"
    local empty_pass
    empty_pass=$(awk -F: '($2==""){print $1}' /etc/shadow 2>/dev/null)
    if [ -n "$empty_pass" ]; then
        RED_echo "    发现空密码账户: $(echo "$empty_pass" | tr '\n' ' ')"
        issue=$((issue + 1))
    else
        echo "    [通过] 无空密码账户"
    fi

    # 2. UID 0 账户
    echo ""
    echo ">>> UID 0 账户检查(应只有 root)"
    local uid0
    uid0=$(awk -F: '($3==0){print $1}' /etc/passwd 2>/dev/null | tr '\n' ' ')
    if [ "$(echo "$uid0" | wc -w)" -gt 1 ]; then
        RED_echo "    发现多个 UID 0 账户: $uid0"
        issue=$((issue + 1))
    else
        echo "    [通过] 仅 root 拥有 UID 0"
    fi

    # 3. 全局可写且无 sticky 的目录
    echo ""
    echo ">>> 全局可写目录检查(应带 sticky 位)"
    local ww_dirs
    ww_dirs=$(find / -xdev -maxdepth 3 -type d -perm -0002 ! -perm -1000 2>/dev/null | head -n 10)
    if [ -n "$ww_dirs" ]; then
        RED_echo "    存在无 sticky 位的全局可写目录:"
        echo "$ww_dirs" | sed 's/^/      /'
        issue=$((issue + 1))
    else
        echo "    [通过] 未发现异常全局可写目录"
    fi

    # 4. 关键文件权限
    echo ""
    echo ">>> 关键文件权限检查"
    local perm_fail=0
    local entry
    for entry in "/etc/passwd:644" "/etc/shadow:640" "/etc/group:644" "/etc/gshadow:640"; do
        local file="${entry%%:*}"
        local want="${entry##*:}"
        [ -e "$file" ] || continue
        local got
        got=$(stat -c '%a' "$file" 2>/dev/null)
        if [ "$got" != "$want" ]; then
            RED_echo "    $file 权限为 $got (建议 $want)"
            perm_fail=1
        fi
    done
    if [ $perm_fail -eq 0 ]; then
        echo "    [通过] 关键文件权限正常"
    else
        issue=$((issue + 1))
    fi

    # 5. 防火墙状态
    echo ""
    echo ">>> 防火墙状态"
    if command -v ufw &>/dev/null; then
        if ufw status 2>/dev/null | grep -q "Status: active"; then
            echo "    [通过] ufw 已启用"
        else
            YELLOW_echo "    ufw 未启用"
            issue=$((issue + 1))
        fi
    else
        YELLOW_echo "    未安装 ufw"
    fi

    # 6. 待安装的安全更新
    echo ""
    echo ">>> 安全更新检查"
    if command -v apt-get &>/dev/null; then
        local sec_count
        sec_count=$(apt-get -s -o Debug::NoLocking=true upgrade 2>/dev/null |
            grep -c "^Inst.*security")
        if [ "${sec_count:-0}" -gt 0 ]; then
            YELLOW_echo "    存在 $sec_count 个待安装的安全更新"
            issue=$((issue + 1))
        else
            echo "    [通过] 无待安装的安全更新(或索引未刷新)"
        fi
    fi

    # 7. SSH 关键配置
    echo ""
    echo ">>> SSH 关键配置检查"
    if [ -r /etc/ssh/sshd_config ]; then
        local key value
        for key in PermitRootLogin PasswordAuthentication PermitEmptyPasswords; do
            value=$(sshd -T 2>/dev/null | awk -v k="$key" 'tolower($1)==tolower(k){print $2}' | head -n1)
            [ -n "$value" ] || value=$(grep -iE "^\s*${key}\s" /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}' | head -n1)
            echo "    ${key}: ${value:-未显式配置}"
        done
    else
        YELLOW_echo "    未找到 /etc/ssh/sshd_config"
    fi

    BLUE_echo "------------------------------------------------------"
    if [ $issue -eq 0 ]; then
        GREEN_echo "基线检查完成: 未发现明显风险项"
    else
        YELLOW_echo "基线检查完成: 共发现 $issue 类风险项, 请逐项确认"
    fi
    echo "说明: 本检查为本地基线核对, 不替代漏洞扫描器与补丁管理平台"
    return 0
}
# endregion

#region 15) 备份管理
BACKUP_MGMT() {
    while true; do
        GREEN_echo "==========备份管理=========="
        GREEN_echo "  1. 创建备份"
        GREEN_echo "  2. 恢复备份"
        GREEN_echo "  0. 返回主菜单"
        read -p "请输入选择: " choice
        case $choice in
        1) echo "" && create_backup ;;
        2) echo "" && restore_backup ;;
        0) break ;;
        *) YELLOW_echo "无效选择,请重新输入" ;;
        esac
        echo
    done
}

# 备份根目录(可通过环境变量覆盖)
BACKUP_ROOT="${BACKUP_ROOT:-/var/backups/os-tools}"

# 创建备份
create_backup() {
    local -a target_paths=()
    local p archive base_name rel size snap_list
    BLUE_echo "------------------------------------------------------"
    GREEN_echo "备份目录: $BACKUP_ROOT"
    echo "可输入多个路径, 空格分隔; 直接回车则使用默认: /etc"
    read -p "要备份的路径: " -a target_paths
    if [ ${#target_paths[@]} -eq 0 ]; then
        target_paths=("/etc")
    fi

    for p in "${target_paths[@]}"; do
        if [ ! -e "$p" ]; then
            RED_echo "路径不存在: $p"
            return 1
        fi
    done

    mkdir -p "$BACKUP_ROOT" || {
        RED_echo "无法创建备份目录: $BACKUP_ROOT"
        return 1
    }
    chmod 700 "$BACKUP_ROOT" 2>/dev/null

    base_name="backup_$(date +%Y%m%d-%H%M%S).tar.gz"
    archive="$BACKUP_ROOT/$base_name"

    GREEN_echo "开始打包: ${target_paths[*]}"
    # 统一去掉前导 /, 以 -C / 的方式打包, 恢复时可直接 -C / 解包
    local -a rel_paths=()
    for p in "${target_paths[@]}"; do
        rel="${p#/}"
        # 传入 "/" 时按整机打包处理
        [ -z "$rel" ] && rel="."
        rel_paths+=("$rel")
    done

    if ! tar czf "$archive" -C / "${rel_paths[@]}" 2>/dev/null; then
        RED_echo "打包失败, 已删除不完整归档"
        rm -f "$archive"
        return 1
    fi

    # 校验归档可读且非空
    if ! tar tzf "$archive" >/dev/null 2>&1 || [ -z "$(tar tzf "$archive" 2>/dev/null | head -n 1)" ]; then
        RED_echo "归档校验失败: $archive"
        rm -f "$archive"
        return 1
    fi

    chmod 600 "$archive" 2>/dev/null
    size=$(du -h "$archive" | awk '{print $1}')
    printf '%s\t%s\t%s\t%s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$archive" \
        "${rel_paths[*]}" "$size" >>"$BACKUP_ROOT/index.tsv"

    GREEN_echo "备份完成: $archive ($size)"
    echo "条目数量: $(tar tzf "$archive" 2>/dev/null | wc -l)"
    echo "恢复命令: tar xzf $archive -C / -p"
    return 0
}

# 恢复备份
restore_backup() {
    local -a archives=()
    local archive choice
    BLUE_echo "------------------------------------------------------"
    mkdir -p "$BACKUP_ROOT" 2>/dev/null
    while IFS= read -r line; do
        [ -n "$line" ] && archives+=("$line")
    done < <(find "$BACKUP_ROOT" -maxdepth 1 -type f -name 'backup_*.tar.gz' 2>/dev/null | sort)

    if [ ${#archives[@]} -eq 0 ]; then
        YELLOW_echo "未找到备份文件(目录: $BACKUP_ROOT)"
        return 1
    fi

    GREEN_echo "可用备份列表:"
    local i=1
    for archive in "${archives[@]}"; do
        echo "  $i) $(basename "$archive")  $(du -h "$archive" 2>/dev/null | awk '{print $1}')"
        i=$((i + 1))
    done
    echo "  0) 返回"

    read -p "请选择要恢复的备份编号: " choice
    case "$choice" in
    0 | "") return 0 ;;
    *[!0-9]*)
        RED_echo "无效编号: $choice"
        return 1
        ;;
    esac
    if [ "$choice" -lt 1 ] || [ "$choice" -gt ${#archives[@]} ]; then
        RED_echo "编号超出范围: $choice"
        return 1
    fi
    archive="${archives[$((choice - 1))]}"

    if ! tar tzf "$archive" >/dev/null 2>&1; then
        RED_echo "归档损坏, 无法恢复: $archive"
        return 1
    fi

    echo ""
    GREEN_echo "归档内容(前 20 条):"
    tar tzf "$archive" 2>/dev/null | head -n 20 | sed 's/^/    /'

    # 收集归档涉及的一级目录, 用于恢复前快照
    local -a tops=()
    local line top
    while IFS= read -r line; do
        top="${line%%/*}"
        [ -z "$top" ] && continue
        case " ${tops[*]} " in
        *" $top "*) ;;
        *) tops+=("$top") ;;
        esac
    done < <(tar tzf "$archive" 2>/dev/null)

    echo ""
    YELLOW_echo "警告: 恢复会覆盖现有文件, 涉及: ${tops[*]}"
    read -p "确认恢复请输入 RESTORE (其它任意输入取消): " choice
    if [ "$choice" != "RESTORE" ]; then
        YELLOW_echo "已取消恢复"
        return 0
    fi

    # 恢复前快照
    local -a existing=()
    for top in "${tops[@]}"; do
        [ -e "/$top" ] && existing+=("$top")
    done
    if [ ${#existing[@]} -gt 0 ]; then
        local snapshot="$BACKUP_ROOT/pre-restore_$(date +%Y%m%d-%H%M%S).tar.gz"
        if tar czf "$snapshot" -C / "${existing[@]}" 2>/dev/null; then
            GREEN_echo "已生成恢复前快照: $snapshot"
        else
            RED_echo "恢复前快照失败, 已中止恢复"
            rm -f "$snapshot"
            return 1
        fi
    fi

    GREEN_echo "开始恢复: $(basename "$archive")"
    if tar xzf "$archive" -C / -p --numeric-owner 2>/dev/null; then
        GREEN_echo "恢复完成"
        echo "已恢复到: ${tops[*]}"
        echo "提示: 涉及 /etc 配置变更时, 请复核服务状态后再重启"
    else
        RED_echo "恢复失败, 请检查磁盘空间与归档完整性"
        return 1
    fi
    return 0
}
# endregion

#region 16) 定时任务管理
# 定时任务管理功能
CRON_MGMT() {
    while true; do
        GREEN_echo "==========定时任务管理=========="
        GREEN_echo "  1. 查看当前任务"
        GREEN_echo "  2. 添加新任务"
        GREEN_echo "  3. 删除任务"
        GREEN_echo "  4. 编辑任务"
        GREEN_echo "  5. 备份/恢复配置"
        GREEN_echo "  6. 任务状态管理"
        GREEN_echo "  7. 任务日志监控"
        GREEN_echo "  8. 批量导入导出"
        GREEN_echo "  0. 返回主菜单"
        read -p "请输入选择: " choice

        case $choice in
        1) echo "" && list_cron_jobs ;;
        2) echo "" && add_cron_job ;;
        3) echo "" && delete_cron_job ;;
        4) echo "" && edit_cron_job ;;
        5) echo "" && backup_restore_cron ;;
        6) echo "" && manage_cron_status ;;
        7) echo "" && monitor_cron_logs ;;
        8) echo "" && batch_import_export ;;
        0) break ;;
        *) YELLOW_echo "无效选择,请重新输入" ;;
        esac
        echo
    done
}

list_cron_jobs() {
    if [ $# -gt 0 ]; then
        _list_cron_jobs "$@"
    else
        while true; do
            BLUE_echo "------------------------------------------------------"
            GREEN_echo "定时任务列表选项:"
            GREEN_echo "  1. 查看当前用户任务"
            GREEN_echo "  2. 查看root用户任务"
            GREEN_echo "  3. 自定义用户查询"
            GREEN_echo "  4. 设置每页显示数量"
            GREEN_echo "  5. 搜索任务"
            GREEN_echo "  0. 返回"
            BLUE_echo "------------------------------------------------------"

            read -p "请输入选项[0-5]: " choice
            case $choice in
            1) _list_cron_jobs "$(whoami)" ;;
            2) _list_cron_jobs "root" ;;
            3)
                read -p "请输入用户名: " username
                _list_cron_jobs "$username"
                ;;
            4)
                read -p "请输入每页显示数量(默认10): " page_size
                _list_cron_jobs "$(whoami)" "" "$page_size"
                ;;
            5)
                read -p "请输入搜索关键词: " search_term
                _list_cron_jobs "$(whoami)" "$search_term"
                ;;
            0) return ;;
            *) RED_echo "无效选项" ;;
            esac
            read -p "按任意键继续..." -n1 -s
            clear
        done
    fi
}

# 添加新定时任务
add_cron_job() {
    if [ $# -ge 1 ]; then
        # 如果传入参数，则直接添加
        local time_expr="$1"
        local command="$2"
        local user="${3:-$(whoami)}"
        local safe_mode="${4:-true}"
        _add_cron_job "$time_expr" "$command" "$user" "$safe_mode"
    else
        BLUE_echo "------------------------------------------------------"
        GREEN_echo "添加新定时任务"
        BLUE_echo "------------------------------------------------------"

        # 时间表达式生成器
        YELLOW_echo "时间表达式格式: 分 时 日 月 周"
        read -p "请输入分钟(0-59,*): " minute
        read -p "请输入小时(0-23,*): " hour
        read -p "请输入日期(1-31,*): " day
        read -p "请输入月份(1-12,*): " month
        read -p "请输入星期(0-7,*): " weekday

        local time_expr="$minute $hour $day $month $weekday"

        # 命令输入
        YELLOW_echo "请输入要执行的命令(支持Tab补全):"
        read -e command

        # 用户选择
        read -p "是否为root用户添加任务? [y/N]: " is_root
        local user=$(whoami)
        [[ "$is_root" =~ [yY] ]] && user="root"

        _add_cron_job "$time_expr" "$command" "$user"
    fi
}

# 删除定时任务
delete_cron_job() {
    if [ $# -gt 0 ]; then
        _delete_cron_job "$@"
    else
        # 先列出任务
        _list_cron_jobs

        BLUE_echo "------------------------------------------------------"
        GREEN_echo "删除定时任务"
        BLUE_echo "------------------------------------------------------"

        read -p "请输入要删除的任务行号: " line_number
        read -p "是否为root用户任务? [y/N]: " is_root

        local user=$(whoami)
        [[ "$is_root" =~ [yY] ]] && user="root"

        _delete_cron_job "$line_number" "$user"
    fi
}

# 编辑现有任务

edit_cron_job() {
    if [ $# -gt 0 ]; then
        _edit_cron_job "$*"
    else
        # 交互式选择要编辑的任务
        _list_cron_jobs
        read -p "请输入要编辑的任务编号: " job_num
        local job=$(_get_cron_job_by_num "$job_num")
        [ -z "$job" ] && {
            RED_echo "无效的任务编号"
            return 1
        }
        _edit_cron_job "$job"
    fi
}

# 备份/恢复配置
backup_restore_cron() {
    if [ $# -gt 0 ]; then
        [ "$1" = "backup" ] && _backup_cron "$2"
        [ "$1" = "restore" ] && _restore_cron "$2"
    else
        while true; do
            BLUE_echo "------------------------------------------------------"
            GREEN_echo "定时任务备份/恢复选项:"
            GREEN_echo "  1. 备份当前配置"
            GREEN_echo "  2. 从备份恢复"
            GREEN_echo "  0. 返回"
            BLUE_echo "------------------------------------------------------"
            read -p "请输入选项[0-2]: " choice
            case $choice in
            1) _backup_cron ;;
            2)
                ls -l $HOME/cron_backups/*.txt 2>/dev/null
                read -p "请输入要恢复的备份文件路径: " backup_file
                _restore_cron "$backup_file"
                ;;
            0) return ;;
            *) RED_echo "无效选项" ;;
            esac
        done
    fi
}

# 任务状态管理
manage_cron_status() {
    if [ $# -gt 0 ]; then
        [ "$1" = "enable" ] && _enable_cron_job "$2"
        [ "$1" = "disable" ] && _disable_cron_job "$2"
    else
        while true; do
            BLUE_echo "------------------------------------------------------"
            GREEN_echo "定时任务状态管理:"
            _list_cron_jobs
            read -p "请输入要操作的任务编号(0返回): " job_num
            [ "$job_num" = "0" ] && return

            local job=$(_get_cron_job_by_num "$job_num")
            [ -z "$job" ] && {
                RED_echo "无效的任务编号"
                continue
            }

            if [[ "$job" =~ ^\# ]]; then
                _enable_cron_job "$job"
            else
                _disable_cron_job "$job"
            fi
        done
    fi
}

# 任务执行日志监控
monitor_cron_logs() {
    if [ $# -gt 0 ]; then
        [ "$1" = "tail" ] && log_file="$2" && lines="${3:-50}" && _tail_log "$log_file" "$lines"
        [ "$1" = "analyze" ] && log_file="$2" && _analyze_log "$log_file"
        [ "$1" = "alert" ] && log_file="$2" && threshold="${3:-5}" && _setup_alerts "$log_file" "$threshold"
    else
        # 主交互逻辑
        while true; do
            BLUE_echo "------------------------------------------------------"
            GREEN_echo "定时任务日志监控选项:"
            GREEN_echo "  1. 实时日志跟踪"
            GREEN_echo "  2. 错误日志分析"
            GREEN_echo "  3. 告警阈值设置"
            GREEN_echo "  0. 返回"
            BLUE_echo "------------------------------------------------------"
            read -p "请输入选项[0-3]: " choice
            case $choice in
            1)
                read -p "请输入日志文件路径: " log_file
                read -p "请输入显示行数(默认50): " lines
                _tail_log "${log_file}" "${lines:-50}"
                ;;
            2)
                read -p "请输入日志文件路径: " log_file
                _analyze_log "$log_file"
                ;;
            3)
                read -p "请输入日志文件路径: " log_file
                read -p "请输入失败告警阈值(默认5次): " threshold
                _setup_alerts "$log_file" "${threshold:-5}"
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

# 批量导入导出
batch_import_export() {
    if [ $# -gt 0 ]; then
        [ "$1" = "import" ] && file="$2" && _import_jobs "$file"
        [ "$1" = "export" ] && file="$2" && format="${3:-csv}" && _export_jobs "$file" "$format"
        [ "$1" = "template" ] && format="${2:-csv}" && _generate_template "$format"
    else
        # 主交互逻辑
        while true; do
            BLUE_echo "------------------------------------------------------"
            GREEN_echo "批量导入导出选项:"
            GREEN_echo "  1. 导入任务"
            GREEN_echo "  2. 导出任务"
            GREEN_echo "  3. 生成模板"
            GREEN_echo "  0. 返回"
            BLUE_echo "------------------------------------------------------"
            read -p "请输入选项[0-3]: " choice
            case $choice in
            1)
                read -p "请输入导入文件路径: " file
                _import_jobs "$file"
                ;;
            2)
                read -p "请输入导出文件路径: " file
                read -p "请输入格式(csv/json,默认csv): " format
                _export_jobs "$file" "${format:-csv}"
                ;;
            3)
                read -p "请输入格式(csv/json,默认csv): " format
                _generate_template "${format:-csv}"
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

# 实时日志跟踪
_tail_log() {
    local log_file="$1"
    local lines="${2:-50}"

    if [ ! -f "$log_file" ]; then
        red_echo "错误: 日志文件不存在"
        return 1
    fi

    BLUE_echo "------------------------------------------------------"
    GREEN_echo "开始实时监控日志文件: $log_file"
    BLUE_echo "------------------------------------------------------"

    # 高亮错误和警告
    tail -n "$lines" -f "$log_file" | while read -r line; do
        if [[ "$line" =~ ERROR|FAILED ]]; then
            RED_echo "$line"
        elif [[ "$line" =~ WARN ]]; then
            YELLOW_echo "$line"
        else
            echo "$line"
        fi
    done
}

# 日志分析
_analyze_log() {
    local log_file="$1"

    if [ ! -f "$log_file" ]; then
        red_echo "错误: 日志文件不存在"
        return 1
    fi

    BLUE_echo "------------------------------------------------------"
    GREEN_echo "日志分析报告: $log_file"
    BLUE_echo "------------------------------------------------------"

    # 统计执行情况
    local total=$(grep -c "执行完成" "$log_file")
    local success=$(grep -c "执行成功" "$log_file")
    local failed=$(grep -c "执行失败" "$log_file")
    local avg_time=$(grep "执行时长" "$log_file" | awk '{sum+=$NF; count++} END{print sum/count}')

    GREEN_echo "执行统计:"
    echo "总执行次数: $total"
    echo "成功次数: $success"
    echo "失败次数: $failed"
    echo "平均执行时长: ${avg_time:-0}秒"

    # 显示最近5个错误
    YELLOW_echo "\n最近5个错误:"
    grep -A 2 -B 2 "ERROR\|FAILED" "$log_file" | head -n 15
}

# 告警设置
_setup_alerts() {
    local log_file="$1"
    local threshold="$2"

    BLUE_echo "------------------------------------------------------"
    GREEN_echo "设置失败告警: 当失败次数超过 $threshold 次时触发"
    BLUE_echo "------------------------------------------------------"

    # 创建监控脚本
    local monitor_script="/tmp/cron_monitor_$(date +%s).sh"
    cat >"$monitor_script" <<EOF
#!/bin/bash
log_file="$log_file"
threshold=$threshold

count=\$(grep -c "执行失败" "\$log_file")
if [ "\$count" -ge "\$threshold" ]; then
    echo "[警报] 定时任务失败次数超过阈值: \$count" | mail -s "定时任务警报" admin@example.com
fi
EOF

    chmod +x "$monitor_script"
    green_echo "已创建监控脚本: $monitor_script"
    yellow_echo "请将此脚本添加到crontab中定期执行"
}

# 导入任务
_import_jobs() {
    local file="$1"

    if [ ! -f "$file" ]; then
        red_echo "错误: 文件不存在"
        return 1
    fi

    # 预览前5行
    BLUE_echo "------------------------------------------------------"
    GREEN_echo "文件预览(前5行):"
    BLUE_echo "------------------------------------------------------"
    head -n 5 "$file"

    read -p "确认导入以上任务? [y/N]: " confirm
    if [[ "$confirm" =~ [yY] ]]; then
        if [[ "$file" == *.csv ]]; then
            _import_csv "$file"
        elif [[ "$file" == *.json ]]; then
            _import_json "$file"
        else
            red_echo "错误: 不支持的格式"
            return 1
        fi
    else
        yellow_echo "已取消导入"
    fi
}

# 导入CSV
_import_csv() {
    local file="$1"
    local temp_file="/tmp/cron_import_$(date +%s)"

    # CSV格式: 分钟,小时,日,月,周,命令
    awk -F, '{print $1" "$2" "$3" "$4" "$5" "$6}' "$file" >"$temp_file"
    crontab "$temp_file"
    rm "$temp_file"
    green_echo "CSV导入完成"
}

# 导入JSON
_import_json() {
    local file="$1"
    local temp_file="/tmp/cron_import_$(date +%s)"

    # JSON格式: [{"schedule":"* * * * *", "command":"echo hello"}]
    jq -r '.[] | "\(.schedule) \(.command)"' "$file" >"$temp_file"
    crontab "$temp_file"
    rm "$temp_file"
    green_echo "JSON导入完成"
}

# 导出任务
_export_jobs() {
    local file="$1"
    local format="$2"

    BLUE_echo "------------------------------------------------------"
    GREEN_echo "导出定时任务到: $file"
    BLUE_echo "------------------------------------------------------"

    if [ "$format" = "csv" ]; then
        _export_csv "$file"
    elif [ "$format" = "json" ]; then
        _export_json "$file"
    else
        red_echo "错误: 不支持的格式"
        return 1
    fi
}

# 导出CSV
_export_csv() {
    local file="$1"

    # 添加CSV头
    echo "minute,hour,day,month,weekday,command" >"$file"
    crontab -l | grep -v '^#' | awk '{print $1","$2","$3","$4","$5","$6}' >>"$file"
    green_echo "CSV导出完成"
}

# 导出JSON
_export_json() {
    local file="$1"

    echo '[' >"$file"
    crontab -l | grep -v '^#' | awk '{
        if(NR>1) printf ",\n";
        printf "  {\"schedule\":\"%s %s %s %s %s\", \"command\":\"%s\"}", $1, $2, $3, $4, $5, $6
    }' >>"$file"
    echo -e '\n]' >>"$file"
    green_echo "JSON导出完成"
}

# 生成模板
_generate_template() {
    local format="$1"
    local template_file="/tmp/cron_template_$(date +%s).$format"

    if [ "$format" = "csv" ]; then
        echo "minute,hour,day,month,weekday,command" >"$template_file"
        echo "0,*,*,*,*,echo hello" >>"$template_file"
    else
        echo '[{"schedule":"0 * * * *", "command":"echo hourly"}]' >"$template_file"
    fi

    green_echo "模板已生成: $template_file"
}

# 任务依赖检查
check_cron_dependencies() {
    if [ $# -gt 0 ]; then
        [ "$1" = "command" ] && cmd="$2" && check_command "$cmd"
        [ "$1" = "file" ] && file="$2" && _check_file "$file"
        [ "$1" = "env" ] && var="$2" && _check_env "$var"
        [ "$1" = "network" ] && host="$2" && port="$3" && _check_network "$host" "$port"
    else
        # 主交互逻辑
        while true; do
            BLUE_echo "------------------------------------------------------"
            GREEN_echo "任务依赖检查选项:"
            GREEN_echo "  1. 检查命令是否存在"
            GREEN_echo "  2. 检查文件权限"
            GREEN_echo "  3. 检查环境变量"
            GREEN_echo "  4. 检查网络依赖"
            GREEN_echo "  0. 返回"
            BLUE_echo "------------------------------------------------------"
            read -p "请输入选项[0-4]: " choice
            case $choice in
            1)
                read -p "请输入要检查的命令: " cmd
                check_command "$cmd"
                ;;
            2)
                read -p "请输入要检查的文件路径: " file
                _check_file "$file"
                ;;
            3)
                read -p "请输入要检查的环境变量: " var
                _check_env "$var"
                ;;
            4)
                read -p "请输入要检查的主机: " host
                read -p "请输入要检查的端口: " port
                _check_network "$host" "$port"
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

# 检查文件
_check_file() {
    local file="$1"

    if [ -f "$file" ]; then
        green_echo "文件检查: $file 存在"

        # 检查权限
        if [ -r "$file" ]; then
            green_echo "  可读权限: 是"
        else
            red_echo "  可读权限: 否"
        fi

        if [ -w "$file" ]; then
            green_echo "  可写权限: 是"
        else
            red_echo "  可写权限: 否"
        fi

        if [ -x "$file" ]; then
            green_echo "  可执行权限: 是"
        else
            red_echo "  可执行权限: 否"
        fi
    else
        red_echo "文件检查: $file 不存在"
        return 1
    fi
}

# 检查环境变量
_check_env() {
    local var="$1"

    if [ -z "${!var}" ]; then
        red_echo "环境变量检查: $var 未设置"
        return 1
    else
        green_echo "环境变量检查: $var 已设置"
        echo "  值: ${!var}"
        return 0
    fi
}

# 检查网络
_check_network() {
    local host="$1"
    local port="$2"

    if nc -z -w 3 "$host" "$port"; then
        green_echo "网络检查: $host:$port 可连接"
        return 0
    else
        red_echo "网络检查: $host:$port 不可连接"
        return 1
    fi
}
# 按编号取出定时任务行，编号口径与 _list_cron_jobs 的展示一致（已过滤注释行）
_get_cron_job_by_num() {
    local num="${1:-}"
    local user="${2:-$(whoami)}"
    local cron_content

    [[ "$num" =~ ^[0-9]+$ ]] || return 1

    if [ "$user" = "root" ]; then
        cron_content=$(sudo crontab -l 2>/dev/null)
    else
        cron_content=$(crontab -l 2>/dev/null)
    fi
    [ -z "$cron_content" ] && return 1

    echo "$cron_content" | grep -v "^#" | sed -n "${num}p"
}

_edit_cron_job() {
    local job="$1"
    local original_job="$job"
    local temp_file=$(mktemp)

    # 可视化时间表达式编辑器
    BLUE_echo "------------------------------------------------------"
    GREEN_echo "当前任务: $job"
    BLUE_echo "------------------------------------------------------"

    # 显示时间表达式帮助
    YELLOW_echo "时间表达式格式: 分 时 日 月 周"
    YELLOW_echo "示例:"
    YELLOW_echo "  * * * * * 每分钟执行"
    YELLOW_echo "  0 * * * * 每小时执行"
    YELLOW_echo "  0 0 * * * 每天执行"

    # 提取时间表达式和命令
    local schedule=$(echo "$job" | awk '{print $1,$2,$3,$4,$5}')
    local command=$(echo "$job" | awk '{$1=$2=$3=$4=$5=""; print substr($0,6)}')

    # 编辑时间表达式
    read -p "请输入新的时间表达式(直接回车保持原样): " new_schedule
    [ -z "$new_schedule" ] && new_schedule="$schedule"

    # 编辑命令
    read -p "请输入新的命令(直接回车保持原样): " new_command
    [ -z "$new_command" ] && new_command="$command"

    # 生成新任务
    local new_job="$new_schedule $new_command"

    # 语法检查
    if ! (crontab -l | grep -v "$original_job" | {
        cat
        echo "$new_job"
    } | crontab -); then
        RED_echo "语法错误: 时间表达式或命令格式不正确"
        return 1
    fi

    # 记录修改历史
    local history_file="$HOME/.cron_edit_history"
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $USER | $original_job -> $new_job" >>"$history_file"

    green_echo "任务修改成功"
    rm -f "$temp_file"
}

_backup_cron() {
    local backup_dir="${1:-$HOME/cron_backups}"
    mkdir -p "$backup_dir"
    local backup_file="$backup_dir/cron_backup_$(date +%Y%m%d_%H%M%S).txt"
    crontab -l >"$backup_file"
    green_echo "定时任务已备份到: $backup_file"
}

_restore_cron() {
    local backup_file="$1"
    if [ ! -f "$backup_file" ]; then
        RED_echo "备份文件不存在: $backup_file"
        return 1
    fi
    crontab "$backup_file"
    green_echo "定时任务已从 $backup_file 恢复"
}

_disable_cron_job() {
    local job="$1"
    # 在行首添加注释符号
    crontab -l | grep -v "$job" | {
        cat
        echo "# $job"
    } | crontab -
    green_echo "任务已禁用: $job"
}

_enable_cron_job() {
    local job="$1"
    # 移除行首的注释符号
    crontab -l | grep -v "$job" | {
        cat
        echo "${job#\# }"
    } | crontab -
    green_echo "任务已启用: ${job#\# }"
}

_delete_cron_job() {
    local line_number="$1"
    local user="${2:-$(whoami)}"
    local safe_mode="${3:-true}"

    # 获取当前crontab
    local cron_content
    if [ "$user" = "root" ]; then
        cron_content=$(sudo crontab -l 2>/dev/null)
    else
        cron_content=$(crontab -l 2>/dev/null)
    fi

    # 安全模式检查
    if [ "$safe_mode" = "true" ]; then
        local target_line=$(echo "$cron_content" | sed -n "${line_number}p")
        YELLOW_echo "即将删除的任务: $target_line"
        read -p "确认删除? [y/N]: " confirm
        [[ "$confirm" =~ [yY] ]] || return 1
    fi

    # 执行删除
    if [ "$user" = "root" ]; then
        echo "$cron_content" | sed "${line_number}d" | sudo crontab -
    else
        echo "$cron_content" | sed "${line_number}d" | crontab -
    fi

    check_command "删除定时任务"
}

_add_cron_job() {
    local time_expr="$1"
    local command="$2"
    local user="${3:-$(whoami)}"

    # 验证时间表达式
    if ! [[ "$time_expr" =~ ^([0-9*,-/]+ ){4}[0-9*,-/]+$ ]]; then
        red_echo "错误: 无效的时间表达式格式"
        return 1
    fi

    # 添加任务
    if [ "$user" = "root" ]; then
        (
            sudo crontab -l 2>/dev/null
            echo "$time_expr $command"
        ) | sudo crontab -
    else
        (
            crontab -l 2>/dev/null
            echo "$time_expr $command"
        ) | crontab -
    fi

    check_command "添加定时任务"
}

# 查看当前所有定时任务
_list_cron_jobs() {
    local user="${1:-$(whoami)}"
    local search_term="$2"
    local page_size="${3:-10}"

    # 获取当前用户crontab内容
    local cron_content
    if [ "$user" = "root" ]; then
        cron_content=$(sudo crontab -l 2>/dev/null)
    else
        cron_content=$(crontab -l 2>/dev/null)
    fi

    # 检查是否为空
    if [ -z "$cron_content" ]; then
        yellow_echo "当前用户 $user 没有定时任务"
        return 1
    fi

    # 过滤和分页处理
    local filtered_content=$(echo "$cron_content" | grep -v "^#" | grep -i "${search_term:-''}")
    local total_lines=$(echo "$filtered_content" | wc -l)

    # 彩色输出
    BLUE_echo "------------------------------------------------------"
    GREEN_echo "用户 $user 的定时任务 (共 $total_lines 条)"
    BLUE_echo "------------------------------------------------------"

    echo "$filtered_content" | awk -v page_size="$page_size" '
    BEGIN {
        user_color["root"]="\033[1;31m"  # 红色高亮root任务
        user_color["'"$user"'"]="\033[1;32m"  # 绿色高亮当前用户任务
        reset=""
    }
    {
        if (NR % page_size == 0 && NR != 0) {
            printf "按任意键继续查看下一页...\n"
            getline dummy < "/dev/tty"
        }
        print user_color["'"$user"'"] $0 reset
    }'

    # 显示最后执行时间（模拟实现）
    YELLOW_echo "提示: 最后执行时间功能需要配置日志系统"
}

# endregion

#region 17) K8S管理（子模块）
# K8S 相关函数约 2400 行，已拆分到同目录的 k8s.sh。
# 缺失时仅 K8S 菜单不可用，不影响其它模块。
if [ -r "$SCRIPT_DIR/k8s.sh" ]; then
    # shellcheck source=k8s.sh
    . "$SCRIPT_DIR/k8s.sh"
else
    K8S_MGMT() {
        red_echo "未找到 k8s.sh，K8S 管理不可用；请重新安装该 OS 配置"
        return 1
    }
fi
# endregion

#region pre
color_echo() {
    local now_current_time=$(date "+%Y-%m-%d %H:%M:%S")
    local color="" reset=""
    # 非交互终端或 TERM=dumb 时 tput 会报错，此处降级为无颜色输出
    if [ -t 1 ] && command -v tput >/dev/null 2>&1 && [ -n "${TERM:-}" ] && [ "${TERM}" != "dumb" ]; then
        color=$(tput setaf "$2" 2>/dev/null) || color=""
        reset=$(tput sgr0 2>/dev/null) || reset=""
    fi
    echo -e "${now_current_time} || ${color}$1${reset}" # First parameter is message
    #sleep 1
}

color_echo_notime() {
    local now_current_time=$(date "+%Y-%m-%d %H:%M:%S")
    local color="" reset=""
    if [ -t 1 ] && command -v tput >/dev/null 2>&1 && [ -n "${TERM:-}" ] && [ "${TERM}" != "dumb" ]; then
        color=$(tput setaf "$2" 2>/dev/null) || color=""
        reset=$(tput sgr0 2>/dev/null) || reset=""
    fi
    echo -e "${color}$1${reset}" # First parameter is message
    #sleep 1
}

# Define colored output functions
red_echo() { color_echo "$1" 1; }           # Red
RED_echo() { color_echo_notime "$1" 1; }    # Red
green_echo() { color_echo "$1" 2; }         # Green     Menu management only
GREEN_echo() { color_echo_notime "$1" 2; }  # Green     Menu management only
yellow_echo() { color_echo "$1" 3; }        # Yellow
YELLOW_echo() { color_echo_notime "$1" 3; } # Yellow
blue_echo() { color_echo "$1" 4; }          # Blue
BLUE_echo() { color_echo_notime "$1" 4; }   # Blue
white_echo() { color_echo "$1" 7; }         # white
WHITE_echo() { color_echo_notime "$1" 7; }  # white

# 检查命令是否成功执行函数
check_command() {
    if [ $? -ne 0 ]; then
        red_echo "错误:$1 失败!!!"
        return 1
    else
        green_echo "$1 成功!!!"
        return 0
    fi
}

pre_script_name=$(basename "$0")
#pre_script_name=$(basename "$0" .sh) # 示例:原脚本名称为 deploy.sh 会变成 deploy
pre_current_time=$(date "+%Y%m%d-%H%M%S")
pre_log_file="log_${pre_current_time}_${pre_script_name}.log"
# 优先使用共享库的统一日志目录，共享库缺失时退回当前目录
if declare -F init_logging >/dev/null 2>&1; then
    init_logging "${pre_script_name%.sh}"
else
    exec > >(tee -a "$pre_log_file") 2>&1
fi
#endregion

#region main
# 根据参数决定运行模式
if [ $# -eq 0 ]; then
    # 默认显示主菜单
    MAIN_MENU
else
    # 检查输入的函数是否存在
    if declare -f "$1" >/dev/null; then
        # 如果存在则执行该函数
        "$@"
    else
        echo "错误: 函数 '$1' 不存在"
        echo "可用函数:"
        declare -F | awk '{print $3}' | grep -v '^_'
        exit 1
    fi
fi
#endregion
