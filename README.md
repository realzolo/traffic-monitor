# traffic-monitor
服务器流量控制、监控脚本，适用于CentOS、Ubuntu系统。

## 脚本：traffic_control.sh
主要作用：控制单位时间内的流量，单位时间内的流量超过限制则限制访问。
根据实际情况修改脚本中的参数：
```bash
# 设置网卡接口
INTERFACE=eth0
# 设置流量上限（单位：MB），超出则断开网络
LIMIT=8
# 设置监控的时间间隔（单位：秒）
INTERVAL=10
# 网卡禁用时间（单位：秒）
DISABLE_TIME=30
```
脚本授权：`chmod +x traffic_control.sh`，执行脚本：`./traffic_control.sh`，即可开始监控服务器的流出流量，并在流量超出阈值时断开网络。

## 脚本：traffic_monitor.sh
主要作用：监控单位时间内的流量，实时显示流量信息。