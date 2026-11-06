#!/usr/bin/env bash
#
# K8S 管理子模块，由 mgt-god.sh source 加载，不单独执行。
# 依赖 mgt-god.sh 中定义的 GREEN_echo / blue_echo / red_echo / check_command 等函数。

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    echo "k8s.sh 是 mgt-god.sh 的子模块，不能直接执行。" >&2
    exit 1
fi

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
