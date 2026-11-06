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

#region 1) 用户管理
USERS_MGMT() {
    while true; do
        GREEN_echo "========== 用户管理 =========="
        GREEN_echo "  1. 显示所有用户信息"
        GREEN_echo "  2. 查询单个用户信息"
        GREEN_echo "  3. 创建新用户"
        GREEN_echo "  4. 修改用户属性"
        GREEN_echo "  5. 删除用户"
        GREEN_echo "  6. 锁定/解锁用户"
        GREEN_echo "  7. 修改用户密码"
        GREEN_echo "  8. 查看用户组信息"
        GREEN_echo "  9. 用户登录历史"
        GREEN_echo "  10. 用户权限管理"
        GREEN_echo "  11. SSH密钥管理"
        GREEN_echo "  12. 用户会话管理"
        GREEN_echo "  13. 用户磁盘配额"
        GREEN_echo "  14. 密码策略管理"
        GREEN_echo "  0. 返回主菜单"
        read -p "请输入选择: " choice

        case $choice in
        1) echo "" && display_all_users ;;
        2) echo "" && query_single_user ;;
        3) echo "" && create_user ;;
        4) echo "" && modify_user ;;
        5) echo "" && delete_user ;;
        6) echo "" && toggle_user_lock ;;
        7) echo "" && change_password ;;
        8) echo "" && show_groups ;;
        9) echo "" && login_history ;;
        10) echo "" && manage_privileges ;;
        11) echo "" && ssh_key_management ;;
        12) echo "" && user_session_management ;;
        13) echo "" && user_disk_quota ;;
        14) echo "" && password_policy_management ;;
        0) break ;;
        *) YELLOW_echo "无效选择,请重新输入" ;;
        esac
        echo
    done
}

# 显示所有用户信息(表格形式)
display_all_users() {
    white_echo "正在列出所有用户信息..."
    BLUE_echo "--------------------------------------------------------------------------------------------------------"
    printf "%-15s %-10s %-10s %-20s %-20s %-15s\n" "用户名" "UID" "GID" "用户目录" "登录Shell" "所属组"
    WHITE_echo "--------------------------------------------------------------------------------------------------------"

    # 获取所有用户列表
    while IFS=: read -r username _ uid gid _ home shell _; do
        # 跳过系统用户(UID < 1000)
        if [ "$uid" -ge 1000 ] || [ "$uid" -eq 0 ]; then
            # 获取用户所属组
            groups=$(id -nG "$username" | tr ' ' ',')
            # 格式化输出
            printf "%-10s %-10s %-10s %-20s %-20s %-15s\n" "$username" "$uid" "$gid" "$home" "$shell" "$groups"
        fi
    done </etc/passwd
    BLUE_echo "--------------------------------------------------------------------------------------------------------"
}

# 查询单个用户详细信息
query_single_user() {
    if [ $# -gt 0 ]; then
        username="$1"
    else
        # 检查是否有参数传入
        read -p "请输入要查询的用户名: " username
    fi
    white_echo "正在查询用户 $username 的详细信息..."
    BLUE_echo "------------------------------------------------------------------------------"

    # 检查用户是否存在
    user_info=$(getent passwd "$username")
    if [ $? -ne "0" ]; then
        WHITE_echo "用户 $username 不存在"
        BLUE_echo "------------------------------------------------------------------------------"
        return
    fi

    # 解析用户信息
    IFS=':' read -ra fields <<<"$user_info"
    uid=${fields[2]}
    gid=${fields[3]}
    home=${fields[5]}
    shell=${fields[6]}

    # 获取用户组信息
    groups=$(id -nG "$username" | tr ' ' ',')

    # 获取用户登录状态
    login_status=$(who | grep -c "^$username")

    # 获取用户最近登录时间
    last_login=$(last -n 1 "$username" 2>/dev/null | head -n 1 | awk '{print $4" "$5" "$6" "$7}')

    # 获取用户磁盘使用情况
    home_usage=$(du -sh "$home" 2>/dev/null | awk '{print $1}') || home_usage="不可访问"

    # 获取用户锁定情况
    current_status=$(sudo passwd -S "$username" | awk '{print $2}')
    [ "$current_status" = "L" ] && current_status="lock" || current_status="unlock"

    # 显示详细信息
    green_echo "用户名: $username"
    green_echo "用户ID (UID): $uid"
    green_echo "主组ID (GID): $gid"
    green_echo "当前密码状态: $current_status"
    green_echo "所属组: $groups"
    green_echo "家目录: $home"
    green_echo "家目录大小: $home_usage"
    green_echo "登录Shell: $shell"
    green_echo "当前登录状态: $([ "$login_status" -gt 0 ] && echo "已登录 ($login_status 次)" || echo "未登录")"
    green_echo "最近登录时间: ${last_login:-从未登录}"

    # 检查sudo权限
    sudo_status=$(sudo -lU "$username" 2>/dev/null | grep -c "may run")
    green_echo "Sudo权限: $([ "$sudo_status" -gt 0 ] && echo "有" || echo "无")"

    # 检查密码过期信息
    password_info=$(chage -l "$username" 2>/dev/null)
    if [ -n "$password_info" ]; then
        green_echo "密码过期信息:"
        echo "$password_info" | while read -r line; do
            green_echo "  $line"
        done
    fi
    BLUE_echo "------------------------------------------------------------------------------"
}

# 创建用户函数实现
create_user() {
    #sudo bash mgt-god.sh create_user ck01 1112 sudo,ck /home/ck01 /bin/bash 1234@msft.com
    if [ $# -gt 0 ]; then
        username="$1"
        uid="-u $2"
        supplementary_groups="-G $3"
        home_dir="-d $4"
        user_shell="-s $5"
        password="$6"
    else
        # 用户输入基本信息
        read -p "请输入要创建的用户名: " username

        # 检查用户名是否已存在
        if id "$username" &>/dev/null; then
            RED_echo "错误: 用户 $username 已存在"
            return 1
        fi

        # 获取UID (可选)
        read -p "请输入用户UID (留空自动分配): " uid
        [ -n "$uid" ] && uid="-u $uid" || uid=""

        # 获取主组 (可选)
        read -p "请输入主组名/GID (留空创建同名组): " primary_group
        [ -n "$primary_group" ] && primary_group="-g $primary_group"

        # 获取附加组 (可选)
        read -p "请输入附加组(逗号分隔,留空跳过): " supplementary_groups
        [ -n "$supplementary_groups" ] && supplementary_groups="-G $supplementary_groups"

        # 获取家目录 (可选)
        read -p "请输入用户目录路径 (留空使用默认): " home_dir
        [ -n "$home_dir" ] && home_dir="-d $home_dir" || home_dir="-m"

        # 获取默认shell (可选)
        read -p "请输入默认shell (留空使用/bin/bash): " user_shell
        [ -n "$user_shell" ] && user_shell="-s $user_shell" || user_shell="-s /bin/bash"
    fi

    # 确认信息
    white_echo "即将创建用户:"
    white_echo "用户名: $username"
    white_echo "UID: ${uid:-自动分配}"
    white_echo "主组: ${primary_group:-创建同名组}"
    white_echo "附加组: ${supplementary_groups:-无}"
    white_echo "用户目录: ${home_dir##-d }"
    white_echo "默认Shell: ${user_shell##-s }"

    white_echo "将要执行的命令为:"
    white_echo "useradd $uid $primary_group $supplementary_groups $home_dir $user_shell $username"
    GREEN_echo "你有5秒钟的后悔时间(中止: CTRL+C)"
    sleep 8

    # 执行用户创建命令
    white_echo "正在创建用户 $username ..."
    if useradd $uid $primary_group $supplementary_groups $home_dir $user_shell $username; then
        # 设置密码
        encrypted_pass=$(openssl passwd -6 $password)
        sudo usermod --password "$encrypted_pass" "$username"

        # 显示创建结果
        white_echo "用户 $username 创建成功!"
        query_single_user "$username"
    else
        red_echo "用户创建失败!"
        return 1
    fi
}

# 修改用户属性函数实现
modify_user() {
    # 显示所有用户供选择
    display_all_users

    # 获取要修改的用户名
    read -p "请输入要修改的用户名: " username

    # 检查用户是否存在
    if ! id "$username" &>/dev/null; then
        RED_echo "错误: 用户 $username 不存在"
        return 1
    fi

    # 显示当前用户信息
    query_single_user "$username"

    # 修改选项菜单
    while true; do
        echo -e "\n\e[34m===== 可修改属性 =====\e[0m"
        echo "1. 修改用户名"
        echo "2. 修改UID"
        echo "3. 修改主组"
        echo "4. 修改附加组"
        echo "5. 修改家目录"
        echo "6. 修改默认Shell"
        echo "7. 锁定/解锁账户"
        echo "8. 设置密码过期策略"
        echo "9. 返回上级菜单"

        read -p "请选择要修改的属性 (1-9): " option

        case $option in
        1) # 修改用户名
            read -p "请输入新的用户名: " new_name
            if usermod -l "$new_name" "$username"; then
                GREEN_echo "用户名修改成功: $username → $new_name"
                username="$new_name" # 更新当前用户名变量
            else
                RED_echo "用户名修改失败"
            fi
            ;;
        2) # 修改UID
            read -p "请输入新的UID: " new_uid
            if usermod -u "$new_uid" "$username"; then
                GREEN_echo "UID修改成功"
            else
                RED_echo "UID修改失败"
            fi
            ;;
        3) # 修改主组
            read -p "请输入新的主组名/GID: " new_group
            if usermod -g "$new_group" "$username"; then
                GREEN_echo "主组修改成功"
            else
                RED_echo "主组修改失败"
            fi
            ;;
        4) # 修改附加组
            read -p "请输入新的附加组(逗号分隔): " new_groups
            if usermod -G "$new_groups" "$username"; then
                GREEN_echo "附加组修改成功"
            else
                RED_echo "附加组修改失败"
            fi
            ;;
        5) # 修改家目录
            read -p "请输入新的家目录路径: " new_home
            if usermod -d "$new_home" -m "$username"; then
                GREEN_echo "家目录修改成功"
            else
                RED_echo "家目录修改失败"
            fi
            ;;
        6) # 修改默认Shell
            read -p "请输入新的默认Shell: " new_shell
            if usermod -s "$new_shell" "$username"; then
                GREEN_echo "默认Shell修改成功"
            else
                RED_echo "默认Shell修改失败"
            fi
            ;;
        7) # 锁定/解锁账户
            current_status=$(passwd -S "$username" | awk '{print $2}')
            if [ "$current_status" = "L" ]; then
                if usermod -U "$username"; then
                    GREEN_echo "账户已解锁"
                else
                    RED_echo "账户解锁失败"
                fi
            else
                if usermod -L "$username"; then
                    GREEN_echo "账户已锁定"
                else
                    RED_echo "账户锁定失败"
                fi
            fi
            ;;
        8) # 密码过期策略
            echo "设置密码过期策略:"
            read -p "密码有效期(天数): " max_days
            read -p "密码最短使用期(天数): " min_days
            read -p "密码过期前警告天数: " warn_days
            if chage -M "$max_days" -m "$min_days" -W "$warn_days" "$username"; then
                GREEN_echo "密码策略设置成功"
            else
                RED_echo "密码策略设置失败"
            fi
            ;;
        9) # 返回
            break
            ;;
        *)
            RED_echo "无效选项,请重新输入"
            ;;
        esac

        # 显示修改后的用户信息
        query_single_user "$username"
    done
}

# 安全删除用户函数实现
delete_user() {
    #sudo bash mgt-god.sh delete_user ck03
    if [ $# -gt 0 ]; then
        username="$1"
        if userdel -r "$username"; then
            green_echo "用户 $username 及其主目录已删除"
        else
            red_echo "用户 $username 删除失败"
            return 1
        fi
    else
        # 显示所有用户供选择
        display_all_users

        # 获取要删除的用户名
        read -p "请输入要删除的用户名: " username

        # 检查用户是否存在
        if ! id "$username" &>/dev/null; then
            RED_echo "错误: 用户 $username 不存在"
            return 1
        fi

        # 显示用户信息
        query_single_user "$username"

        # 确认删除
        read -p "确定要删除用户 $username 吗？(y/n): " confirm
        [ "$confirm" != "y" ] && return

        # 删除选项
        echo -e "\n\e[33m===== 删除选项 =====\e[0m"
        echo "1. 仅删除用户账户"
        echo "2. 删除用户账户及主目录"
        echo "3. 取消删除"

        read -p "请选择删除方式 (1-3): " delete_option

        case $delete_option in
        1)
            WHITE_echo "正在删除用户 $username (保留主目录)..."
            if userdel "$username"; then
                green_echo "用户 $username 已删除 (主目录保留)"
            else
                red_echo "用户删除失败"
            fi
            ;;
        2)
            WHITE_echo "正在删除用户 $username 及其主目录..."
            if userdel -r "$username"; then
                green_echo "用户 $username 及其主目录已删除"
            else
                red_echo "用户删除失败"
            fi
            ;;
        3)
            WHITE_echo "已取消删除操作"
            return
            ;;
        *)
            RED_echo "无效选项,删除操作已取消"
            return 1
            ;;
        esac

    fi

    # 检查用户组是否需要删除
    if [ -n "$(getent group "$username" | grep ":$username:")" ]; then
        read -p "检测到同名用户组 $username 存在,是否删除？(y/n): " del_group
        if [ "$del_group" = "y" ]; then
            if groupdel "$username"; then
                green_echo "用户组 $username 已删除"
            else
                red_echo "用户组删除失败 (可能仍有其他用户属于该组)"
            fi
        fi
    fi

    # 检查是否删除crontab
    if [ -f "/var/spool/cron/$username" ]; then
        read -p "检测到用户 $username 有crontab任务,是否删除? (y/n): " del_cron
        if [ "$del_cron" = "y" ]; then
            if crontab -r -u "$username"; then
                green_echo "用户 $username 的crontab已删除"
            else
                red_echo "crontab删除失败"
                return 1
            fi
        fi
    fi
}

