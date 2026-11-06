#!/usr/bin/env bash
#
# 服务管理子模块，由 mgt-god.sh source 加载，不单独执行。
# 依赖 mgt-god.sh 中定义的 GREEN_echo / blue_echo / red_echo / check_command 等函数。

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    echo "service.sh 是 mgt-god.sh 的子模块，不能直接执行。" >&2
    exit 1
fi

#region 6) 服务管理
SERVICE_MGMT() {
    while true; do
        GREEN_echo "==========服务管理=========="
        GREEN_echo "  1. 服务查询"
        GREEN_echo "  2. 启动/停止/重启服务"
        GREEN_echo "  3. 服务状态监控"
        GREEN_echo "  4. 服务日志查看"
        GREEN_echo "  5. 服务依赖分析"
        GREEN_echo "  6. 服务自动启动配置"
        GREEN_echo "  7. 常规服务安装卸载"
        GREEN_echo "  0. 返回主菜单"
        read -p "请输入选择: " choice
        case $choice in
        1) echo "" && display_services ;;
        2) echo "" && manage_service ;;
        3) echo "" && monitor_service_status ;;
        4) echo "" && view_service_logs ;;
        5) echo "" && analyze_service_dependencies ;;
        6) echo "" && configure_service_autostart ;;
        7) echo "" && install_uninstall_service ;;
        0) break ;;
        *) YELLOW_echo "无效选择,请重新输入" ;;
        esac
        echo
    done
}

# 1. 服务查询
display_services() {
    if [ $# -gt 0 ]; then
        [ $1 = "s" ] && _show_service_description $2 && return
        _display_services $1 && return
    fi

    # 主交互逻辑
    while true; do
        BLUE_echo "------------------------------------------------------"
        GREEN_echo "服务显示选项:"
        GREEN_echo "  1. 显示所有服务"
        GREEN_echo "  2. 显示运行中的服务"
        GREEN_echo "  3. 显示已停止的服务"
        GREEN_echo "  4. 显示失败的服务"
        GREEN_echo "  5. 导出服务列表到文件"
        GREEN_echo "  6. 特定服务详细查看"
        GREEN_echo "  0. 返回"
        BLUE_echo "------------------------------------------------------"

        read -p "请输入选项[0-5]: " choice
        case $choice in
        1)
            _display_services
            ;;
        2)
            _display_services "running"
            ;;
        3)
            _display_services "stopped"
            ;;
        4)
            _display_services "failed"
            ;;
        5)
            read -p "请输入导出文件名(默认services_list.txt): " output_file
            _display_services "" "${output_file:-"services_list.txt"}"
            ;;
        6)
            read -p "输入服务名查看详细描述(留空跳过): " service_name
            [[ -n "$service_name" ]] && _show_service_description "$service_name"
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

# 2. 启动/停止/重启服务
manage_service() {
    if [ $# -gt 0 ]; then
        [ $2 = "start" ] && service=$1 && _start_service "$service"
        [ $2 = "stop" ] && service=$1 && _stop_service "$service"
        [ $2 = "restart" ] && service=$1 && _restart_service "$service"
        [ $2 = "reload" ] && service=$1 && _reload_service "$service"
        [ $2 = "status" ] && service=$1 && _status_service "$service"
    else
        # 主交互逻辑
        while true; do
            BLUE_echo "------------------------------------------------------"
            GREEN_echo "服务管理选项:"
            GREEN_echo "  1. 启动服务"
            GREEN_echo "  2. 停止服务"
            GREEN_echo "  3. 重启服务"
            GREEN_echo "  4. 重载服务"
            GREEN_echo "  5. 查看服务状态"
            GREEN_echo "  0. 返回"
            BLUE_echo "------------------------------------------------------"
            read -p "请输入选项[0-5]: " choice

            case $choice in
            1)
                read -p "请输入要启动的服务名称: " service
                _start_service "$service"
                ;;
            2)
                read -p "请输入要停止的服务名称: " service
                _stop_service "$service"
                ;;
            3)
                read -p "请输入要重启的服务名称: " service
                _restart_service "$service"
                ;;
            4)
                read -p "请输入要重载的服务名称: " service
                _reload_service "$service"
                ;;
            5)
                read -p "请输入要查看的服务名称: " service
                _status_service "$service"
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
# 3. 服务状态监控
monitor_service_status() {
    if [ $# -gt 0 ]; then
        [ $1 = "monitor" ] && service=$2 && interval=${3:-5} && _monitor_service "$service" "$interval"
        [ $1 = "stats" ] && service=$2 && _show_stats "$service"
        [ $1 = "test" ] && service=$2 && _test_response "$service"
        [ $1 = "dashboard" ] && _show_dashboard
    else
        # 主交互逻辑
        while true; do
            BLUE_echo "------------------------------------------------------"
            GREEN_echo "服务状态监控选项:"
            GREEN_echo "  1. 实时监控服务状态"
            GREEN_echo "  2. 查看服务资源占用"
            GREEN_echo "  3. 测试服务响应时间"
            GREEN_echo "  4. 显示监控仪表盘"
            GREEN_echo "  0. 返回"
            BLUE_echo "------------------------------------------------------"
            read -p "请输入选项[0-4]: " choice

            case $choice in
            1)
                read -p "请输入要监控的服务名称: " service
                read -p "请输入监控间隔(秒，默认5): " interval
                _monitor_service "$service" "${interval:-5}"
                ;;
            2)
                read -p "请输入要查看的服务名称: " service
                _show_stats "$service"
                ;;
            3)
                read -p "请输入要测试的服务名称: " service
                _test_response "$service"
                ;;
            4)
                _show_dashboard
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

