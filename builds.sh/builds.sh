#!/bin/sh
#==========================#
###### Author: CuteBi ######
#==========================#

option() {
	echo -n $echo_opt_e "1. 安装项目\n2. 卸载项目\n请输入选项(默认为1): "
	read install_opt
	echo "$install_opt"|grep -q '2' && task_type='uninstall' || task_type='install'
	echo -n $echo_opt_e "可选项目:
	\r1. TinyProxy
	\r2. cns
	\r3. SSR
	\r4. v2ray
	\r请选择项目(多个用空格隔开): "
	read build_projects
	echo -n '后台运行吗?(输出保存在builds.out文件)[n]: '
	read daemon_run
}

TinyProxy_set() {
	echo -n '请输入TinyProxy端口: '
	read TinyProxy_port
	echo -n "请输入TinyProxy代理头域(默认为 'Meng'): "
	read TinyProxy_proxyHeader
	[ -z "$TinyProxy_proxyHeader" ] && TinyProxy_proxyHeader='Meng'
	export TinyProxy_port TinyProxy_proxyHeader
}

cns_set() {
	echo -n '请输入cns服务端口(如果不用请留空): '
	read cns_port
	echo -n '请输入cns加密密码(默认不加密): '
	read cns_encrypt_password
	echo -n "请输入cns的udp标识(默认: 'httpUDP'): "
	read cns_udp_flag
	echo -n "请输入cns代理头域(默认: 'Meng'): "
	read cns_proxy_key
	echo -n '请输入tls服务端口(如果不用请留空): '
	read cns_tls_port
	echo -n '请输入cns安装目录(默认/usr/local/cns): '
	read cns_install_dir
	echo -n "安装UPX版本?[n]: "
	read cns_UPX
	echo "$cns_UPX"|grep -qi '^y' && cns_UPX="upx" || cns_UPX=""
	[ -z "$cns_install_dir" ] && cns_install_dir='/usr/local/cns'
	export cns_port cns_encrypt_password cns_udp_flag cns_proxy_key cns_tls_port cns_install_dir cns_UPX
}

SSR_set() {
	echo -n '请输入SSR端口: '
	read SSR_port
	echo -n '请输入SSR加密模式(默认rc4-md5): '
	read SSR_encryption_method
	echo -n '请输入SSR加密协议(默认auth_sha1_v4): '
	read SSR_protocol
	echo -n '请输入SSR混淆(默认http_simple): '
	read SSR_obfs
	echo -n '请输入SSR密码: '
	read SSR_password
	#export SSR_port SSR_encryption_method SSR_protocol SSR_obfs SSR_password
}

v2ray_set() {
	echo -n "请输入v2ray安装目录(默认/usr/local/v2ray): "
	read v2ray_install_directory
	echo -n "安装UPX版本?[n]: "
	read v2ray_UPX
	echo "$v2ray_UPX"|grep -qi '^y' && v2ray_UPX="upx" || v2ray_UPX=""
	echo $echo_opt_e "options(tls默认为自签名证书, 如有需要请自行更改):
	\r\t1. tcp_http
	\r\t2. tcp_http+tls
	\r\t3. WebSocket
	\r\t4. WebSocket+tls
	\r\t5. mkcp
	\r\t6. mkcp+tls
	\r请输入你的选项(用空格分隔多个选项):"
	read v2ray_inbounds_options
	for opt in $v2ray_inbounds_options; do
		case $opt in
			1)
				echo -n "请输入v2ray http端口: "
				read v2ray_http_port
			;;
			2)
				echo -n "请输入v2ray http tls端口: "
				read v2ray_http_tls_port
			;;
			3)
				echo -n "请输入v2ray webSocket端口: "
				read v2ray_ws_port
				echo -n "请输入v2ray WebSocket请求头的Path(默认为/): "
				read v2ray_ws_path
				v2ray_ws_path=${v2ray_ws_path:-/}
			;;
			4)
				echo -n "请输入v2ray webSocket tls端口: "
				read v2ray_ws_tls_port
				echo -n "请输入v2ray WebSocket请求头的Path(默认为/): "
				read v2ray_ws_tls_path
				v2ray_ws_tls_path=${v2ray_ws_tls_path:-/}
			;;
			5)
				echo -n "请输入v2ray mKCP端口: "
				read v2ray_mkcp_port
			;;
			6)
				echo -n "请输入v2ray mKCP tls端口: "
				read v2ray_mkcp_tls_port
			;;
		esac
	done
	[ -z "$v2ray_install_directory" ] && v2ray_install_directory='/usr/local/v2ray'
	export v2ray_install_directory v2ray_UPX v2ray_inbounds_options v2ray_http_port v2ray_http_tls_port v2ray_ws_port v2ray_ws_path v2ray_ws_tls_port v2ray_ws_tls_path v2ray_mkcp_port v2ray_mkcp_tls_port
}

