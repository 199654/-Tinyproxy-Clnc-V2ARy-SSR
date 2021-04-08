#!/bin/bash
#==========================#
###### Author: CuteBi ######
#==========================#

#Stop v2ray & delete v2ray files.
Delete() {
	systemctl disable v2ray.service
	rm -rf /etc/init.d/v2ray /lib/systemd/system/v2ray.service
	if [ -f "${v2ray_install_directory:=/usr/local/v2ray}/v2ray.init" ]; then
		"$v2ray_install_directory"/v2ray.init stop
		rm -rf "$v2ray_install_directory"
	fi
}

#Print error message and exit.
Error() {
	echo $echo_e_arg "\033[41;37m$1\033[0m"
	echo -n "remove v2ray?[y]: "
	read remove
	echo "$remove"|grep -qi 'n' || Delete
	exit 1
}

makeHttpInbound() {
local port="$1"
local tlsConfig="$2"
echo '{
			"port": "'$port'",
			"protocol": "vmess",
			"settings": {
				"udp": true,
				"clients": [{
					 "id": "'$uuid'",
					 "level": 0,
					 "alterId": 4
				}]
			},
			"streamSettings": {
				"sockopt": {
					"tcpFastOpen": '$tcpFastOpen'
				},
				"network": "tcp",
				"tcpSettings": {
					"header": {
						"type": "http"
					}
				}'"$tlsConfig"'
			}
		}'
}

makeWSInbound() {
local port="$1"
local tlsConfig="$2"
local url="$3"
echo '{
			"port": "'$port'",
			"protocol": "vmess",
			"settings": {
				"udp": true,
				"clients": [{
					"id": "'$uuid'",
					"level": 0,
					"alterId": 4
				}]
			},
			"streamSettings": {
				"sockopt": {
					"tcpFastOpen": '$tcpFastOpen'
				},
				"network": "ws",
				"wsSettings": {
					"path": "'$url'"
				}'"$tlsConfig"'
			}
		}'
}

makeKcpInbound() {
local port="$1"
local tlsConfig="$2"
echo '{
			"port": "'$port'",
			"protocol": "vmess",
			"settings": {
				"udp": true,
				"clients": [{
					"id": "'$uuid'",
					"level": 0,
					"alterId": 4
				}]
			},
			"streamSettings": {
				"network": "kcp",
				"kcpSettings": {
					"header": {
						"type": "utp"
					}
				}'"$tlsConfig"'
			}
		}'
}

