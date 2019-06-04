#!/bin/bash

function blue(){
    echo -e "\033[34m\033[01m $1 \033[0m"
}
function green(){
    echo -e "\033[32m\033[01m $1 \033[0m"
}
function red(){
    echo -e "\033[31m\033[01m $1 \033[0m"
}
function yellow(){
    echo -e "\033[33m\033[01m $1 \033[0m"
}

init() {
    read -p "Enter your domain (example: www.google.com) " domain
    read -p "Enter your certificate.crt path (example: /etc/ssl/certificate.crt) " certPath
    read -p "Enter your private.key path (example: /etc/ssl/private.key) " keyPath

    install_v2ray
    install_goddy
    try_enable_bbr
}


install_v2ray() {
    cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
    bash <(curl -L -s https://install.direct/go.sh)  
    cd /etc/v2ray/
    rm -f config.json
    wget https://raw.githubusercontent.com/wzc0x0/break-firewall/master/v2ray-tls-ws/config.json
    v2uuid=$(cat /proc/sys/kernel/random/uuid)
    sed -i "s/uid/$v2uuid/;" config.json
    systemctl restart v2ray.service

    clear
    green
    green "安装已经完成"
    green 
    green "===========配置参数============"
    green "地址：${domain}"
    green "端口：443"
    green "uuid：${v2uuid}"
    green "额外id：99"
    green "加密方式：auto"
    green "传输协议：ws"
    green "底层传输：tls"
    green
    green "shadowsocks"
    green "端口：8080"
    green "加密方式：aes-256-gcm",
    green "密码：helloworld"
    green
}

remove_v2ray() {
    systemctl stop v2ray.service
    systemctl disable v2ray.service
    
    rm -rf /usr/bin/v2ray /etc/v2ray
    rm -rf /etc/v2ray
    
    green "v2ray已删除"
}

install_goddy() {
    curl https://getcaddy.com | bash -s personal hook.service,http.filter

    cp /usr/local/bin/caddy /usr/bin/

    if [! -d "/var/www" ]; then 
        mkdir /var/www
        chmod 555 /var/www
    fi
    
    if [! -d "/etc/caddy" ]; then
        mkdir /etc/caddy
        chown -R root:root /etc/caddy
    fi

    curl -s https://raw.githubusercontent.com/wzc0x0/break-firewall/master/v2ray-tls-ws/index.html -o /var/www/index.html
    cat > /etc/caddy/Caddyfile <<EOF
$domain:443 {
    root /var/www
    gzip
    index index.html
    tls  $certPath $keyPath
    header / -Server
    header / Strict-Transport-Security "max-age=31536000;"
    proxy /ray localhost:10086 {
            websocket
            header_upstream -Origin
    }
}
EOF

    caddy -service install -conf /etc/caddy/Caddyfile
    systemctl restart caddy.service
}

try_enable_bbr() {
	if [[ $(uname -r | cut -b 1) -eq 4 ]]; then
		case $(uname -r | cut -b 3-4) in
		9. | [1-9][0-9])
			sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf
			sed -i '/net.core.default_qdisc/d' /etc/sysctl.conf
			echo "net.ipv4.tcp_congestion_control = bbr" >>/etc/sysctl.conf
			echo "net.core.default_qdisc = fq" >>/etc/sysctl.conf
			sysctl -p >/dev/null 2>&1
			;;
		esac
	fi
}

remove_goddy() {
    caddy -service stop
    caddy -service uninstall

    rm /usr/local/bin/caddy /usr/bin/caddy
    rm -rf /etc/caddy

    green "goddy remove already！"
}

start_menu() {
    clear
    echo
    green " 1. 安装v2ray + goddy"
    green " 2. 升级v2ray"
    red " 3. 卸载v2ray"
    red " 4. 卸载goddy"
    yellow " 0. 退出脚本"
    echo
    read -p "请输入数字:" num
    case "$num" in
    1)
    init
    ;;
    2)
    bash <(curl -L -s https://install.direct/go.sh)  
    ;;
    3)
    remove_v2ray
    ;;
    4)
    remove_goddy
    ;;
    0)
    exit 1
    ;;
    *)
    clear
    red "请输入正确数字"
    sleep 2s
    start_menu
    ;;
    esac
}

start_menu