# 4. 服务日志查看
view_service_logs() {
    if [ $# -gt 0 ]; then
        [ $1 = "latest" ] && service=$2 && lines=${3:-20} && _show_latest_logs "$service" "$lines"
        [ $1 = "filter" ] && service=$2 && since=$3 && until=$4 && _filter_logs_by_time "$service" "$since" "$until"
        [ $1 = "search" ] && service=$2 && keyword=$3 && _search_logs "$service" "$keyword"
        [ $1 = "export" ] && service=$2 && filename=$3 && _export_logs "$service" "$filename"
        [ $1 = "follow" ] && service=$2 && _follow_logs "$service"
    else
        # 主交互逻辑
        while true; do
            BLUE_echo "------------------------------------------------------"
            GREEN_echo "服务日志查看工具选项:"
            GREEN_echo "  1. 查看最新日志"
            GREEN_echo "  2. 按时间范围过滤"
            GREEN_echo "  3. 关键词搜索"
            GREEN_echo "  4. 导出日志"
            GREEN_echo "  5. 实时跟踪模式"
            GREEN_echo "  0. 返回"
            BLUE_echo "------------------------------------------------------"
            read -p "请输入选项[0-5]: " choice
            case $choice in
            1)
                read -p "请输入服务名称: " service
                read -p "请输入显示行数(默认20): " lines
                _show_latest_logs "${service}" "${lines:-20}"
                ;;
            2)
                read -p "请输入服务名称: " service
                read -p "请输入开始时间(格式:YYYY-MM-DD HH:MM:SS): " since
                read -p "请输入结束时间(可选): " until
                _filter_logs_by_time "$service" "$since" "$until"
                ;;
            3)
                read -p "请输入服务名称: " service
                read -p "请输入搜索关键词: " keyword
                _search_logs "$service" "$keyword"
                ;;
            4)
                read -p "请输入服务名称: " service
                read -p "请输入导出文件名: " filename
                _export_logs "$service" "$filename"
                ;;
            5)
                read -p "请输入服务名称: " service
                _follow_logs "$service"
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
# 5. 服务依赖分析
analyze_service_dependencies() {
    if [ $# -gt 0 ]; then
        [ $1 = "tree" ] && service=$2 && _show_dependency_tree "$service"
        [ $1 = "circular" ] && service=$2 && _check_circular_deps "$service"
        [ $1 = "report" ] && service=$2 && _generate_dep_report "$service"
    else
        # 主交互逻辑
        while true; do
            BLUE_echo "------------------------------------------------------"
            GREEN_echo "服务依赖分析选项:"
            GREEN_echo "  1. 显示服务依赖树"
            GREEN_echo "  2. 检查循环依赖"
            GREEN_echo "  3. 生成依赖分析报告"
            GREEN_echo "  0. 返回"
            BLUE_echo "------------------------------------------------------"
            read -p "请输入选项[0-3]: " choice

            case $choice in
            1)
                read -p "请输入服务名称: " service
                _show_dependency_tree "$service"
                ;;
            2)
                read -p "请输入服务名称: " service
                _check_circular_deps "$service"
                ;;
            3)
                read -p "请输入服务名称: " service
                _generate_dep_report "$service"
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