#Make v2ray.json
Config() {
	clear
	uuid=`cat /proc/sys/kernel/random/uuid`
	tcpFastOpen=`[ -f /proc/sys/net/ipv4/tcp_fastopen ] && echo -n 'true' || echo -n 'false'`
	local tlsConfig=',
				"security": "tls",
				"tlsSettings": {
					"certificates": [
						{
							"certificate": [
								"-----BEGIN CERTIFICATE-----",
								"MIIBXDCCAQGgAwIBAgIRAJGznGo52YN8XZsskKV8Lb0wCgYIKoZIzj0EAwIwEjEQ",
								"MA4GA1UEChMHQWNtZSBDbzAeFw0yMDEwMjkwMjE4MThaFw0yMTEwMjkwMjE4MTha",
								"MBIxEDAOBgNVBAoTB0FjbWUgQ28wWTATBgcqhkjOPQIBBggqhkjOPQMBBwNCAATh",
								"HdMSNXahLmHCz+NP/GrBn6N1aV+qqLrjLMdK8J044pdJ0DrvnbCCDestM14MQ1xU",
								"EDDHcEwNOg4E5vY4/24TozgwNjAOBgNVHQ8BAf8EBAMCBaAwEwYDVR0lBAwwCgYI",
								"KwYBBQUHAwEwDwYDVR0TAQH/BAUwAwEB/zAKBggqhkjOPQQDAgNJADBGAiEAq8v6",
								"zMfBD/gvyDk5ll6tpMygOv7WpOymw4OpHh/c9wwCIQCkuF5wMaSdr1OfaRbCjSah",
								"GKz05vffU1oB4os+cWqnAA==",
								"-----END CERTIFICATE-----"
							],
							"key": [
								"-----BEGIN PRIVATE KEY-----",
								"MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQgZUHA/1lmLZNCmGU5",
								"Qum/+rf5FVfS3WacJwQSfw/MKyuhRANCAAThHdMSNXahLmHCz+NP/GrBn6N1aV+q",
								"qLrjLMdK8J044pdJ0DrvnbCCDestM14MQ1xUEDDHcEwNOg4E5vY4/24T",
								"-----END PRIVATE KEY-----"
							]
						}
					]
				}'
	if [ -z "$v2ray_install_directory" ]; then
		echo -n "Please input v2ray install directory(default is /usr/local/v2ray): "
		read v2ray_install_directory
		echo -n "Install UPX version?[n]: "
		read v2ray_UPX
		echo "$v2ray_UPX"|grep -qi '^y' && v2ray_UPX="upx" || v2ray_UPX=""
		echo $echo_e_arg "options(TLS default self signed certificate, if necessary, please change it yourself.):
		\r\t1. tcp_http
		\r\t2. tcp_http+tls
		\r\t3. WebSocket
		\r\t4. WebSocket+tls
		\r\t5. mkcp
		\r\t6. mkcp+tls
		\rPlease input your options(Separate multiple options with spaces):"
		read v2ray_inbounds_options
		for opt in $v2ray_inbounds_options; do
			case $opt in
				1)
					echo -n "Please input v2ray http server port: "
					read v2ray_http_port
				;;
				2)
					echo -n "Please input v2ray http tls server port: "
					read v2ray_http_tls_port
				;;
				3)
					echo -n "Please input v2ray webSocket server port: "
					read v2ray_ws_port
					echo -n "Please input v2ray webSocket Path(default is '/'): "
					read v2ray_ws_path
					v2ray_ws_path=${v2ray_ws_path:-/}
				;;
				4)
					echo -n "Please input v2ray webSocket tls server port: "
					read v2ray_ws_tls_port
					echo -n "Please input v2ray webSocket tls Path(default is '/'): "
					read v2ray_ws_tls_path
					v2ray_ws_tls_path=${v2ray_ws_tls_path:-/}
				;;
				5)
					echo -n "Please input v2ray mKCP server port: "
					read v2ray_mkcp_port
				;;
				6)
					echo -n "Please input v2ray mKCP tls server port: "
					read v2ray_mkcp_tls_port
				;;
			esac
		done
	fi
	for opt in $v2ray_inbounds_options; do
		[ -n "$in_networks" ] && in_networks="$in_networks, "
		case $opt in
			1) in_networks="$in_networks"`makeHttpInbound "$v2ray_http_port" ""`;;
			2) in_networks="$in_networks"`makeHttpInbound "$v2ray_http_tls_port" "$tlsConfig"`;;
			3) in_networks="$in_networks"`makeWSInbound "$v2ray_ws_port" "" "$v2ray_ws_path"`;;
			4) in_networks="$in_networks"`makeWSInbound "$v2ray_ws_tls_port" "$tlsConfig" "$v2ray_ws_tls_path"`;;
			5) in_networks="$in_networks"`makeKcpInbound "$v2ray_mkcp_port" ""`;;
			6) in_networks="$in_networks"`makeKcpInbound "$v2ray_mkcp_tls_port" "$tlsConfig"`;;
		esac
	done
}

GetAbi() {
	machine=`uname -m`
	#mips[...] use 'le' version
	if echo "$machine"|grep -q 'mips64'; then
		machine='mips64le'
	elif echo "$machine"|grep -q 'mips'; then
		machine='mipsle'
	elif echo "$machine"|grep -Eq 'i686|i386'; then
		machine='32'
	elif echo "$machine"|grep -Eq 'armv7|armv6'; then
		machine='arm'
	elif echo "$machine"|grep -Eq 'armv8|aarch64'; then
		machine='arm64'
	else
		machine='64'
	fi
}

