#!/data/data/com.termux/files/usr/bin/bash

ARCHITECTURE=$(dpkg --print-architecture)

#Adding colors
R="$(printf '\033[1;31m')"
G="$(printf '\033[1;32m')"
Y="$(printf '\033[1;33m')"
W="$(printf '\033[1;37m')"
C="$(printf '\033[1;36m')"

#Warning
clear 
echo ${R}"Warning!
Error may occur during installation."
echo " "
echo ${C}"Script made by 23xvx "
sleep 2

#requirements
echo ""
echo ${G}"Installing requirements"${W}
pkg install proot pulseaudio wget -y
echo " " 
cd 
if [ ! -d "storage" ]; then
    echo ${G}"Please allow storage permissions"
    termux-setup-storage
    clear
fi 

#Notice
echo ${C}"Your architecture is $ARCHITECTURE ."
case `dpkg --print-architecture` in
    aarch64)
        arch="arm64" ;;
    arm*)
        arch="armhf" ;;
    x86_64)
        arch="amd64" ;;
    *)
        echo "Unknown architecture"
        exit 1 ;;
esac
echo "Please download the rootfs file for $arch." 
echo "Press enter to continue"
read enter
sleep 1
clear

#Links
echo ${G}"Please put in your URL here for downloading rootfs: "${W}
read URL        
sleep 1
echo " "
echo ${G}"Please put in your distro name "
echo ${G}"If you put in 'kali', your login script will be"
echo ${G}" 'bash kali.sh' "${W}
read ds_name
sleep 1
echo " "
echo ${Y}"Your distro name is $ds_name "${W}
sleep 2 ; cd

rootfs_dir=$ds_name-fs
if [ -d "$rootfs_dir" ]; then
    echo ${G}"Existing distro found, are you sure to remove it? (y or n)"${W}
    read ans
    if [[ "$ans" =~ ^([yY])$ ]]; then
        echo ${Y}"Deleting existing directory...."${W}
        chmod u+rwx -R ~/$rootfs_dir
        rm -rf ~/$rootfs_dir
        rm -rf ~/$ds_name.sh
        if [ -d "$rootfs_dir" ]; then
            echo ${R}"Cannot remove directory"
            exit 1
        fi 
    elif [[ "$ans" =~ ^([nN])$ ]]; then
        echo ${R}"Sorry, but we cannot complete the installation"
        exit
    else 
        echo ${R}"Invalid answer"; exit 1
    fi
else 
    mkdir -p ~/$rootfs_dir
fi
mkdir -p ~/$rootfs_dir/.cache
clear

#Downloading and decompressing rootfs
archive=$(echo $URL | awk -F / '{print $NF}')
echo ${G}"Downloading $archive....."${W}
wget -q --show-progress $URL -P ~/$rootfs_dir/.cache/ || ( echo ${R}"Error in downloading rootfs,exiting..." && exit 1 )
echo ${G}"Decompressing Rootfs....."${W}
proot --link2symlink tar -xpf ~/$rootfs_dir/.cache/$archive -C ~/$rootfs_dir/ --exclude='dev'
rm -rf ~/$rootfs_dir/.cache
if [[ ! -d $rootfs_dir/root ]]; then
    dirs=$(ls $rootfs_dir)
    for dir in $dirs; do
        mv $rootfs_dir/$dir/* $rootfs_dir/
        chmod u+rwx -R $rootfs_dir/$dir
        rm -rf $rootfs_dir/$dir
    done
    if [[ ! -d $rootfs_dir/root ]]; then
        echo ${R}"Error in decompressing rootfs"; exit 1
    fi
fi

#Setting up environment
mkdir -p ~/$rootfs_dir/tmp
mkdir -p ~/$rootfs_dir/dev/shm
rm -rf ~/$rootfs_dir/etc/hostname
rm -rf ~/$rootfs_dir/etc/resolv.conf
echo "localhost" > ~/$rootfs_dir/etc/hostname
echo "127.0.0.1 localhost" > ~/$rootfs_dir/etc/hosts
echo "nameserver 8.8.8.8" > ~/$rootfs_dir/etc/resolv.conf
echo -e "#!/bin/sh\nexit" > ~/$rootfs_dir/usr/bin/groups
mkdir -p $rootfs_dir/binds
cat <<- EOF >> "$rootfs_dir/etc/environment"
EXTERNAL_STORAGE=/sdcard
LANG=en_US.UTF-8
MOZ_FAKE_NO_SANDBOX=1
PATH=/usr/local/sbin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin:/usr/games:/usr/local/games
PULSE_SERVER=127.0.0.1
TERM=xterm-256color
TMPDIR=/tmp
EOF

#Sound Fix
echo "export PULSE_SERVER=127.0.0.1" >> $rootfs_dir/root/.bashrc

##script
echo ${G}"writing launch script"
sleep 1
bin=$ds_name.sh
cat > $bin <<- EOM
#!/bin/bash
cd \$(dirname \$0)

## Start pulseaudio
pulseaudio --start --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" --exit-idle-time=-1

## Set login shell for different distributions
login_shell=\$(grep "^root:" "$rootfs_dir/etc/passwd" | cut -d ':' -f 7)

## unset LD_PRELOAD in case termux-exec is installed
unset LD_PRELOAD

## Proot Command
command="proot"
## uncomment following line if you are having FATAL: kernel too old message.
#command+=" -k 4.14.81"
command+=" --link2symlink"
command+=" -0"
command+=" -r $rootfs_dir"
if [ -n "\$(ls -A $rootfs_dir/binds)" ]; then
    for f in $rootfs_dir/binds/* ;do
      . \$f
    done
fi
command+=" -b /dev"
command+=" -b /dev/null:/proc/sys/kernel/cap_last_cap"
command+=" -b /proc"
command+=" -b /dev/null:/proc/stat"
command+=" -b /sys"
command+=" -b /data/data/com.termux/files/usr/tmp:/tmp"
command+=" -b $rootfs_dir/tmp:/dev/shm"
command+=" -b /data/data/com.termux"
command+=" -b /sdcard"
command+=" -b /storage"
command+=" -b /mnt"
command+=" -w /root"
command+=" /usr/bin/env -i"
command+=" HOME=/root"
command+=" PATH=/usr/local/sbin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin:/usr/games:/usr/local/games"
command+=" TERM=\$TERM"
command+=" LANG=C.UTF-8"
command+=" \$login_shell"
com="\$@"
if [ -z "\$1" ];then
    exec \$command
else
    \$command -c "\$com"
fi
EOM

clear
termux-fix-shebang $bin
bash $bin "touch ~/.hushlogin ; exit"
clear 
rm -rf ~/wget-proot.sh
echo ""
echo ${R}"If you find problem, try to restart Termux !"
echo ${G}"You can now start your distro with '$ds_name.sh' script"
echo ${G}" Command : ${Y}bash $ds_name.sh "
echo ""
