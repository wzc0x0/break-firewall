#!/bin/bash
#判断系统
if [ ! -e '/etc/redhat-release' ]; then
echo "仅支持centos7"
exit
fi
if  [ -n "$(grep ' 6\.' /etc/redhat-release)" ] ;then
echo "仅支持centos7"
exit
fi

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


install_caddy() {

    curl https://getcaddy.com | bash -s personal
    curl -s https://raw.githubusercontent.com/wzc0x0/break-firewall/master/v2ray-tls-ws/caddy.service -o /etc/systemd/system/caddy.service

    mkdir -p /etc/caddy
    mkdir -p /var/www
    
    curl -s https://raw.githubusercontent.com/wzc0x0/break-firewall/master/v2ray-tls-ws/index.html -o /var/www/index.html
    cat > /etc/caddy/Caddyfile <<-EOF
    dls.cankiss.ml:443 {
        root /var/www
        gzip
        index index.html
        tls /etc/ssl/cankiss.ml/certificate.crt /etc/ssl/cankiss.ml/private.key
        header / -Server
        header / Strict-Transport-Security "max-age=31536000;"
        proxy /ray localhost:10086 {
            websocket
            header_upstream -Origin
        }
    }
EOF
    systemctl enable caddy
    systemctl start caddy
}

install_v2ray() {

    green "======================"
    green " 输入解析到此VPS的域名"
    green "======================"
    read domain

    yum install -y wget
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
}

remove_v2ray(){
    systemctl stop v2ray.service
    systemctl disable v2ray.service
    
    rm -rf /usr/bin/v2ray /etc/v2ray
    rm -rf /etc/v2ray
    
    green "v2ray已删除"
    
}

remove_caddy() {
    systemctl stop caddy
    systemctl disable caddy
    rm /usr/local/bin/caddy
    rm -rf /etc/caddy
    
    green "caddy已删除"
}

start_menu(){
    clear
    green " ===================================="
    green " 介绍：一键安装v2ray+ws+tls            "
    green " 系统：centos7                       "
    green " 作者：wzc0x0@gmail.com              "
    green " ===================================="
    echo
    green " 1. 安装v2ray+ws+tls"
    green " 2. 升级v2ray"
    red " 3. 卸载v2ray"
    yellow " 0. 退出脚本"
    green " 4. 安装caddy"
    echo
    read -p "请输入数字:" num
    case "$num" in
    1)
    install_caddy
    install_v2ray
    ;;
    2)
    bash <(curl -L -s https://install.direct/go.sh)  
    ;;
    3)
    remove_v2ray 
    ;;
    0)
    exit 1
    ;;
    4)
    install_caddy
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