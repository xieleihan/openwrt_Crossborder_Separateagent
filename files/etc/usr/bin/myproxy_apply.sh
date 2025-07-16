#!/bin/sh

# 清理旧规则
iptables -t nat -F MYPROXY 2>/dev/null || iptables -t nat -N MYPROXY
iptables -t nat -D PREROUTING -j MYPROXY 2>/dev/null
iptables -t nat -A PREROUTING -j MYPROXY

# 加载配置并设置规则
. /lib/functions.sh
config_load myproxy

config_foreach apply_rule device_proxy

apply_rule() {
    local cfg="$1"
    config_get ip "$cfg" ip
    config_get proxy_ip "$cfg" proxy_ip
    config_get proxy_port "$cfg" proxy_port

    # 添加 REDIRECT 规则到自定义链
    iptables -t nat -A MYPROXY -s $ip -p tcp -j REDIRECT --to-ports $proxy_port
}