# 6. 服务自动启动配置
configure_service_autostart() {
    if [ $# -gt 0 ]; then
        [ $2 = "check" ] && service=$1 && _check_autostart "$service"
        [ $2 = "enable" ] && service=$1 && _toggle_autostart "$service" "enable"
        [ $2 = "disable" ] && service=$1 && _toggle_autostart "$service" "disable"
        [ $2 = "batch" ] && config_file=$1 && action=$3 && _batch_configure "$config_file" "$action"
    else
        # 主交互逻辑
        while true; do
            BLUE_echo "------------------------------------------------------"
            GREEN_echo "服务自动启动配置选项:"
            GREEN_echo "  1. 检查服务启动状态"
            GREEN_echo "  2. 启用服务开机启动"
            GREEN_echo "  3. 禁用服务开机启动"
            GREEN_echo "  4. 批量修改启动配置"
            GREEN_echo "  0. 返回"
            BLUE_echo "------------------------------------------------------"
            read -p "请输入选项[0-4]: " choice

            case $choice in
            1)
                read -p "请输入服务名称: " service
                _check_autostart "$service"
                ;;
            2)
                read -p "请输入要启用的服务名称: " service
                _toggle_autostart "$service" "enable"
                ;;
            3)
                read -p "请输入要禁用的服务名称: " service
                _toggle_autostart "$service" "disable"
                ;;
            4)
                read -p "请输入包含服务列表的文件: " config_file
                read -p "启用(e)或禁用(d)服务? [e/d]: " action
                [ "$action" = "e" ] && action="enable" || action="disable"
                _batch_configure "$config_file" "$action"
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

install_uninstall_service() {
    if [ $# -gt 0 ]; then
        [ $1 = "docker" ] && _install_docker
        [ $1 = "ckautotask" ] && installtype=$2 && _ckautotask_installer $installtype
    else
        while true; do
            BLUE_echo "------------------------------------------------------"
            GREEN_echo "常规服务安装:"
            GREEN_echo "  1. Docker 服务安装"
            GREEN_echo "  2. ckautotask 服务安装/卸载"
            GREEN_echo "  0. 返回"
            BLUE_echo "------------------------------------------------------"
            read -p "请输入选项[0-4]: " choice

            case $choice in
            1)
                _install_docker
                ;;
            2)
                GREEN_echo "ckautotask 服务目录, 请选择操作:"
                GREEN_echo "  1. 安装服务"
                GREEN_echo "  2. 卸载服务"
                GREEN_echo "  3. 查看服务"
                read -p "请输入操作[1-3]: " action_choice
                case $action_choice in
                1) action="install" ;;
                2) action="uninstall" ;;
                3) action="show" ;;
                *)
                    RED_echo "无效选择"
                    continue
                    ;;
                esac
                [ $action = "install" ] && _ckautotask_installer
                [ $action = "uninstall" ] && _ckautotask_installer "c"
                [ $action = "show" ] && _show_service_description "ckautotask.service"
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

        RED_echo "无效选项"
    fi
}

# 显示所有服务功能模块
_display_services() {
    local status_filter=$1
    local output_file=$2

    blue_echo "------------------------------------------------------"
    # 构建基础命令
    local cmd="systemctl list-units --type=service --all"

    # 添加状态过滤条件
    if [[ -n "$status_filter" ]]; then
        case "$status_filter" in
        "running") cmd+=" --state=running" ;;
        "stopped") cmd+=" --state=inactive" ;;
        "failed") cmd+=" --state=failed" ;;
        esac
    fi

    # 添加完整输出格式
    cmd+=" --no-pager --plain --no-legend"

    # 执行命令并处理结果
    local services
    services=$(eval "$cmd" 2>&1)
    if [[ $? -ne 0 ]]; then
        red_echo "获取服务列表失败: $services"
        blue_echo "------------------------------------------------------"

        return 1
    fi

    # 显示或导出结果
    if [[ -n "$output_file" ]]; then
        echo "$services" >"$output_file"
        green_echo "服务列表已导出到: $output_file"
    else
        # 分页显示
        echo "$services" | less -R
    fi
    blue_echo "------------------------------------------------------"
}

