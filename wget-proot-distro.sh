#!/data/data/com.termux/files/usr/bin/sh

SCRIPT=$PREFIX/etc/proot-distro/
PD=$PREFIX/var/lib/proot-distro/installed-rootfs
ARCHITECTURE=$(dpkg --print-architecture)

#clear
clear 

#Adding colors
R="$(printf '\033[1;31m')"
G="$(printf '\033[1;32m')"
Y="$(printf '\033[1;33m')"
W="$(printf '\033[1;37m')"
C="$(printf '\033[1;36m')"

#Warning
echo ${R}"Warning!
This script is not a suggested way for installing distro in termux.
Error may occur during installation."
sleep 3
clear

#Notice
echo ${C}"Please check your architecture first in order to install the right rootfs."
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

#requirements
echo ${G}"Installing requirements"
pkg install wget proot-distro -y
sleep 1
clear

#Links
echo ${G}"Have you already downloaded the file? (y/n)"
read link 
if [[ "$link" =~ ^([yY])$ ]]; then 
        echo ${G}"Please put in the absolute path you put the file in"
        echo ${G}"If you put your file in your downloads, the absolute path would be"
        echo ${Y}"/sdcard/Download/"your file""
        read path  
        sleep 1
        echo ${G}"Your path is $path"
        sleep 1 
elif [[ "$link" =~ ^([nN])$ ]]; then
        echo ${G}"Please put in your URL here for downloading rootfs: "${W}
        read URL        
        sleep 1
else 
        echo "Cannot identify your answer" ; exit 1
fi 
echo ${Y}"Your distro name is $ds_name "${W}
sleep 2

#checking intergrities

if [[ ! -d "$PREFIX/var/lib/proot-distro" ]]; then
    mkdir -p $PREFIX/var/lib/proot-distro
    mkdir -p $PREFIX/var/lib/proot-distro/installed-rootfs
fi 
echo
if [[ -d "$PREFIX/var/lib/proot-distro/installed-rootfs/$ds_name" ]]; then
echo ${G}"Existing file found, are you sure to remove it? (y or n)"${W}
read ans
fi

#YES/NO
if [[ "$ans" =~ ^([yY])$ ]]
then
    echo ${W}"Deleting existing directory...."${W}
    rm -rf $PD/$ds_name
    clear
elif [[ "$ans" =~ ^([nN])$ ]]
then
    echo ${R}"Sorry, but we cannot complete the installation"
    exit 1
else 
    echo
    clear
fi

#Downloading and Decompressing rootfs
mkdir -p $PD/$ds_name
if [[ "$link" =~ ^([nN])$ ]]; then
    echo ${G}"Downloading rootfs"${W}
    wget $URL  
    path=~/*.tar.*
echo ${G}"Decompressing rootfs"
proot --link2symlink  \
    tar --warning=no-unknown-keyword \
        --delay-directory-restore --preserve-permissions \
        -xpf $path -C $PD/$ds_name/ --exclude='dev'||:
rm -rf ~/*.tar.*
if [[ ! -d "$PD/$ds_name/bin" ]]; then
     mv $PD/$ds_name/*/* $PD/$ds_name/
fi

echo "127.0.0.1 localhost " >> $PD/$ds_name/etc/hosts
rm -rf $PD/$ds_name/etc/resolv.conf
echo "nameserver 8.8.8.8 " >> $PD/$ds_name/etc/resolv.conf
echo "touch .hushlogin" >> $PD/$ds_name/root/.bashrc
echo -e "#!/bin/sh\nexit" > "$PD/$ds_name/usr/bin/groups"

#Adding distro in proot-distro list
if [[ ! -f "$PREFIX/etc/proot-distro/$ds_name.sh" ]]; then
    echo "
    # This is a default distribution plug-in.
    # Do not modify this file as your changes will be overwritten on next update.
    # If you want customize installation, please make a copy.

    DISTRO_NAME="$ds_name" 
    ">> $SCRIPT/$ds_name.sh 
fi
sleep 2
clear

#finish
sleep 2
echo ${G}"Installation Finish!"
echo ${G}"Now you can login to your distro by" 
echo ${Y}"proot-distro login $ds_name"
echo ${R}"Notice : You cannot install it by proot-distro after removing it."
