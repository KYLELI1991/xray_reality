#!/bin/bash
sudo apt install unzip -y
mkdir xray_reality && cd xray_reality
version_tag=$(wget -qO- -t1 -T2 "https://api.github.com/repos/XTLS/Xray-core/releases" | grep "tag_name" | head -n 1 | awk -F ":" '{print $2}' | sed 's/\"//g;s/,//g;s/ //g')
wget -N --no-check-certificate https://github.com/XTLS/Xray-core/releases/download/$version_tag/Xray-linux-64.zip
unzip -o Xray-linux-64.zip
rm Xray-linux-64.zip
chmod +x xray

# generate reality keys and uuid
uuid=$(./xray uuid)
reality_keys=$(./xray x25519)
private_key=$(echo $reality_keys | awk '{print $3}')
public_key=$(echo $reality_keys | awk '{print $6}')
cwd=$(pwd)

echo -n "握手网站:"                   
read  tlsdomain
echo -n "自定义端口:"                   
read  custom_port
# get config
wget --no-check-certificate -O config.json https://raw.githubusercontent.com/KYLELI1991/xray_reality/main/test/vmess-config.json
wget --no-check-certificate -O /etc/systemd/system/xray_reality.service https://raw.githubusercontent.com/KYLELI1991/xray_reality/main/test/xray_reality.service

# get ip
wgcfv6status=$(curl -s6m8 https://www.cloudflare.com/cdn-cgi/trace -k | grep warp | cut -d= -f2) 
wgcfv4status=$(curl -s4m8 https://www.cloudflare.com/cdn-cgi/trace -k | grep warp | cut -d= -f2)
if [[ $wgcfv4status =~ "on"|"plus" ]] || [[ $wgcfv6status =~ "on"|"plus" ]]; then
        wg-quick down wgcf >/dev/null 2>&1
        systemctl stop warp-go >/dev/null 2>&1
        v6=$(curl -s6m8 api64.ipify.org -k)
        v4=$(curl -s4m8 api64.ipify.org -k)
        wg-quick up wgcf >/dev/null 2>&1
        systemctl start warp-go >/dev/null 2>&1
else
        v6=$(curl -s6m8 api64.ipify.org -k)
        v4=$(curl -s4m8 api64.ipify.org -k)
fi

sed -i "s/uuid/$uuid/g" config.json
sed -i "s/握手网站/$tlsdomain/g" config.json
sed -i "s/自定义端口/$custom_port/g" config.json
sed -i "s/私钥/$private_key/g" config.json
sed -i "s#安装路径#$cwd#g" config.json
sed -i "s#安装路径#$cwd#g" /etc/systemd/system/xray_reality.service

# nohup ./xray run >/dev/null 2>&1 &
# use systemctl service

systemctl enable xray_reality.service
systemctl start xray_reality.service

clash_proxy=$(echo -e "{name: vmess_reality, type: vmess, server: $v4, port: $custom_port, uuid: $uuid, alterId: 0, cipher: none, network: tcp, tls: true, udp: true, client-fingerprint: chrome, servername: $tlsdomain, reality-opts: {public-key: $public_key}}")
echo $reality_keys $clash_proxy >clash_proxy.txt
echo -e "已完成安装xray vmess reality clash meta 代理设置 \n $clash_proxy"