# 显示服务描述信息
_show_service_description() {
    local service_name=$1
    # 定义需要提取的属性列表（逗号分隔）
    blue_echo "------------------------------------------------------"
    sudo systemctl status $service_name
    blue_echo "------------------------------------------------------"

}

_check_autostart() {
    local service=$1
    blue_echo "------------------------------------------------------"
    green_echo "检查服务启动配置: $service"
    systemctl is-enabled "$service"
}

_toggle_autostart() {
    local service=$1
    local action=$2
    blue_echo "------------------------------------------------------"
    if [ "$action" = "enable" ]; then
        green_echo "启用服务开机启动: $service"
        systemctl enable "$service"
    else
        yellow_echo "禁用服务开机启动: $service"
        systemctl disable "$service"
    fi
    check_command "修改启动配置"
}

_batch_configure() {
    local config_file=$1
    blue_echo "------------------------------------------------------"
    green_echo "批量修改启动配置"
    while IFS= read -r service; do
        _toggle_autostart "$service" "$2"
    done <"$config_file"
}

# 子函数实现
_start_service() {
    local service=$1
    BLUE_echo "------------------------------------------------------"
    yellow_echo "正在启动服务: $service"
    sudo systemctl start "$service"
    check_command "启动服务 $service"
    _status_service "$service"
}

_stop_service() {
    local service=$1
    BLUE_echo "------------------------------------------------------"
    yellow_echo "正在停止服务: $service"
    sudo systemctl stop "$service"
    check_command "停止服务 $service"
    _status_service "$service"
}

_restart_service() {
    local service=$1
    BLUE_echo "------------------------------------------------------"
    yellow_echo "正在重启服务: $service"
    sudo systemctl restart "$service"
    check_command "重启服务 $service"
    _status_service "$service"
}

_reload_service() {
    local service=$1
    BLUE_echo "------------------------------------------------------"
    yellow_echo "正在重载服务: $service"
    sudo systemctl reload "$service"
    check_command "重载服务 $service"
    _status_service "$service"
}

_status_service() {
    local service=$1
    BLUE_echo "------------------------------------------------------"
    yellow_echo "服务状态: $service"
    sudo systemctl status "$service" --no-pager
    check_command "查看服务状态 $service"
}

# 显示最新日志
_show_latest_logs() {
    local service=$1
    local lines=$2

    BLUE_echo "------------------------------------------------------"
    yellow_echo "正在获取 ${service} 服务的最新 ${lines} 行日志..."

    if ! systemctl is-active "$service" >/dev/null 2>&1; then
        red_echo "错误: 服务 ${service} 未运行或不存在"
        return 1
    fi

    journalctl -u "$service" -n "$lines" --no-pager
    check_command "获取 ${service} 服务日志"
}

# 按时间范围过滤日志
_filter_logs_by_time() {
    local service=$1
    local since=$2
    local until=${3:-"now"}

    BLUE_echo "------------------------------------------------------"
    yellow_echo "正在过滤 ${service} 服务 ${since} 至 ${until} 的日志..."

    if ! systemctl is-active "$service" >/dev/null 2>&1; then
        red_echo "错误: 服务 ${service} 未运行或不存在"
        return 1
    fi

    journalctl -u "$service" --since "$since" --until "$until" --no-pager
    check_command "按时间过滤 ${service} 服务日志"
}

# 关键词搜索日志
_search_logs() {
    local service=$1
    local keyword=$2

    BLUE_echo "------------------------------------------------------"
    yellow_echo "正在搜索 ${service} 服务包含 '${keyword}' 的日志..."

    if ! systemctl is-active "$service" >/dev/null 2>&1; then
        red_echo "错误: 服务 ${service} 未运行或不存在"
        return 1
    fi

    journalctl -u "$service" -g "$keyword" --no-pager
    check_command "搜索 ${service} 服务日志"
}

# 导出日志到文件
_export_logs() {
    local service=$1
    local filename=$2

    BLUE_echo "------------------------------------------------------"
    yellow_echo "正在导出 ${service} 服务日志到 ${filename}..."

    if ! systemctl is-active "$service" >/dev/null 2>&1; then
        red_echo "错误: 服务 ${service} 未运行或不存在"
        return 1
    fi

    journalctl -u "$service" --no-pager >"$filename"
    check_command "导出 ${service} 服务日志"
    green_echo "日志已成功导出到 ${filename}"
}

