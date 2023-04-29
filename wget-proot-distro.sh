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
echo ${C}"Please check your architecture first in order to download the right rootfs."
echo ${C}"Your architecture is $ARCHITECTURE ."
case `dpkg --print-architecture` in
    aarch64)
            echo "Please download the rootfs file for arm64." ;;
    arm*)
            echo "Please download the rootfs file for armf." ;;
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
echo ${G}"Please put in your URL here for downloading rootfs: "${W}
read URL
sleep 1
echo ${G}"Please put in your distro name in order to login after all
If you put in 'kali' , everytime you login will be 
'proot-distro login kali' "${W}
read ds_name
sleep 1
echo ${Y}"your URl is $URL 
and your distro name is $ds_name "${W}
sleep 2

#checking intergrities

if [[ ! -d "$PREFIX/var/lib/proot-distro/installed-rootfs" ]]; then
    mkdir -p $PD
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
    rm -rf $PREFIX/etc/proot-distro/$ds_name.sh
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
echo ${G}"Downloading rootfs"${W}
wget $URL 
echo ${G}"Decompressing rootfs"
proot --link2symlink  \
    tar --warning=no-unknown-keyword \
        --delay-directory-restore --preserve-permissions \
        -xpf ~/*.tar.* -C $PD/$ds_name/ --exclude='dev'||:
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
echo "
# This is a default distribution plug-in.
# Do not modify this file as your changes will be overwritten on next update.
# If you want customize installation, please make a copy.

DISTRO_NAME="$ds_name" ">> $SCRIPT/$ds_name.sh 

clear
echo ${G}"Installation Finish!"
echo ${G}"Now you can login to your distro by" 
echo ${Y}"proot-distro login $ds_name"
echo ${R}"Notice : You cannot install it by proot-distro after removing it."
