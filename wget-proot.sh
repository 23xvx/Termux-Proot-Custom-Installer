#!/data/data/com.termux/files/usr/bin/bash

ARCHITECTURE=$(dpkg --print-architecture)

#Adding colors
R="$(printf '\033[1;31m')"
G="$(printf '\033[1;32m')"
Y="$(printf '\033[1;33m')"
W="$(printf '\033[1;37m')"
C="$(printf '\033[1;36m')"

clear
echo ""
echo ${C}"Script made by No Hope#0281 "
echo ""
sleep2
clear

#requirements
pkg install proot pulseaudio wget -y
clear
termux-setup-storage
clear

#Warning
echo ${R}"Warning!
Error may occur during installation."
sleep 2
clear

#Notice
echo ${C}"Please check your architecture first in order to download the right rootfs."
echo ${C}"Your architecture is $ARCHITECTURE ."
case `dpkg --print-architecture` in
    aarch64)
            echo "Please download the rootfs file for arm64." ;;
    arm*)
            echo "Please download the rootfs file for armhf." ;;
    ppc64el)
            echo "Please download the rootfs file for ppc64el.";;
    x86_64)
            echo "Please download the rootfs file for amd64." ;;
    *)
            echo "Unknown architecture"; exit 1 ;;
esac
echo "Press enter to continue"
read enter
sleep 1
clear

#Links
echo ${G}"Please put in your URL here for downloading rootfs: "${W}
read URL
sleep 1
echo ${G}"Please put in your distro name in order to login after all
If you put in 'kali' , afterwards your login script will be 'bash kali.sh' "${W}
read ds_name
sleep 1
echo ${Y}"your URl is $URL 
and your distro name is $ds_name "${W}
sleep 2

folder=$ds_name-fs
if [ -d "$folder" ]; then
        echo ${G}"Existing file found, are you sure to remove it? (y or n)"${W}
        read ans
        if [[ "$ans" =~ ^([yY])$ ]]; then
                echo ${W}"Deleting existing directory...."${W}
                rm -rf ~/$folder
                rm -rf ~/$ds_name.sh
                sleep 2
        elif [[ "$ans" =~ ^([nN])$ ]]; then
        echo ${R}"Sorry, but we cannot complete the installation"
        exit
        else 
        echo
        fi
else 
mkdir -p $folder
fi

#Downloading and decompressing rootfs
clear
echo ${G}"Downloading Rootfs....."${W}
wget $URL -P ~/$folder/ 
echo ${G}"Decompressing Rootfs....."
proot --link2symlink \
    tar -xpf ~/$folder/*.tar.* -C ~/$folder/ --exclude='dev'||:
if [[ ! -d "$folder/etc" ]]; then
     mv $folder/*/* $folder/
fi
echo "127.0.0.1 localhost" > ~/$folder/etc/hosts
rm -rf ~/$folder/etc/resolv.conf
echo "nameserver 8.8.8.8" > ~/$folder/etc/resolv.conf
echo -e "#!/bin/sh\nexit" > "$folder/usr/bin/groups"
mkdir -p $folder/binds


#Sound Fix
echo "#!/bin/bash
pulseaudio --start \
    --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" \
    --exit-idle-time=-1 
" >> ~/$de_name.sh 

##script
echo ${G}"writing launch script"
sleep 1
bin=$ds_name.sh
cat > $bin <<- EOM
#!/bin/bash
cd \$(dirname \$0)
## unset LD_PRELOAD in case termux-exec is installed
unset LD_PRELOAD
command="proot"
## uncomment following line if you are having FATAL: kernel too old message.
#command+=" -k 4.14.81"
command+=" --link2symlink"
command+=" -0"
command+=" -r $folder"
if [ -n "\$(ls -A $folder/binds)" ]; then
    for f in $folder/binds/* ;do
      . \$f
    done
fi
command+=" -b /dev"
command+=" -b /proc"
command+=" -b /dev/null:/proc/stat"
command+=" -b /sys"
command+=" -b $folder/tmp:/dev/shm"
command+=" -b /data/data/com.termux"
command+=" -b /:/host-rootfs"
command+=" -b /sdcard"
command+=" -b /storage"
command+=" -b /mnt"
command+=" -w /root"
command+=" /usr/bin/env -i"
command+=" HOME=/root"
command+=" PATH=/usr/local/sbin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin:/usr/games:/usr/local/games"
command+=" TERM=\$TERM"
command+=" LANG=C.UTF-8"
command+=" /bin/bash --login"
com="\$@"
if [ -z "\$1" ];then
    exec \$command
else
    \$command -c "\$com"
fi
EOM

echo "#!/bin/bash
touch ~/.hushlogin
rm -rf ~/.bash_profile
exit" > $folder/root/.bash_profile
clear
termux-fix-shebang $bin
rm -rf $folder/*.tar.*
bash $bin

echo ""
echo ${R}"If you find problem, try to restart Termux !"
echo ${G}"You can now start your distro with '$ds_name.sh' script next time"
echo ""
