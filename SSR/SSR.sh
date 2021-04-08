#!/bin/bash
Exit()
{
	echo -e "$1"
	exit $2
}

#Make SSR.json
Config()
{
	clear
	echo -n "Please input shadowsocksR encryption method(default rc4-md5): "
	read encryption_method
	echo -n "Please input shadowsocksR protocol(default auth_sha1_v4): "
	read protocol
	echo -n "Please input shadowsocksR obfs(default http_simple): "
	read obfs
	while [ "$conf_done" != 'y' -a "$conf_done" != 'Y' ]
	do
		while true
		do
			echo -n "Please input shadowsocksR server port: "
			read server_port
			[ "$server_port" -gt "0" -a "$server_port" -lt "65536" ] && break
			echo "Please input 1-65535"
		done
		echo -n "Please input shadowsocksR password(default 123456): "
		read password
		port_password+="\"$server_port\":\"${password:-123456}\", "
		echo -n "Already input all ports and passwords?[y/n]: "
		read conf_done
	done
	cat >/etc/SSR.json <<-conf
	{
	"server": "0.0.0.0",
	"port_password": {${port_password%,*}},
	"method": "${encryption_method:=rc4-md5}",
	"protocol": "${protocol:=auth_sha1_v4}",
	"obfs": "${obfs:=http_simple}",
	"timeout": 120
	}
	conf
	chmod 777 /etc/SSR.json
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
		echo "$script_dir"|grep -Eq "\.\.?$"&&script_dir=
		script_dir="${PWD}/${script_dir##*/}"
	fi
	cd "$script_dir"
	cd ..
}

#Install shadowsocksR files to '$SSR_path'.
Install_file()
{
	if [ -d SSR_install ]
	then
		mv SSR_install $SSR_path
	elif [ -d SSR_install-master ]
	then
		mv SSR_install-master $SSR_path
	else
		$PM -y install git
		git clone https://github.com/mmmdbybyd/SSR_install.git $SSR_path
	fi
	[ ! -d $SSR_path ] && Exit "shadowsocksR files download failed." 1
	chmod -R 0777 $SSR_path
	cp -f $SSR_path/init.d/SSR /etc/init.d/SSR
	#add systemd service
	if which systemctl
	then
		mkdir -p /etc/systemd/system
		cp -f $SSR_path/systemd/SSR.service /usr/lib/systemd/system
		systemctl daemon-reload
		systemctl start SSR.service
	fi
	if [ ! -f /usr/local/lib/libsodium.a ] && echo "$encryption_method"|grep -Eq "chacha20|salsa20"
	then
		$PM -y install curl gcc make unzip autoconf automake libtool
		curl -k -o libsodium.zip https://codeload.github.com/jedisct1/libsodium/zip/master || \
		Exit "libsodium files download failed." 1
		unzip -q libsodium.zip
		cd libsodium-master
		./autogen.sh && \
		./configure --prefix=/usr/local && \
		make -j 2 && \
		make install || \
		Exit "libsodium compile failed." 1
		cd .. ; rm -rf libsodium* 
		echo "/usr/local/lib" >>/etc/ld.so.conf
		ldconfig
	fi
}

#Stop shadowsocksR and delete shadowsocksR files.
Delete()
{
	/etc/init.d/SSR stop &>/dev/null
	systemctl disable SSR.service
	rm -rf /etc/init.d/SSR /usr/lib/systemd/system/SSR.service $SSR_path
}

Init()
{
	SSR_path="/usr/local/SSR" #Set shadowsocksR install path.
	[ "$1" == "uninstall" ] && return
	PM=`which apt-get || which yum`
	[ -z $PM ] && Exit "Not support OS." 1
	echo -n "make a update?[y/n]: "
	read update
	[ "$update" == "y" -o "$update" == "Y" ] && $PM -y update
	$PM -y install python\*
}

Install()
{
	Config 2>&-
	Init
	Delete
	Change_pwd
	Install_file
	/etc/init.d/SSR start|grep -q OK && Exit \
	"\033[44;37mShadowsocksR install success.\033[0;34m
	port_password:\033[25G${port_password%, }
	method:\033[25G${encryption_method:=rc4-md5}
	protocol:\033[25G${protocol:=auth_sha1_v4}
	obfs:\033[25G${obfs:=http_simple}
	\033[0G`/etc/init.d/SSR usage`\n\033[0m"
	Delete
	Exit "\033[41;37mShadowsocksR install failed.\033[0m" 1
}

Uninstall()
{
	echo -e "Uninstall shadowsocksR? [y/n]:\c"
	read answer
	[ "$answer" == "n" -o "$answer" == "N" ] && Exit "Quit uninstall."
	Init uninstall #Get shadowsocksR install path
	Delete
	Exit "\033[44;37mShadowsocksR uninstall success.\033[0m"
}

echo $*|grep -qi uninstall && Uninstall
Install