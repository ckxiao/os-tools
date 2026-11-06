#!/usr/bin/env bash
# getopts example shipped with the Ubuntu 24.04 tool profile.
# 设置默认值
host="default_host"
arg="default_arg"

# 解析选项参数
while getopts ":h:a:" opt; do
    case $opt in
    h)
        host="$OPTARG" # 覆盖默认值
        ;;
    a)
        arg="$OPTARG"
        ;;
    \?)
        echo "无效选项: -$OPTARG"
        exit 1
        ;;
    :)
        echo "选项 -$OPTARG 需要参数"
        exit 1
        ;;
    esac
done

# 输出结果
echo "Host: $host, Argument: $arg"