# 实时跟踪日志
_follow_logs() {
    local service=$1

    BLUE_echo "------------------------------------------------------"
    yellow_echo "开始实时跟踪 ${service} 服务日志 (Ctrl+C 退出)..."

    if ! systemctl is-active "$service" >/dev/null 2>&1; then
        red_echo "错误: 服务 ${service} 未运行或不存在"
        return 1
    fi

    journalctl -u "$service" -f
}

_show_dependency_tree() {
    local service=$1
    blue_echo "------------------------------------------------------"
    green_echo "服务依赖树分析: $service"
    systemctl list-dependencies --all "$service"
    check_command "显示服务依赖树"
}

_check_circular_deps() {
    local service=$1
    blue_echo "------------------------------------------------------"
    green_echo "检查循环依赖: $service"
    # 使用systemd-analyze检查循环依赖
    systemd-analyze verify "$service" | grep -i "cycle" || yellow_echo "未检测到循环依赖"
}

_generate_dep_report() {
    local service=$1
    local report_file="dependency_report_${service}_$(date +%Y%m%d).txt"
    blue_echo "------------------------------------------------------"
    green_echo "生成依赖分析报告: $report_file"
    {
        echo "===== 服务依赖分析报告 ====="
        echo "生成时间: $(date)"
        echo "目标服务: $service"
        echo ""
        echo "=== 依赖树 ==="
        systemctl list-dependencies --all "$service"
        echo ""
        echo "=== 循环依赖检查 ==="
        systemd-analyze verify "$service" | grep -i "cycle" || echo "未检测到循环依赖"
    } >"$report_file"
    green_echo "报告已生成: $report_file"
}

# 子函数实现
_monitor_service() {
    local service=$1
    local interval=$2

    BLUE_echo "------------------------------------------------------"
    yellow_echo "开始监控服务: $service (间隔: ${interval}秒)"
    BLUE_echo "------------------------------------------------------"
    echo "按 Ctrl+C 停止监控..."

    while true; do
        local status=$(systemctl is-active "$service")
        local cpu=$(ps -C "$service" -o %cpu --no-headers | awk '{sum+=$1} END {print sum}')
        local mem=$(ps -C "$service" -o %mem --no-headers | awk '{sum+=$1} END {print sum}')

        if [ "$status" != "active" ]; then
            red_echo "[异常] 服务状态: $status | CPU: ${cpu:-0}% | 内存: ${mem:-0}%"
        else
            green_echo "[正常] 服务状态: $status | CPU: ${cpu:-0}% | 内存: ${mem:-0}%"
        fi

        sleep "$interval"
    done
}

_show_stats() {
    local service=$1

    BLUE_echo "------------------------------------------------------"
    yellow_echo "服务资源占用统计: $service"
    BLUE_echo "------------------------------------------------------"

    # 1. 显示systemd服务状态
    yellow_echo "[服务状态]"
    systemctl status "$service" --no-pager
    echo ""

    # 2. 显示进程树
    yellow_echo "[进程树]"
    pstree -p $(pgrep -d, "$service") 2>/dev/null || red_echo "无法获取进程树信息"
    echo ""

    # 3. 显示详细的进程资源占用
    yellow_echo "[进程资源占用]"
    echo "PID     USER    CPU%  MEM%  VSZ     RSS    THREADS  STARTED  COMMAND"
    ps -u -p $(pgrep -d, "$service") -o pid,user,%cpu,%mem,vsz,rss,nlwp,lstart,cmd --sort=-%cpu 2>/dev/null |
        awk 'NR>1 {printf "%-6s %-8s %-5s %-5s %-7s %-7s %-8s %-12s %s\n", $1,$2,$3,$4,$5,$6,$7,$8" "$9" "$10,$11}'
    echo ""

    # 4. 显示汇总统计
    yellow_echo "[资源汇总]"
    local cpu=$(ps -C "$service" -o %cpu --no-headers | awk '{sum+=$1} END {printf "%.1f", sum}')
    local mem=$(ps -C "$service" -o %mem --no-headers | awk '{sum+=$1} END {printf "%.1f", sum}')
    local threads=$(ps -C "$service" -o nlwp --no-headers | awk '{sum+=$1} END {print sum}')
    local processes=$(pgrep "$service" | wc -l)
    local open_files=$(lsof -p $(pgrep -d, "$service") 2>/dev/null | wc -l)

    green_echo "进程数: ${processes:-0}"
    green_echo "CPU总占用: ${cpu:-0}%"
    green_echo "内存总占用: ${mem:-0}%"
    green_echo "线程总数: ${threads:-0}"
    green_echo "打开文件数: ${open_files:-0}"
    echo ""

    # 5. 显示网络连接
    yellow_echo "[网络连接]"
    ss -tulnp | grep "$service" || red_echo "没有网络连接信息"
    echo ""

    # 6. 显示IO统计
    yellow_echo "[磁盘IO]"
    pidstat -d -p $(pgrep -d, "$service") 1 1 2>/dev/null || red_echo "无法获取IO统计"
}