#install v2ray v2ray.init v2ray.service
InstallFiles() {
	GetAbi
	mkdir -p "${v2ray_install_directory:=/usr/local/v2ray}" || Error "Create v2ray install directory failed."
	cd "$v2ray_install_directory" || Error "Create cns install directory failed."
	echo $echo_E_arg '
	{
		"log" : {
			"loglevel": "none"
		},
		"inbounds": ['"$in_networks"'],
		"outbounds": [{
			"protocol": "freedom"
		}]
	}
	' >v2ray.json
	#install v2ray
	$download_tool_cmd v2ray http://pros.cutebi.taobao69.cn:666/v2ray/${v2ray_UPX}/${machine} || Error "v2ray download failed."
	$download_tool_cmd v2ray.init http://pros.cutebi.taobao69.cn:666/v2ray/v2ray.init || Error "v2ray.init download failed."
	sed -i "s~\[v2ray_install_directory\]~$v2ray_install_directory~g" v2ray.init
	sed -i "s~\[v2ray_tcp_port_list\]~$v2ray_http_port $v2ray_http_tls_port $v2ray_ws_port $v2ray_ws_tls_port~g" v2ray.init
	sed -i "s~\[v2ray_udp_port_list\]~$v2ray_mkcp_port $v2ray_mkcp_tls_port~g" v2ray.init
	ln -s "$v2ray_install_directory/v2ray.init" /etc/init.d/v2ray
	chmod -R 777 "$v2ray_install_directory" /etc/init.d/v2ray
	if type systemctl; then
		$download_tool_cmd /lib/systemd/system/v2ray.service http://pros.cutebi.taobao69.cn:666/v2ray/v2ray.service || Error "v2ray.service download failed."
		chmod 777 /lib/systemd/system/v2ray.service
		sed -i "s~\[v2ray_install_directory\]~$v2ray_install_directory~g" /lib/systemd/system/v2ray.service
		systemctl daemon-reload
	fi
}

#install initialization
InstallInit() {
	echo -n "make a update?[n]: "
	read update
	PM=`which apt-get || which yum`
	echo "$update"|grep -qi 'y' && $PM -y update
	$PM -y install curl wget #unzip
	type curl && download_tool_cmd='curl -L --connect-timeout 7 -ko' || download_tool_cmd='wget -T 60 --no-check-certificate -O'
	getip_urls="http://myip.dnsomatic.com/ http://ip.sb/"
	for url in $getip_urls; do
		ip=`$download_tool_cmd - "$url"`
	done
}