TinyProxy_task() {
	if $download_tool_cmd TinyProxy.sh 'https://mmmdbybyd.coding.net/p/tinyproxy_cloud/d/tinyproxy_cloud/git/raw/master/tinyproxy.sh?download=true'; then
		chmod 777 TinyProxy.sh
		sed -i "s~#!/bin/bash~#!$SHELL~" TinyProxy.sh
		./TinyProxy.sh $task_type && \
				echo 'TinyProxy任务成功' >>builds.log || \
				echo 'TinyProxy启动失败' >>builds.log
	else
		echo 'TinyProxy脚本下载失败' >>builds.log
	fi
	rm -f TinyProxy.sh
}

cns_task() {
	if $download_tool_cmd cns.sh http://pros.cutebi.taobao69.cn:666/cns/cns.sh; then
		chmod 777 cns.sh
		sed -i "s~#!/bin/bash~#!$SHELL~" cns.sh
		if [ "$task_type" != 'install' ]; then
			echo -n '请输cns卸载目录(默认/usr/local/cns): '
			read cns_install_directory
		fi
		echo $echo_opt_e "n\ny\ny\ny\ny\n"|./cns.sh $task_type && \
				echo 'cns任务成功' >>builds.log || \
				echo 'cns启动失败' >>builds.log
	else
		echo 'cns脚本下载失败' >>builds.log
	fi
	rm -f cns.sh
}

SSR_task() {
	if $download_tool_cmd SSR.sh https://raw.githubusercontent.com/mmmdbybyd/SSR_install/master/SSR.sh; then
		chmod 777 SSR.sh
		sed -i "s~#!/bin/bash~#!$SHELL~" SSR.sh
		echo $echo_opt_e "$SSR_encryption_method\n$SSR_protocol\n$SSR_obfs\n$SSR_port\n$SSR_password\ny"|./SSR.sh $task_type && \
			echo 'SSR任务成功' >>builds.log || \
			echo 'SSR任务失败' >>builds.log
	else
		echo 'SSR脚本下载失败' >>builds.log
	fi
	rm -f SSR.sh
}

v2ray_task() {
	if $download_tool_cmd v2ray.sh http://pros.cutebi.taobao69.cn:666/v2ray/v2ray.sh; then
		chmod 777 v2ray.sh
		sed -i "s~#!/bin/bash~#!$SHELL~" v2ray.sh
		if [ "$task_type" != 'install' ]; then
			echo -n '请输入v2ray卸载目录(默认/usr/local/v2ray): '
			read v2ray_install_directory
		fi
		echo $echo_opt_e "n\ny\ny\ny\ny\n"|./v2ray.sh $task_type && \
			echo 'v2ray任务成功' >>builds.log || \
			echo 'v2ray任务失败' >>builds.log
	else
		echo 'v2ray脚本下载失败' >>builds.log
	fi
	rm -f v2ray.sh
}

server_set() {
	for opt in $*; do
		case $opt in
			1) TinyProxy_set;;
			2) cns_set;;
			3) SSR_set;;
			4) v2ray_set;;
			*) exec echo "选项($opt)不正确，请输入正确的选项！";;
		esac
	done
}

start_task() {
	for opt in $*; do
		case $opt in
			1) TinyProxy_task;;
			2) cns_task;;
			3) SSR_task;;
			4) v2ray_task;;
		esac
		sleep 1
	done
	echo '所有任务完成' >>builds.log
	echo $echo_opt_e "\033[32m`cat builds.log 2>&-`\033[0m"
}

run_tasks() {
	[ "$task_type" != 'uninstall' ] && server_set $build_projects
	if echo "$daemon_run"|grep -qi 'y'; then
		(`start_task $build_projects &>builds.out` &)
		echo "正在后台运行中......"
	else
		start_task $build_projects
		rm -f builds.log
	fi
}

script_init() {
	emulate bash 2>/dev/null #zsh仿真模式
	echo -e '' | grep -q 'e' && echo_opt_e='' || echo_opt_e='-e' #dash的echo没有-e选项
	PM=`which apt-get || which yum`
	type curl || type wget || $PM -y install curl wget
	type curl && download_tool_cmd='curl -sko' || download_tool_cmd='wget --no-check-certificate -qO'
	rm -f builds.log builds.out
	clear
}

main() {
	script_init
	option
	run_tasks
}

main