# 锁定/解锁用户账户函数实现
toggle_user_lock() {
    #sudo bash mgt-god.sh toggle_user_lock ck01 L
    if [ $# -gt 0 ]; then
        username="$1"
        if [ "$2" = "U" ]; then
            usermod -U "$username" && green_echo "用户 $username 已成功解锁" || red_echo "用户 $username 解锁操作失败"
        else
            usermod -L "$username" && green_echo "用户 $username 已成功锁定" || red_echo "用户 $username 锁定操作失败"
        fi
    else
        # 显示所有用户供选择
        display_all_users

        # 获取要操作的用户名
        read -p "请输入要锁定/解锁的用户名: " username

        # 检查用户是否存在
        if ! id "$username" &>/dev/null; then
            red_echo "错误: 用户 $username 不存在"
            return 1
        fi

        # 获取当前锁定状态
        current_status=$(sudo passwd -S "$username" | awk '{print $2}')

        # 根据当前状态执行操作
        if [ "$current_status" = "L" ]; then
            # 当前已锁定,执行解锁
            read -p "用户 $username 当前已锁定,是否要解锁？(y/n): " confirm
            if [ "$confirm" = "y" ]; then
                usermod -U "$username" && green_echo "用户 $username 已成功解锁" || red_echo "用户 $username 解锁操作失败" #当前已锁定,执行解锁
            else
                yellow_echo_echo "已取消解锁操作"
            fi
        else
            # 当前未锁定,执行锁定
            read -p "用户 $username 当前未锁定,是否要锁定？(y/n): " confirm
            if [ "$confirm" = "y" ]; then
                usermod -L "$username" && green_echo "用户 $username 已成功锁定" || red_echo "用户 $username 锁定操作失败" #当前未锁定,是否要锁定
            else
                yellow_echo_echo "已取消锁定操作"
            fi
        fi
    fi
    # 显示更新后的状态
    green_echo "当前账户状态:"
    passwd -S "$username"
}

# 修改用户密码函数实现
change_password() {
    #sudo bash mgt-god.sh change_password ck01 '!@#2wsx3edc'           #密码使用单引号
    if [ $# -gt 0 ]; then
        username=$1
        password=$2
        # 修改密码
        encrypted_pass=$(openssl passwd -6 "$password")
        sudo usermod --password "$encrypted_pass" "$username" && green_echo "用户 $username 的密码已成功修改" || red_echo "用户 $username 密码修改失败" && return 1
    else
        # 显示所有用户供选择
        display_all_users

        # 获取要修改密码的用户名
        read -p "请输入要修改密码的用户名: " username

        # 检查用户是否存在
        if ! id "$username" &>/dev/null; then
            red_echo "错误: 用户 $username 不存在"
            return 1
        fi

        # 检查当前用户权限
        if [ "$(id -u)" -ne 0 ] && [ "$(whoami)" != "$username" ]; then
            red_echo "错误: 只有root用户或账户本人可以修改密码"
            return 1
        fi

        # 密码强度检查函数
        check_password_strength() {
            local password=$1
            local strength=0

            # 长度检查
            if [ ${#password} -ge 12 ]; then
                ((strength++))
            fi

            # 包含大写字母
            if [[ "$password" =~ [A-Z] ]]; then
                ((strength++))
            fi

            # 包含小写字母
            if [[ "$password" =~ [a-z] ]]; then
                ((strength++))
            fi

            # 包含数字
            if [[ "$password" =~ [0-9] ]]; then
                ((strength++))
            fi

            # 包含特殊字符
            if [[ "$password" =~ [^a-zA-Z0-9] ]]; then
                ((strength++))
            fi

            return $strength
        }

        # 输入新密码
        while true; do
            read -sp "请输入新密码: " password1
            echo ""
            read -sp "请再次输入新密码: " password2
            echo ""
            # 检查两次输入是否一致
            if [ "$password1" != "$password2" ]; then
                red_echo "错误: 两次输入的密码不匹配"
                continue
            fi

            # 检查密码强度
            check_password_strength "$password1"
            strength=$?

            if [ "$strength" -lt 3 ]; then
                red_echo "密码强度不足 (评分: $strength/5)"
                red_echo "建议: 密码至少12位, 包含大小写字母、数字和特殊字符"
                read -p "仍要使用弱密码吗？(y/n): " confirm
                [ "$confirm" != "y" ] && continue
            else
                green_echo "密码强度良好 (评分: $strength/5)"
            fi

            break
        done

        # 修改密码
        encrypted_pass=$(openssl passwd -6 $password1)
        sudo usermod --password "$encrypted_pass" "$username" && green_echo "用户 $username 的密码已成功修改" || red_echo "密码修改失败" && return 1
    fi
}

# 显示用户所属组
show_groups() {
    if [ $# -gt 0 ]; then
        username=$1
        primary_group="$(id -gn "$username") (GID: $(id -g "$username"))"
        Gn_group=$(id -Gn "$username")
        blue_echo "主要组: $primary_group | 附加组: $Gn_group"
    else
        # 显示所有用户供选择
        display_all_users

        # 获取要查询的用户名
        read -p "请输入要查询组信息的用户名: " username

        # 检查用户是否存在
        if ! id "$username" &>/dev/null; then
            RED_echo "错误: 用户 $username 不存在"
            return 1
        fi

        # 获取用户组信息
        green_echo "用户 $username 的组信息:"
        blue_echo "------------------------------------------------------------"

        # 显示主要组
        primary_group=$(id -gn "$username")
        white_echo "主要组: $primary_group (GID: $(id -g "$username"))"

        # 显示附加组
        supplementary_groups=$(id -Gn "$username" | sed "s/$primary_group //")
        if [ -n "$supplementary_groups" ]; then
            white_echo "附加组: $supplementary_groups"
        else
            white_echo "附加组: 无"
        fi

        # 显示组详细信息
        # Display detailed group information
        green_echo "组详细信息:"
        blue_echo "------------------------------------------------------------"

        # Process each group the user belongs to
        groups "$username" | tr ' ' '\n' | while read -r group; do
            # Get group details from /etc/group
            group_info=$(getent group "$group")

            # Extract group ID and members
            gid=$(echo "$group_info" | cut -d: -f3)
            members=$(echo "$group_info" | cut -d: -f4)

            # Display group information with proper formatting
            white_echo "$group (GID: $gid)"
            white_echo "成员: ${members:-无}"
        done
        # 显示用户权限信息
        blue_echo "------------------------------------------------------------"
        green_echo "用户权限信息:"
        sudo -l -U "$username" 2>/dev/null || white_echo "无特殊权限"
        blue_echo "------------------------------------------------------------"
    fi
}

# 显示用户登录历史函数实现
login_history() {
    if [ $# -gt 0 ]; then
        username=$1
    else
        # 显示所有用户供选择
        display_all_users

        # 获取要查询的用户名
        read -p "请输入要查询登录历史的用户名: " username
    fi
    # 检查用户是否存在
    if ! id "$username" &>/dev/null; then
        red_echo "错误: 用户 $username 不存在"
        return 1
    fi

    # 显示最近登录信息
    blue_echo "---------------------------------------------------------------"
    green_echo "用户 $username 的登录历史:"

    # 使用last命令显示最近的登录记录
    green_echo "最近登录记录:"
    last -F -n 10 "$username" | awk '{print $1,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15}' | column -t

    # 使用lastlog显示最后一次登录信息
    echo -e "\n"
    blue_echo "---------------------------------------------------------------"
    green_echo "最后一次登录信息:"
    lastlog -u "$username" | awk 'NR==1 || NR==2 {print $1,$3,$4,$5,$6,$7,$8,$9,$10,$11}' | column -t

    # 检查是否登录中
    echo -e "\n"
    blue_echo "---------------------------------------------------------------"
    if who | grep -q "^$username "; then
        green_echo "当前登录状态: 已登录"
        who | grep "^$username " | awk '{print "登录终端:",$2, "登录时间:",$3,$4}'
    else
        green_echo "当前登录状态: 未登录"
    fi

    # 显示失败的登录尝试(需要root权限)
    blue_echo "---------------------------------------------------------------"
    if [ "$(id -u)" -eq 0 ]; then
        echo -e "\n"
        yellow_echo "失败的登录尝试:"
        lastb -F -n 5 "$username" 2>/dev/null || WHITE_echo "无失败登录记录"
    else
        echo -e "\n"
        yellow_echo "提示: 需要root权限查看失败登录记录"
    fi
    blue_echo "---------------------------------------------------------------"
}

# 用户权限管理函数实现
manage_privileges() {
    #sudo bash mgt-god.sh manage_privileges ck test
    if [ $# -gt 0 ]; then
        username=$1
        [ $2 = "add" ] && sudo usermod -aG sudo "$username" && gree_echo "权限添加成功($username)"
        [ $2 = "del" ] && sudo deluser "$username" sudo && gree_echo "权限移除成功($username)"
        [ $2 = "test" ] && sudo -l -U "$username" | grep -q "(ALL) NOPASSWD: ALL" && green_echo "测试通过($username)"
    else
        # 显示所有用户供选择
        display_all_users

        # 获取要管理的用户名
        read -p "请输入要管理权限的用户名: " username

        # 检查用户是否存在
        if ! id "$username" &>/dev/null; then
            red_echo "错误: 用户 $username 不存在"
            return 1
        fi

        while true; do
            blue_echo "===== 用户权限管理 [$username] ====="
            blue_echo "  1. 查看当前权限"
            blue_echo "  2. 添加sudo权限"
            blue_echo "  3. 移除sudo权限"
            blue_echo "  4. 测试sudo权限"
            blue_echo "  5. 返回上级菜单"
            read -p "请输入选择: " choice

            case $choice in
            1) # 查看当前权限
                gree_echo "用户 $username 的权限信息:"
                blue_echo "--------------------------------"
                sudo -l -U "$username" 2>/dev/null || white_echo "无特殊权限"
                ;;
            2) # 添加sudo权限
                if grep -q "^$username" /etc/sudoers /etc/sudoers.d/* 2>/dev/null; then
                    yellow_echo "用户 $username 已有sudo权限"
                else
                    if sudo usermod -aG sudo "$username"; then
                        green_echo "成功添加sudo权限"
                    else
                        red_echo "添加sudo权限失败"
                    fi
                fi
                ;;
            3) # 移除sudo权限
                if ! grep -q "^$username" /etc/sudoers /etc/sudoers.d/* 2>/dev/null; then
                    yellow_echo "用户 $username 没有sudo权限"
                else
                    if sudo deluser "$username" sudo; then
                        green_echo "成功移除sudo权限"
                    else
                        red_echo "移除sudo权限失败"
                    fi
                fi
                ;;
            4) # 测试sudo权限
                white_echo "测试用户 $username 的sudo权限..."
                if sudo -l -U "$username" | grep -q "(ALL) NOPASSWD: ALL"; then
                    green_echo "测试通过: 用户 $username 有sudo权限"
                else
                    red_echo "测试失败: 用户 $username 没有sudo权限"
                fi
                ;;
            5) # 返回
                break
                ;;
            *) # 无效输入
                red_echo "无效选择,请重新输入"
                ;;
            esac
        done
    fi
}

# SSH密钥管理函数实现
ssh_key_management() {
    if [ $# -gt 0 ]; then
        username=$1
        [ $2 = "cat" ] && cat "/home/$username/.ssh/authorized_keys"
        [ $2 = "add" ] && echo "$3" >>"/home/$username/.ssh/authorized_keys"
        [ $2 = "gen" ] && sudo -u "$username" ssh-keygen -t "rsa" -b "4096" -C "SSH Login cert" -f "/home/$username/.ssh/id_rsa" && gree_echo "成功" ||
            red_echo "你失败啦!!!"
        [ $2 = "zw" ] && ssh-keygen -lf "/home/$username/.ssh/id_rsa" && green_echo "指纹来自id_rsa文件" ||
            ssh-keygen -lf "/home/$username/.ssh/authorized_keys" && green_echo "指纹来自authorized_keys文件"
    else
        # 显示所有用户供选择
        display_all_users

        # 获取要管理的用户名
        read -p "请输入要管理SSH密钥的用户名: " username

        # 检查用户是否存在
        if ! id "$username" &>/dev/null; then
            red_echo "错误: 用户 $username 不存在"
            return 1
        fi

        # 检查用户是否有home目录
        if [ ! -d "/home/$username" ]; then
            yellow_echo "错误: 用户 $username 没有home目录,开始创建用户目录..."
            mkdir -p "/home/$username/.ssh"
            sudo cp -r /etc/skel/. "/home/$username/"
            chown "$username:$username" "/home/$username/.ssh"
            chmod 700 "/home/$username/.ssh"
            sudo chown -R ck:ck /home/ck
            sudo chmod 755 /home/ck
        fi

        while true; do
            blue_echo "===== SSH密钥管理 [$username] ====="
            blue_echo "  1. 查看现有密钥"
            blue_echo "  2. 添加新公钥"
            blue_echo "  3. 删除公钥"
            blue_echo "  4. 生成新密钥对"
            blue_echo "  5. 查看密钥指纹"
            blue_echo "  6. 返回上级菜单"
            read -p "请输入选择: " choice

            case $choice in
            1) # 查看现有密钥
                green_echo "用户 $username 的SSH公钥:"
                blue_echo "--------------------------------"
                if [ -f "/home/$username/.ssh/authorized_keys" ]; then
                    cat "/home/$username/.ssh/authorized_keys"
                else
                    yellow_echo "没有配置SSH公钥"
                fi
                ;;
            2) # 添加新公钥
                read -p "请输入要添加的公钥内容: " pubkey
                if echo "$pubkey" >>"/home/$username/.ssh/authorized_keys"; then
                    chown "$username:$username" "/home/$username/.ssh/authorized_keys"
                    chmod 600 "/home/$username/.ssh/authorized_keys"
                    green_echo "公钥添加成功"
                else
                    red_echo "公钥添加失败"
                fi
                ;;
            3) # 删除公钥
                if [ ! -f "/home/$username/.ssh/authorized_keys" ]; then
                    blue_echo "没有可删除的公钥"
                    continue
                fi

                green_echo "当前公钥列表:"
                nl "/home/$username/.ssh/authorized_keys"
                read -p "请输入要删除的公钥行号: " line_num

                if sed -i "${line_num}d" "/home/$username/.ssh/authorized_keys"; then
                    green_echo "公钥删除成功"
                else
                    red_echo "公钥删除失败"
                fi
                ;;
            4) # 生成新密钥对
                read -p "请输入密钥类型 (默认rsa): " key_type
                key_type=${key_type:-rsa}
                read -p "请输入密钥位数 (默认4096): " key_bits
                key_bits=${key_bits:-4096}
                read -p "请输入密钥注释 (可选): " key_comment

                key_file="/home/$username/.ssh/id_${key_type}"
                if [ -f "$key_file" ]; then
                    read -p "密钥文件已存在,是否覆盖? (y/N): " overwrite
                    if [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
                        continue
                    fi
                fi

                if sudo -u "$username" ssh-keygen -t "$key_type" -b "$key_bits" -C "$key_comment" -f "$key_file"; then
                    green_echo "密钥对生成成功"
                    green_echo "公钥内容:"
                    cat "${key_file}.pub"
                else
                    red_echo "密钥对生成失败"
                fi
                ;;
            5) # 查看密钥指纹
                if [ -f "/home/$username/.ssh/authorized_keys" ]; then
                    green_echo "公钥指纹:"
                    ssh-keygen -lf "/home/$username/.ssh/authorized_keys"
                fi
                if [ -f "/home/$username/.ssh/id_rsa" ]; then
                    green_echo "RSA私钥指纹:"
                    ssh-keygen -lf "/home/$username/.ssh/id_rsa"
                fi
                if [ -f "/home/$username/.ssh/id_ecdsa" ]; then
                    green_echo "ECDSA私钥指纹:"
                    ssh-keygen -lf "/home/$username/.ssh/id_ecdsa"
                fi
                if [ -f "/home/$username/.ssh/id_ed25519" ]; then
                    green_echo "ED25519私钥指纹:"
                    ssh-keygen -lf "/home/$username/.ssh/id_ed25519"
                fi
                ;;
            6) # 返回
                break
                ;;
            *) # 无效输入
                red_echo "无效选择,请重新输入"
                ;;
            esac
        done
    fi
}

# 用户会话管理函数
user_session_management() {
    while true; do
        echo "===== 用户会话管理 ====="
        echo "  1. 显示所有活跃会话"
        echo "  2. 终止指定会话"
        echo "  3. 查看会话详情"
        echo "  4. 返回上级菜单"
        read -p "请输入选择: " choice

        case $choice in
        1) # 显示所有活跃会话
            green_echo "当前活跃用户会话:"
            blue_echo "--------------------------------"
            if command -v who &>/dev/null; then
                printf "%-10s %-10s %-20s %-15s %-20s\n" "用户" "终端" "登录时间" "来源IP" "会话ID"
                who -u | awk '{printf "%-10s %-10s %-20s %-15s %-20s\n", $1, $2, $3" "$4, $5, $6}'
            else
                red_echo "who命令不可用"
            fi
            ;;

        2) # 终止指定会话
            green_echo "当前活跃会话:"
            who -u
            read -p "请输入要终止的会话终端名(如pts/1): " terminal

            if [[ -z "$terminal" ]]; then
                red_echo "终端名不能为空"
                continue
            fi

            # 查找会话对应的PID
            pid=$(ps -t "$terminal" -o pid= | head -n 1)

            if [[ -z "$pid" ]]; then
                red_echo "找不到指定终端的会话"
            else
                read -p "确认要终止终端 $terminal 的会话(PID: $pid)? (y/N): " confirm
                if [[ "$confirm" =~ ^[Yy]$ ]]; then
                    if kill -9 "$pid"; then
                        green_echo "会话终止成功"
                    else
                        red_echo "会话终止失败"
                    fi
                fi
            fi
            ;;

        3) # 查看会话详情
            green_echo "当前活跃会话:"
            who -u
            read -p "请输入要查看的用户名: " username

            if [[ -z "$username" ]]; then
                red_echo "用户名不能为空"
                continue
            fi

            green_echo "用户 $username 的会话详情:"
            blue_echo "--------------------------------"

            # 显示登录历史
            green_echo "最近登录记录:"
            last "$username" | head -n 5

            # 显示当前会话
            green_echo "当前会话:"
            who -u | grep "^$username"

            # 显示进程信息
            green_echo "相关进程:"
            pgrep -u "$username" | xargs ps -fp 2>/dev/null || green_echo "没有找到相关进程"
            ;;

        4) # 返回
            break
            ;;

        *) # 无效输入
            red_echo "无效选择,请重新输入"
            ;;
        esac
    done
}

# 用户磁盘配额管理函数实现
user_disk_quota() {
    while true; do
        echo "===== 用户磁盘配额管理 ====="
        echo "  1. 查看用户配额"
        echo "  2. 设置用户配额"
        echo "  3. 配额警告设置"
        echo "  4. 返回上级菜单"
        read -p "请输入选择: " choice

        case $choice in
        1) # 查看用户配额
            if ! command -v quota &>/dev/null; then
                red_echo "配额工具未安装, 请先安装quota包"
                continue
            fi

            display_all_users
            read -p "请输入要查看的用户名: " username

            if ! id "$username" &>/dev/null; then
                red_echo "错误: 用户 $username 不存在"
                continue
            fi

            green_echo "用户 $username 的磁盘配额:"
            echo "--------------------------------"
            sudo quota -uvs "$username" 2>/dev/null ||
                yellow_echo "该用户没有设置磁盘配额"
            ;;

        2) # 设置用户配额
            if ! command -v setquota &>/dev/null; then
                red_echo "配额工具未安装, 请先安装quota包"
                continue
            fi

            display_all_users
            read -p "请输入要设置的用户名: " username

            if ! id "$username" &>/dev/null; then
                red_echo "错误: 用户 $username 不存在"
                continue
            fi

            read -p "请输入块软限制(MB): " block_soft
            read -p "请输入块硬限制(MB): " block_hard
            read -p "请输入inode软限制: " inode_soft
            read -p "请输入inode硬限制: " inode_hard

            # 转换为1K blocks
            block_soft=$((block_soft * 1024))
            block_hard=$((block_hard * 1024))

            if sudo setquota -u "$username" "$block_soft" "$block_hard" "$inode_soft" "$inode_hard" /; then
                green_echo "配额设置成功"
            else
                red_echo "配额设置失败"
            fi
            ;;

        3) # 配额警告设置
            green_echo "\e[36m当前系统配额警告设置:"
            echo "--------------------------------"
            grep -E "^[[:space:]]*quota[[:space:]]" /etc/login.defs 2>/dev/null ||
                yellow_echo "没有找到配额警告设置"

            read -p "是否要修改配额警告设置? (y/N): " confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                read -p "请输入警告天数(默认7): " warn_days
                warn_days=${warn_days:-7}

                if sudo sed -i "/^[[:space:]]*quota[[:space:]]/d" /etc/login.defs; then
                    echo "quota $warn_days" | sudo tee -a /etc/login.defs >/dev/null
                    green_echo "配额警告设置更新成功"
                else
                    red_echo "配额警告设置更新失败"
                fi
            fi
            ;;

        4) # 返回
            break
            ;;

        *) # 无效输入
            red_echo"无效选择,请重新输入"
            ;;
        esac
    done
}

# 密码策略管理函数实现
password_policy_management() {
    #sudo bash mgt-god.sh password_policy_management cat
    #sudo bash mgt-god.sh password_policy_management complexity 8 1 1 1 1 2 2

    if [ $# -gt 0 ]; then
        [ $1 = "cat" ] && _get_password_complexity
        [ $1 = "complexity" ] && minlen=${2:-8} && ucredit="-$3" && dcredit="-$4" && lcredit="-$5" && ocredit="-$6" && maxrepeat=$7 && difok=${8:-3} &&
            _change_password_complexity "${minlen:-8}" $ucredit $dcredit $lcredit $ocredit $maxrepeat "${difok:-3}"
        [ $1 = "passmaxday" ] && max_days=$2 && min_days=$3 && warn_age=$4 && _change_password_complexity_passmaxday $max_days $min_days $warn_age
        [ $1 = "remember" ] && remember=$2 && _change_password_complexity_remember "$remember"
    else
        while true; do
            echo "==== 密码策略管理 ====="
            echo "  1. 查看当前策略"
            echo "  2. 修改密码复杂度"
            echo "  3. 设置密码有效期"
            echo "  4. 密码历史设置"
            echo "  5. 返回上级菜单"
            read -p "请输入选择: " choice

            case $choice in
            1) # 查看当前策略
                green_echo "当前密码策略:"
                blue_echo "--------------------------------------------------------------------------"
                _get_password_complexity || red_echo "失败,请检查输入或权限."
                ;;

            2) # 修改密码复杂度
                blue_echo "--------------------------------------------------------------------------"
                read -p "是否要修改密码复杂度? (y/N): " confirm
                if [[ "$confirm" =~ ^[Yy]$ ]]; then
                    echo "中途想返回?(CTRL + C 滚蛋!!!)"
                    read -p "最小长度(默认8): " minlen
                    read -p "数字要求(0-取消 1-需要): " dcredit
                    read -p "大写字母要求(0-取消 1-需要): " ucredit
                    read -p "小写字母要求(0-取消 1-需要): " lcredit
                    read -p "特殊字符要求(0-取消 1-需要): " ocredit
                    read -p "允许连续重复的字符(默认:3): " maxrepeat
                    read -p "拒绝与旧密码相似(默认:3): " difok

                    [ $dcredit = "1" ] && dcredit="-1"
                    [ $ucredit = "1" ] && ucredit="-1"
                    [ $lcredit = "1" ] && lcredit="-1"
                    [ $ocredit = "1" ] && ocredit="-1"
                    maxrepeat=${maxrepeat:-3}

                    _change_password_complexity "${minlen:-8}" $ucredit $dcredit $lcredit $ocredit $maxrepeat "${difok:-3}" || red_echo "修改失败,请检查输入或权限." && return 1
                    green_echo "密码复杂度更新成功"
                fi
                blue_echo "--------------------------------------------------------------------------"
                ;;

            3) # 设置密码有效期
                blue_echo "--------------------------------------------------------------------------"
                green_echo "当前密码有效期:"
                grep -E "^PASS_MAX_DAYS|^PASS_MIN_DAYS|^PASS_WARN_AGE" /etc/login.defs ||
                    red_echo "没有找到密码有效期配置"

                read -p "是否要修改密码有效期? (y/N): " confirm
                if [[ "$confirm" =~ ^[Yy]$ ]]; then
                    read -p "密码最大有效期(天\默认:90): " max_days
                    read -p "密码最小有效期(天\默认:7): " min_days
                    read -p "密码过期前警告(天\默认:15): " warn_age

                    _change_password_complexity_passmaxday "$max_days" "$min_days" "$warn_age" || {
                        red_echo "失败,请检查输入或权限."
                        return 1
                    }
                    green_echo "密码有效期设置已更新"
                fi
                blue_echo "--------------------------------------------------------------------------"

                ;;

            4) # 密码历史设置
                blue_echo "--------------------------------------------------------------------------"
                PAM_COMMON_PASSWORD="/etc/pam.d/common-password" # PAM密码配置文件路径
                read -p "是否要修改密码历史设置? (y/N): " confirm
                if [[ "$confirm" =~ ^[Yy]$ ]]; then
                    read -p "要记住的历史密码数量(0-取消): " remember
                    [ "$remember" = "0" ] && return 0
                    _change_password_complexity_remember "$remember" || {
                        red_echo "修改失败,请检查输入或权限."
                        return 1
                    }
                    green_echo "密码历史设置已更新"
                else
                    green_echo "已经取消!!!"
                fi
                blue_echo "--------------------------------------------------------------------------"

                ;;

            5) # 返回
                break
                ;;

            *) # 无效输入
                red_echo "无效选择, 请重新输入"
                ;;
            esac
        done
    fi
}

#原子化操作
_get_password_complexity() {
    # PAM配置
    if [ -f "/etc/pam.d/common-password" ]; then
        green_echo "PAM密码复杂度:"
        grep -E "password.*pam_pwquality" /etc/pam.d/common-password ||
            grep -E "password.*pam_cracklib" /etc/pam.d/common-password ||
            red_echo "没有找到PAM密码复杂度配置"
        sudo cat /etc/security/pwquality.conf || red_echo "没有找到密码复杂度规则配置"
    fi

    # login.defs配置
    green_echo "密码有效期:"
    grep -E "^PASS_MAX_DAYS|^PASS_MIN_DAYS|^PASS_WARN_AGE" /etc/login.defs ||
        red_echo "没有找到密码有效期配置"
    blue_echo "--------------------------------------------------------------------------"

}

_change_password_complexity() {
    local minlen=${1:-"10"}   #密码最小长度
    local ucredit=${2:-"-1"}  #至少包含一个大写字母
    local dcredit=${3:-"-1"}  #至少包含一个数字
    local lcredit=${4:-"-1"}  #至少包含一个小写字母
    local ocredit=${5:-"-1"}  #至少包含一个特殊字符
    local maxrepeat=${6:-"3"} #拒绝连续重复字符(如aaa)
    local difok=${7:-"3"}     #拒绝与旧密码相似

    sudo apt install -y cracklib-runtime libpam-pwquality
    PAM_COMMON_PASSWORD="/etc/pam.d/common-password" # PAM密码配置文件路径
    CONFIG_FILE="/etc/security/pwquality.conf"       # 密码复杂性规则配置文件

    sed -i '/^password\s\+.*pam_cracklib\.so/d' "$PAM_COMMON_PASSWORD" || gree_echo "删除旧配置失败(pam_cracklib)" #被pam_cracklib替换掉了不用了.
    sed -i '/^password\s\+.*pam_pwquality\.so/d' "$PAM_COMMON_PASSWORD" || gree_echo "删除旧配置失败(pam_pwquality)"
    echo "password    requisite           pam_pwquality.so retry=3 minlen=$minlen ucredit=$ucredit lcredit=$lcredit dcredit=$dcredit ocredit=$ocredit difok=$difok enforce_for_root" >>"$PAM_COMMON_PASSWORD" || {
        red_echo "写入失败(pam_pwquality)"
        return 1
    }
    sed -i '/^minlen/d' "$CONFIG_FILE" && echo "minlen = $minlen" >>"$CONFIG_FILE" && gree_echo "minlen 更新成功" || red_echo "minlen 更新失败"
    sed -i '/^ucredit/d' "$CONFIG_FILE" && echo "ucredit = $ucredit" >>"$CONFIG_FILE" && gree_echo "ucredit 更新成功" || red_echo "ucredit 更新失败"
    sed -i '/^dcredit/d' "$CONFIG_FILE" && echo "dcredit = $dcredit" >>"$CONFIG_FILE" && gree_echo "dcredit 更新成功" || red_echo "dcredit 更新失败"
    sed -i '/^ocredit/d' "$CONFIG_FILE" && echo "ocredit = $ocredit" >>"$CONFIG_FILE" && gree_echo "ocredit 更新成功" || red_echo "ocredit 更新失败"
    sed -i '/^maxrepeat/d' "$CONFIG_FILE" && echo "maxrepeat = $maxrepeat" >>"$CONFIG_FILE" && gree_echo "maxrepeat 更新成功" || red_echo "maxrepeat 更新失败"
    sed -i '/^difok/d' "$CONFIG_FILE" && echo "difok = $difok" >>"$CONFIG_FILE" && gree_echo "difok 更新成功" || red_echo "difok 更新失败"

    #/etc/pam.d/common-password这个配置文件中可以只写入这一段 password requisite pam_pwquality.so   后面的规则全部放在/etc/security/pwquality.conf统一配置
    #如果两个文件都配置密码复杂性规则那么/etc/pam.d/common-password的优先级高冲突的配置优先级高的生效
    #如果/etc/pam.d/common-password未指定的参数那么/etc/security/pwquality.conf指定了那么的可以生效
    #如果两个地方都配置了那么在更新的时候最好还是都更新一下

    # 确保密码哈希设置是幂等的
    sed -i '/^password\s\+.*pam_unix\.so/d' "$PAM_COMMON_PASSWORD" || red_echo "删除旧配置失败(pam_unix)"
    echo "password    [success=1 default=ignore]      pam_unix.so obscure try_first_pass sha512 remember=3" >>"$PAM_COMMON_PASSWORD" || {
        red_echo "写入密码哈希配置失败"
        return 1
    }

    sed -i '/^password\s\+.*pam_deny\.so/d' "$PAM_COMMON_PASSWORD" &&
        echo "password        requisite                       pam_deny.so" >>"$PAM_COMMON_PASSWORD" || red_echo "失败(pam_deny)"
    sed -i '/^password\s\+.*pam_permit\.so/d' "$PAM_COMMON_PASSWORD" &&
        echo "password        required                        pam_permit.so" >>"$PAM_COMMON_PASSWORD" || red_echo "失败(pam_permit)"
    sudo systemctl restart ssh || red_echo "重启 sshd 服务失败"
}

_change_password_complexity_remember() {
    local remember=${1:-"3"} # 记住的历史密码数量
    # 确保密码哈希设置是幂等的
    [ $remember = "0" ] && return #如果等于0就不玩了......
    sed -i '/^password\s\+.*pam_unix\.so/d' "$PAM_COMMON_PASSWORD" || red_echo "删除旧配置失败(pam_unix)"
    echo "password    [success=1 default=ignore]      pam_unix.so obscure try_first_pass sha512 remember=${remember} " >>"$PAM_COMMON_PASSWORD" || red_echo "写入密码哈希配置失败"
}

_change_password_complexity_passmaxday() {
    local max_days=${1:-"90"} # 密码最大有效期
    local min_days=${2:-"7"}  # 密码最小有效期
    local warn_age=${3:-"15"} #告警提前多长时间告知
    sudo sed -i "/^PASS_MAX_DAYS/d;/^PASS_MIN_DAYS/d;/^PASS_WARN_AGE/d" /etc/login.defs
    echo "PASS_MAX_DAYS $max_days" | sudo tee -a /etc/login.defs >/dev/null
    echo "PASS_MIN_DAYS $min_days" | sudo tee -a /etc/login.defs >/dev/null
    echo "PASS_WARN_AGE $warn_age" | sudo tee -a /etc/login.defs >/dev/null

}
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
        [ $1 = "static" ] && selected_interface=$2 && ip=$3 && netmask=$4 && gateway=$5 && dns=$6 && _set_static_ip "$selected_interface" "$ip" "$netmask" "$gateway" "$dns"
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
            sudo apt-get install -y iftop || {
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
            sudo apt-get install -y nload || {
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
        sudo apt install traceroute || red_echo "traceroute 安装失败!!!"
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
            sudo apt install -y fio || {
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
        sudo apt install -y smartmontools
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
        [ $1 = "cpu" ] && interval=${2:-5} && local detailed=${3:-false} && _cpu_monitor "$interval" "$detailed"
        [ $1 = "memory" ] && interval=${2:-5} && _memory_monitor "$interval"
        [ $1 = "disk" ] && interval=${2:-5} && _disk_monitor "$interval"
        [ $1 = "load" ] && _load_monitor
        [ $1 = "temp" ] && _temp_monitor
        [ $1 = "all" ] && interval=${2:-5} && _os_unified_monitor "$interval"

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
        yellow_echo "正在安装lm-sensors包: sudo apt install lm-sensors"
        sudo apt install -y lm-sensors
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
            sudo apt install -y lm-sensors
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
                _install_uninstall_service "$service"
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

_install_docker() {

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

    green_echo "当前生效源列表:"
    apt-cache policy | grep -E 'http|https' # 应仅显示aliyun和docker镜像源

    green_echo "刷新软件源元数据，从 /etc/apt/sources.list 更新系统包列表，不会修改已安装的软件包..."
    sudo apt-get update
    green_echo "根据缓存的软件包列表，升级所有可更新的软件包..."
    apt upgrade -y
    green_echo "系统更新完成..."
    #endregion

    #region 安装 Docker 引擎
    #region 安装Docker
    green_echo "安装必要的依赖包..."
    sudo apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        software-properties-common

    green_echo "开始添加 Docker 官方 GPG 密钥..."
    # 初始化计数器
    counter=0
    while true; do
        green_echo "添加Docker仓库密钥..."
        curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | sudo gpg --yes --dearmor -o /usr/share/keyrings/docker-aliyun-keyring.gpg
        # curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --yes --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        if [ $? -eq 0 ]; then
            green_echo "GPG 密钥添加成功!"
            break
        else
            red_echo "网络问题导致失败，正在重试, Sleep 5S..."
            sleep 5 # 等待5秒后重试
        fi

        # 增加计数器
        counter=$((counter + 1))
        # 如果计数器达到10次，退出循环
        if [ $counter -ge 10 ]; then
            red_echo "已达到最大重试次数，退出。"
            break
        fi
    done

    green_echo "添加 Docker 仓库..."
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-aliyun-keyring.gpg] \
  https://mirrors.aliyun.com/docker-ce/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

    green_echo "更新包列表以包含 Docker 仓库..."
    sudo apt-get update

    green_echo "安装 Docker 引擎..."
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io

    green_echo "启动 Docker 服务..."
    sudo systemctl start docker

    green_echo "查看 Docker 服务状态..."
    systemctl --no-pager status docker

    green_echo "启用 Docker 服务开机自启..."
    sudo systemctl enable docker

    green_echo "验证 Docker 安装..."
    sudo docker --version

    green_echo "添加当前用户到 docker 组，避免每次使用 docker 命令都需要 sudo..."
    sudo usermod -aG docker $USER

    green_echo "Docker 安装完成。请注销并重新登录以使组更改生效。"

    #endregion

    #region 更改Docker镜像源
    green_echo "更改 Docker 镜像源..."
    # 创建 /etc/docker/daemon.json 文件
    mkdir -p /etc/docker
    tee /etc/docker/daemon.json <<EOF
{
  "registry-mirrors": [
    "https://docker.211678.top",
    "https://docker.1panel.live",
    "https://hub.rat.dev",
    "https://docker.m.daocloud.io",
    "https://do.nark.eu.org",
    "https://dockerpull.com",
    "https://dockerproxy.cn",
    "https://docker.awsl9527.cn/"
  ]
}
EOF

    # 重启 Docker 服务以应用更改
    green_echo "重启 Docker 服务..."
    systemctl restart docker
    systemctl --no-pager status docker
    green_echo "Docker 镜像加速器配置完成。"
    #endregion
    #endregion

    #region 检查并启动所有已停止的容器
    # 获取所有容器的 ID 和状态
    green_echo "检查容器状态: ID\tContainer Name\tContainer Status..."
    docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Status}}"

    # 启动所有已停止的容器
    green_echo "启动所有已停止的容器..."
    containers=$(docker ps -a --format "{{.ID}}\t{{.Status}}")
    # 循环遍历每个容器
    OLD_IFS=$IFS
    IFS=$'\n' # 设置字段分隔符为换行符
    bestartflag=false
    for id_status in $containers; do
        # 将ID和status分割成两个变量
        IFS=$'\t' read -r id status <<<"$id_status"

        # 检查状态是否表示容器未运行（这里简单检查是否包含"Exited"或"Created"）
        if [[ $status == *"Exited"* || $status == *"Created"* ]]; then
            echo "Starting container: $id ($status)"
            bestartflag=true
            docker start "$id"
        fi
    done
    IFS=$OLD_IFS

    if [ "$bestartflag" = true ]; then
        green_echo "已启动所有已停止的容器,如果状态还有问题，请手工启动..."
        docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Status}}"
    else
        green_echo "没有已停止的容器需要启动..."
    fi
    #endregion

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
        [ $1 = "check" ] && _check_updates
        [ $1 = "security" ] && _security_updates
        [ $1 = "update" ] && _perform_update "$2"
        [ $1 = "log" ] && _view_update_log
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
        [ $1 = "list" ] && _list_repos
        [ $1 = "add" ] && _add_repo "$2" "$3" "$4"
        [ $1 = "remove" ] && _remove_repo "$2"
        [ $1 = "gpg" ] && _manage_gpg_keys
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
        [ $1 = "tree" ] && _show_dep_tree "$2"
        [ $1 = "reverse" ] && _reverse_deps "$2"
        [ $1 = "conflict" ] && _check_conflicts "$2"
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
        [ $1 = "cache" ] && _clean_download_cache
        [ $1 = "old" ] && _remove_old_kernels
        [ $1 = "orphans" ] && _remove_orphans
        [ $1 = "space" ] && _show_disk_usage
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
        apt update && apt list --upgradable
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
        apt list --upgradable | grep -i security
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
            apt upgrade -y
        elif command -v yum &>/dev/null; then
            yum update -y
        elif command -v dnf &>/dev/null; then
            dnf upgrade -y
        elif command -v zypper &>/dev/null; then
            zypper update -y
        fi
    else
        if command -v apt-get &>/dev/null; then
            apt install -y $packages
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
        sudo apt-get update
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
        apt update
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
        sudo apt install -y "$pkg"
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
        sudo apt purge -y "$pkg"
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
        search_cmd="sudo apt search ^$pkg"
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
        [ $1 = "less" ] && _display_system_logs "" "less"
        [ $1 = "time" ] && time_range=$2 && _display_system_logs $time_range "less"
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
        [ $1 = "search" ] && keyword=$2 && logfile=$3 && _search_logs "$keyword" "$logfile"
        [ $1 = "regex" ] && pattern=$2 && logfile=$3 && _search_logs_regex "$pattern" "$logfile"
        [ $1 = "time" ] && keyword=$2 && logfile=$3 && start_time=$4 && end_time=$5 && _search_logs_time "$keyword" "$logfile" "$start_time" "$end_time"
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
        [ $1 = "stats" ] && logfile=$2 && _analyze_log_stats "$logfile"
        [ $1 = "errors" ] && logfile=$2 && _analyze_log_errors "$logfile"
        [ $1 = "patterns" ] && logfile=$2 && _analyze_log_patterns "$logfile"
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
        [ $1 = "time" ] && days=$2 && _clear_logs_by_time "$days"
        [ $1 = "size" ] && size=$2 && _clear_logs_by_size "$size"
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
        [ $1 = "show" ] && _show_logrotate_config
        [ $1 = "days" ] && logname=$2 && days=$3 && _set_logrotate_days "$logname" "$days"
        [ $1 = "size" ] && logname=$2 && size=$3 && _set_logrotate_size "$logname" "$size"
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

#region 9) 容器管理
# 容器管理功能模块
CONTAINER_MGMT() {
    while true; do
        GREEN_echo "==========容器管理=========="
        GREEN_echo "  1. 容器服务信息"
        GREEN_echo "  2. 容器管理"
        GREEN_echo "  3. 镜像管理"
        GREEN_echo "  4. 数据管理"
        GREEN_echo "  5. 网络管理"
        GREEN_echo "  6. 密钥|Config管理"
        GREEN_echo "  7. Dockerfile管理"
        GREEN_echo "  8. 系统资源监控"
        GREEN_echo "  0. 返回主菜单"
        read -p "请输入选择: " choice
        case $choice in
        1) get_docker_info ;;
        2) container_operations ;;
        3) image_operations ;;
        4) data_operations ;;
        5) network_operations ;;
        6) secret_config_operations ;;
        7) dockerfile_operations ;;
        8) docker_system_monitoring ;;
        0) break ;;
        *) YELLOW_echo "无效选择,请重新输入" ;;
        esac
        echo
    done
}

get_docker_info() {
    BLUE_echo "------------------------------------------------------"
    sudo docker info
    BLUE_echo "------------------------------------------------------"
}

# 1. 容器管理
container_operations() {
    if [ $# -gt 0 ]; then
        case $1 in
        1 | list)
            _list_containers
            ;;
        detail)
            container_id="$2" && _describe_container "$container_id"
            ;;
        start)
            container_id="$2" && action="$3" && _manage_container_state "$container_id" "start"
            ;;
        stop)
            container_id="$2" && action="$3" && _manage_container_state "$container_id" "stop"
            ;;
        restart)
            container_id="$2" && action="$3" && _manage_container_state "$container_id" "restart"
            ;;
        remove)
            container_id="$2" && action="$3" && _manage_container_state "$container_id" "remove"
            ;;
        exec)
            container_id="$2" && command="$3" && _exec_command "$container_id" "$command"
            ;;
        shell)
            container_id="$2" && _enter_shell "$container_id" "sh"
            ;;
        monitor)
            container_id="$2" && _monitor_container_resources "$container_id"
            ;;
        logs)
            container_id="$2" && line="$3" && _view_container_logs "$container_id" "${line:-"100"}"
            ;;
        commit)
            container=$2 && image_name=$3 && message=${4:-"Auto commit"} && _container_commit_image "$container" "$image_name" "$message"
            ;;
        export)
            container=$2 && filepath=${3:-"."} && _export_container "$container" "$filepath"
            ;;
        run)
            container=$2 && port=$3 && mount=$4 && image=$5 && _run_container "$container" "$port" "$mount" "$image"
            ;;
        *)
            RED_echo "无效操作: $1"
            ;;
        esac
        return
    fi

    # 交互模式
    while true; do
        BLUE_echo "------------------------------------------------------"
        GREEN_echo "--------容器管理--------"
        GREEN_echo "  1. 列出所有容器"
        GREEN_echo "  2. 容器详细信息"
        GREEN_echo "  3. 容器部署"
        GREEN_echo "  4. 容器操作(启动/停止/重启/删除)"
        GREEN_echo "  5. 在容器中执行命令"
        GREEN_echo "  6. 进入容器Shell(sh)"
        GREEN_echo "  7. 容器资源监控"
        GREEN_echo "  8. 容器日志查看"
        GREEN_echo "  9. 容器提交为镜像"
        GREEN_echo "  10.导出容器为tar包"
        GREEN_echo "  0. 返回上级"
        BLUE_echo "------------------------------------------------------"

        read -p "请输入选择: " choice

        case $choice in
        1)
            _list_containers
            ;;
        2)
            local containers_list_sanp=$(sudo docker ps -a --format "table {{.ID}}\t{{.Image}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.Command}}" | awk '{print NR-1,$0}')
            echo "$containers_list_sanp"
            read -p "请输入容器的序号: " container_numb
            local containers_name=$(echo "$containers_list_sanp" | awk -v line="$((container_numb + 1))" 'NR==line{print $4}')
            local containers_id=$(echo "$containers_list_sanp" | awk -v line="$((container_numb + 1))" 'NR==line{print $2}')
            green_echo "选择的容器: $containers_name | $containers_id"
            read -p "请确认操作(Y|N,default:Y): " areyouok
            areyouok="${areyouok:-Y}"
            [ "$areyouok" = "Y" ] && _describe_container "$containers_id"
            ;;
        3)
            image_list=$(sudo docker images --format "table {{.ID}}\t{{.Repository}}:{{.Tag}}\t{{.Size}}" | awk '{print NR-1,$0}')
            WHITE_echo "可用镜像列表:"
            echo "$image_list"
            read -p "请输入镜像序号: " container_numb
            image_name=$(echo "$image_list" | awk -v line="$((container_numb + 1))" 'NR==line{print $3}')
            read -p "请输入容器名称: " container_name
            read -p "请输入端口映射(主机端口:容器端口,可选): " port_mapping
            read -p "是否需要外部存储(模式<mount:m | volume:v>,默认:none): " st
            if [ "$st" = "m" ] || [ "$st" = "v" ]; then
                green_echo "将使用 $st 模式添加存储!!!"
                strong=""
                while true; do
                    strongpath=${container_name}_vol_$(date +%s)
                    if [ "$st" = "m" ]; then _create_volume "$strongpath"; fi
                    read -p "请输入容器内挂在路径(如:/app): " mountpath
                    [ "$st" = "m" ] && strong+=" -v /home/$strongpath:$mountpath"
                    [ "$st" = "v" ] && strong+=" -v $strongpath:$mountpath"
                    read -p "是否需要再添加一块存储(Y|N,Default:N): " st1
                    [ "${st1:-"N"}" = "N" ] || [ "${st1:-"n"}" = "n" ] && break
                done
            fi
            green_echo "容器部署信息- 镜像: $image_name | 容器名字: $container_name | 端口映射: $port_mapping | 存储: $strong"
            read -p "请确认操作(Y|N,default:Y): " areyouok
            areyouok="${areyouok:-Y}"
            [ "$areyouok" = "Y" ] && _run_container "$image_name" "$container_name" "$port_mapping" "$strong"
            ;;
        4)
            local containers_list_sanp=$(sudo docker ps -a --format "table {{.ID}}\t{{.Image}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.Command}}" | awk '{print NR-1,$0}')
            echo "$containers_list_sanp"
            read -p "请输入容器的序号: " container_numb
            local containers_name=$(echo "$containers_list_sanp" | awk -v line="$((container_numb + 1))" 'NR==line{print $4}')
            local containers_id=$(echo "$containers_list_sanp" | awk -v line="$((container_numb + 1))" 'NR==line{print $2}')

            GREEN_echo "请选择操作:"
            GREEN_echo "  1. 启动容器"
            GREEN_echo "  2. 停止容器"
            GREEN_echo "  3. 重启容器"
            GREEN_echo "  4. 删除容器"
            read -p "请输入操作[1-4]: " action_choice
            case $action_choice in
            1) action="start" ;;
            2) action="stop" ;;
            3) action="restart" ;;
            4) action="remove" ;;
            *)
                RED_echo "无效选择"
                continue
                ;;
            esac

            green_echo "选择的容器: $containers_name | $containers_id | 操作: $action"
            read -p "请确认操作(Y|N,default:Y): " areyouok
            areyouok="${areyouok:-Y}"
            [ "$areyouok" = "Y" ] && _manage_container_state "$containers_id" "$action"
            ;;
        5)
            local containers_list_sanp=$(sudo docker ps -a --format "table {{.ID}}\t{{.Image}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.Command}}" | awk '{print NR-1,$0}')
            echo "$containers_list_sanp"
            read -p "请输入容器的序号: " container_numb
            local containers_name=$(echo "$containers_list_sanp" | awk -v line="$((container_numb + 1))" 'NR==line{print $4}')
            local containers_id=$(echo "$containers_list_sanp" | awk -v line="$((container_numb + 1))" 'NR==line{print $2}')
            read -p "请输入要执行的命令: " exec_command
            green_echo "选择的容器: $containers_name | $containers_id | 命令: $exec_command"
            read -p "请确认操作(Y|N,default:Y): " areyouok
            areyouok="${areyouok:-Y}"
            [ "$areyouok" = "Y" ] && _exec_command "$containers_id" "$exec_command"
            ;;
        6)
            local containers_list_sanp=$(sudo docker ps -a --format "table {{.ID}}\t{{.Image}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.Command}}" | awk '{print NR-1,$0}')
            echo "$containers_list_sanp"
            read -p "请输入容器的序号: " container_numb
            local containers_name=$(echo "$containers_list_sanp" | awk -v line="$((container_numb + 1))" 'NR==line{print $4}')
            local containers_id=$(echo "$containers_list_sanp" | awk -v line="$((container_numb + 1))" 'NR==line{print $2}')
            green_echo "选择的容器: $containers_name | $containers_id"
            read -p "请确认操作(Y|N,default:Y): " areyouok
            areyouok="${areyouok:-Y}"
            [ "$areyouok" = "Y" ] && _enter_shell "$containers_id" "sh"
            ;;

        7)
            read -p "查看所有容器或单个容器(all:A | single:O ,Default: A): " flag
            [ ${flag:-"A"} = "A" ] && _monitor_container_resources && return
            local containers_list_sanp=$(sudo docker ps -a --format "table {{.ID}}\t{{.Image}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.Command}}" | awk '{print NR-1,$0}')
            echo "$containers_list_sanp"
            read -p "请输入容器的序号: " container_numb
            local containers_name=$(echo "$containers_list_sanp" | awk -v line="$((container_numb + 1))" 'NR==line{print $4}')
            local containers_id=$(echo "$containers_list_sanp" | awk -v line="$((container_numb + 1))" 'NR==line{print $2}')
            green_echo "选择的容器: $containers_name | $containers_id"
            read -p "请确认操作(Y|N,default:Y): " areyouok
            areyouok="${areyouok:-Y}"
            [ "$areyouok" = "Y" ] && _monitor_container_resources "$containers_id"
            ;;
        8)
            local containers_list_sanp=$(sudo docker ps -a --format "table {{.ID}}\t{{.Image}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.Command}}" | awk '{print NR-1,$0}')
            echo "$containers_list_sanp"
            read -p "请输入容器的序号: " container_numb
            local containers_name=$(echo "$containers_list_sanp" | awk -v line="$((container_numb + 1))" 'NR==line{print $4}')
            local containers_id=$(echo "$containers_list_sanp" | awk -v line="$((container_numb + 1))" 'NR==line{print $2}')
            green_echo "选择的容器: $containers_name | $containers_id"
            read -p "请确认操作(Y|N,default:Y): " areyouok
            areyouok="${areyouok:-Y}"
            [ "$areyouok" = "Y" ] && _view_container_logs "$containers_id" "${line:-"100"}"
            ;;
        9)
            local containers_list_sanp=$(sudo docker ps -a --format "table {{.ID}}\t{{.Image}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.Command}}" | awk '{print NR-1,$0}')
            echo "$containers_list_sanp"
            read -p "请输入容器的序号: " container_numb
            local containers_name=$(echo "$containers_list_sanp" | awk -v line="$((container_numb + 1))" 'NR==line{print $4}')
            local containers_id=$(echo "$containers_list_sanp" | awk -v line="$((container_numb + 1))" 'NR==line{print $2}')
            read -p "请输入新镜像名称(格式: name[:tag]): " newimage_name
            read -p "请输入提交说明(可选): " message
            green_echo "选择的容器: $containers_name | $containers_id | 新镜像: $newimage_name | 提交说明: $message"
            read -p "请确认操作(Y|N,default:Y): " areyouok
            areyouok="${areyouok:-Y}"
            [ "$areyouok" = "Y" ] && _container_commit_image "$containers_id" "$newimage_name" "$message"
            ;;
        10)
            local containers_list_sanp=$(sudo docker ps -a --format "table {{.ID}}\t{{.Image}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.Command}}" | awk '{print NR-1,$0}')
            echo "$containers_list_sanp"
            read -p "请输入容器的序号: " container_numb
            local containers_name=$(echo "$containers_list_sanp" | awk -v line="$((container_numb + 1))" 'NR==line{print $4}')
            local containers_id=$(echo "$containers_list_sanp" | awk -v line="$((container_numb + 1))" 'NR==line{print $2}')
            read -p "请输入导出文件名(默认${containers_name}.tar): " output
            green_echo "选择的容器: $containers_name | $containers_id | 文件名: ${output:-${containers_name}.tar} "
            read -p "请确认操作(Y|N,default:Y): " areyouok
            areyouok="${areyouok:-Y}"
            [ "$areyouok" = "Y" ] && _export_container "${containers_id}" "${output:-${containers_name}.tar}"
            ;;
        0)
            break
            ;;
        *)
            YELLOW_echo "无效选择,请重新输入"
            ;;
        esac

        read -p "按任意键继续..." -n1 -s
        clear
    done
}

# 2. 镜像管理
image_operations() {
    if [ $# -gt 0 ]; then
        [ $1 = "list" ] || [ $1 = "1" ] && _list_images
        [ $1 = "search" ] && image_name=$2 && _search_image "$image_name"
        [ $1 = "pull" ] && image_name=$2 && _pull_image "$image_name"
        [ $1 = "push" ] && image_name=$2 && _push_image "$image_name"
        [ $1 = "build" ] && dockerfile_path=$2 && tag=$3 && _build_image "$dockerfile_path" "$tag"
        [ $1 = "remove" ] && image_name=$2 && _remove_image "$image_name"
        [ $1 = "tag" ] && image_name=$2 && target_name=$3 && _tag_image "$image_name" "$target_name"
        [ $1 = "history" ] && image_name=$2 && _image_history "$image_name"
        [ $1 = "export" ] && image_name=$2 && output="${3:-"."}" && _save_image "$image_name" "$output"
        [ $1 = "import" ] && image_name=$2 && filepath="${3:-"."}" && _import_image "$image_name" "$filepath"

    else
        # 主交互逻辑
        while true; do
            BLUE_echo "------------------------------------------------------"
            GREEN_echo "镜像管理选项:"
            GREEN_echo "  1. 列出本地镜像"
            GREEN_echo "  2. 搜索远程镜像"
            GREEN_echo "  3. 拉取镜像"
            GREEN_echo "  4. 推送镜像"
            GREEN_echo "  5. 构建镜像"
            GREEN_echo "  6. 删除镜像"
            GREEN_echo "  7. 镜像标签管理"
            GREEN_echo "  8. 查看镜像历史"
            GREEN_echo "  9. 导出镜像为tar包"
            GREEN_echo "  10. 导入tar包为镜像"
            GREEN_echo "  0. 返回"
            BLUE_echo "------------------------------------------------------"
            read -p "请输入选项[0-8]: " choice
            case $choice in
            1)
                _list_images
                ;;
            2)
                _list_images
                read -p "请输入要搜索的镜像名称(名称:版本): " image_name
                _search_image "$image_name"
                ;;
            3)
                _list_images
                read -p "请输入要拉取的镜像名称(名称:版本): " image_name
                _pull_image "$image_name"
                ;;
            4)
                local image_list_sanp=$(sudo docker images --format "table {{.ID}}\t{{.Repository}}:{{.Tag}}\t{{.Size}}\t{{.CreatedSince}}" | awk '{print NR-1,$0}')
                echo "$image_list_sanp"
                read -p "请输入镜像的序号: " image_num
                local image_name=$(echo "$image_list_sanp" | awk -v line="$((image_num + 1))" 'NR==line{print $3}')
                green_echo "选择需要推送的镜像信息: $image_name"
                read -p "请确认操作(Y|N,default:Y): " areyouok
                areyouok="${areyouok:-Y}"
                [ "$areyouok" = "Y" ] && _push_image "$image_name"
                ;;
            5)
                _list_images
                read -p "请输入Dockerfile路径: " dockerfile_path
                read -p "请输入镜像标签: " tag
                _build_image "$dockerfile_path" "$tag"
                ;;
            6)
                local image_list_sanp=$(sudo docker images --format "table {{.ID}}\t{{.Repository}}:{{.Tag}}\t{{.Size}}\t{{.CreatedSince}}" | awk '{print NR-1,$0}')
                echo "$image_list_sanp"
                read -p "请输入镜像的序号: " image_num
                local image_name=$(echo "$image_list_sanp" | awk -v line="$((image_num + 1))" 'NR==line{print $3}')
                green_echo "选择需要删除的镜像信息: $image_name "
                read -p "请确认操作(Y|N,default:Y): " areyouok
                areyouok="${areyouok:-Y}"
                [ "$areyouok" = "Y" ] && _remove_image "$image_name"
                ;;
            7)
                local image_list_sanp=$(sudo docker images --format "table {{.ID}}\t{{.Repository}}:{{.Tag}}\t{{.Size}}\t{{.CreatedSince}}" | awk '{print NR-1,$0}')
                echo "$image_list_sanp"
                read -p "请输入源镜像的序号: " image_num
                local image_name=$(echo "$image_list_sanp" | awk -v line="$((image_num + 1))" 'NR==line{print $3}')
                read -p "请输入目标镜像名称(名称:版本): " target_image
                green_echo "选择需要标签维护的镜像信息: $image_name | 目标标签: $target_image"
                read -p "请确认操作(Y|N,default:Y): " areyouok
                areyouok="${areyouok:-Y}"
                [ "$areyouok" = "Y" ] && _tag_image "$image_name" "$target_image"
                ;;
            8)
                local image_list_sanp=$(sudo docker images --format "table {{.ID}}\t{{.Repository}}:{{.Tag}}\t{{.Size}}\t{{.CreatedSince}}" | awk '{print NR-1,$0}')
                echo "$image_list_sanp"
                read -p "请输入镜像的序号: " image_num
                local image_name=$(echo "$image_list_sanp" | awk -v line="$((image_num + 1))" 'NR==line{print $3}')
                green_echo "选择需要查看镜像信息: $image_name "
                read -p "请确认操作(Y|N,default:Y): " areyouok
                areyouok="${areyouok:-Y}"
                [ "$areyouok" = "Y" ] && _image_history "$image_name"
                ;;
            9)
                local image_list_sanp=$(sudo docker images --format "table {{.ID}}\t{{.Repository}}:{{.Tag}}\t{{.Size}}\t{{.CreatedSince}}" | awk '{print NR-1,$0}')
                echo "$image_list_sanp"
                read -p "请输入镜像的序号: " image_num
                local image_name=$(echo "$image_list_sanp" | awk -v line="$((image_num + 1))" 'NR==line{print $3}')
                read -p "请输入输出文件名(可选): " output
                green_echo "选择需要导出的镜像信息: $image_name | 路径: ${output:-"."}"
                read -p "请确认操作(Y|N,default:Y): " areyouok
                areyouok="${areyouok:-Y}"
                [ "$areyouok" = "Y" ] && _save_image "$image_name" ""
                ;;
            10)
                read -p "请输入要导入的tar文件路径: " image_file
                read -p "请输入镜像名称: " image_name
                green_echo "输入的内容-  文件: $image_file | 镜像名称: $image_name "
                read -p "请确认操作(Y|N,default:Y): " areyouok
                areyouok="${areyouok:-Y}"
                [ "$areyouok" = "Y" ] && _import_image "$image_file" "$image_name"
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

# 3. 存储管理
data_operations() {
    if [ $# -gt 0 ]; then
        [ "$1" = "list" ] && _list_volumes
        [ "$1" = "create" ] && _create_volume "$2"
        [ "$1" = "remove" ] && _remove_volume "$2"
        [ "$1" = "inspect" ] && _inspect_volume "$2"
        [ "$1" = "prune" ] && _prune_volumes
        [ "$1" = "backup" ] && _backup_volume "$2" "$3"
        [ "$1" = "restore" ] && _restore_volume "$2" "$3"
    else
        # 主交互逻辑
        while true; do
            BLUE_echo "------------------------------------------------------"
            GREEN_echo "卷管理选项:"
            GREEN_echo "  1. 列出所有卷"
            GREEN_echo "  2. 创建卷"
            GREEN_echo "  3. 删除卷"
            GREEN_echo "  4. 查看卷详情"
            GREEN_echo "  5. 清理未使用卷"
            GREEN_echo "  6. 卷备份"
            GREEN_echo "  7. 卷恢复"
            GREEN_echo "  0. 返回"
            BLUE_echo "------------------------------------------------------"
            read -p "请输入选项[0-7]: " choice
            case $choice in
            1) _list_volumes ;;
            2)
                read -p "请输入卷名称: " vol_name
                _create_volume "$vol_name"
                ;;
            3)
                local volume_list=$(sudo docker volume ls --format "table {{.Driver}}\t{{.Name}}" | awk '{print NR-1,$0}')
                echo "$volume_list"
                read -p "请输入要删除卷的编号: " vol_numb
                local vol_name=$(echo "$volume_list" | awk -v line="$((vol_numb + 1))" 'NR==line{print $3}')
                green_echo "输入的内容- 卷名: $vol_name  "
                read -p "请确认操作(Y|N,default:Y): " areyouok
                areyouok="${areyouok:-Y}"
                [ "$areyouok" = "Y" ] && _remove_volume "$vol_name"
                ;;
            4)
                local volume_list=$(sudo docker volume ls --format "table {{.Driver}}\t{{.Name}}" | awk '{print NR-1,$0}')
                echo "$volume_list"
                read -p "请输入要查看卷的编号: " vol_numb
                local vol_name=$(echo "$volume_list" | awk -v line="$((vol_numb + 1))" 'NR==line{print $3}')
                green_echo "输入的内容- 卷名: $vol_name  "
                read -p "请确认操作(Y|N,default:Y): " areyouok
                areyouok="${areyouok:-Y}"
                [ "$areyouok" = "Y" ] && _inspect_volume "$vol_name"
                ;;
            5)
                local volume_list=$(sudo docker volume ls --format "table {{.Driver}}\t{{.Name}}" | awk '{print NR-1,$0}')
                echo "$volume_list"
                _prune_volumes
                ;;
            6)
                local volume_list=$(sudo docker volume ls --format "table {{.Driver}}\t{{.Name}}" | awk '{print NR-1,$0}')
                echo "$volume_list"
                read -p "请输入要查备份卷的编号: " vol_numb
                local vol_name=$(echo "$volume_list" | awk -v line="$((vol_numb + 1))" 'NR==line{print $3}')
                read -p "请输入备份文件路径: " backup_path
                green_echo "输入的内容- 卷名: $vol_name | 路径: $backup_path "
                read -p "请确认操作(Y|N,default:Y): " areyouok
                areyouok="${areyouok:-Y}"
                [ "$areyouok" = "Y" ] && _backup_volume "$vol_name" "$backup_path"
                ;;
            7)
                _list_volumes
                read -p "请输入要恢复的卷名称: " vol_name
                read -p "请输入备份文件路径: " backup_path
                _restore_volume "$vol_name" "$backup_path"
                ;;
            0) return ;;
            *) RED_echo "无效选项" ;;
            esac
            read -p "按任意键继续..." -n1 -s
            clear
        done
    fi
}

# 4. docker网络管理
network_operations() {
    if [ $# -gt 0 ]; then
        [ "$1" = "list" ] && _list_networks
        [ "$1" = "create" ] && _create_network "$2" "$3" "$4" "$5"
        [ "$1" = "remove" ] && _remove_network "$2"
        [ "$1" = "inspect" ] && _inspect_network "$2"
        [ "$1" = "connect" ] && _connect_container "$2" "$3"
        [ "$1" = "disconnect" ] && _disconnect_container "$2" "$3"
    else
        # 交互模式
        while true; do
            BLUE_echo "------------------------------------------------------"
            GREEN_echo "Docker网络管理选项:"
            GREEN_echo "  1. 列出所有网络"
            GREEN_echo "  2. 创建网络"
            GREEN_echo "  3. 删除网络"
            GREEN_echo "  4. 检查网络详情"
            GREEN_echo "  5. 连接容器到网络"
            GREEN_echo "  6. 断开容器与网络连接"
            GREEN_echo "  0. 返回"
            BLUE_echo "------------------------------------------------------"

            read -p "请输入选项[0-6]: " choice
            case $choice in
            1) _list_networks ;;
            2)
                read -p "请输入网络名称: " name
                read -p "请输入驱动类型(默认bridge): " driver
                read -p "请输入子网(可选): " subnet
                read -p "请输入网关(可选): " gateway
                _create_network "$name" "${driver:-bridge}" "$subnet" "$gateway"
                ;;
            3)
                local network_list=$(sudo docker network ls --format "table {{.ID}}\t{{.Name}}\t{{.Driver}}\t{{.Scope}}" | awk '{print NR-1,$0}')
                echo "$network_list"
                read -p "请输入要删除的网络编号: " vol_numb
                local network_id=$(echo "$network_list" | awk -v line="$((vol_numb + 1))" 'NR==line{print $2}')
                green_echo "输入的内容- 网络名: $network_id  "
                read -p "请确认操作(Y|N,default:Y): " areyouok
                areyouok="${areyouok:-Y}"
                [ "$areyouok" = "Y" ] && _remove_network "$network_id"
                ;;
            4)
                local network_list=$(sudo docker network ls --format "table {{.ID}}\t{{.Name}}\t{{.Driver}}\t{{.Scope}}" | awk '{print NR-1,$0}')
                echo "$network_list"
                read -p "请输入要检查的网络编号: " vol_numb
                local network_id=$(echo "$network_list" | awk -v line="$((vol_numb + 1))" 'NR==line{print $2}')
                green_echo "输入的内容- 网络名: $network_id  "
                read -p "请确认操作(Y|N,default:Y): " areyouok
                areyouok="${areyouok:-Y}"
                [ "$areyouok" = "Y" ] && _inspect_network "$network_id"
                ;;
            5)
                local network_list=$(sudo docker network ls --format "table {{.ID}}\t{{.Name}}\t{{.Driver}}\t{{.Scope}}" | awk '{print NR-1,$0}')
                echo "$network_list"
                read -p "请输入要连接的网络编号: " vol_numb
                local network_id=$(echo "$network_list" | awk -v line="$((vol_numb + 1))" 'NR==line{print $2}')
                local containers_list_sanp=$(sudo docker ps -a --format "table {{.ID}}\t{{.Image}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.Command}}" | awk '{print NR-1,$0}')
                echo "$containers_list_sanp"
                read -p "请输入容器的序号: " container_numb
                local containers_id=$(echo "$containers_list_sanp" | awk -v line="$((container_numb + 1))" 'NR==line{print $2}')
                green_echo "输入的内容- 网络名: $network_id | 容器ID: $containers_id"
                read -p "请确认操作(Y|N,default:Y): " areyouok
                areyouok="${areyouok:-Y}"
                [ "$areyouok" = "Y" ] && _connect_container "$network_id" "$containers_id"
                ;;
            6)
                local network_list=$(sudo docker network ls --format "table {{.ID}}\t{{.Name}}\t{{.Driver}}\t{{.Scope}}" | awk '{print NR-1,$0}')
                echo "$network_list"
                read -p "请输入要连接的网络编号: " vol_numb
                local network_id=$(echo "$network_list" | awk -v line="$((vol_numb + 1))" 'NR==line{print $2}')
                local containers_list_sanp=$(sudo docker ps -a --format "table {{.ID}}\t{{.Image}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.Command}}" | awk '{print NR-1,$0}')
                echo "$containers_list_sanp"
                read -p "请输入容器的序号: " container_numb
                local containers_id=$(echo "$containers_list_sanp" | awk -v line="$((container_numb + 1))" 'NR==line{print $2}')
                green_echo "输入的内容- 网络名: $network_id | 容器ID: $containers_id"
                read -p "请确认操作(Y|N,default:Y): " areyouok
                areyouok="${areyouok:-Y}"
                [ "$areyouok" = "Y" ] && _disconnect_container "$network" "$container"
                ;;
            0) return ;;
            *) RED_echo "无效选项" ;;
            esac
            read -p "按任意键继续..." -n1 -s
            clear
        done
    fi
}

# 5. 密钥|Config管理
secret_config_operations() {
    if [ $# -gt 0 ]; then
        # 直接调用功能模块
        [ "$1" = "secret-list" ] && _secret_list
        [ "$1" = "secret-create" ] && _secret_create "$2" "$3"
        [ "$1" = "secret-remove" ] && _secret_remove "$2"
        [ "$1" = "config-list" ] && _config_list
        [ "$1" = "config-create" ] && _config_create "$2" "$3"
        [ "$1" = "config-remove" ] && _config_remove "$2"
        [ "$1" = "encrypt" ] && _encrypt_file "$2" "$3"
        [ "$1" = "decrypt" ] && _decrypt_file "$2" "$3"
    else
        # 主交互逻辑
        while true; do
            BLUE_echo "------------------------------------------------------"
            GREEN_echo "Secret/Config管理工具选项:"
            GREEN_echo "  1. 列出所有Secrets"
            GREEN_echo "  2. 创建Secret"
            GREEN_echo "  3. 删除Secret"
            GREEN_echo "  4. 列出所有Configs"
            GREEN_echo "  5. 创建Config"
            GREEN_echo "  6. 删除Config"
            GREEN_echo "  7. 加密文件"
            GREEN_echo "  8. 解密文件"
            GREEN_echo "  0. 返回"
            BLUE_echo "------------------------------------------------------"
            read -p "请输入选项[0-8]: " choice

            case $choice in
            1)
                _secret_list
                ;;
            2)
                read -p "请输入Secret名称: " name
                read -p "请输入文件路径: " file
                _secret_create "$name" "$file"
                _secret_list
                ;;
            3)
                _secret_list
                read -p "请输入要删除的Secret名称: " name
                _secret_remove "$name"
                _secret_list
                ;;
            4)
                _config_list
                ;;
            5)
                read -p "请输入Config名称: " name
                read -p "请输入文件路径: " file
                _config_create "$name" "$file"
                _config_list
                ;;
            6)
                _config_list
                read -p "请输入要删除的Config名称: " name
                _config_remove "$name"
                ;;
            7)
                _config_list
                read -p "请输入要加密的文件路径: " input
                read -p "请输入加密后输出路径: " output
                _encrypt_file "$input" "$output"
                ;;
            8)
                _config_list
                read -p "请输入要解密的文件路径: " input
                read -p "请输入解密后输出路径: " output
                _decrypt_file "$input" "$output"
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

# 6. Dockerfile管理
dockerfile_operations() {
    if [ $# -gt 0 ]; then
        [ $1 = "validate" ] && file=${2:-"Dockerfile"} && _dockerfile_validate "$file"
        [ $1 = "build" ] && file=${2:-"Dockerfile"} && tag=${3:-"latest"} && _dockerfile_build "$file" "$tag"
        [ $1 = "lint" ] && file=${2:-"Dockerfile"} && _dockerfile_lint "$file"
        [ $1 = "template" ] && type=${2:-"list"} && [ $type = "get" ] && name=$3 && _dockerfile_template "$type" "$name"
        [ $1 = "multistage" ] && action=${2:-"list"} && [ $action = "add" ] && stage_name=$3 && _dockerfile_multistage "$action" "$stage_name"
    else
        # 主交互逻辑
        while true; do
            BLUE_echo "------------------------------------------------------"
            GREEN_echo "Dockerfile 操作菜单:"
            GREEN_echo "  1. 验证Dockerfile语法"
            GREEN_echo "  2. 构建Docker镜像"
            GREEN_echo "  3. 检查最佳实践"
            GREEN_echo "  4. 模板管理"
            GREEN_echo "  5. 多阶段构建管理"
            GREEN_echo "  0. 返回"
            BLUE_echo "------------------------------------------------------"
            read -p "请输入选项[0-5]: " choice
            case $choice in
            1)
                read -p "请输入Dockerfile路径(默认当前目录): " file
                _dockerfile_validate "${file:-"Dockerfile"}"
                ;;
            2)
                read -p "请输入Dockerfile路径(默认当前目录): " file
                read -p "请输入镜像标签(默认latest): " tag
                _dockerfile_build "${file:-"Dockerfile"}" "${tag:-"latest"}"
                ;;
            3)
                read -p "请输入Dockerfile路径(默认当前目录): " file
                _dockerfile_lint "${file:-"Dockerfile"}"
                ;;
            4)
                BLUE_echo "------------------------------------------------------"
                GREEN_echo "模板操作:"
                GREEN_echo "  1) 列出模板"
                GREEN_echo "  2) 获取模板"
                read -p "请选择子操作[1-2]: " sub_choice
                case $sub_choice in
                1) _dockerfile_template "list" ;;
                2)
                    read -p "请输入模板名称: " name
                    _dockerfile_template "get" "$name"
                    ;;
                *) RED_echo "无效选项" ;;
                esac
                ;;
            5)
                BLUE_echo "------------------------------------------------------"
                GREEN_echo "多阶段构建:"
                GREEN_echo "  1) 列出阶段"
                GREEN_echo "  2) 添加阶段"
                read -p "请选择子操作[1-2]: " sub_choice
                case $sub_choice in
                1) _dockerfile_multistage "list" ;;
                2)
                    read -p "请输入阶段名称: " stage_name
                    _dockerfile_multistage "add" "$stage_name"
                    ;;
                *) RED_echo "无效选项" ;;
                esac
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

# 7. 系统资源监控
docker_system_monitoring() {
    if [ $# -gt 0 ]; then
        [ $1 = "status" ] && _system_docker_status
        [ $1 = "stats" ] && _system_resource_stats
        [ $1 = "events" ] && _system_docker_events
        [ $1 = "profile" ] && _system_performance_profile
        [ $1 = "clean" ] && _system_auto_clean
    else
        # 主交互逻辑
        while true; do
            BLUE_echo "------------------------------------------------------"
            GREEN_echo "系统资源监控选项:"
            GREEN_echo "  1. Docker引擎状态检查"
            GREEN_echo "  2. 资源状态统计"
            GREEN_echo "  3. Docker事件日志查看"
            GREEN_echo "  4. 性能分析"
            GREEN_echo "  5. 自动清理策略"
            GREEN_echo "  0. 返回"
            BLUE_echo "------------------------------------------------------"
            read -p "请输入选项[0-5]: " choice
            case $choice in
            1)
                _system_docker_status
                ;;
            2)
                _system_resource_stats
                ;;
            3)
                _system_docker_events
                ;;
            4)
                _system_performance_profile
                ;;
            5)
                _system_auto_clean
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

# 子函数定义
_system_docker_status() {
    blue_echo "检查Docker引擎状态..."
    systemctl is-active docker >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        green_echo "Docker引擎运行正常"
        docker version | grep -A 20 "Server:"
    else
        red_echo "Docker引擎未运行"
    fi
}

_system_docker_resource_stats() {
    blue_echo "---------------系统资源状态统计-----------------------------"
    blue_echo "内存使用情况:"
    free -h
    blue_echo "CPU使用情况:"
    top -bn1 | head -5
    blue_echo "磁盘使用情况:"
    df -h
    blue_echo "Docker资源使用:"
    sudo docker stats --no-stream --format \
        "table {{.ID}}\t{{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.NetIO}}\t{{.BlockIO}}\t{{.PIDs}}" | awk '{print NR-1,$0}'
    blue_echo "-----------------------------------------------------------"
}

_system_docker_events() {
    blue_echo "查看Docker事件日志(最近20条)..."
    docker events --since '1h' | tail -20
}

_system_performance_profile() {
    blue_echo "系统性能分析..."
    echo -e "\n系统负载:"
    uptime
    echo -e "\n进程资源占用TOP10:"
    ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head -11
    echo -e "\n网络连接统计:"
    netstat -s | head -20
}

_system_auto_clean() {
    blue_echo "执行自动清理策略..."
    echo -e "\n清理未使用的Docker资源:"
    docker system prune -f
    check_command "Docker资源清理"

    echo -e "\n清理临时文件:"
    rm -rf /tmp/*
    check_command "临时文件清理"

    echo -e "\n清理日志文件(保留最近7天):"
    find /var/log -type f -mtime +7 -delete
    check_command "日志文件清理"
}

_dockerfile_validate() {
    local file=$1
    blue_echo "开始验证 Dockerfile: $file"
    docker build --no-cache -f "$file" . >/dev/null
    check_command "Dockerfile验证"
}

_dockerfile_build() {
    local file=$1 tag=$2
    blue_echo "开始构建镜像 (Dockerfile: $file, Tag: $tag)"
    docker build -f "$file" -t "$tag" .
    check_command "Docker镜像构建"
}

_dockerfile_lint() {
    local file=$1
    blue_echo "检查Dockerfile最佳实践: $file"
    if ! command -v hadolint &>/dev/null; then
        yellow_echo "提示: 安装hadolint可增强检查效果 (brew install hadolint)"
        docker run --rm -i hadolint/hadolint <"$file"
    else
        hadolint "$file"
    fi
    check_command "Dockerfile lint检查"
}

_dockerfile_template() {
    local type=$1 name=$2
    case $type in
    "list")
        blue_echo "可用模板列表:"
        ls -1 /usr/local/share/dockerfile_templates/
        ;;
    "get")
        blue_echo "获取模板: $name"
        cp "/usr/local/share/dockerfile_templates/$name" ./Dockerfile
        check_command "模板获取"
        ;;
    esac
}

_dockerfile_multistage() {
    local action=$1 stage_name=$2
    case $action in
    "list")
        blue_echo "当前构建阶段:"
        grep -E '^FROM.*AS' Dockerfile | awk '{print $NF}'
        ;;
    "add")
        blue_echo "添加构建阶段: $stage_name"
        echo -e "\nFROM alpine AS $stage_name\nRUN echo 'New stage added'" >>Dockerfile
        check_command "多阶段添加"
        ;;
    esac
}

# 子函数:列出所有secrets
_secret_list() {
    blue_echo "------------------------------------------------------"
    green_echo "当前Docker Secrets列表:"
    docker secret ls
    check_command "列出Docker Secrets"
}

# 子函数:创建secret
_secret_create() {
    local name=$1
    local file=$2
    docker secret create "$name" "$file"
    check_command "创建Secret [$name]"
}

# 子函数:删除secret
_secret_remove() {
    local name=$1
    docker secret rm "$name"
    check_command "删除Secret [$name]"
}

# 子函数:列出所有configs
_config_list() {
    blue_echo "------------------------------------------------------"
    green_echo "当前Docker Configs列表:"
    docker config ls
    check_command "列出Docker Configs"
}

# 子函数:创建config
_config_create() {
    local name=$1
    local file=$2
    docker config create "$name" "$file"
    check_command "创建Config [$name]"
}

# 子函数:删除config
_config_remove() {
    local name=$1
    docker config rm "$name"
    check_command "删除Config [$name]"
}

# 子函数:加密文件
_encrypt_file() {
    local input=$1
    local output=$2
    openssl enc -aes-256-cbc -salt -in "$input" -out "$output"
    check_command "加密文件 [$input] -> [$output]"
}

# 子函数:解密文件
_decrypt_file() {
    local input=$1
    local output=$2
    openssl enc -d -aes-256-cbc -in "$input" -out "$output"
    check_command "解密文件 [$input] -> [$output]"
}

# 子函数:列出所有网络
_list_networks() {
    blue_echo "------------------------------------------------------"
    green_echo "Docker网络列表:"
    sudo docker network ls --format "table {{.ID}}\t{{.Name}}\t{{.Driver}}\t{{.Scope}}" | awk '{print NR-1,$0}'
    check_command "获取Docker网络列表"
}

# 子函数:创建网络
_create_network() {
    local name=$1
    local driver=${2:-"bridge"}
    local subnet=$3
    local gateway=$4

    local create_cmd="docker network create --driver $driver"
    [ -n "$subnet" ] && create_cmd+=" --subnet $subnet"
    [ -n "$gateway" ] && create_cmd+=" --gateway $gateway"
    create_cmd+=" $name"

    blue_echo "正在创建网络..."
    eval "$create_cmd"
    check_command "创建网络 $name"
}

# 子函数:删除网络
_remove_network() {
    local name=$1
    yellow_echo "警告: 即将删除网络 $name"
    docker network rm "$name"
    check_command "删除网络 $name"
}

# 子函数:检查网络详情
_inspect_network() {
    local name=$1
    blue_echo "网络 $name 的详细信息:"
    docker network inspect "$name" | jq .
    check_command "检查网络 $name"
}

# 子函数:连接容器到网络
_connect_container() {
    local network=$1
    local container=$2
    docker network connect "$network" "$container"
    check_command "将容器 $container 连接到网络 $network"
}

# 子函数:断开容器与网络连接
_disconnect_container() {
    local network=$1
    local container=$2
    docker network disconnect "$network" "$container"
    check_command "将容器 $container 从网络 $network 断开"
}

# 子函数:保存镜像为tar文件
_save_image() {
    local image=$1
    local output=$2

    blue_echo "开始导出镜像 [$image] 到 [$output]..."
    docker save -o "$output" "$image"
    check_command "镜像 [$image] 导出到 [$output]"

    # 显示导出文件信息
    ls -lh "$output" | awk '{print "导出文件:", $9, "大小:", $5}'
}

_enter_shell() {
    local container=$1
    local shell_type=$2

    blue_echo "正在进入容器 $container 的$shell_type环境..."
    sudo docker exec -it "$container" "$shell_type"
    check_command "进入Shell"
}

_container_commit_image() {
    local container=$1
    local image_name=$2
    local message=${3:-"Auto commit"}

    blue_echo "正在提交容器 $container 为镜像 $image_name ..."
    docker commit -m "$message" "$container" "$image_name"

    if [ $? -eq 0 ]; then
        green_echo "提交成功"
        WHITE_echo "新镜像信息:"
        docker images | grep "$(echo $image_name | cut -d':' -f1)"
    else
        red_echo "提交失败"
    fi
}

_run_container() {
    local image=$1
    local name=$2
    local port=$3
    local mount=$4

    if [ -z $image ] || [ -z $name ] || [ -z $port ]; then
        red_echo "错误: 输入信息不能为空"
        red_echo "镜像 :$image | 名称: $name | 端口: $port"
        return 1
    fi

    blue_echo "------------------------------------------------------"
    blue_echo "正在运行容器..."
    local cmd="sudo docker run -d --name \"$name\" -p \"$port\"$mount \"$image\""

    blue_echo "执行命令: $cmd"
    eval "$cmd"
    check_command "运行容器"
    blue_echo "------------------------------------------------------"
}

_exec_command() {
    local container=$1
    local command=$2

    blue_echo "------------------------------------------------------"
    blue_echo "正在容器 $container 中执行命令..."
    sudo docker exec -it "$container" sh -c "$command"
    check_command "执行命令"
    blue_echo "------------------------------------------------------"
}

# 导出容器为tar文件
_export_container() {
    local container_id="$1"
    local filepath="$2"
    if [ -z "$container_id" ] || [ -z "$filepath" ]; then
        RED_echo "错误: 输入信息不能为空"
        return 1
    fi

    blue_echo "开始导出容器 $container_id..."
    docker export "$container_id" >"$filepath"
    check_command "导出容器 $container_id 到 $filepath"
}

# 导入tar文件为镜像
_import_image() {
    local image_id=$1
    local filepath=$2
    if [ -z $image_id ] || [ -z $filepath ]; then
        RED_echo "错误: 输入信息不能为空"
        return 1
    fi

    blue_echo "开始导入镜像 $image_id..."
    image_id=$(basename "$filepath" .tar)
    docker import "$filepath" "$image_id:imported"
    check_command "导入镜像 $filepath 为 $image_id:imported"
}

# 列出所有卷
_list_volumes() {
    blue_echo "正在列出所有卷..."
    blue_echo "------------------------------------------------------"
    sudo docker volume ls --format "table {{.Driver}}\t{{.Name}}" | awk '{print NR-1,$0}'
    check_command "列出卷"
    blue_echo "------------------------------------------------------"
}

_create_volume() {
    local vol_name=$1
    blue_echo "正在创建卷: $vol_name..."
    blue_echo "------------------------------------------------------"
    docker volume create "$vol_name"
    check_command "创建卷 $vol_name"
    blue_echo "------------------------------------------------------"
}

# 删除卷
_remove_volume() {
    local vol_name=$1
    blue_echo "正在删除卷: $vol_name..."
    blue_echo "------------------------------------------------------"
    docker volume rm "$vol_name"
    check_command "删除卷 $vol_name"
    blue_echo "------------------------------------------------------"
}

# 查看卷详情
_inspect_volume() {
    local vol_name=$1
    blue_echo "正在查看卷详情: $vol_name..."
    blue_echo "------------------------------------------------------"
    docker volume inspect "$vol_name"
    check_command "查看卷详情 $vol_name"
    blue_echo "------------------------------------------------------"
}

# 清理未使用卷
_prune_volumes() {
    blue_echo "正在清理未使用卷..."
    blue_echo "------------------------------------------------------"
    docker volume prune -f
    blue_echo "------------------------------------------------------"
    check_command "清理未使用卷"
}

# 卷备份
_backup_volume() {
    local vol_name=$1
    local backup_path=$2
    blue_echo "正在备份卷 $vol_name 到 $backup_path..."
    blue_echo "------------------------------------------------------"
    docker run --rm -v "$vol_name":/volume -v "$(dirname "$backup_path")":/backup alpine \
        tar czf "/backup/$(basename "$backup_path")" -C /volume ./
    check_command "备份卷 $vol_name"
    blue_echo "------------------------------------------------------"
}

# 卷恢复
_restore_volume() {
    local vol_name=$1
    local backup_path=$2
    blue_echo "------------------------------------------------------"
    blue_echo "正在从 $backup_path 恢复卷 $vol_name..."
    docker run --rm -v "$vol_name":/volume -v "$(dirname "$backup_path")":/backup alpine \
        tar xzf "/backup/$(basename "$backup_path")" -C /volume
    check_command "恢复卷 $vol_name"
    blue_echo "------------------------------------------------------"
}

_describe_container() {
    local container_id_or_name=$1
    if [ -z "$container_id_or_name" ]; then
        RED_echo "错误: 容器输入信息不能为空"
        return 1
    fi

    BLUE_echo "------------------------------------------------------------------------------------------"
    BLUE_echo "============ 容器详情 ============"
    # 2. 基础信息
    GREEN_echo "【基础信息】"
    docker inspect --format='
    ID:           {{.Id}}
    Name:         {{.Name}}
    Status:       {{.State.Status}}
    Running:      {{.State.Running}}
    RestartCount: {{.RestartCount}}
    Pid:          {{.State.Pid}}
    ExitCode:    {{.State.ExitCode}}
    Created:      {{.Created}}
    StartedAt:    {{.State.StartedAt}}
    FinishedAt:   {{.State.FinishedAt}}
    Image:        {{.Config.Image}}
    Command:      {{.Config.Cmd}}
    ' "$container_id_or_name"

    # 1. 资源使用情况
    BLUE_echo "------------------------------------------------------"
    GREEN_echo "【资源使用】"
    docker stats "$container_id_or_name" --no-stream

    # 3. 网络信息
    BLUE_echo "------------------------------------------------------"
    GREEN_echo "【网络配置】"
    docker inspect --format='{{json .NetworkSettings.Networks}}' "$container_id_or_name" | jq

    # 4. 挂载卷
    BLUE_echo "------------------------------------------------------"
    GREEN_echo "【存储卷】"
    docker inspect --format='{{range .Mounts}}
    Source:      {{.Source}}
    Destination: {{.Destination}}
    Type:        {{.Type}}
    {{end}}' "$container_id_or_name"

    # 5. 环境变量
    BLUE_echo "------------------------------------------------------"
    GREEN_echo "【环境变量】"
    docker inspect --format='{{range .Config.Env}}{{.}}
    {{end}}' "$container_id_or_name"

    # 6. 资源限制
    BLUE_echo "------------------------------------------------------"
    GREEN_echo "【资源限制】"
    docker inspect --format='
    CPU:         {{.HostConfig.CpuShares}} shares
    Memory:      {{.HostConfig.Memory}} bytes
    MemorySwap:  {{.HostConfig.MemorySwap}} bytes
    ' "$container_id_or_name"

    # 7. 日志路径（需要jq）
    BLUE_echo "------------------------------------------------------"
    GREEN_echo "【日志配置】"
    logpath=$(sudo docker inspect --format='{{.LogPath}}' "$container_id_or_name" | xargs sudo ls)
    echo "日志路径($container_id_or_name): $logpath"
    sudo cat "$logpath"
    BLUE_echo "------------------------------------------------------------------------------------------"

}

# 列出本地镜像
_list_images() {
    GREEN_echo "本地镜像列表:"
    BLUE_echo "------------------------------------------------------------------------------------------"
    sudo ctr image list --format "table {{.ID}}\t{{.Repository}}:{{.Tag}}\t{{.Size}}\t{{.CreatedSince}}" | awk '{print NR-1,$0}'
    BLUE_echo "------------------------------------------------------------------------------------------"
    check_command "列出本地镜像"
}

# 搜索远程镜像
_search_image() {
    local image_name=$1
    BLUE_echo "------------------------------------------------------"
    GREEN_echo "搜索远程镜像: $image_name"
    docker search "$image_name"
    #docker search 始终指向 Docker Hub，不受镜像加速器配置影响。
    #若需搜索私有仓库中的镜像，需显式指定仓库地址:docker search <私有仓库地址>/<镜像名>
    check_command "搜索远程镜像 $image_name"
    BLUE_echo "------------------------------------------------------"
}

# 拉取镜像
_pull_image() {
    local _image_id=$1

    BLUE_echo "------------------------------------------------------"
    GREEN_echo "正在拉取镜像: $_image_id"
    docker pull "$_image_id"
    check_command "拉取镜像 $_image_id"
    BLUE_echo "------------------------------------------------------"
}

# 推送镜像
_push_image() {
    local _image_id=$1
    if [ -z "$_image_id" ]; then
        RED_echo "错误: 镜像输入信息不能为空"
        return 1
    fi

    BLUE_echo "------------------------------------------------------"
    GREEN_echo "正在推送镜像: $_image_id"
    docker push "$_image_id"
    check_command "推送镜像 $_image_id"
    BLUE_echo "------------------------------------------------------"
}

# 构建镜像
_build_image() {
    local dockerfile_path=$1
    local tag=$2
    BLUE_echo "------------------------------------------------------"
    GREEN_echo "正在构建镜像: $tag"
    docker build -t "$tag" "$dockerfile_path"
    check_command "构建镜像 $tag"
    BLUE_echo "------------------------------------------------------"
}

# 删除镜像
_remove_image() {
    local _image_id=${1}
    if [ -z "$_image_id" ]; then
        RED_echo "错误: 镜像输入信息不能为空"
        return 1
    fi

    BLUE_echo "------------------------------------------------------"
    green_echo "正在删除镜像: $_image_id"
    #return
    docker rmi "$_image_id"
    check_command "删除镜像 $_image_id"
    BLUE_echo "------------------------------------------------------"
}

# 镜像标签管理
_tag_image() {
    local _image_id=$1
    local _target_image=$2
    if [ -z "$_image_id" ] || [ -z "$_target_image" ]; then
        RED_echo "错误: 镜像输入信息不能为空"
        return 1
    fi

    BLUE_echo "------------------------------------------------------"
    GREEN_echo "正在标记镜像: $_image_id -> $_target_image"
    docker tag "$_image_id" "$_target_image"
    check_command "标记镜像 $_image_id 为 $_target_image"
    BLUE_echo "------------------------------------------------------"
}

# 查看镜像历史
_image_history() {
    local _image_id=$1
    if [ -z "$_image_id" ]; then
        RED_echo "错误: 镜像输入信息不能为空"
        return 1
    fi

    BLUE_echo "------------------------------------------------------"
    GREEN_echo "镜像历史记录: $_image_id"
    docker history "$_image_id"
    check_command "查看镜像 $_image_id 的历史记录"
    BLUE_echo "------------------------------------------------------"
}

# 列出所有容器
_list_containers() {
    BLUE_echo "------------------------------------------------------"
    GREEN_echo "正在列出所有容器..."
    #sudo docker ps -a
    sudo docker ps -a --format "table {{.ID}}\t{{.Image}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.Command}}" | awk '{print NR-1,$0}'
    check_command "列出容器"
    BLUE_echo "------------------------------------------------------"
}

# 管理容器状态
_manage_container_state() {
    local _container_id=$1
    local _action=$2
    if [ -z "$_container_id" ] || [ -z "$_action" ]; then
        RED_echo "错误: 容器ID或操作不能为空"
        return 1
    fi

    BLUE_echo "------------------------------------------------------"

    case $_action in
    start)
        docker start "$_container_id"
        check_command "启动容器 $_container_id"
        ;;
    stop)
        docker stop "$_container_id"
        check_command "停止容器 $_container_id"
        ;;
    restart)
        docker restart "$_container_id"
        check_command "重启容器 $_container_id"
        ;;
    remove)
        docker rm -f "$_container_id"
        check_command "删除容器 $_container_id"
        ;;
    *)
        RED_echo "无效操作: $_action"
        return 1
        ;;
    esac
}

# 监控容器资源
_monitor_container_resources() {
    local _container_id=$1

    BLUE_echo "------------------------------------------------------"
    GREEN_echo "正在监控容器资源使用情况..."
    sudo docker stats --no-stream $_container_id --format \
        "table {{.ID}}\t{{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.NetIO}}\t{{.BlockIO}}\t{{.PIDs}}" | awk '{print NR-1,$0}'
    check_command "监控容器资源"
    BLUE_echo "------------------------------------------------------"
}

# 查看容器日志
_view_container_logs() {
    local _container_id=$1
    local _lines=${2:-100}

    BLUE_echo "------------------------------------------------------"
    GREEN_echo "正在查看容器日志(最近${_lines}行)..."
    sudo docker logs --tail="$_lines" "$_container_id"
    check_command "查看容器日志"
    BLUE_echo "------------------------------------------------------"
}
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
                read -p "请输入时区(Deafult:"Asia/Shanghai"): " TIMEZONE
                gree_echo "输入信息:- 时区: ${TIMEZONE:-"Asia/Shanghai"}"
                _set_timezone ${TIMEZONE:-"Asia/Shanghai"}
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
            [ $usernow = "root" ] && KEY_PATH="root/.ssh/id_rsa.pub" || KEY_PATH="/home/$usernow/.ssh/id_rsa.pub"
            read -p "本地的密钥路径(默认:"$KEY_PATH"): " KEY_PATH
            if [ -z "$KEY_PATH" ]; then
                [ $usernow = "root" ] && KEY_PATH="root/.ssh/id_rsa.pub" || KEY_PATH="/home/$usernow/.ssh/id_rsa.pub"
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
            [ $usernow = "root" ] && KEY_PATH="root/.ssh/id_rsa.pub" || KEY_PATH="/home/$usernow/.ssh/id_rsa.pub"
            read -p "请输入证书文件路径(公钥|私钥, 默认:"$KEY_PATH"): " KEY_PATH
            if [ -z "$KEY_PATH" ]; then
                [ $usernow = "root" ] && KEY_PATH="root/.ssh/id_rsa.pub" || KEY_PATH="/home/$usernow/.ssh/id_rsa.pub"
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
        sudo apt-get install -y sshpass || {
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

#region 17) K8S管理
K8S_MGMT() {
    GREEN_echo "=========K8S管理功能=================="
    while true; do
        GREEN_echo "1)  工作负载管理"
        GREEN_echo "2)  节点管理"
        GREEN_echo "3)  命名空间管理"
        GREEN_echo "4)  集群管理"
        GREEN_echo "5)  网络策略管理(calico)"
        GREEN_echo "6)  存储管理"
        GREEN_echo "7)  Pod管理"
        GREEN_echo "8)  ConfigMap管理"
        GREEN_echo "9)  Secret管理"
        GREEN_echo "10) RBAC配置"
        GREEN_echo "11) 资源限制配置"
        GREEN_echo "12) 应用资源配置文件"
        GREEN_echo "13) 镜像管理(ctr)"
        GREEN_echo "14) Service管理"
        GREEN_echo "15) ingress管理"
        GREEN_echo "16) DNS管理"
        GREEN_echo "17) HPA自动扩缩管理"
        GREEN_echo "18) CRD自定义资源管理"
        GREEN_echo "19) 调度器配置管理"
        GREEN_echo "99) 进入到Shell终端"
        GREEN_echo "0)  返回上级"
        read -p "请选择管理项: " choice

        case $choice in
        1) k8s_workload_mgmt ;;
        2) k8s_node_mgmt ;;
        3) k8s_namespace_mgmt ;;
        4) k8s_cluster_mgmt ;;
        5) k8s_network_policy_mgmt ;;
        6) k8s_storage_mgmt ;;
        7) k8s_pod_mgmt ;;
        8) k8s_cm_mgmt ;;
        9) k8s_secret_mgmt ;;
        10) k8s_rbac_mgmt ;;
        11) k8s_resource_limits_mgmt ;;
        12) k8s_resource_config_apply ;;
        13) k8s_image_operations ;;
        14) k8s_svc_mgmt ;;
        15) k8s_ingress_mgmt ;;
        16) k8s_dns_mgmt ;;
        17) hpa_management ;;
        18) crd_management ;;
        19) scheduler_management ;;
        99) bash ;;
        0) break ;;
        *) echo "无效选择" ;;
        esac
    done
}
# 集群管理
k8s_cluster_mgmt() {
    if [ $# -gt 0 ]; then
        [ $1 = "status" ] && _k8s_cluster_status
        [ $1 = "health" ] && _k8s_cluster_health
        [ $1 = "upgrade" ] && version=$2 && _k8s_cluster_upgrade "$version"
        [ $1 = "backup" ] && backup_file=$2 && _k8s_cluster_backup "$backup_file"
        [ $1 = "restore" ] && backup_file=$2 && _k8s_cluster_restore "$backup_file"
    else
        # 主交互逻辑
        while true; do
            BLUE_echo "------------------------------------------------------"
            GREEN_echo "K8S集群管理选项:"
            GREEN_echo "  1. 集群状态查看"
            GREEN_echo "  2. 集群组件健康检查"
            GREEN_echo "  3. 集群版本升级"
            GREEN_echo "  4. 集群备份"
            GREEN_echo "  5. 集群恢复"
            GREEN_echo "  0. 返回"
            BLUE_echo "------------------------------------------------------"
            read -p "请输入选项[0-5]: " choice
            case $choice in
            1)
                _k8s_cluster_status
                ;;
            2)
                _k8s_cluster_health
                ;;
            3)
                read -p "请输入要升级的版本号: " version
                green_echo "输入信息为- 版本号: $version "
                read -p "请确认操作(Y|N,default:Y): " areyouok
                areyouok="${areyouok:-Y}"
                [ "$areyouok" = "Y" ] && _k8s_cluster_upgrade "$version"
                ;;
            4)
                read -p "请输入备份文件名: " backup_file
                green_echo "输入信息为- 文件: $backup_file "
                read -p "请确认操作(Y|N,default:Y): " areyouok
                areyouok="${areyouok:-Y}"
                [ "$areyouok" = "Y" ] && _k8s_cluster_backup "$backup_file"
                ;;
            5)
                read -p "请输入备份文件名: " backup_file
                green_echo "输入信息为- 文件: $backup_file "
                read -p "请确认操作(Y|N,default:Y): " areyouok
                areyouok="${areyouok:-Y}"
                [ "$areyouok" = "Y" ] && _k8s_cluster_restore "$backup_file"
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

hpa_management() {
    if [ $# -gt 0 ]; then
        [ $1 = "list" ] && _hpa_list
        [ $1 = "create" ] && namespace=$2 && hpa_name=$3 && min_replicas=$4 && max_replicas=$5 && target_cpu=$6 && _hpa_create "$namespace" "$hpa_name" "$min_replicas" "$max_replicas" "$target_cpu"
        [ $1 = "delete" ] && namespace=$2 && hpa_name=$3 && _hpa_delete "$namespace" "$hpa_name"
    else
        # 主交互逻辑
        while true; do
            BLUE_echo "------------------------------------------------------"
            GREEN_echo "HPA自动扩缩管理选项:"
            GREEN_echo "  1. 列出所有HPA"
            GREEN_echo "  2. 创建HPA"
            GREEN_echo "  3. 删除HPA"
            GREEN_echo "  0. 返回"
            BLUE_echo "------------------------------------------------------"
            read -p "请输入选项[0-3]: " choice
            case $choice in
            1)
                _hpa_list
                ;;
            2)
                read -p "请输入命名空间: " namespace
                read -p "请输入HPA名称: " hpa_name
                read -p "请输入最小副本数: " min_replicas
                read -p "请输入最大副本数: " max_replicas
                read -p "请输入目标CPU利用率(百分比): " target_cpu
                green_echo "输入信息为- 命名空间: $namespace, HPA名称: $hpa_name, 最小副本数: $min_replicas, 最大副本数: $max_replicas, 目标CPU利用率: $target_cpu%"
                read -p "请确认操作(Y|N,default:Y): " areyouok
                areyouok="${areyouok:-Y}"
                [ "$areyouok" = "Y" ] && _hpa_create "$namespace" "$hpa_name" "$min_replicas" "$max_replicas" "$target_cpu"
                ;;
            3)
                read -p "请输入命名空间: " namespace
                read -p "请输入HPA名称: " hpa_name
                green_echo "输入信息为- 命名空间: $namespace, HPA名称: $hpa_name"
                read -p "请确认操作(Y|N,default:Y): " areyouok
                areyouok="${areyouok:-Y}"
                [ "$areyouok" = "Y" ] && _hpa_delete "$namespace" "$hpa_name"
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

crd_management() {
    if [ $# -gt 0 ]; then
        [ $1 = "list" ] && _crd_list
        [ $1 = "describe" ] && crd_name=$2 && _crd_describe "$crd_name"
        [ $1 = "delete" ] && crd_name=$2 && _crd_delete "$crd_name"
    else
        # 主交互逻辑
        while true; do
            BLUE_echo "------------------------------------------------------"
            GREEN_echo "CRD自定义资源管理选项:"
            GREEN_echo "  1. 列出所有CRD"
            GREEN_echo "  2. 查看CRD详情"
            GREEN_echo "  3. 删除CRD"
            GREEN_echo "  0. 返回"
            BLUE_echo "------------------------------------------------------"
            read -p "请输入选项[0-3]: " choice
            case $choice in
            1)
                _crd_list
                ;;
            2)
                local crd_list=$(kubectl get crd | awk '{print NR-1,$0}')
                echo "$crd_list"
                crd_numb=
                read -p "请输入crd编号: " crd_numb
                local crd_name=$(echo "$crd_list" | awk -v line="$((crd_numb + 1))" 'NR==line{print $2}')
                green_echo "输入信息为:- crd: $crd_name"
                read -p "请确认操作(Y|N,default:Y): " areyouok
                areyouok="${areyouok:-Y}"
                [ "$areyouok" = "Y" ] && _crd_describe "$crd_name"
                ;;
            3)
                crd_list=$(kubectl get crd | awk '{print NR-1,$0}')
                echo "$crd_list"
                crd_numb=
                read -p "请输入crd编号: " crd_numb
                local crd_name=$(echo "$crd_list" | awk -v line="$((crd_numb + 1))" 'NR==line{print $2}')
                green_echo "输入信息为:- crd: $crd_name"
                read -p "请确认操作(Y|N,default:Y): " areyouok
                areyouok="${areyouok:-Y}"
                [ "$areyouok" = "Y" ] && _crd_delete "$crd_name"
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

scheduler_management() {
    if [ $# -gt 0 ]; then
        [ $1 = "view" ] && _scheduler_view
        [ $1 = "edit" ] && _scheduler_edit
        [ $1 = "reset" ] && _scheduler_reset
    else
        # 主交互逻辑
        while true; do
            BLUE_echo "------------------------------------------------------"
            GREEN_echo "调度器配置管理选项:"
            GREEN_echo "  1. 查看当前调度器配置"
            GREEN_echo "  2. 编辑调度器配置"
            GREEN_echo "  3. 重置调度器配置"
            GREEN_echo "  0. 返回"
            BLUE_echo "------------------------------------------------------"
            read -p "请输入选项[0-3]: " choice
            case $choice in
            1)
                _scheduler_view
                ;;
            2)
                read -p "请确认要编辑调度器配置(Y|N,default:Y): " areyouok
                areyouok="${areyouok:-Y}"
                [ "$areyouok" = "Y" ] && _scheduler_edit
                ;;
            3)
                read -p "请确认要重置调度器配置(Y|N,default:Y): " areyouok
                areyouok="${areyouok:-Y}"
                [ "$areyouok" = "Y" ] && _scheduler_reset
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

k8s_image_operations() {
    if [ $# -gt 0 ]; then
        local image_name target_name output filepath
        case "$1" in
        list | 1)
            _k8s_list_images "${2:-default}"
            ;;
        pull)
            image_name="$2"
            _k8s_pull_image "${3:-default}" "$image_name"
            ;;
        push)
            image_name="$2"
            _k8s_push_image "$image_name" "${3:-default}"
            ;;
        remove)
            image_name="$2"
            _k8s_remove_image "$image_name" "${3:-default}"
            ;;
        tag)
            image_name="$2"
            target_name="$3"
            _k8s_tag_image "$image_name" "$target_name" "${4:-default}"
            ;;
        export)
            image_name="$2"
            output="${3:-.}"
            _k8s_export_image "$image_name" "$output" "${4:-default}"
            ;;
        import)
            filepath="$2"
            _k8s_import_image "$filepath" "${3:-default}"
            ;;
        *)
            echo "未知操作: $1（支持 list/pull/push/remove/tag/export/import）" >&2
            return 2
            ;;
        esac
    else
        # 主交互逻辑
        while true; do
            BLUE_echo "------------------------------------------------------"
            GREEN_echo "镜像管理选项:"
            GREEN_echo "  1. 列出本地镜像"
            GREEN_echo "  2. 拉取镜像"
            GREEN_echo "  3. 推送镜像"
            GREEN_echo "  4. 删除镜像"
            GREEN_echo "  5. 镜像标签管理"
            GREEN_echo "  6. 导出镜像为tar包"
            GREEN_echo "  7. 导入tar包为镜像"
            GREEN_echo "  0. 返回"
            BLUE_echo "------------------------------------------------------"
            read -p "请输入选项[0-8]: " choice
            case $choice in
            1)
                local ns_list_snap=$(kubectl get namespaces | awk '{print NR-1,$0}')
                echo "$ns_list_snap"
                ns_numb=
                read -p "请输入命名空间编号(默认:default): " ns_numb
                [ -n "$ns_numb" ] && local namespace=$(echo "$ns_list_snap" | awk -v line="$((ns_numb + 1))" 'NR==line{print $2}')
                green_echo "输入信息为:- namespace: ${namespace:-"default"}"
                read -p "请确认操作(Y|N,default:Y): " areyouok
                areyouok="${areyouok:-Y}"
                [ "$areyouok" = "Y" ] && _k8s_list_images ${namespace:-"default"}
                ;;
            2)
                local ns_list_snap=$(kubectl get namespaces | awk '{print NR-1,$0}')
                echo "$ns_list_snap"
                ns_numb=
                read -p "请输入命名空间编号(默认:default): " ns_numb
                [ -n "$ns_numb" ] && local namespace=$(echo "$ns_list_snap" | awk -v line="$((ns_numb + 1))" 'NR==line{print $2}')
                read -p "请输入要拉取的镜像信息(如:docker.io/calico/apiserver:v3.29.1 ): " image_name
                green_echo "输入信息为:- namespace: ${namespace:-"default"} | image_name: $image_name"
                read -p "请确认操作(Y|N,default:Y): " areyouok
                areyouok="${areyouok:-Y}"
                [ "$areyouok" = "Y" ] && _k8s_pull_image ${namespace:-"default"} $image_name
                ;;
            3)
                local ns_list_snap=$(kubectl get namespaces | awk '{print NR-1,$0}')
                echo "$ns_list_snap"
                ns_numb=
                read -p "请输入命名空间编号(默认:default): " ns_numb
                [ -n "$ns_numb" ] && local namespace=$(echo "$ns_list_snap" | awk -v line="$((ns_numb + 1))" 'NR==line{print $2}')
                local image_list_sanp=$(sudo ctr -n ${namespace:-"default"} images list | awk '{print NR-1,$0}')
                echo "$image_list_sanp"
                read -p "请输入镜像的序号: " image_num
                local image_name=$(echo "$image_list_sanp" | awk -v line="$((image_num + 1))" 'NR==line{print $2}')
                green_echo "选择需要推送的镜像信息: image_name: $image_name | namespace: ${namespace:-"default"}"
                read -p "请确认操作(Y|N,default:Y): " areyouok
                areyouok="${areyouok:-Y}"
                [ "$areyouok" = "Y" ] && _k8s_push_image $image_name "${namespace:-"default"}"
                ;;
            4)
                local ns_list_snap=$(kubectl get namespaces | awk '{print NR-1,$0}')
                echo "$ns_list_snap"
                ns_numb=
                read -p "请输入命名空间编号(默认:default): " ns_numb
                [ -n "$ns_numb" ] && local namespace=$(echo "$ns_list_snap" | awk -v line="$((ns_numb + 1))" 'NR==line{print $2}')
                local image_list_sanp=$(sudo ctr -n ${namespace:-"default"} images list | awk '{print NR-1,$0}')
                echo "$image_list_sanp"
                read -p "请输入镜像的序号: " image_num
                local image_name=$(echo "$image_list_sanp" | awk -v line="$((image_num + 1))" 'NR==line{print $2}')
                green_echo "选择需要删除的镜像信息: image_name: $image_name | namespace: ${namespace:-"default"}"
                read -p "请确认操作(Y|N,default:Y): " areyouok
                areyouok="${areyouok:-Y}"
                [ "$areyouok" = "Y" ] && _k8s_remove_image $image_name "${namespace:-"default"}"
                ;;
            5)
                local ns_list_snap=$(kubectl get namespaces | awk '{print NR-1,$0}')
                echo "$ns_list_snap"
                ns_numb=
                read -p "请输入命名空间编号(默认:default): " ns_numb
                [ -n "$ns_numb" ] && local namespace=$(echo "$ns_list_snap" | awk -v line="$((ns_numb + 1))" 'NR==line{print $2}')
                local image_list_sanp=$(sudo ctr -n ${namespace:-"default"} images list | awk '{print NR-1,$0}')
                echo "$image_list_sanp"
                read -p "请输入镜像的序号: " image_num
                local image_name=$(echo "$image_list_sanp" | awk -v line="$((image_num + 1))" 'NR==line{print $2}')
                read -p "请输入目标镜像的标签信息: " target_image
                green_echo "选择需要标签维护的镜像信息: image_name: $image_name | 目标标签: $target_image | namespace: ${namespace:-"default"}"
                read -p "请确认操作(Y|N,default:Y): " areyouok
                areyouok="${areyouok:-Y}"
                [ "$areyouok" = "Y" ] && _k8s_tag_image $image_name $target_image "${namespace:-"default"}"
                ;;
            6)
                local ns_list_snap=$(kubectl get namespaces | awk '{print NR-1,$0}')
                echo "$ns_list_snap"
                ns_numb=
                read -p "请输入命名空间编号(默认:default): " ns_numb
                [ -n "$ns_numb" ] && local namespace=$(echo "$ns_list_snap" | awk -v line="$((ns_numb + 1))" 'NR==line{print $2}')
                local image_list_sanp=$(sudo ctr -n ${namespace:-"default"} images list | awk '{print NR-1,$0}')
                echo "$image_list_sanp"
                read -p "请输入镜像的序号: " image_num
                local image_name=$(echo "$image_list_sanp" | awk -v line="$((image_num + 1))" 'NR==line{print $2}')
                read -p "请输入输出文件名(例如:image_v1.0.tar): " output
                green_echo "选择需要导出的镜像信息: $image_name | 路径: ${output:-"."} | namespace: ${namespace:-"default"}"
                read -p "请确认操作(Y|N,default:Y): " areyouok
                areyouok="${areyouok:-Y}"
                [ "$areyouok" = "Y" ] && _k8s_export_image "$image_name" "${output:-"."}" "${namespace:-"default"}"
                ;;
            7)
                local ns_list_snap=$(kubectl get namespaces | awk '{print NR-1,$0}')
                echo "$ns_list_snap"
                ns_numb=
                read -p "请输入命名空间编号(默认:default): " ns_numb
                [ -n "$ns_numb" ] && local namespace=$(echo "$ns_list_snap" | awk -v line="$((ns_numb + 1))" 'NR==line{print $2}')
                read -p "请输入要导入的tar文件路径: " image_file
                green_echo "输入的内容-  文件: $image_file | namespace: ${namespace:-"default"} "
                yellow_echo "镜像名称: 镜像名称将会是tar包导出前的名字,无法变化,请先确认镜像库中没有同名的,否则会被覆盖"
                read -p "请确认操作(Y|N,default:Y): " areyouok
                areyouok="${areyouok:-Y}"
                [ "$areyouok" = "Y" ] && _k8s_import_image "$image_file" "${namespace:-"default"}"
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

# 节点管理
k8s_node_mgmt() {
    if [ $# -gt 0 ]; then
        [ $1 = "status" ] && _k8s_node_status "$2"
        [ $1 = "add" ] && node_name=$2 && _k8s_node_add "$node_name"
        [ $1 = "remove" ] && node_name=$2 && _k8s_node_remove "$node_name"
        [ $1 = "maintenance" ] && node_name=$2 && action=$3 && _k8s_node_maintenance "$node_name" "$action"
        [ $1 = "monitor" ] && node_name=$2 && _k8s_node_monitor "$node_name"
    else
        # 主交互逻辑
        while true; do
            BLUE_echo "------------------------------------------------------"
            GREEN_echo "K8S节点管理选项:"
            GREEN_echo "  1. 查看节点状态"
            GREEN_echo "  2. 添加节点"
            GREEN_echo "  3. 删除节点"
            GREEN_echo "  4. 节点维护模式"
            GREEN_echo "  5. 节点资源监控"
            GREEN_echo "  0. 返回"
            BLUE_echo "------------------------------------------------------"
            read -p "请输入选项[0-5]: " choice
            case $choice in
            1)
                read -p "请输入节点名称(可选，留空查看所有节点): " node_name
                green_echo "输入信息为-  node_name: $node_name "
                read -p "请确认操作(Y|N,default:Y): " areyouok
                areyouok="${areyouok:-Y}"
                [ "$areyouok" = "Y" ] && _k8s_node_status "$node_name"

                ;;
            2)
                _k8s_node_status
                read -p "请输入主节点IP: " master
                read -p "请输入要添加的节点名称: " node_name
                read -p "请输入加入令牌: " JOIN_TOKEN
                read -p "请输入发现证书哈希: " DISCOVERY_TOKEN_CA_CERT_HASH
                green_echo "输入信息为: master: $master | node_name: $node_name | JOIN_TOKEN: $JOIN_TOKEN | DISCOVERY_TOKEN_CA_CERT_HASH: $DISCOVERY_TOKEN_CA_CERT_HASH"
                read -p "请确认操作(Y|N,default:Y): " areyouok
                areyouok="${areyouok:-Y}"
                [ "$areyouok" = "Y" ] && _k8s_node_add "$master" "$node_name" "$JOIN_TOKEN" "$DISCOVERY_TOKEN_CA_CERT_HASH"
                ;;
            3)
                _k8s_node_status
                read -p "请输入要删除的节点名称: " node_name
                green_echo "输入信息为-  node_name: $node_name "
                read -p "请确认操作(Y|N,default:Y): " areyouok
                areyouok="${areyouok:-Y}"
                [ "$areyouok" = "Y" ] && _k8s_node_remove "$node_name"
                ;;
            4)
                _k8s_node_status
                read -p "请输入节点名称: " node_name
                read -p "请输入操作(enable/disable): " action
                green_echo "输入信息为-  node_name: $node_name | action: $action"
                read -p "请确认操作(Y|N,default:Y): " areyouok
                areyouok="${areyouok:-Y}"
                [ "$areyouok" = "Y" ] && _k8s_node_maintenance "$node_name" "$action"
                ;;
            5)
                _k8s_node_status
                read -p "请输入节点名称: " node_name
                green_echo "输入信息为-  node_name: $node_name "
                read -p "请确认操作(Y|N,default:Y): " areyouok
                areyouok="${areyouok:-Y}"
                [ "$areyouok" = "Y" ] && _k8s_node_monitor "$node_name"
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

# 命名空间管理
k8s_namespace_mgmt() {
    if [ $# -gt 0 ]; then
        [ $1 = "list" ] && _k8s_namespace_list
        [ $1 = "create" ] && namespace=$2 && _k8s_namespace_create "$namespace"
        [ $1 = "delete" ] && namespace=$2 && _k8s_namespace_delete "$namespace"
        [ $1 = "quota" ] && namespace=$2 && quota_file=$3 && _k8s_namespace_quota "$namespace" "$quota_file"
        [ $1 = "usage" ] && namespace=$2 && _k8s_namespace_usage "$namespace"
    else
        # 交互逻辑
        while true; do
            BLUE_echo "------------------------------------------------------"
            GREEN_echo "K8S命名空间管理选项:"
            GREEN_echo "  1. 查看命名空间列表"
            GREEN_echo "  2. 创建命名空间"
            GREEN_echo "  3. 删除命名空间"
            GREEN_echo "  4. 设置资源配额"
            GREEN_echo "  5. 查看资源使用情况"
            GREEN_echo "  0. 返回"
            BLUE_echo "------------------------------------------------------"
            read -p "请输入选项[0-5]: " choice

            case $choice in
            1)
                _k8s_namespace_list
                ;;
            2)
                _k8s_namespace_list
                read -p "请输入要创建的命名空间名称: " namespace
                green_echo "输入信息为- 命名空间: $namespace"
                read -p "请确认操作(Y|N,default:Y): " areyouok
                areyouok="${areyouok:-Y}"
                [ "$areyouok" = "Y" ] && _k8s_namespace_create "$namespace"
                ;;
            3)
                _k8s_namespace_list
                read -p "请输入要删除的命名空间名称: " namespace
                green_echo "输入信息为- 命名空间: $namespace"
                read -p "请确认操作(Y|N,default:Y): " areyouok
                areyouok="${areyouok:-Y}"
                [ "$areyouok" = "Y" ] && _k8s_namespace_delete "$namespace"
                ;;
            4)
                _k8s_namespace_list
                read -p "请输入命名空间名称: " namespace
                read -p "请输入资源配额文件路径: " quota_file
                green_echo "输入信息为- 命名空间: $namespace, 配额文件: $quota_file"
                read -p "请确认操作(Y|N,default:Y): " areyouok
                areyouok="${areyouok:-Y}"
                [ "$areyouok" = "Y" ] && _k8s_namespace_quota "$namespace" "$quota_file"
                ;;
            5)
                _k8s_namespace_list
                read -p "请输入命名空间名称: " namespace
                green_echo "输入信息为- 命名空间: $namespace"
                read -p "请确认操作(Y|N,default:Y): " areyouok
                areyouok="${areyouok:-Y}"
                [ "$areyouok" = "Y" ] && _k8s_namespace_usage "$namespace"
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

# 工作负载管理
k8s_workload_mgmt() {
    if [ $# -gt 0 ]; then
        [ $1 = "deployment" ] && _k8s_workload_deployment_list
        [ $1 = "statefulset" ] && _k8s_workload_statefulset_list
        [ $1 = "daemonset" ] && _k8s_workload_daemonset_list
        [ $1 = "cronjob" ] && _k8s_workload_cronjob_list
    else
        # 主交互逻辑
        while true; do
            BLUE_echo "------------------------------------------------------"
            GREEN_echo "K8S工作负载管理选项:"
            GREEN_echo "  1. Deployment管理"
            GREEN_echo "  2. StatefulSet管理"
            GREEN_echo "  3. DaemonSet管理"
            GREEN_echo "  4. CronJob管理"
            GREEN_echo "  0. 返回"
            BLUE_echo "------------------------------------------------------"
            read -p "请输入选项[0-5]: " choice
            case $choice in
            1)
                _k8s_workload_deployment_list
                ;;
            2)
                _k8s_workload_statefulset_list
                ;;
            3)
                _k8s_workload_daemonset_list
                ;;
            4)
                _k8s_workload_cronjob_list
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

# 网络管理
k8s_network_policy_mgmt() {
    if [ $# -gt 0 ]; then
        [ $1 = "list" ] && _k8s_network_policy_list
        [ $1 = "detail" ] && _k8s_network_policy_detail "$2" "$3"
        [ $1 = "create" ] && _k8s_network_policy_create "$2"
        [ $1 = "delete" ] && _k8s_network_policy_delete "$2" "$3"
        [ $1 = "update" ] && _k8s_network_policy_update "$2"
    else
        # 主交互逻辑
        while true; do
            BLUE_echo "------------------------------------------------------"
            GREEN_echo "K8S网络策略(calico)管理选项:"
            GREEN_echo "  1. 查看所有 NetworkPolicy 列表"
            GREEN_echo "  2. 查看 NetworkPolicy 详细信息"
            GREEN_echo "  3. 创建\更新 NetworkPolicy"
            GREEN_echo "  4. 删除 NetworkPolicy"
            GREEN_echo "  0. 返回"
            BLUE_echo "------------------------------------------------------"
            read -p "请输入选项[0-5]: " choice
            case $choice in
            1)
                _k8s_network_policy_list
                ;;
            2)
                local policy_list=$(kubectl get networkpolicy --all-namespaces | awk '{print NR-1,$0}')
                echo "$policy_list"
                read -p "请输入要查看的NetworkPolicy编号: " policy_num
                local policy_name=$(echo "$policy_list" | awk -v line="$((policy_num + 1))" 'NR==line{print $3}')
                local namespace=$(echo "$policy_list" | awk -v line="$((policy_num + 1))" 'NR==line{print $2}')
                green_echo "输入信息为- NetworkPolicy: $policy_name, 命名空间: $namespace"
                read -p "请确认操作(Y|N,default:Y): " areyouok
                [ "${areyouok:-Y}" = "Y" ] && _k8s_network_policy_detail "$policy_name" "$namespace"
                ;;
            3)
                read -p "请输入 YAML 文件路径: " yaml_file
                green_echo "输入信息为- YAML 文件: $yaml_file"
                read -p "请确认操作(Y|N,default:Y): " areyouok
                areyouok="${areyouok:-Y}"
                [ "$areyouok" = "Y" ] && _k8s_network_policy_apply "$yaml_file"
                ;;
            5)
                local policy_list=$(kubectl get networkpolicy --all-namespaces | awk '{print NR-1,$0}')
                echo "$policy_list"
                read -p "请输入要删除的NetworkPolicy编号: " policy_num
                local policy_name=$(echo "$policy_list" | awk -v line="$((policy_num + 1))" 'NR==line{print $3}')
                local namespace=$(echo "$policy_list" | awk -v line="$((policy_num + 1))" 'NR==line{print $2}')
                green_echo "输入信息为- NetworkPolicy: $policy_name, 命名空间: $namespace"
                read -p "请确认操作(Y|N,default:Y): " areyouok
                areyouok="${areyouok:-Y}"
                [ "$areyouok" = "Y" ] && _k8s_network_policy_delete "$policy_name" "$namespace"
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

k8s_svc_mgmt() {
    if [ $# -gt 0 ]; then
        [ $1 = "list" ] && _k8s_network_service_list
        [ $1 = "detail" ] && _k8s_network_service_detail "$2" "$3"
        [ $1 = "create" ] && _k8s_network_service_create "$2"
        [ $1 = "delete" ] && _k8s_network_service_delete "$2" "$3"
        [ $1 = "update" ] && _k8s_network_service_update "$2"
    else
        # 主交互逻辑
        while true; do
            BLUE_echo "------------------------------------------------------"
            GREEN_echo "K8S Service 管理选项:"
            GREEN_echo "  1. 查看所有 Service 列表"
            GREEN_echo "  2. 查看 Service 详细信息"
            GREEN_echo "  3. 创建\更新 Service"
            GREEN_echo "  4. 删除 Service"
            GREEN_echo "  0. 返回"
            BLUE_echo "------------------------------------------------------"
            read -p "请输入选项[0-5]: " choice

            case $choice in
            1)
                _k8s_network_service_list
                ;;
            2)
                local svc_list_snap=$(sudo kubectl get svc --all-namespaces | awk '{print NR-1,$0}')
                echo "$svc_list_snap"
                read -p "请输入要查看SVC的编号: " pod_bumb
                local svc_name=$(echo "$svc_list_snap" | awk -v line="$((pod_bumb + 1))" 'NR==line{print $3}')
                local namespace=$(echo "$svc_list_snap" | awk -v line="$((pod_bumb + 1))" 'NR==line{print $2}')
                green_echo "输入信息为- Service: $svc_name, 命名空间: $namespace"
                read -p "请确认操作(Y|N,default:Y): " areyouok
                [ "${areyouok:-Y}" = "Y" ] && _k8s_network_service_detail "$svc_name" "$namespace"
                ;;
            3)
                read -p "请输入 YAML 文件路径: " yaml_file
                green_echo "输入信息为- YAML 文件: $yaml_file"
                read -p "请确认操作(Y|N,default:Y): " areyouok
                areyouok="${areyouok:-Y}"
                [ "$areyouok" = "Y" ] && _k8s_network_service_apply "$yaml_file"
                ;;
            4)
                local svc_list_snap=$(sudo kubectl get svc --all-namespaces | awk '{print NR-1,$0}')
                echo "$svc_list_snap"
                read -p "请输入要查看SVC的编号: " pod_bumb
                local svc_name=$(echo "$svc_list_snap" | awk -v line="$((pod_bumb + 1))" 'NR==line{print $3}')
                local namespace=$(echo "$svc_list_snap" | awk -v line="$((pod_bumb + 1))" 'NR==line{print $2}')
                green_echo "输入信息为- Service: $svc_name, 命名空间: $namespace"
                read -p "请确认操作(Y|N,default:Y): " areyouok
                areyouok="${areyouok:-Y}"
                [ "$areyouok" = "Y" ] && _k8s_network_service_delete "$svc_name" "$namespace"
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

k8s_ingress_mgmt() {
    if [ $# -gt 0 ]; then
        [ $1 = "list" ] && _k8s_network_ingress_list
        [ $1 = "detail" ] && _k8s_network_ingress_detail "$2" "$3"
        [ $1 = "create" ] && _k8s_network_ingress_create "$2"
        [ $1 = "delete" ] && _k8s_network_ingress_delete "$2" "$3"
    else
        # 主交互逻辑
        while true; do
            BLUE_echo "------------------------------------------------------"
            GREEN_echo "K8S Ingress 管理选项:"
            GREEN_echo "  1. 查看所有 Ingress 列表"
            GREEN_echo "  2. 查看 Ingress 详细信息"
            GREEN_echo "  3. 创建/更新 Ingress (通过YAML)"
            GREEN_echo "  4. 删除 Ingress"
            GREEN_echo "  0. 返回"
            BLUE_echo "------------------------------------------------------"
            read -p "请输入选项[0-4]: " choice

            case $choice in
            1)
                _k8s_network_ingress_list
                ;;
            2)
                local ingress_list=$(kubectl get ingress --all-namespaces | awk '{print NR-1,$0}')
                echo "$ingress_list"
                read -p "请输入要查看的Ingress编号: " ingress_num
                local ingress_name=$(echo "$ingress_list" | awk -v line="$((ingress_num + 1))" 'NR==line{print $3}')
                local namespace=$(echo "$ingress_list" | awk -v line="$((ingress_num + 1))" 'NR==line{print $2}')
                green_echo "输入信息为- Ingress: $ingress_name, 命名空间: $namespace"
                read -p "请确认操作(Y|N,default:Y): " areyouok
                [ "${areyouok:-Y}" = "Y" ] && _k8s_network_ingress_detail "$ingress_name" "$namespace"
                ;;
            3)
                read -p "请输入 YAML 文件路径: " yaml_file
                green_echo "输入信息为- YAML 文件: $yaml_file"
                read -p "请确认操作(Y|N,default:Y): " areyouok
                [ "${areyouok:-Y}" = "Y" ] && _k8s_network_ingress_create "$yaml_file"
                ;;
            4)
                local ingress_list=$(kubectl get ingress --all-namespaces | awk '{print NR-1,$0}')
                echo "$ingress_list"
                read -p "请输入要删除的Ingress编号: " ingress_num
                local ingress_name=$(echo "$ingress_list" | awk -v line="$((ingress_num + 1))" 'NR==line{print $3}')
                local namespace=$(echo "$ingress_list" | awk -v line="$((ingress_num + 1))" 'NR==line{print $2}')
                green_echo "输入信息为- Ingress: $ingress_name, 命名空间: $namespace"
                read -p "请确认操作(Y|N,default:Y): " areyouok
                [ "${areyouok:-Y}" = "Y" ] && _k8s_network_ingress_delete "$ingress_name" "$namespace"
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

k8s_dns_mgmt() {
    if [ $# -gt 0 ]; then
        [ $1 = "list" ] && _k8s_network_dns_check
        [ $1 = "config" ] && _k8s_network_dns_config "$2"
    else
        # 主交互逻辑
        while true; do
            BLUE_echo "------------------------------------------------------"
            GREEN_echo "K8S DNS 管理选项:"
            GREEN_echo "  1. 检查 DNS 状态"
            GREEN_echo "  2. 配置 DNS"
            GREEN_echo "  0. 返回"
            BLUE_echo "------------------------------------------------------"
            read -p "请输入选项[0-2]: " choice

            case $choice in
            1)
                _k8s_network_dns_check
                ;;
            2)
                read -p "请输入 CoreDNS 配置文件名: " dns_config
                GREEN_echo "输入信息为- 配置文件: $dns_config"
                read -p "请确认操作(Y|N,default:Y): " areyouok
                areyouok="${areyouok:-Y}"
                [ "$areyouok" = "Y" ] && _k8s_network_dns_config "$dns_config"
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
# 存储管理
k8s_storage_mgmt() {
    # 主交互逻辑
    if [ $# -gt 0 ]; then
        [ $1 = "pv" ] && _k8s_storage_pv_list
        [ $1 = "pvc" ] && _k8s_storage_pvc_list
        [ $1 = "sc" ] && _k8s_storage_sc_list
        [ $1 = "monitor" ] && _k8s_storage_monitor
    else
        while true; do
            BLUE_echo "------------------------------------------------------"
            GREEN_echo "K8S存储管理选项:"
            GREEN_echo "  1. PersistentVolume管理"
            GREEN_echo "  2. PersistentVolumeClaim管理"
            GREEN_echo "  3. StorageClass管理"
            GREEN_echo "  4. 存储资源监控"
            GREEN_echo "  0. 返回"
            BLUE_echo "------------------------------------------------------"
            read -p "请输入选项[0-4]: " choice
            case $choice in
            1)
                _k8s_storage_pv_list
                ;;
            2)
                _k8s_storage_pvc_list
                ;;
            3)
                _k8s_storage_sc_list
                ;;
            4)
                _k8s_storage_monitor
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

# 7) Pod管理路由
k8s_pod_mgmt() {
    if [ $# -gt 0 ]; then
        [ $1 = "list" ] && _k8s_pod_list
        [ $1 = "describe" ] && pod_name=$2 && _k8s_pod_describe "$pod_name"
        [ $1 = "exec" ] && pod_name=$2 && command=$3 && _k8s_pod_exec "$pod_name" "$command"
        [ $1 = "delete" ] && pod_name=$2 && _k8s_pod_delete "$pod_name"
        [ $1 = "restart" ] && pod_name=$2 && _k8s_pod_restart "$pod_name"
        [ $1 = "export" ] && pod_name=$2 && output_file=$3 && _k8s_pod_export "$pod_name" "$output_file"
        [ $1 = "logs" ] && pod_name=$2 && _k8s_pod_logs "$pod_name"
        [ $1 = "label" ] && pod_name=$2 && label_key=$3 && label_value=$4 && _k8s_pod_label "$pod_name" "$label_key" "$label_value"
        [ $1 = "resources" ] && pod_name=$2 && _k8s_pod_resources "$pod_name"
        [ $1 = "events" ] && pod_name=$2 && _k8s_pod_events "$pod_name"
        [ $1 = "copy" ] && pod_name=$2 && src_path=$3 && dest_path=$4 && _k8s_pod_copy "$pod_name" "$src_path" "$dest_path"
    else
        # 主交互逻辑
        while true; do
            clear
            BLUE_echo "------------------------------------------------------"
            GREEN_echo "Pod 管理菜单:"
            GREEN_echo "  1) 所有Pod清单"
            GREEN_echo "  2) 查看Pod详情"
            GREEN_echo "  3) Pod执行命令(exec|sh)"
            GREEN_echo "  4) 删除Pod"
            GREEN_echo "  5) 重启Pod"
            GREEN_echo "  6) 导出Pod配置"
            GREEN_echo "  7) 查看Pod日志"
            GREEN_echo "  8) 修改Pod标签"
            GREEN_echo "  9) 查看Pod资源使用情况"
            GREEN_echo " 10) 查看Pod事件"
            GREEN_echo " 11) 复制Pod文件"
            GREEN_echo "  0) 返回上级菜单"
            BLUE_echo "------------------------------------------------------"
            read -p "请输入选项[0-11]: " choice

            case $choice in
            1)
                _k8s_pod_list
                ;;
            2)
                local pod_list_snap=$(sudo kubectl get pods -A -o wide | awk '{print NR-1,$0}')
                echo "$pod_list_snap"
                read -p "请输入要查看Pod的编号: " pod_bumb
                local pod_name=$(echo "$pod_list_snap" | awk -v line="$((pod_bumb + 1))" 'NR==line{print $3}')
                local pod_ns=$(echo "$pod_list_snap" | awk -v line="$((pod_bumb + 1))" 'NR==line{print $2}')
                green_echo "输入信息为- Pod名称: $pod_name | 命名空间: $pod_ns"
                read -p "请确认操作(Y|N,default:Y): " areyouok
                areyouok="${areyouok:-Y}"
                [ "$areyouok" = "Y" ] && _k8s_pod_describe "$pod_name" "$pod_ns"
                ;;
            3)
                local pod_list_snap=$(sudo kubectl get pods -A -o wide | awk '{print NR-1,$0}')
                echo "$pod_list_snap"
                read -p "请输入要执行Pod的编号: " pod_bumb
                local pod_name=$(echo "$pod_list_snap" | awk -v line="$((pod_bumb + 1))" 'NR==line{print $3}')
                local pod_ns=$(echo "$pod_list_snap" | awk -v line="$((pod_bumb + 1))" 'NR==line{print $2}')
                read -p "请输入要执行的命令(进入Pod,输入:sh): " command
                green_echo "输入信息为- Pod名称: $pod_name | 命名空间: $pod_ns | 命令: $command"
                read -p "请确认操作(Y|N,default:Y): " areyouok
                areyouok="${areyouok:-Y}"
                [ "$areyouok" = "Y" ] && _k8s_pod_exec "$pod_name" "$pod_ns" "$command"
                ;;
            4)
                local pod_list_snap=$(sudo kubectl get pods -A -o wide | awk '{print NR-1,$0}')
                echo "$pod_list_snap"
                read -p "请输入要操作Pod的编号: " pod_bumb
                local pod_name=$(echo "$pod_list_snap" | awk -v line="$((pod_bumb + 1))" 'NR==line{print $3}')
                local pod_ns=$(echo "$pod_list_snap" | awk -v line="$((pod_bumb + 1))" 'NR==line{print $2}')
                green_echo "输入信息为- Pod名称: $pod_name | 命名空间: $pod_ns "
                read -p "请确认操作(Y|N,default:Y): " areyouok
                areyouok="${areyouok:-Y}"
                [ "$areyouok" = "Y" ] && _k8s_pod_delete "$pod_name" "$pod_ns"
                ;;
            5)
                local pod_list_snap=$(sudo kubectl get pods -A -o wide | awk '{print NR-1,$0}')
                echo "$pod_list_snap"
                read -p "请输入要操作Pod的编号: " pod_bumb
                local pod_name=$(echo "$pod_list_snap" | awk -v line="$((pod_bumb + 1))" 'NR==line{print $3}')
                local pod_ns=$(echo "$pod_list_snap" | awk -v line="$((pod_bumb + 1))" 'NR==line{print $2}')
                green_echo "输入信息为- Pod名称: $pod_name | 命名空间: $pod_ns "
                read -p "请确认操作(Y|N,default:Y): " areyouok
                areyouok="${areyouok:-Y}"
                [ "$areyouok" = "Y" ] && _k8s_pod_restart "$pod_name" "$pod_ns"
                ;;
            6)
                local pod_list_snap=$(sudo kubectl get pods -A -o wide | awk '{print NR-1,$0}')
                echo "$pod_list_snap"
                read -p "请输入要操作Pod的编号: " pod_bumb
                local pod_name=$(echo "$pod_list_snap" | awk -v line="$((pod_bumb + 1))" 'NR==line{print $3}')
                local pod_ns=$(echo "$pod_list_snap" | awk -v line="$((pod_bumb + 1))" 'NR==line{print $2}')
                read -p "请输入输出文件名: " output_file
                green_echo "输入信息为- Pod名称: $pod_name | 命名空间: $pod_ns | 输出文件: $output_file"
                read -p "请确认操作(Y|N,default:Y): " areyouok
                areyouok="${areyouok:-Y}"
                [ "$areyouok" = "Y" ] && _k8s_pod_export "$pod_name" "$pod_ns" "$output_file"
                ;;
            7)
                local pod_list_snap=$(sudo kubectl get pods -A -o wide | awk '{print NR-1,$0}')
                echo "$pod_list_snap"
                read -p "请输入要操作Pod的编号: " pod_bumb
                local pod_name=$(echo "$pod_list_snap" | awk -v line="$((pod_bumb + 1))" 'NR==line{print $3}')
                local pod_ns=$(echo "$pod_list_snap" | awk -v line="$((pod_bumb + 1))" 'NR==line{print $2}')
                green_echo "输入信息为- Pod名称: $pod_name | 命名空间: $pod_ns "
                read -p "请确认操作(Y|N,default:Y): " areyouok
                areyouok="${areyouok:-Y}"
                [ "$areyouok" = "Y" ] && _k8s_pod_logs "$pod_name" "$pod_ns"
                ;;
            8)
                local pod_list_snap=$(sudo kubectl get pods -A -o wide | awk '{print NR-1,$0}')
                echo "$pod_list_snap"
                read -p "请输入要操作Pod的编号: " pod_bumb
                local pod_name=$(echo "$pod_list_snap" | awk -v line="$((pod_bumb + 1))" 'NR==line{print $3}')
                local pod_ns=$(echo "$pod_list_snap" | awk -v line="$((pod_bumb + 1))" 'NR==line{print $2}')
                read -p "请输入标签键: " label_key
                read -p "请输入标签值: " label_value
                green_echo "输入信息为- Pod名称: $pod_name | 命名空间: $pod_ns | Pod名称: $pod_name, 标签: $label_key=$label_value"
                read -p "请确认操作(Y|N,default:Y): " areyouok
                areyouok="${areyouok:-Y}"
                [ "$areyouok" = "Y" ] && _k8s_pod_label "$pod_name" "$pod_ns" "$label_key" "$label_value"
                ;;
            9)
                local pod_list_snap=$(sudo kubectl get pods -A -o wide | awk '{print NR-1,$0}')
                echo "$pod_list_snap"
                read -p "请输入要操作Pod的编号: " pod_bumb
                local pod_name=$(echo "$pod_list_snap" | awk -v line="$((pod_bumb + 1))" 'NR==line{print $3}')
                local pod_ns=$(echo "$pod_list_snap" | awk -v line="$((pod_bumb + 1))" 'NR==line{print $2}')
                green_echo "输入信息为- Pod名称: $pod_name | 命名空间: $pod_ns "
                read -p "请确认操作(Y|N,default:Y): " areyouok
                areyouok="${areyouok:-Y}"
                [ "$areyouok" = "Y" ] && _k8s_pod_resources "$pod_name" "$pod_ns"
                ;;
            10)
                local pod_list_snap=$(sudo kubectl get pods -A -o wide | awk '{print NR-1,$0}')
                echo "$pod_list_snap"
                read -p "请输入要操作Pod的编号: " pod_bumb
                local pod_name=$(echo "$pod_list_snap" | awk -v line="$((pod_bumb + 1))" 'NR==line{print $3}')
                local pod_ns=$(echo "$pod_list_snap" | awk -v line="$((pod_bumb + 1))" 'NR==line{print $2}')
                green_echo "输入信息为- Pod名称: $pod_name | 命名空间: $pod_ns "
                read -p "请确认操作(Y|N,default:Y): " areyouok
                areyouok="${areyouok:-Y}"
                [ "$areyouok" = "Y" ] && _k8s_pod_events "$pod_name" "$pod_ns"
                ;;
            11)
                local pod_list_snap=$(sudo kubectl get pods -A -o wide | awk '{print NR-1,$0}')
                echo "$pod_list_snap"
                read -p "请输入要操作Pod的编号: " pod_bumb
                local pod_name=$(echo "$pod_list_snap" | awk -v line="$((pod_bumb + 1))" 'NR==line{print $3}')
                local pod_ns=$(echo "$pod_list_snap" | awk -v line="$((pod_bumb + 1))" 'NR==line{print $2}')
                read -p "请输入源文件路径: " src_path
                read -p "请输入目标路径: " dest_path
                green_echo "输入信息为- Pod名称: $pod_name | 命名空间: $pod_ns, 源路径: $src_path, 目标路径: $dest_path"
                read -p "请确认操作(Y|N,default:Y): " areyouok
                areyouok="${areyouok:-Y}"
                [ "$areyouok" = "Y" ] && _k8s_pod_copy "$pod_name" "$pod_ns" "$src_path" "$dest_path"
                ;;
            0)
                return
                ;;
            *)
                RED_echo "无效选项"
                ;;
            esac
            read -p "按任意键继续..." -n1 -s
        done
    fi
}

# 8) ConfigMap管理路由
k8s_cm_mgmt() {
    if [ $# -gt 0 ]; then
        case $1 in
        list)
            local namespace="${2:-default}"
            _list_configmaps "$namespace"
            return
            ;;
        view)
            local configmap_name="$2"
            local namespace="${3:-default}"
            _view_configmap_details "$configmap_name" "$namespace"
            return
            ;;
        create)
            local configmap_name="$2"
            local namespace="${3:-default}"
            local data_file="$4"
            _create_configmap "$configmap_name" "$namespace" "$data_file"
            return
            ;;
        update)
            local configmap_name="$2"
            local namespace="${3:-default}"
            local data_file="$4"
            _update_configmap "$configmap_name" "$namespace" "$data_file"
            return
            ;;
        delete)
            local configmap_name="$2"
            local namespace="${3:-default}"
            _delete_configmap "$configmap_name" "$namespace"
            return
            ;;
        export)
            local configmap_name="$2"
            local namespace="${3:-default}"
            local output_file="$4"
            _export_configmap "$configmap_name" "$namespace" "$output_file"
            return
            ;;
        *)
            RED_echo "无效命令: $1"
            echo "可用命令: list, view, create, update, delete, export"
            return 1
            ;;
        esac
    fi
    while true; do
        clear
        BLUE_echo "------------------------------------------------------"
        GREEN_echo "ConfigMap 管理菜单:"
        GREEN_echo "  1) 列出ConfigMap"
        GREEN_echo "  2) 查看ConfigMap详情"
        GREEN_echo "  3) 创建ConfigMap"
        GREEN_echo "  4) 更新ConfigMap"
        GREEN_echo "  5) 删除ConfigMap"
        GREEN_echo "  6) 导出ConfigMap"
        GREEN_echo "  0) 返回上级菜单"
        BLUE_echo "------------------------------------------------------"
        read -p "请输入选项[0-6]: " choice
        case $choice in
        1)
            local ns_list_snap=$(kubectl get namespaces | awk '{print NR-1,$0}')
            echo "$ns_list_snap"
            ns_numb=
            read -p "请输入命名空间编号(default:all): " ns_numb
            [ -n "$ns_numb" ] && local namespace=$(echo "$ns_list_snap" | awk -v line="$((ns_numb + 1))" 'NR==line{print $2}')
            namespace=${namespace:-"all"}
            green_echo "输入信息为- 命名空间: $namespace"
            read -p "请确认操作(Y|N,default:Y): " areyouok
            [ "${areyouok:-Y}" = "Y" ] && _list_configmaps "$namespace"
            ;;
        2)
            local cm_list_snap=$(kubectl get configmaps -A | awk '{print NR-1,$0}')
            echo "$cm_list_snap"
            read -p "请输入configmap编号(default:all): " ns_numb
            local configmap_name=$(echo "$cm_list_snap" | awk -v line="$((ns_numb + 1))" 'NR==line{print $3}')
            local namespace=$(echo "$cm_list_snap" | awk -v line="$((ns_numb + 1))" 'NR==line{print $2}')
            green_echo "输入信息为- ConfigMap: $configmap_name 命名空间: $namespace"
            _view_configmap_details "$configmap_name" "$namespace"
            ;;
        3)
            local ns_list_snap=$(kubectl get namespaces | awk '{print NR-1,$0}')
            echo "$ns_list_snap"
            read -p "请输入命名空间编号(default:all): " ns_numb
            local namespace=$(echo "$cm_list_snap" | awk -v line="$((ns_numb + 1))" 'NR==line{print $2}')
            read -p "请输入configmap名字: " configmap_name
            read -p "请输入数据文件路径: " data_file
            green_echo "输入信息为- ConfigMap: $configmap_name 命名空间: $namespace 数据文件: $data_file"
            read -p "请确认操作(Y|N,default:Y): " areyouok
            [ "${areyouok:-Y}" = "Y" ] && _create_configmap "$configmap_name" "$namespace" "$data_file"
            ;;
        4)
            local cm_list_snap=$(kubectl get configmaps -A | awk '{print NR-1,$0}')
            echo "$cm_list_snap"
            read -p "请输入configmap编号(default:all): " ns_numb
            local configmap_name=$(echo "$cm_list_snap" | awk -v line="$((ns_numb + 1))" 'NR==line{print $3}')
            local namespace=$(echo "$cm_list_snap" | awk -v line="$((ns_numb + 1))" 'NR==line{print $2}')
            read -p "请输入数据文件路径: " data_file
            green_echo "输入信息为- ConfigMap: $configmap_name 命名空间: $namespace 数据文件: $data_file"
            read -p "请确认操作(Y|N,default:Y): " areyouok
            areyouok="${areyouok:-Y}"
            [ "$areyouok" = "Y" ] && _update_configmap "$configmap_name" "$namespace" "$data_file"
            ;;
        5)
            local cm_list_snap=$(kubectl get configmaps -A | awk '{print NR-1,$0}')
            echo "$cm_list_snap"
            read -p "请输入configmap编号(default:all): " ns_numb
            local configmap_name=$(echo "$cm_list_snap" | awk -v line="$((ns_numb + 1))" 'NR==line{print $3}')
            local namespace=$(echo "$cm_list_snap" | awk -v line="$((ns_numb + 1))" 'NR==line{print $2}')
            green_echo "输入信息为- ConfigMap: $configmap_name 命名空间: $namespace"
            read -p "请确认操作(Y|N,default:Y): " areyouok
            areyouok="${areyouok:-Y}"
            [ "$areyouok" = "Y" ] && _delete_configmap "$configmap_name" "$namespace"
            ;;
        6)
            local cm_list_snap=$(kubectl get configmaps -A | awk '{print NR-1,$0}')
            echo "$cm_list_snap"
            read -p "请输入configmap编号(default:all): " ns_numb
            local configmap_name=$(echo "$cm_list_snap" | awk -v line="$((ns_numb + 1))" 'NR==line{print $3}')
            local namespace=$(echo "$cm_list_snap" | awk -v line="$((ns_numb + 1))" 'NR==line{print $2}')
            read -p "请输入导出文件路径: " output_file
            green_echo "输入信息为- ConfigMap: $configmap_name 命名空间: $namespace 导出文件: $output_file"
            _export_configmap "$configmap_name" "$namespace" "$output_file"
            ;;
        0)
            return
            ;;
        *)
            RED_echo "无效选项"
            ;;
        esac
        read -p "按任意键继续..." -n1 -s
    done
}

# 9) Secret管理路由
k8s_secret_mgmt() {
    if [ $# -gt 0 ]; then
        [ $1 = "list" ] && _k8s_secret_list
        [ $1 = "details" ] && _k8s_secret_details "$2" "$3"
        [ $1 = "tsl" ] && _k8s_secret_create_tls "$2" "$3" "$4" "$5" "$6"
        [ $1 = "generic" ] && _k8s_secret_create_generic "$2" "$3" "$4" "$5" "$6"
        [ $1 = "registry" ] && _k8s_secret_create_dockerregistry "$2" "$3" "$4" "$5" "$6"
        [ $1 = "update" ] && _k8s_secret_update "$2" "$3" "$4"
        [ $1 = "delete" ] && _k8s_secret_delete "$2" "$3"
        [ $1 = "export" ] && _k8s_secret_export "$2" "$3" "$4"
    else
        while true; do
            clear
            BLUE_echo "------------------------------------------------------"
            GREEN_echo "Secret 管理菜单:"
            GREEN_echo "  1) 列出Secret"
            GREEN_echo "  2) 查看Secret详情"
            GREEN_echo "  3) 创建Secret:-tls"
            GREEN_echo "  4) 创建Secret:-generic"
            GREEN_echo "  5) 创建Secret:-docker-registry"
            GREEN_echo "  6) 更新Secret"
            GREEN_echo "  7) 删除Secret"
            GREEN_echo "  8) 导出Secret"
            GREEN_echo "  0) 返回上级菜单"
            BLUE_echo "------------------------------------------------------"
            read -p "请输入选项[0-6]: " choice
            case $choice in
            1)
                _k8s_secret_list
                ;;
            2)
                local secret_list_snap=$(kubectl get secrets --all-namespaces | awk '{print NR-1,$0}')
                echo "$secret_list_snap"
                read -p "请输入 Secret 编号: " Secret_numb
                local secret_name=$(echo "$secret_list_snap" | awk -v line="$((Secret_numb + 1))" 'NR==line{print $3}')
                local namespace=$(echo "$secret_list_snap" | awk -v line="$((Secret_numb + 1))" 'NR==line{print $2}')
                green_echo "输入信息为- Secret名称: $secret_name, 命名空间: $namespace"
                read -p "请确认操作(Y|N,default:Y): " areyouok
                areyouok="${areyouok:-Y}"
                [ "$areyouok" = "Y" ] && _k8s_secret_details "$secret_name" "$namespace"
                ;;
            3)
                local ns_list_snap=$(kubectl get namespaces | awk '{print NR-1,$0}')
                echo "$ns_list_snap"
                read -p "请输入命名空间编号(default:all): " ns_numb
                local namespace=$(echo "$ns_list_snap" | awk -v line="$((ns_numb + 1))" 'NR==line{print $2}')
                read -p "请输入Secret名字: " secret_name
                read -p "是否创建全新tls(Y|N, Default:Y): " create_type
                if [ ${create_type:-"Y"} != "Y" ]; then
                    echo "请将文件存放在当前脚本路径,命名为./tls.crt ./tls.key"
                fi
                green_echo "输入信息为- Secret名称: $secret_name | 命名空间: $namespace | 类型: tls | 文件路径: ./tls.crt ./tls.key"
                read -p "请确认操作(Y|N,default:Y): " areyouok
                areyouok="${areyouok:-Y}"
                [ "$areyouok" = "Y" ] && _k8s_secret_create_tls "$secret_name" "$namespace" "${create_type:-"Y"}"
                ;;
            4)
                local ns_list_snap=$(kubectl get namespaces | awk '{print NR-1,$0}')
                echo "$ns_list_snap"
                read -p "请输入命名空间编号(default:all): " ns_numb
                local namespace=$(echo "$ns_list_snap" | awk -v line="$((ns_numb + 1))" 'NR==line{print $2}')
                read -p "请输入Secret名称: " secret_name
                echo "请输入Secret的内容, 示例如下:
                  1)基于文件: --from-file=username=./username.txt --from-file=password=./password.txt
                  2)基于字符: --from-literal=DB_USER=admin --from-literal=DB_PASSWORD='S3cret!'
                "
                read -p "请输入Secret创建内容: " secret_content
                green_echo "输入信息为- Secret名称: $secret_name, 命名空间: $namespace, 类型: "generic", 文件: $secret_content"
                read -p "请确认操作(Y|N,default:Y): " areyouok
                areyouok="${areyouok:-Y}"
                [ "$areyouok" = "Y" ] && _k8s_secret_create_generic "$secret_name" "$namespace" "$secret_content"
                ;;
            5)
                read -p "请输入Secret名字: " secret_name
                read -p "请输入docker-server: " dockerserver
                read -p "请输入username: " username
                read -p "请输入password: " password
                read -p "请输入email: " email
                green_echo "输入信息为- Secret名称: $secret_name, docker server: $dockerserver, 用户名: $username, email: $email"
                read -p "请确认操作(Y|N,default:Y): " areyouok
                areyouok="${areyouok:-Y}"
                [ "$areyouok" = "Y" ] && _k8s_secret_create_dockerregistry "$secret_name" "$dockerserver" "$username" "$password" "$email"
                ;;
            6)
                local secret_list_snap=$(kubectl get secrets --all-namespaces | awk '{print NR-1,$0}')
                echo "$secret_list_snap"
                read -p "请输入 Secret 编号: " Secret_numb
                local secret_name=$(echo "$secret_list_snap" | awk -v line="$((Secret_numb + 1))" 'NR==line{print $3}')
                local namespace=$(echo "$secret_list_snap" | awk -v line="$((Secret_numb + 1))" 'NR==line{print $2}')
                read -p "请输入Secret文件路径: " secret_file
                green_echo "输入信息为- Secret名称: $secret_name, 命名空间: $namespace, 文件: $secret_file"
                read -p "请确认操作(Y|N,default:Y): " areyouok
                areyouok="${areyouok:-Y}"
                [ "$areyouok" = "Y" ] && _k8s_secret_update "$secret_name" "$namespace" "$secret_file"
                ;;
            7)
                local secret_list_snap=$(kubectl get secrets --all-namespaces | awk '{print NR-1,$0}')
                echo "$secret_list_snap"
                read -p "请输入 Secret 编号: " Secret_numb
                local secret_name=$(echo "$secret_list_snap" | awk -v line="$((Secret_numb + 1))" 'NR==line{print $3}')
                local namespace=$(echo "$secret_list_snap" | awk -v line="$((Secret_numb + 1))" 'NR==line{print $2}')
                green_echo "输入信息为- Secret名称: $secret_name, 命名空间: $namespace"
                read -p "请确认操作(Y|N,default:Y): " areyouok
                areyouok="${areyouok:-Y}"
                [ "$areyouok" = "Y" ] && _k8s_secret_delete "$secret_name" "$namespace"
                ;;
            8)
                local secret_list_snap=$(kubectl get secrets --all-namespaces | awk '{print NR-1,$0}')
                echo "$secret_list_snap"
                read -p "请输入 Secret 编号: " Secret_numb
                local secret_name=$(echo "$secret_list_snap" | awk -v line="$((Secret_numb + 1))" 'NR==line{print $3}')
                local namespace=$(echo "$secret_list_snap" | awk -v line="$((Secret_numb + 1))" 'NR==line{print $2}')
                read -p "请输入导出文件名: " output_file
                green_echo "输入信息为- Secret名称: $secret_name, 命名空间: $namespace, 导出文件: $output_file"
                read -p "请确认操作(Y|N,default:Y): " areyouok
                areyouok="${areyouok:-Y}"
                [ "$areyouok" = "Y" ] && _k8s_secret_export "$secret_name" "$namespace" "$output_file"
                ;;
            0)
                return
                ;;
            *)
                RED_echo "无效选项"
                ;;
            esac
            read -p "按任意键继续..." -n1 -s
        done
    fi
}

# 10) RBAC配置路由
k8s_rbac_mgmt() {
    if [ $# -gt 0 ]; then
        [ $1 = "list_roles" ] && _k8s_rbac_list_roles
        [ $1 = "list_rolebindings" ] && _k8s_rbac_list_rolebindings
        [ $1 = "list_clusterroles" ] && _k8s_rbac_list_clusterroles
        [ $1 = "list_clusterrolebindings" ] && _k8s_rbac_list_clusterrolebindings
        [ $1 = "view_rules" ] && namespace=$2 && _k8s_rbac_view_rules "$namespace"
        [ $1 = "apply_rules" ] && file=$2 && _k8s_rbac_apply_rules "$file"
        [ $1 = "delete_rules" ] && resource=$2 name=$3 && _k8s_rbac_delete_rules "$resource" "$name"
    else
        # 主交互逻辑
        while true; do
            clear
            BLUE_echo "------------------------------------------------------"
            GREEN_echo "RBAC 管理菜单:"
            GREEN_echo "  1) 列出serviceaccount"
            GREEN_echo "  2) 列出角色"
            GREEN_echo "  3) 列出角色绑定"
            GREEN_echo "  4) 列出集群角色"
            GREEN_echo "  5) 列出集群角色绑定"
            GREEN_echo "  6) 查看RBAC规则"
            GREEN_echo "  7) 创建/更新RBAC规则"
            GREEN_echo "  8) 删除RBAC规则"
            GREEN_echo "  0) 返回上级菜单"
            BLUE_echo "------------------------------------------------------"
            read -p "请输入选项[0-7]: " choice
            case $choice in
            1)
                _k8s_rbac_list_serviceaccount
                ;;
            2)
                _k8s_rbac_list_roles
                ;;
            3)
                _k8s_rbac_list_rolebindings
                ;;
            4)
                _k8s_rbac_list_clusterroles
                ;;
            5)
                _k8s_rbac_list_clusterrolebindings
                ;;
            6)
                local ns_list_snap=$(kubectl get namespaces | awk '{print NR-1,$0}')
                echo "$ns_list_snap"
                read -p "请输入命名空间编号(default:all): " ns_numb
                local namespace=$(echo "$ns_list_snap" | awk -v line="$((ns_numb + 1))" 'NR==line{print $2}')
                green_echo "输入信息为- 命名空间: ${namespace:-所有命名空间}"
                read -p "请确认操作(Y|N,default:Y): " areyouok
                areyouok="${areyouok:-Y}"
                [ "$areyouok" = "Y" ] && _k8s_rbac_view_rules "$namespace"
                ;;
            7)
                read -p "请输入RBAC规则文件路径: " file
                green_echo "输入信息为- 文件: $file"
                read -p "请确认操作(Y|N,default:Y): " areyouok
                areyouok="${areyouok:-Y}"
                [ "$areyouok" = "Y" ] && _k8s_rbac_apply_rules "$file"
                ;;
            8)
                _k8s_rbac_list_clusterrolebindings
                read -p "请输入资源类型(Role|RoleBinding|ClusterRole|ClusterRoleBinding): " resource
                read -p "请输入资源名称: " name
                green_echo "输入信息为- 资源类型: $resource, 名称: $name"
                read -p "请确认操作(Y|N,default:Y): " areyouok
                areyouok="${areyouok:-Y}"
                [ "$areyouok" = "Y" ] && _k8s_rbac_delete_rules "$resource" "$name"
                ;;
            0)
                return
                ;;
            *)
                RED_echo "无效选项"
                ;;
            esac
            read -p "按任意键继续..." -n1 -s
        done
    fi
}

# 11) 资源限制配置路由
k8s_resource_limits_mgmt() {
    if [ $# -gt 0 ]; then
        [ $1 = "list-quotas" ] && _k8s_resource_list_quotas
        [ $1 = "list-limits" ] && _k8s_resource_list_limits
        [ $1 = "describe" ] && namespace=$2 && _k8s_resource_describe "$namespace"
        [ $1 = "apply" ] && file=$2 && _k8s_resource_apply "$file"
        [ $1 = "delete" ] && namespace=$2 && _k8s_resource_delete "$namespace"
    else
        while true; do
            clear
            BLUE_echo "------------------------------------------------------"
            GREEN_echo "资源限制 管理菜单:"
            GREEN_echo "  1) 列出资源配额"
            GREEN_echo "  2) 列出限制范围"
            GREEN_echo "  3) 查看配额详情"
            GREEN_echo "  4) 创建/更新资源限制"
            GREEN_echo "  5) 删除资源限制"
            GREEN_echo "  0) 返回上级菜单"
            BLUE_echo "------------------------------------------------------"
            read -p "请输入选项[0-5]: " choice
            case $choice in
            1)
                _k8s_resource_list_quotas
                ;;
            2)
                _k8s_resource_list_limits
                ;;
            3)
                local ns_list_snap=$(kubectl get namespaces | awk '{print NR-1,$0}')
                echo "$ns_list_snap"
                read -p "请输入命名空间编号(default:all): " ns_numb
                local namespace=$(echo "$cm_list_snap" | awk -v line="$((ns_numb + 1))" 'NR==line{print $2}')
                green_echo "输入信息为- 命名空间: ${namespace:-所有命名空间}"
                read -p "请确认操作(Y|N,default:Y): " areyouok
                [ "${areyouok:-Y}" = "Y" ] && _k8s_resource_describe "$namespace"
                ;;
            4)
                read -p "请输入YAML文件路径: " file
                green_echo "输入信息为- 文件: $file"
                read -p "请确认操作(Y|N,default:Y): " areyouok
                [ "${areyouok:-Y}" = "Y" ] && _k8s_resource_apply "$file"
                ;;
            5)
                local ns_list_snap=$(kubectl get namespaces | awk '{print NR-1,$0}')
                echo "$ns_list_snap"
                read -p "请输入命名空间编号(default:all): " ns_numb
                local namespace=$(echo "$cm_list_snap" | awk -v line="$((ns_numb + 1))" 'NR==line{print $2}')
                green_echo "输入信息为- 命名空间: ${namespace:-所有命名空间}"
                read -p "请确认操作(Y|N,default:Y): " areyouok
                [ "${areyouok:-Y}" = "Y" ] && _k8s_resource_delete "$namespace"
                ;;
            0)
                return
                ;;
            *)
                RED_echo "无效选项"
                ;;
            esac
            read -p "按任意键继续..." -n1 -s
        done
    fi
}

k8s_resource_config_apply() {
    if [ $# -gt 0 ]; then
        [ $1 = "apply" ] && _k8s__apply_resource_yaml $1 $2
        [ $1 = "delete" ] && _k8s__delete_resource_yaml $1 $2
    else
        while true; do
            clear
            BLUE_echo "----------------------资源配置管理菜单--------------------------------"
            GREEN_echo "  1) apply资源配置"
            GREEN_echo "  2) delete资源配置"
            GREEN_echo "  0) 返回上级菜单"
            BLUE_echo "------------------------------------------------------"
            read -p "请输入选项[0-2]: " choice
            case $choice in
            1)
                local ns_list_snap=$(kubectl get namespaces | awk '{print NR-1,$0}')
                echo "$ns_list_snap"
                read -p "请输入命名空间编号(default:none): " ns_numb
                local namespace=$(echo "$ns_list_snap" | awk -v line="$((ns_numb + 1))" 'NR==line{print $2}')
                [ "$namespace" = "NAME" ] && namespace=""
                read -p "请输入yaml文件路径: " filepath
                green_echo "输入信息为- 命名空间: ${namespace:-未选择} | yaml文件路径: $filepath"
                read -p "请确认操作(Y|N,default:Y): " areyouok
                [ "${areyouok:-Y}" = "Y" ] && _k8s__apply_resource_yaml $filepath $namespace
                ;;
            2)
                local ns_list_snap=$(kubectl get namespaces | awk '{print NR-1,$0}')
                echo "$ns_list_snap"
                read -p "请输入命名空间编号(default:none): " ns_numb
                local namespace=$(echo "$ns_list_snap" | awk -v line="$((ns_numb + 1))" 'NR==line{print $2}')
                [ "$namespace" = "NAME" ] && namespace=""
                read -p "请输入yaml文件路径: " filepath
                green_echo "输入信息为- 命名空间: ${namespace:-未选择} | yaml文件路径: $filepath"
                read -p "请确认操作(Y|N,default:Y): " areyouok
                [ "${areyouok:-Y}" = "Y" ] && _k8s__delete_resource_yaml $filepath $namespace
                ;;
            0)
                return
                ;;
            *)
                RED_echo "无效选项"
                ;;
            esac
            read -p "按任意键继续..." -n1 -s
        done
    fi

}

# 调度器子函数
_scheduler_view() {
    kubectl get configmap -n kube-system kube-scheduler -o yaml
    check_command "查看调度器配置"
}

_scheduler_edit() {
    kubectl edit configmap -n kube-system kube-scheduler
    check_command "编辑调度器配置"
}

_scheduler_reset() {
    kubectl delete configmap -n kube-system kube-scheduler
    kubectl create -f /path/to/default/scheduler/config.yaml # 需要替换为实际的默认配置文件路径
    check_command "重置调度器配置"
}

_crd_list() {
    kubectl get crd | awk '{print NR-1,$0}'
    check_command "列出所有CRD"
}

_crd_describe() {
    local crd_name=$1
    kubectl describe crd "$crd_name"
    check_command "查看CRD $crd_name 详情"
}

_crd_delete() {
    local crd_name=$1
    kubectl delete crd "$crd_name"
    check_command "删除CRD $crd_name"
}

# HPA子函数
_hpa_list() {
    kubectl get hpa --all-namespaces | awk '{print NR-1,$0}'
    check_command "列出所有HPA"
}

_hpa_create() {
    local namespace=$1
    local hpa_name=$2
    local min_replicas=$3
    local max_replicas=$4
    local target_cpu=$5

    kubectl autoscale deployment "$hpa_name" --namespace="$namespace" --min="$min_replicas" --max="$max_replicas" --cpu-percent="$target_cpu"
    check_command "创建HPA $hpa_name"
}

_hpa_delete() {
    local namespace=$1
    local hpa_name=$2

    kubectl delete hpa "$hpa_name" --namespace="$namespace"
    check_command "删除HPA $hpa_name"
}

# Kubernetes NetworkPolicy 管理增强版 (支持CRUD操作)
_k8s_network_policy_list() {
    blue_echo "------------------------------------------------------"
    yellow_echo "正在获取所有 NetworkPolicy 列表..."
    kubectl get networkpolicy --all-namespaces | awk '{print NR-1,$0}'
    check_command "获取 NetworkPolicy 列表"
    blue_echo "------------------------------------------------------"
}

_k8s_network_policy_detail() {
    local policy_name=$1
    local namespace=$2

    blue_echo "------------------------------------------------------"
    yellow_echo "正在获取 NetworkPolicy 详细信息..."
    kubectl describe networkpolicy "$policy_name" -n "$namespace"
    check_command "获取 NetworkPolicy 详细信息"
    blue_echo "------------------------------------------------------"
}

_k8s_network_policy_apply() {
    local yaml_file=$1

    blue_echo "------------------------------------------------------"
    yellow_echo "正在 创建\更新 NetworkPolicy..."
    kubectl apply -f "$yaml_file"
    check_command "创建\更新 NetworkPolicy"
    blue_echo "------------------------------------------------------"
}

_k8s_network_policy_delete() {
    local policy_name=$1
    local namespace=$2

    blue_echo "------------------------------------------------------"
    yellow_echo "正在删除 NetworkPolicy..."
    kubectl delete networkpolicy "$policy_name" -n "$namespace"
    check_command "删除 NetworkPolicy"
    blue_echo "------------------------------------------------------"
}

# Kubernetes DNS 管理增强版 (支持CRUD操作)
_k8s_network_dns_check() {
    BLUE_echo "------------------------------------------------------"
    GREEN_echo "正在检查 Kubernetes DNS 状态..."

    # 检查 CoreDNS 或 kube-dns 运行状态
    local dns_pods=$(kubectl get pods -n kube-system -l k8s-app=kube-dns 2>/dev/null || kubectl get pods -n kube-system -l k8s-app=coredns 2>/dev/null)

    if [ -z "$dns_pods" ]; then
        red_echo "错误：未找到 DNS 服务 Pod!"
        return 1
    fi

    echo "$dns_pods"
    BLUE_echo "------------------------------------------------------"

    # 检查 DNS 服务
    GREEN_echo "DNS 服务信息:"
    kubectl get svc -n kube-system -l k8s-app=kube-dns 2>/dev/null || kubectl get svc -n kube-system -l k8s-app=coredns 2>/dev/null

    # 检查 DNS 解析
    BLUE_echo "------------------------------------------------------"
    GREEN_echo "测试 DNS 解析功能..."
    local test_pod="dns-test-$(date +%s)"
    kubectl run $test_pod --image=swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/library/busybox:1.28 --restart=Never --rm -it -- sh -c "nslookup kubernetes.default && nslookup google.com" 2>&1

    check_command "DNS 功能测试"
}

_k8s_network_dns_config() {
    BLUE_echo "------------------------------------------------------"
    GREEN_echo "配置 Kubernetes DNS..."

    read -p "请输入 CoreDNS 配置文件名: " dns_config
    GREEN_echo "输入信息为- 配置文件: $dns_config"
    read -p "请确认操作(Y|N,default:Y): " areyouok
    areyouok="${areyouok:-Y}"

    if [ "$areyouok" = "Y" ]; then
        kubectl apply -f "$dns_config"
        check_command "DNS 配置更新"
    fi
}

# Kubernetes Ingress 管理增强版 (支持CRUD操作)
_k8s_network_ingress_list() {
    blue_echo "------------------------------------------------------"
    white_echo "正在获取所有 Ingress 列表..."
    kubectl get ingress --all-namespaces | awk '{print NR-1,$0}'
    check_command "获取 Ingress 列表"
    blue_echo "------------------------------------------------------"
}

_k8s_network_ingress_detail() {
    local ingress_name=$1
    local namespace=$2

    blue_echo "------------------------------------------------------"
    white_echo "正在获取 Ingress [$ingress_name] 详细信息..."
    kubectl describe ingress "$ingress_name" -n "$namespace"
    check_command "获取 Ingress [$ingress_name] 详细信息"
    blue_echo "------------------------------------------------------"
}

_k8s_network_ingress_create() {
    local yaml_file=$1

    blue_echo "------------------------------------------------------"
    white_echo "正在创建/更新 Ingress..."
    kubectl apply -f "$yaml_file"
    check_command "创建/更新 Ingress [$yaml_file]"
    blue_echo "------------------------------------------------------"
}

_k8s_network_ingress_delete() {
    local ingress_name=$1
    local namespace=$2

    blue_echo "------------------------------------------------------"
    white_echo "正在删除 Ingress [$ingress_name]..."
    kubectl delete ingress "$ingress_name" -n "$namespace"
    check_command "删除 Ingress [$ingress_name]"
    blue_echo "------------------------------------------------------"
}

# Kubernetes Service 管理增强版 (支持CRUD操作)
_k8s_network_service_list() {
    blue_echo "------------------------------------------------------"
    green_echo "正在获取 Kubernetes 所有 Service 列表..."
    sudo kubectl get svc --all-namespaces | awk '{print NR-1,$0}'
    check_command "获取 Service 列表"
    blue_echo "------------------------------------------------------"
}

_k8s_network_service_detail() {
    local svc_name=$1
    local namespace=$2
    blue_echo "------------------------------------------------------"
    green_echo "正在获取 Service ${svc_name} 详细信息..."
    kubectl describe svc "$svc_name" -n "$namespace"
    check_command "获取 Service 详细信息"
    blue_echo "------------------------------------------------------"
}

_k8s_network_service_apply() {
    local yaml_file=$1
    blue_echo "------------------------------------------------------"
    green_echo "正在 创建\更新 Service..."
    kubectl apply -f "$yaml_file"
    check_command "创建\更新 Service"
    blue_echo "------------------------------------------------------"
}

_k8s_network_service_delete() {
    local svc_name=$1
    local namespace=$2
    blue_echo "------------------------------------------------------"
    yellow_echo "警告：即将删除 Service ${svc_name}"
    kubectl delete svc "$svc_name" -n "$namespace"
    check_command "删除 Service"
    blue_echo "------------------------------------------------------"
}

_k8s_export_image() {
    local image=$1
    local output=$2
    local ns=$3

    blue_echo "开始导出镜像 [$image] 到 [$output]..."
    sudo ctr -n $ns image export "$output" "$image"
    check_command "镜像 [$image] 导出到 [$output]"

    # 显示导出文件信息
    ls -lh "$output" | awk '{print "导出文件:", $9, "大小:", $5}'
}

# 导入tar文件为镜像
_k8s_import_image() {
    local filepath=$1
    local ns=$2
    if [ -z $image_id ] || [ -z $filepath ]; then
        RED_echo "错误: 输入信息不能为空"
        return 1
    fi

    blue_echo "开始导入镜像 $image_id..."
    sudo ctr -n $ns image import "$filepath" "$image_id"
    check_command "导入镜像 $filepath 为 $image_id"
}

_k8s_list_images() {
    ns=$1
    GREEN_echo "本地命名空间($ns)镜像列表:"
    BLUE_echo "------------------------------------------------------------------------------------------"
    sudo ctr -n $ns images list | awk '{print NR-1,$0}'
    BLUE_echo "------------------------------------------------------------------------------------------"
    check_command "列出本地镜像"
}

# 拉取镜像
_k8s_pull_image() {
    local ns=$1
    local _image_id=$2

    BLUE_echo "------------------------------------------------------"
    GREEN_echo "正在拉取镜像: $_image_id"
    sudo ctr -n $ns image pull "$_image_id"
    check_command "拉取镜像 $_image_id"
    BLUE_echo "------------------------------------------------------"
}

# 推送镜像
_k8s_push_image() {
    local _image_id=$1
    local ns=$2
    if [ -z "$_image_id" ]; then
        RED_echo "错误: 镜像输入信息不能为空"
        return 1
    fi

    BLUE_echo "------------------------------------------------------"
    GREEN_echo "正在推送镜像: $_image_id"
    sudo ctr -N $ns image push "$_image_id"
    check_command "推送镜像 $_image_id"
    BLUE_echo "------------------------------------------------------"
}

# 删除镜像
_k8s_remove_image() {
    local _image_id=$1
    local ns=$2
    if [ -z "$_image_id" ]; then
        RED_echo "错误: 镜像输入信息不能为空"
        return 1
    fi

    BLUE_echo "------------------------------------------------------"
    green_echo "正在删除镜像: $_image_id"
    #return
    sudo ctr -n $ns image delete "$_image_id"
    check_command "删除镜像 $_image_id"
    BLUE_echo "------------------------------------------------------"
}

# 镜像标签管理
_k8s_tag_image() {
    local _image_id=$1
    local _target_image=$2
    local ns=$3
    if [ -z "$_image_id" ] || [ -z "$_target_image" ]; then
        RED_echo "错误: 镜像输入信息不能为空"
        return 1
    fi

    BLUE_echo "------------------------------------------------------"
    GREEN_echo "正在标记镜像: $_image_id -> $_target_image"
    sudo ctr -n $ns image tag "$_image_id" "$_target_image"
    check_command "标记镜像 $_image_id 为 $_target_image"
    BLUE_echo "------------------------------------------------------"
}

_k8s_resource_list_quotas() {
    blue_echo "正在列出所有命名空间的资源配额..."
    kubectl get resourcequotas --all-namespaces | awk '{print NR-1,$0}'
    check_command "资源配额列表查询"
}

_k8s_resource_list_limits() {
    blue_echo "正在列出所有命名空间的限制范围..."
    kubectl get limitranges --all-namespaces | awk '{print NR-1,$0}'
    check_command "限制范围列表查询"
}

_k8s_resource_describe() {
    local namespace=$1
    blue_echo "正在查询命名空间 [$namespace] 的配额详情..."
    kubectl describe resourcequota -n "$namespace" | awk '{print NR-1,$0}'
    check_command "配额详情查询"
}

_k8s_resource_apply() {
    local file=$1
    blue_echo "正在应用资源限制配置 [$file]..."
    kubectl apply -f "$file"
    check_command "资源限制配置应用"
}

_k8s_resource_delete() {
    local namespace=$1
    blue_echo "正在删除命名空间 [$namespace] 的资源限制..."
    kubectl delete resourcequota --all -n "$namespace"
    check_command "资源限制删除"
}

_k8s_rbac_list_serviceaccount() {
    blue_echo "正在列出所有serviceaccount..."
    kubectl get serviceaccount --all-namespaces | awk '{print NR-1,$0}'
    check_command "列出serviceaccount"
}

_k8s_rbac_list_roles() {
    blue_echo "正在列出所有角色..."
    kubectl get roles --all-namespaces | awk '{print NR-1,$0}'
    check_command "列出角色"
}

_k8s_rbac_list_rolebindings() {
    blue_echo "正在列出所有角色绑定..."
    kubectl get rolebindings --all-namespaces | awk '{print NR-1,$0}'
    check_command "列出角色绑定"
}

_k8s_rbac_list_clusterroles() {
    blue_echo "正在列出集群角色..."
    kubectl get clusterroles | awk '{print NR-1,$0}'
    check_command "列出集群角色"
}

_k8s_rbac_list_clusterrolebindings() {
    blue_echo "正在列出集群角色绑定..."
    kubectl get clusterrolebindings | awk '{print NR-1,$0}'
    check_command "列出集群角色绑定"
}

_k8s_rbac_view_rules() {
    local namespace=${1:-"--all-namespaces"}
    blue_echo "正在查看RBAC规则..."
    if [ "$namespace" == "--all-namespaces" ]; then
        kubectl get roles,rolebindings,clusterroles,clusterrolebindings --all-namespaces | awk '{print NR-1,$0}'
    else
        kubectl get roles,rolebindings -n "$namespace" | awk '{print NR-1,$0}'
        kubectl get clusterroles,clusterrolebindings | awk '{print NR-1,$0}'
    fi
    check_command "查看RBAC规则"
}

_k8s__apply_resource_yaml() {
    local file=$1
    local nsname=$2
    blue_echo "正在应用资源配置..."
    if [ -z $nsname ]; then
        kubectl apply -f "$file"
    else
        kubectl apply -f "$file" -n $nsname
    fi
    check_command "应用应用资源配置"
}

_k8s__delete_resource_yaml() {
    local file=$1
    local nsname=$2
    blue_echo "正在删除资源配置..."
    if [ -z $nsname ]; then
        kubectl delete -f "$file"
    else
        kubectl delete -f "$file" -n $nsname
    fi
    check_command "应用应用资源配置"
}

_k8s_rbac_apply_rules() {
    local file=$1
    blue_echo "正在应用RBAC规则..."
    kubectl apply -f "$file"
    check_command "应用RBAC规则"
}

_k8s_rbac_delete_rules() {
    local resource=$1
    local name=$2
    blue_echo "正在删除RBAC规则..."
    kubectl delete "$resource" "$name"
    check_command "删除RBAC规则"
}

_k8s_secret_list() {
    blue_echo "------------------------------------------------------"
    yellow_echo "正在列出所有 Secret..."
    kubectl get secrets --all-namespaces | awk '{print NR-1,$0}'
    check_command "列出 Secret"
}

_k8s_secret_details() {
    local secret_name=$1
    local namespace=$2
    blue_echo "------------------------------------------------------"
    yellow_echo "正在查看 Secret ${secret_name} 的详情..."
    kubectl describe secret "$secret_name" -n "$namespace"
    blue_echo "------------------------------------------------------"
    kubectl get secret $secret_name -n $namespace -o jsonpath='{.data}' | jq
    check_command "查看 Secret 详情"
}

_k8s_secret_create_dockerregistry() {
    local secret_name=$1
    local dockerserver=$2
    local username=$3
    local password=$4
    local email=$5
    blue_echo "------------------------------------------------------"
    yellow_echo "正在创建 Secret ${secret_name}..."
    kubectl create secret docker-registry $secret_name \
        --docker-server=$dockerserver \
        --docker-username=$username \
        --docker-password=$password \
        --docker-email=email
    check_command "创建 Secret"
}

_k8s_secret_create_generic() {
    local secret_name=$1
    local namespace=$2
    local secretcontent=$3
    blue_echo "------------------------------------------------------"
    yellow_echo "正在创建 Secret ${secret_name}..."
    kubectl create secret "$secret_name" $secretcontent -n "$namespace"
    check_command "创建 Secret"
}

_k8s_secret_create_tls() {
    local secret_name=$1
    local namespace=$2
    local create_type=$3
    local secret_type=$4
    local secret_file=$5
    blue_echo "------------------------------------------------------"
    yellow_echo "正在创建 Secret ${secret_name}..."

    if [ $create_type = "Y" ]; then
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout tls.key -out tls.crt \
            -subj "/CN=argocd.ckadmin.com"
    fi

    kubectl create secret tls $secret_name --cert=tls.crt --key=tls.key -n $namespace
    check_command "创建 Secret"
}

_k8s_secret_update() {
    local secret_name=$1
    local namespace=$2
    local secret_file=$3
    blue_echo "------------------------------------------------------"
    yellow_echo "正在更新 Secret ${secret_name}..."
    kubectl create secret generic "$secret_name" --from-file="$secret_file" -n "$namespace" --dry-run=client -o yaml | kubectl apply -f -
    check_command "更新 Secret"
}

_k8s_secret_delete() {
    local secret_name=$1
    local namespace=$2
    blue_echo "------------------------------------------------------"
    yellow_echo "正在删除 Secret ${secret_name}..."
    kubectl delete secret "$secret_name" -n "$namespace"
    check_command "删除 Secret"
}

_k8s_secret_export() {
    local secret_name=$1
    local namespace=$2
    local output_file=$3
    blue_echo "------------------------------------------------------"
    yellow_echo "正在导出 Secret ${secret_name}..."
    kubectl get secret "$secret_name" -n "$namespace" -o yaml >"$output_file"
    check_command "导出 Secret"
}

# 子函数实现
_k8s_pod_list() {
    blue_echo "------------------------------------------------------"
    blue_echo "正在列出所有Pod..."
    local pod_list_snap=$(sudo kubectl get pods -A -o wide | awk '{print NR-1,$0}')
    echo "$pod_list_snap"
    check_command "列出Pod"
    blue_echo "------------------------------------------------------"
}

_list_configmaps() {
    blue_echo "正在列出所有ConfigMap..."
    local namespace="$1"
    if [ $namespace = "all" ]; then
        kubectl get configmaps -A | awk '{print NR-1,$0}'
    else
        kubectl get configmaps -n "$namespace" | awk '{print NR-1,$0}'
    fi
    check_command "列出ConfigMap"
}

_view_configmap_details() {
    local configmap_name="$1"
    local namespace="$2"
    blue_echo "正在查看ConfigMap [$configmap_name] 详情..."
    kubectl get configmap "$configmap_name" -n "$namespace" -o yaml
    check_command "查看ConfigMap详情"
}

_create_configmap() {
    local configmap_name="$1"
    local namespace="$2"
    local data_file="$3"
    blue_echo "正在创建ConfigMap [$configmap_name]..."
    kubectl create configmap "$configmap_name" -n "$namespace" --from-file="$data_file"
    check_command "创建ConfigMap"
}

_update_configmap() {
    local configmap_name="$1"
    local namespace="$2"
    local data_file="$3"
    blue_echo "正在更新ConfigMap [$configmap_name]..."
    kubectl create configmap "$configmap_name" -n "$namespace" --from-file="$data_file" --dry-run=client -o yaml | kubectl apply -f -
    check_command "更新ConfigMap"
}

_delete_configmap() {
    local configmap_name="$1"
    local namespace="$2"
    blue_echo "正在删除ConfigMap [$configmap_name]..."
    kubectl delete configmap "$configmap_name" -n "$namespace"
    check_command "删除ConfigMap"
}

_export_configmap() {
    local configmap_name="$1"
    local namespace="$2"
    local output_file="$3"
    blue_echo "正在导出ConfigMap [$configmap_name] 到 [$output_file]..."
    kubectl get configmap "$configmap_name" -n "$namespace" -o yaml >"$output_file"
    check_command "导出ConfigMap"
}

_k8s_pod_describe() {
    local pod_name=$1
    local pod_ns=$2
    blue_echo "------------------------------------------------------"
    blue_echo "正在查看Pod详情: $pod_name..."
    kubectl describe pod "$pod_name" -n $pod_ns
    check_command "查看Pod详情"
    blue_echo "------------------------------------------------------"
}

_k8s_pod_exec() {
    local pod_name=$1
    local pod_ns=$2
    local command=$3
    blue_echo "------------------------------------------------------"
    blue_echo "正在进入Pod执行命令: $pod_name -> $command..."
    kubectl exec -it "$pod_name" -n $pod_ns -- $command
    check_command "在Pod中执行命令"
    blue_echo "------------------------------------------------------"
}

_k8s_pod_delete() {
    local pod_name=$1
    local pod_ns=$2
    blue_echo "------------------------------------------------------"
    blue_echo "正在删除Pod: $pod_name..."
    kubectl delete pod "$pod_name" -n $pod_ns
    check_command "删除Pod"
    blue_echo "------------------------------------------------------"
}

_k8s_pod_restart() {
    local pod_name=$1
    local pod_ns=$2
    blue_echo "------------------------------------------------------"
    blue_echo "正在重启Pod: $pod_name..."
    kubectl delete pod "$pod_name" -n $pod_ns
    check_command "重启Pod"
    blue_echo "------------------------------------------------------"
}

_k8s_pod_export() {
    local pod_name=$1
    local pod_ns=$2
    local output_file=$3
    blue_echo "------------------------------------------------------"
    blue_echo "正在导出Pod配置: $pod_name -> $output_file..."
    kubectl get pod "$pod_name" -n $pod_ns -o yaml >"$output_file"
    check_command "导出Pod配置"
    blue_echo "------------------------------------------------------"
}

_k8s_pod_logs() {
    local pod_name=$1
    local pod_ns=$2
    blue_echo "------------------------------------------------------"
    blue_echo "正在查看Pod日志: $pod_name..."
    kubectl logs "$pod_name" -n $pod_ns
    check_command "查看Pod日志"
    blue_echo "------------------------------------------------------"
}

_k8s_pod_label() {
    local pod_name=$1
    local pod_ns=$2
    local label_key=$2
    local label_value=$3
    blue_echo "正在修改Pod标签: $pod_name -> $label_key=$label_value..."
    kubectl label pods "$pod_name" -n $pod_ns "$label_key=$label_value" --overwrite
    check_command "修改Pod标签"
    blue_echo "------------------------------------------------------"
}

_k8s_pod_resources() {
    local pod_name=$1
    local pod_ns=$2
    blue_echo "正在查看Pod资源使用情况: $pod_name..."
    kubectl top pod "$pod_name" -n $pod_ns | awk '{print NR-1,$0}'
    check_command "查看Pod资源使用情况"
    blue_echo "------------------------------------------------------"
}

_k8s_pod_events() {
    local pod_name=$1
    local pod_ns=$2
    blue_echo "正在查看Pod事件: $pod_name..."
    kubectl get events --namespace="$pod_ns" --field-selector involvedObject.name="$pod_name"
    check_command "查看Pod事件"
    blue_echo "------------------------------------------------------"
}

_k8s_pod_copy() {
    local pod_name=$1
    local pod_ns=$2
    local src_path=$2
    local dest_path=$3
    blue_echo "------------------------------------------------------"
    blue_echo "正在复制Pod文件: $pod_name:$src_path -> $dest_path..."
    kubectl cp "$pod_name:$src_path" "$dest_path" -n $pod_ns
    check_command "复制Pod文件"
    blue_echo "------------------------------------------------------"
}

# 子函数：查看PersistentVolume列表
_k8s_storage_pv_list() {
    blue_echo "------------------------------------------------------"
    green_echo "正在获取PersistentVolume列表..."
    kubectl get pv | awk '{print NR-1,$0}'
    check_command "获取PersistentVolume列表"
    blue_echo "------------------------------------------------------"
}

# 子函数：查看PersistentVolumeClaim列表
_k8s_storage_pvc_list() {
    blue_echo "------------------------------------------------------"
    green_echo "正在获取PersistentVolumeClaim列表..."
    kubectl get pvc --all-namespaces | awk '{print NR-1,$0}'
    check_command "获取PersistentVolumeClaim列表"
    blue_echo "------------------------------------------------------"
}

# 子函数：查看StorageClass列表
_k8s_storage_sc_list() {
    blue_echo "------------------------------------------------------"
    green_echo "正在获取StorageClass列表..."
    kubectl get storageclass | awk '{print NR-1,$0}'
    check_command "获取StorageClass列表"
    blue_echo "------------------------------------------------------"
}

# 子函数：存储资源监控
_k8s_storage_monitor() {
    blue_echo "------------------------------------------------------"
    green_echo "正在检查存储资源使用情况..."
    kubectl top pod --all-namespaces --containers | grep -E 'PV|PVC' | awk '{print NR-1,$0}'
    check_command "检查存储资源使用情况"
    blue_echo "------------------------------------------------------"
}

# 查看节点状态
_k8s_node_status() {
    local node_name=$1
    blue_echo "开始检查K8S节点状态..."

    if [ -z "$node_name" ]; then
        kubectl get nodes
    else
        kubectl describe node "$node_name" | awk '{print NR-1,$0}'
    fi

    check_command "查看K8S节点状态"
}

# 添加节点
_k8s_node_add() {
    local MASTER_IP=$1
    local node_name=$2
    local JOIN_TOKEN=$3
    local DISCOVERY_TOKEN_CA_CERT_HASH=$4
    blue_echo "开始添加K8S节点: $node_name..."

    echo "正在添加节点 $node_name..."
    kubeadm join $MASTER_IP:6443 --token $JOIN_TOKEN --discovery-token-ca-cert-hash $DISCOVERY_TOKEN_CA_CERT_HASH
    check_command "添加K8S节点"
}

# 子函数：查看Deployment列表
_k8s_workload_deployment_list() {
    blue_echo "------------------------------------------------------"
    green_echo "正在获取Deployment列表..."
    kubectl get deployments --all-namespaces | awk '{print NR-1,$0}'
    check_command "获取Deployment列表"
}

# 子函数：查看StatefulSet列表
_k8s_workload_statefulset_list() {
    blue_echo "------------------------------------------------------"
    green_echo "正在获取StatefulSet列表..."
    kubectl get statefulsets --all-namespaces | awk '{print NR-1,$0}'
    check_command "获取StatefulSet列表"
}

# 子函数：查看DaemonSet列表
_k8s_workload_daemonset_list() {
    blue_echo "------------------------------------------------------"
    green_echo "正在获取DaemonSet列表..."
    kubectl get daemonsets --all-namespaces | awk '{print NR-1,$0}'
    check_command "获取DaemonSet列表"
}

# 子函数：查看CronJob列表
_k8s_workload_cronjob_list() {
    blue_echo "------------------------------------------------------"
    green_echo "正在获取CronJob列表..."
    kubectl get cronjobs --all-namespaces | awk '{print NR-1,$0}'
    check_command "获取CronJob列表"
}

# 子函数：查看Pod列表
_k8s_workload_pod_list() {
    blue_echo "------------------------------------------------------"
    green_echo "正在获取Pod列表..."
    kubectl get pods --all-namespaces | awk '{print NR-1,$0}'
    check_command "获取Pod列表"
}

# 子函数：查看命名空间列表
_k8s_namespace_list() {
    blue_echo "------------------------------------------------------"
    green_echo "正在获取命名空间列表..."
    kubectl get namespaces | awk '{print NR-1,$0}'
    check_command "获取命名空间列表"
    blue_echo "------------------------------------------------------"
}

# 子函数：创建命名空间
_k8s_namespace_create() {
    local namespace=$1
    blue_echo "------------------------------------------------------"
    green_echo "正在创建命名空间: $namespace"
    kubectl create namespace "$namespace"
    check_command "创建命名空间 $namespace"
    blue_echo "------------------------------------------------------"
}

# 子函数：删除命名空间
_k8s_namespace_delete() {
    local namespace=$1
    blue_echo "------------------------------------------------------"
    yellow_echo "警告：即将删除命名空间: $namespace"
    kubectl delete namespace "$namespace"
    check_command "删除命名空间 $namespace"
    blue_echo "------------------------------------------------------"
}

# 子函数：设置命名空间资源配额
_k8s_namespace_quota() {
    local namespace=$1
    local quota_file=$2
    blue_echo "------------------------------------------------------"
    green_echo "正在为命名空间 $namespace 设置资源配额..."
    kubectl apply -f "$quota_file" -n "$namespace"
    check_command "设置命名空间 $namespace 资源配额"
    blue_echo "------------------------------------------------------"
}

# 子函数：查看命名空间资源使用情况
_k8s_namespace_usage() {
    local namespace=$1
    blue_echo "------------------------------------------------------"
    green_echo "正在获取命名空间 $namespace 的资源使用情况..."
    kubectl top pods -n "$namespace" | awk '{print NR-1,$0}'
    kubectl describe quota -n "$namespace"
    check_command "获取命名空间 $namespace 资源使用情况"
    blue_echo "------------------------------------------------------"
}

# 删除节点
_k8s_node_remove() {
    local node_name=$1
    blue_echo "开始删除K8S节点: $node_name..."

    kubectl drain "$node_name" --delete-local-data --force --ignore-daemonsets
    kubectl delete node "$node_name"

    check_command "删除K8S节点"
}

# 节点维护模式
_k8s_node_maintenance() {
    local node_name=$1
    local action=$2
    blue_echo "开始设置节点维护模式: $node_name -> $action..."

    if [ "$action" = "enable" ]; then
        kubectl cordon "$node_name"
    elif [ "$action" = "disable" ]; then
        kubectl uncordon "$node_name"
    else
        red_echo "无效的操作: $action (必须是enable/disable)"
        return 1
    fi

    check_command "设置节点维护模式"
}

# 节点资源监控
_k8s_node_monitor() {
    local node_name=$1
    blue_echo "开始监控K8S节点资源: $node_name..."

    kubectl top node "$node_name"
    kubectl describe node "$node_name" | grep -A 10 "Allocated resources"

    check_command "监控K8S节点资源"
}

# 集群状态查看
_k8s_cluster_status() {
    blue_echo "正在检查K8S集群状态..."
    kubectl get nodes -o wide | awk '{print NR-1,$0}'
    check_command "获取K8S节点状态"
    kubectl get pods --all-namespaces -o wide | awk '{print NR-1,$0}'
    check_command "获取所有命名空间的Pods状态"
}

# 集群组件健康检查
_k8s_cluster_health() {
    blue_echo "正在检查K8S集群组件健康状况..."
    kubectl get componentstatuses | awk '{print NR-1,$0}'
    check_command "获取K8S组件状态"
    kubectl get --raw '/healthz?verbose'
    check_command "检查集群健康状态"
}

# 集群版本升级
_k8s_cluster_upgrade() {
    local version=$1
    blue_echo "正在准备升级K8S集群到版本: $version..."
    # 这里应该有实际的升级逻辑
    yellow_echo "警告:集群升级是一个危险操作，请确保已做好备份！"
    if command -v kubeadm &>/dev/null; then
        kubeadm upgrade plan "$version"
        check_command "检查升级计划"
        # 实际升级命令应该在这里，但为了安全起见我们只模拟
        green_echo "模拟升级完成到版本 $version"
    else
        red_echo "错误:kubeadm 命令未找到"
    fi
}

# 集群备份
_k8s_cluster_backup() {
    local backup_file=$1
    blue_echo "正在备份K8S集群到文件: $backup_file..."
    # 这里应该有实际的备份逻辑
    kubectl get all --all-namespaces -o yaml >"$backup_file"
    check_command "集群资源备份"
    green_echo "集群已成功备份到 $backup_file"
}

# 集群恢复
_k8s_cluster_restore() {
    local backup_file=$1
    blue_echo "正在从文件 $backup_file 恢复K8S集群..."
    # 这里应该有实际的恢复逻辑
    if [ -f "$backup_file" ]; then
        kubectl apply -f "$backup_file"
        check_command "集群恢复"
    else
        red_echo "错误:备份文件 $backup_file 不存在"
    fi
}
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
# 将标准输出和标准错误重定向到日志文件
exec > >(tee -a "$pre_log_file") 2>&1
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