_test_response() {
    local service=$1

    BLUE_echo "------------------------------------------------------"
    yellow_echo "测试服务响应时间: $service"
    BLUE_echo "------------------------------------------------------"

    local start_time=$(date +%s%N)
    systemctl status "$service" --no-pager >/dev/null 2>&1
    local end_time=$(date +%s%N)

    local duration=$(((end_time - start_time) / 1000000))
    green_echo "服务响应时间: ${duration}毫秒"
}

_show_dashboard() {
    BLUE_echo "------------------------------------------------------"
    yellow_echo "服务监控仪表盘"
    BLUE_echo "------------------------------------------------------"

    local services=($(systemctl list-units --type=service --no-pager --no-legend | awk '{print $1}'))
    local total=${#services[@]}
    local active=0

    for service in "${services[@]}"; do
        if systemctl is-active "$service" >/dev/null 2>&1; then
            ((active++))
        fi
    done

    local inactive=$((total - active))

    green_echo "总服务数: $total"
    green_echo "运行中服务: $active"
    red_echo "停止的服务: $inactive"
    echo ""

    # 显示前5个CPU占用最高的服务
    yellow_echo "CPU占用最高的服务:"
    echo "CPU%   PID     COMMAND"
    ps -eo %cpu,pid,cmd --sort=-%cpu | head -n 6 | tail -n 5 | awk '{printf "%-6s %-6s %s\n", $1"%", $2, $3}'

    # 显示前5个内存占用最高的服务
    echo ""
    yellow_echo "内存占用最高的服务:"
    echo "MEM%   PID     COMMAND"
    ps -eo %mem,pid,cmd --sort=-%mem | head -n 6 | tail -n 5 | awk '{printf "%-6s %-6s %s\n", $1"%", $2, $3}'
}

# Docker 安装统一走共享库的 install_docker（可配置镜像源、存活探测、幂等）
_install_docker() {
    if declare -F install_docker >/dev/null 2>&1; then
        run_step docker-install install_docker
        return $?
    fi
    RED_echo "缺少 common.sh，无法执行 Docker 安装；请重新安装该 OS 配置"
    return 1
}


_ckautotask_installer() {
    #!/bin/bash
    #region
    #region ========================================================
    # 脚本名称: ckautotask_installer.sh
    # 功能描述:
    #   这是一个用于安装和管理ckbin服务的自动化脚本。
    #   主要功能包括:
    #     1. 卸载旧版本服务(如果存在)
    #     2. 创建服务所需的目录结构
    #     3. 生成主服务脚本(cksvc.sh)
    #     4. 创建并配置systemd服务单元文件
    #     5. 启动并启用新创建的服务
    #
    # ckautotask服务说明:
    #   - 这是一个定时执行各类脚本(sh\python)的服务，支持多种执行频率:
    #     * startup: 只在系统启动时执行一次
    #     * daily: 每天指定时间执行一次(默认7点)
    #     * hourly: 每小时执行一次
    #     * halfday: 每半天执行一次(可配置时间)
    #     * runonce: 只执行一次的脚本(执行后自动重命名)
    #     * running: 每次循环都会执行的持续运行脚本
    #
    #   - 所有执行结果都会记录到日志文件中，路径为:
    #     $BIN_PATH/logs/execution_YYYYMMDD.log
    #
    #   - 服务配置了资源限制:
    #     * CPU使用率不超过10%
    #     * 内存使用不超过50MB
    # 使用方法:
    #   1. 将此脚本复制到目标服务器
    #   2. sudo bash ckautotask_installer.sh c      # 卸载旧服务
    #   3. sudo bash ckautotask_installer.sh        # 卸载旧服务 and 安装新服务
    #endregion ========================================================
    DEPLOY_TYPE=$1

    # 定义服务名称和路径变量
    SERVICE_NAME="ckautotask.service"
    SERVICE_PATH="/usr/lib/systemd/system/$SERVICE_NAME"
    BIN_PATH="/home/ck/ckbin/ckautotask"
    SCRIPT_PATH="$BIN_PATH/ckautotask.sh"
    PAUSETIME="60" # 脚本执行任务轮询检查间隔(单位: 秒)

    # 检查执行权限
    if [ $(id -u) -ne 0 ]; then
        echo "请使用sudo执行本脚本"
        exit 1
    fi

    # 检查ckautotask.sh文件是否存在
    if [ -f "$SCRIPT_PATH" ]; then
        # 卸载服务
        echo "正在卸载旧服务, 并且删除旧服务目录文件..."
        sudo systemctl stop $SERVICE_NAME 2>/dev/null
        sudo systemctl disable $SERVICE_NAME 2>/dev/null
        sudo rm -rf /etc/systemd/system/$SERVICE_NAME 2>/dev/null
        sudo systemctl daemon-reload 2>/dev/null
        sudo rm -rf "$BIN_PATH/" 2>/dev/null

    fi

    if [ $DEPLOY_TYPE = "c" ]; then
        echo "删除旧服务目录文件成功, 退出安装脚本..."
        exit 0
    fi

    # 创建目录和脚本文件
    echo "创建服务目录和脚本..."
    mkdir -p "$BIN_PATH/"{logs,running,startup,daily,runonce,hourly,halfday} 2>/dev/null
    for dir in running startup daily runonce hourly halfday; do
        echo "echo '.sh test script!!!'" >"$BIN_PATH/$dir/test.sh"
        echo "print('python test script!!!')" >"$BIN_PATH/$dir/test.py"
        chmod +x "$BIN_PATH/$dir/test.sh" "$BIN_PATH/$dir/test.py" 2>/dev/null
    done

    # 生成 ckautotask.sh 脚本
    echo "生成 ckautotask.sh..."
    sudo tee "$SCRIPT_PATH" >/dev/null <<EOF
#!/bin/bash
bin="$BIN_PATH"
pausetime=$PAUSETIME            # 设置脚本执行间隔时间(单位: 秒)
last_daily_date="18770101"      # 初始化值, 不用更改
daily_run_hour="7"              # 设置每日执行时间(24小时制)
last_halfday_period="none"      # 初始化值, 不用更改
halfday_run_hour="7"            # 设置执行时间(24小时制),必须小于12,第二次执行时间加12H
last_hourly_time="none"         # 初始化值, 不用更改
is_first_run="true"             # 初始化值, 不用更改

log_message() {
    local script_type=\$1
    local file_path=\$2
    local status=\$3
    local error_result=\$4
    local current_date=\$(date "+%Y%m%d")
    local current_time=\$(date "+%Y%m%d-%H%M%S")
    local log_file="\$bin/logs/execution_\$current_date.log"

    case "\$status" in
            "success")
                echo "\$current_time | \$script_type | success | <\$file_path> 脚本执行完成..." >>"\$log_file"
                ;;
            "failure")
                echo "\$current_time | \$script_type | failure | <\$file_path> 脚本执行失败:(错误码: \$error_result)" >>"\$log_file"
                ;;
            "error_result")
                echo "\$current_time | \$script_type | error_result | <\$file_path> 错误信息: \$error_result" >>"\$log_file"
                ;;
            *)
                echo "\$current_time | \$script_type | skipping | 无待执行脚本.(监控路径: \$bin/\$script_type/)" >>"\$log_file"
                ;;
        esac
}