outputVmessLink() {
	[ -z "$ip" ] && return
	for opt in $v2ray_inbounds_options; do
		case $opt in
			1)
				link=`echo -n $echo_E_arg '{"add": "'$ip'", "port": '$v2ray_http_port', "aid": "4", "host": "cutebi.taobao69.cn", "id": "'$uuid'", "net": "tcp", "path": "/", "ps": "http_'$ip:$v2ray_http_port'", "tls": "", "type": "http", "v": "2"}'|base64 -w 0`
				echo $echo_e_arg "\033[45;37m\rhttp:\033[0m\n\t\033[4;35mvmess://$link\033[0m"
			;;
			2)
				link=`echo -n $echo_E_arg '{"add": "'$ip'", "port": '$v2ray_http_tls_port', "aid": "4", "host": "cutebi.taobao69.cn", "id": "'$uuid'", "net": "tcp", "path": "/", "ps": "httpTLS_'$ip:$v2ray_http_tls_port'", "tls": "cutebi.taobao69.cn", "type": "http", "v": "2"}'|base64 -w 0`
				echo $echo_e_arg "\033[45;37m\rhttp+tls:\033[0m\n\t\033[4;35mvmess://$link\033[0m"
			;;
			3)
				link=`echo -n $echo_E_arg '{"add": "'$ip'", "port": "'$v2ray_ws_port'", "aid": "4", "host": "cutebi.taobao69.cn", "id": "'$uuid'", "net": "ws", "path": "'$v2ray_ws_path'", "ps": "ws_'$ip:$v2ray_ws_port'", "tls": "", "type": "none", "v": "2"}'|base64 -w 0`
				echo $echo_e_arg "\033[45;37m\rws:\033[0m\n\t\033[4;35mvmess://$link\033[0m"
			;;
			4)
				link=`echo -n $echo_E_arg '{"add": "'$ip'", "port": "'$v2ray_ws_tls_port'", "aid": "4", "host": "cutebi.taobao69.cn", "id": "'$uuid'", "net": "ws", "path": "'$v2ray_ws_tls_path'", "ps": "ws+tls_'$ip:$v2ray_ws_tls_port'", "tls": "cutebi.taobao69.cn", "type": "none", "v": "2"}'|base64 -w 0`
				echo $echo_e_arg "\033[45;37m\rws+tls:\033[0m\n\t\033[4;35mvmess://$link\033[0m"
			;;
			5)
				link=`echo -n $echo_E_arg '{"add": "'$ip'", "port": "'$v2ray_mkcp_port'", "aid": "4", "host": "", "id": "'$uuid'", "net": "kcp", "path": "", "ps": "mkcp_'$ip:$v2ray_mkcp_port'", "tls": "", "type": "utp", "v": "2"}'|base64 -w 0`
				echo $echo_e_arg "\033[45;37m\rmkcp:\033[0m\n\t\033[4;35mvmess://$link\033[0m"
			;;
			6)
				link=`echo -n $echo_E_arg '{"add": "'$ip'", "port": "'$v2ray_mkcp_tls_port'", "aid": "4", "host": "", "id": "'$uuid'", "net": "kcp", "path": "", "ps": "mkcp_'$ip:$v2ray_mkcp_tls_port'", "tls": "cutebi.taobao69.cn", "type": "utp", "v": "2"}'|base64 -w 0`
				echo $echo_e_arg "\033[45;37m\rmkcp+tls:\033[0m\n\t\033[4;35mvmess://$link\033[0m"
			;;
		esac
	done
}

Install() {
	Config
	Delete >/dev/null 2>&1
	InstallInit
	InstallFiles
	"$v2ray_install_directory/v2ray.init" start|grep -q FAILED && Error "v2ray install failed."
	systemctl restart v2ray &>/dev/null
	echo $echo_e_arg \
		"\033[44;37mv2rayinstall success.\033[0;34m
		`
			for opt in $v2ray_inbounds_options; do
				case $opt in
					1) echo $echo_e_arg "\r	http server:\033[34G port=${v2ray_http_port}";;
					2) echo $echo_e_arg "\r	http tls server:\033[34G port=${v2ray_http_tls_port}";;
					3) echo $echo_e_arg "\r	webSocket server:\033[34G port=${v2ray_ws_port} path=${v2ray_ws_path}";;
					4) echo $echo_e_arg "\r	webSocket tls server:\033[34G port=${v2ray_ws_tls_port} path=${v2ray_ws_tls_path}";;
					5) echo $echo_e_arg "\r	mKCP server:\033[34G port=${v2ray_mkcp_port} type=utp";;
					6) echo $echo_e_arg "\r	mKCP tls server:\033[34G port=${v2ray_mkcp_tls_port} type=utp";;
				esac
			done
		`
		\r	uuid:\033[35G$uuid
		\r	alterId:\033[35G4
		\r`[ -f /etc/init.d/v2ray ] && /etc/init.d/v2ray usage || \"$v2ray_install_directory/v2ray.init\" usage`
		`outputVmessLink`\033[0m"
}

Uninstall() {
	echo -n "Please input v2ray install directory(default is /usr/local/v2ray): "
	read v2ray_install_directory
	Delete >/dev/null 2>&1 && \
		echo $echo_e_arg "\n\033[44;37mv2ray uninstall success.\033[0m" || \
		echo $echo_e_arg "\n\033[41;37mv2ray uninstall failed.\033[0m"
}

#script initialization
ScriptInit() {
	emulate bash 2>/dev/null #zsh emulation mode
	if echo -e ''|grep -q 'e'; then
		echo_e_arg=''
		echo_E_arg=''
	else
		echo_e_arg='-e'
		echo_E_arg='-E'
	fi
}

ScriptInit
echo $*|grep -qi uninstall && Uninstall || Install
