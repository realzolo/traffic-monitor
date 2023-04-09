#!/bin/bash

# 设置网卡接口
INTERFACE=eth0
# 设置流量上限（单位：MB），超出则断开网络
LIMIT=8
# 设置监控的时间间隔（单位：秒）
INTERVAL=10
# 网卡禁用时间（单位：秒）
DISABLE_TIME=30

#判断网卡存在与否,不存在则退出
if [ ! -d /sys/class/net/$INTERFACE ]; then
    echo -e "Network-Interface Not Found"
    echo -e "You system have network-interface:\n$(ls /sys/class/net)"
    exit 5
fi

# 获取操作系统类型
OS=$(awk -F= '$1=="ID"{print $2}' /etc/os-release)

# 判断网络管理器是否启动
if [[ "$OS" == "ubuntu" ]]; then
    if [[ $(systemctl is-active NetworkManager) == "inactive" ]]; then
        echo "NetworkManager未启动，请先启动NetworkManager后再运行此脚本。"
        exit 1
    fi
else
    if [[ $(systemctl is-active NetworkManager.service) == "inactive" ]]; then
        echo "NetworkManager未启动，请先启动NetworkManager后再运行此脚本。"
        exit 1
    fi
fi

# 获取当前的出流量
tx_scale="cat /proc/net/dev | grep $INTERFACE | tr ':' ' ' | awk '{print \$10}'"
prev_tx=$(eval $tx_scale)

while :; do
    # 等待
    sleep $INTERVAL

    # 获取10秒后的出流量
    current_tx=$(eval $tx_scale)

    # 计算10秒内的出流量
    tx_bytes=$((current_tx - prev_tx))

    tx_mb=$(echo "scale=2; $tx_bytes/1024/1024" | bc)
    if [[ $tx_mb =~ ^\.[0-9]+$ ]]; then
        tx_mb="0$tx_mb"
    fi

    # 打印信息
    echo "$(date "+%Y-%m-%d %H:%M:%S"): $INTERVAL 秒内 $INTERFACE 网口的出口流量为 $tx_mb MB"

    # 如果出流量超过阈值，关闭网络并重连
    if [ $(echo "$tx_mb>$LIMIT" | bc) -eq 1 ]; then
        echo "流量超出上限 $LIMIT MB，网络保护已启动。服务器将在 $DISABLE_TIME 秒后恢复正常。"

        # 关闭网络接口
        if [[ "$OS" == "ubuntu" ]]; then
            nmcli dev disconnect $INTERFACE
        else
            nmcli device disconnect $INTERFACE
        fi

        sleep $DISABLE_TIME

        # 重新启动网络接口
        if [[ "$OS" == "ubuntu" ]]; then
            nmcli dev connect $INTERFACE
        else
            nmcli device connect $INTERFACE
        fi

        # 更新上一次的流量数据
        prev_tx=$(eval $tx_scale)
        continue
    fi

    # 更新上一次的流量数据
    prev_tx=$current_tx
done