# 定义执行脚本的函数
execute_scripts() {
    local script_type=\$1     # 脚本类型(startup/daily/runonce/running/hourly/halfday)
    local move_to_backup=\$2  # 是否备份(仅runonce需要)
    
    if [ -z "\$(ls -A "\$bin"/\${script_type}/*.{sh,py} 2>/dev/null)" ]; then
        log_message "\$script_type" "" "no_script"
        return
    fi

    shopt -s nullglob       # 开启nullglob选项, 避免没有匹配文件时出错
    for file in "\$bin"/\${script_type}/*.{sh,py}; do
        local current_time=\$(date "+%Y%m%d-%H%M%S")

        echo "执行脚本: \$file"
        if [[ "\$file" == *.sh ]]; then
            interpreter="bash"
        elif [[ "\$file" == *.py ]]; then
            interpreter="python3"
        fi

        result=\$(sudo "\$interpreter" "\$file" 3>&1 1>/dev/null 2>&3-)
        exit_code=\$?
        
        if [ \$exit_code -eq 0 ]; then
            log_message "\$script_type" "\$file" "success"
            if [ "\$move_to_backup" = "true" ]; then
                mv "\$file" "\$file"_"\${current_time}"
            fi
        else
            log_message "\$script_type" "\$file" "failure" \$exit_code
            log_message "\$script_type" "\$file" "error_result" "\$result"
        fi
    done
    shopt -u nullglob       # 恢复默认设置
}

while true; do
    current_date=\$(date "+%Y%m%d")

    # 1) startup - 开机脚本 (只在服务启动时执行一次)
    if [ "\$is_first_run" = "true" ]; then
        execute_scripts "startup" "false"
        is_first_run="false"
    fi

    # 2) daily - 每日脚本 (每天<\$daily_run_hour>点执行一次)
    current_daily_timestamp=\$((10#\$(date +%H)))
    if [ "\$current_date" != "\$last_daily_date" ] && [ \$current_daily_timestamp -eq \$daily_run_hour ]; then
        execute_scripts "daily" "false"
        last_daily_date="\$current_date"
    fi

   # 3) hourly - 每小时脚本 (每小时执行一次)
    current_hourly_timestamp=\$((10#\$(date +%H)))
	if [ \$current_hourly_timestamp != \$last_hourly_time ]; then    
		execute_scripts "hourly" "false"
        last_hourly_time=\$current_hourly_timestamp
	fi

    # 4) halfday - 每半天脚本 (每半天执行一次)
    current_hour=\$((10#\$(date +%H)))
    current_halfday_period=\$([ "\$current_hour" -lt 12 ] && echo "am" || echo "pm")
    if [ "\$current_halfday_period" != "\$last_halfday_period" ]; then
        # AM/PM时段发生了变化
        if { [ "\$current_halfday_period" = "am" ] && [ \$current_hour -ge \${halfday_run_hour:-0} ]; } || \\
        { [ "\$current_halfday_period" = "pm" ] && [ \$current_hour -ge \$((\${halfday_run_hour:-0} + 12)) ]; }; then
            execute_scripts "halfday" "false"
            last_halfday_period=\$current_halfday_period
        fi
    fi

    # 5) runonce - 执行一次脚本 (执行一次后加时间后缀)
    execute_scripts "runonce" "true"

    # 6) running - 轮询执行脚本 (每次循环都执行) 
    execute_scripts "running" "false"

    unset file current_time current_date error_code  # 及时释放变量
    sudo sync && echo 3 > /proc/sys/vm/drop_caches  # 清理缓存
    wait \$! 2>/dev/null         # 等待子进程结束
    sleep \$pausetime
done
EOF

    chmod +x "$SCRIPT_PATH"

    # 创建服务文件
    sudo tee $SERVICE_PATH >/dev/null <<EOF
[Unit]
Description=The first project about FastAPI, used for uploading documents

[Service]
ExecStart=$SCRIPT_PATH
Restart=always
User=root
Type=simple
WorkingDirectory=$BIN_PATH
MemoryMax=50M
CPUQuota=10%
LimitNOFILE=1024
LimitNPROC=200

StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=$SERVICE_NAME  

[Install]
WantedBy=multi-user.target
EOF

    # 设置文件权限
    chmod 644 $SERVICE_PATH

    # 重新加载systemd配置
    systemctl daemon-reload
    systemctl enable $SERVICE_NAME
    systemctl start $SERVICE_NAME
    systemctl status $SERVICE_NAME | head -n 30

    echo "服务配置完成，可执行以下命令管理服务:"
    echo "启动服务: systemctl start $SERVICE_NAME"
    echo "查看状态: systemctl status $SERVICE_NAME | head -n 30"
    echo "查看系统日志: journalctl -t $SERVICE_NAME"
    # 以下是可选的停止和删除服务的命令:
    #sudo systemctl status $SERVICE_NAME | head -n 30
    #sudo systemctl stop $SERVICE_NAME
    #sudo systemctl disable $SERVICE_NAME
    #sudo rm -rf /etc/systemd/system/$SERVICE_NAME
    #sudo systemctl daemon-reload
    #endregion
}
# endregion
