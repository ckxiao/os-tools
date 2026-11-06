#!/usr/bin/env bash
#
# 用户管理子模块，由 mgt-god.sh source 加载，不单独执行。
# 依赖 mgt-god.sh 中定义的 GREEN_echo / blue_echo / red_echo / check_command 等函数。

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    echo "users.sh 是 mgt-god.sh 的子模块，不能直接执行。" >&2
    exit 1
fi

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
                yellow_echo "已取消解锁操作"
            fi
        else
            # 当前未锁定,执行锁定
            read -p "用户 $username 当前未锁定,是否要锁定？(y/n): " confirm
            if [ "$confirm" = "y" ]; then
                usermod -L "$username" && green_echo "用户 $username 已成功锁定" || red_echo "用户 $username 锁定操作失败" #当前未锁定,是否要锁定
            else
                yellow_echo "已取消锁定操作"
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
        [ $2 = "add" ] && sudo usermod -aG sudo "$username" && green_echo "权限添加成功($username)"
        [ $2 = "del" ] && sudo deluser "$username" sudo && green_echo "权限移除成功($username)"
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
                green_echo "用户 $username 的权限信息:"
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
        [ $2 = "gen" ] && sudo -u "$username" ssh-keygen -t "rsa" -b "4096" -C "SSH Login cert" -f "/home/$username/.ssh/id_rsa" && green_echo "成功" ||
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

    sed -i '/^password\s\+.*pam_cracklib\.so/d' "$PAM_COMMON_PASSWORD" || green_echo "删除旧配置失败(pam_cracklib)" #被pam_cracklib替换掉了不用了.
    sed -i '/^password\s\+.*pam_pwquality\.so/d' "$PAM_COMMON_PASSWORD" || green_echo "删除旧配置失败(pam_pwquality)"
    echo "password    requisite           pam_pwquality.so retry=3 minlen=$minlen ucredit=$ucredit lcredit=$lcredit dcredit=$dcredit ocredit=$ocredit difok=$difok enforce_for_root" >>"$PAM_COMMON_PASSWORD" || {
        red_echo "写入失败(pam_pwquality)"
        return 1
    }
    sed -i '/^minlen/d' "$CONFIG_FILE" && echo "minlen = $minlen" >>"$CONFIG_FILE" && green_echo "minlen 更新成功" || red_echo "minlen 更新失败"
    sed -i '/^ucredit/d' "$CONFIG_FILE" && echo "ucredit = $ucredit" >>"$CONFIG_FILE" && green_echo "ucredit 更新成功" || red_echo "ucredit 更新失败"
    sed -i '/^dcredit/d' "$CONFIG_FILE" && echo "dcredit = $dcredit" >>"$CONFIG_FILE" && green_echo "dcredit 更新成功" || red_echo "dcredit 更新失败"
    sed -i '/^ocredit/d' "$CONFIG_FILE" && echo "ocredit = $ocredit" >>"$CONFIG_FILE" && green_echo "ocredit 更新成功" || red_echo "ocredit 更新失败"
    sed -i '/^maxrepeat/d' "$CONFIG_FILE" && echo "maxrepeat = $maxrepeat" >>"$CONFIG_FILE" && green_echo "maxrepeat 更新成功" || red_echo "maxrepeat 更新失败"
    sed -i '/^difok/d' "$CONFIG_FILE" && echo "difok = $difok" >>"$CONFIG_FILE" && green_echo "difok 更新成功" || red_echo "difok 更新失败"

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
