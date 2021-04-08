#!/bin/bash
Exit()
{
    clear
    echo -e "$1"
    exit $2
}

Configuration()
{
	[ -n "$TinyProxy_port" ] && return  #Variables come from the environment
    while true
    do
        echo -n "Please input tinyproxy server port: "
        read TinyProxy_port
        [ "$TinyProxy_port" -gt "0" -a "$TinyProxy_port" -lt "65536" ] && break
        echo "Please input 1-65535."
    done
    read -p "Please input tinyproxy proxy header(default is 'Meng'): " TinyProxy_proxyHeader
    echo "
    User root
    Group root
    Port $TinyProxy_port
    Proxy_header \"${TinyProxy_proxyHeader:-Meng}\"
    Timeout 600
    MaxClients 100
    MinSpareServers 5
    MaxSpareServers 20
    StartServers 10
    MaxRequestsPerChild 0" >/etc/tinyproxy.conf
    chmod 777 /etc/tinyproxy.conf
}

Compile()
{
    errmsg="download tinyproxy source code failed"
    [ -d tinyproxy_cloud ] || git clone https://e.coding.net/mmmdbybyd/tinyproxy_cloud/
    [ ! -d tinyproxy_cloud ] && return 1
    errmsg="compile tinyproxy failed"
    cd tinyproxy_cloud
    . ./autogen.sh && make && strip src/tinyproxy && \
    \cp -f src/tinyproxy /usr/local/sbin && \
    \cp -f etc/init.d/tinyproxy /etc/init.d
    rm -rf ../tinyproxy_cloud
	chmod 777 /etc/init.d/tinyproxy
    /etc/init.d/tinyproxy start|grep -q OK
}

#Change the working directory to script directory the parent directory.
Change_pwd()
{
    if [ -z "$(echo $0|grep /)" ]
    then
        if [ -f "$0" ]
        then
             script_dir="$PWD"
        else
            script_dir=`type "${0##*/}"`
            script_dir="${script_dir%/*}"
            script_dir="/${script_dir#*/}"
        fi
    else
        script_dir="${0%/*}"
        echo "$script_dir"|grep -Eq "\.\.?$" && script_dir=
        script_dir="${PWD}/${script_dir##*/}"
    fi
    cd "$script_dir"
    cd ..
}

Del()
{
    /etc/init.d/tinyproxy stop &>/dev/null
    rm -f /usr/local/sbin/tinyproxy /etc/tinyproxy.conf /etc/init.d/tinyproxy
}

Install()
{
    clear
    Del
    Configuration
    apt-get -y update || ${PM:=yum} -y update
    for package in git asciidoc gcc make autoconf automake
    do
        ${PM:-apt-get} install -y $package
    done
    Compile && Exit "\033[44;37m`/etc/init.d/tinyproxy status`\n\033[0;34m`/etc/init.d/tinyproxy usage`\033[0m"
    Del
    Exit "\033[41;37mInstall tinyproxy failed($errmsg).\033[0m"
}

Uninstall()
{
    clear
    echo -n "Uninstall tinyproxy?[y/n]: "
    read answer
    [ "$answer" == "N" -o "$answer" == "n" ] && Exit "Quit uninstall."
    Del
    Exit "\033[44;37mUninstall tinyproxy success.\n\033[0m"
}

echo $* | grep -qi uninstall 2>/dev/null && Uninstall
Install
