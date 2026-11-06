#!/usr/bin/env bash
#
# 容器管理子模块，由 mgt-god.sh source 加载，不单独执行。
# 依赖 mgt-god.sh 中定义的 GREEN_echo / blue_echo / red_echo / check_command 等函数。

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    echo "container.sh 是 mgt-god.sh 的子模块，不能直接执行。" >&2
    exit 1
fi

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
        [ $1 = "stats" ] && _system_docker_resource_stats
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
                _system_docker_resource_stats
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
