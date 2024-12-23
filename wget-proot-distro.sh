#!/data/data/com.termux/files/usr/bin/sh

SCRIPT=$PREFIX/etc/proot-distro/
PD=$PREFIX/var/lib/proot-distro/installed-rootfs
ARCHITECTURE=$(dpkg --print-architecture)

#Adding colors
RST="$(printf '\033[0m')"
R="$(printf '\033[1;31m')"
G="$(printf '\033[1;32m')"
Y="$(printf '\033[1;33m')"
W="$(printf '\033[1;37m')"
C="$(printf '\033[1;36m')"

# Arguments taken if needed
if [ -z "$1" ]; then
    mode="normal"
else
    mode="args"
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                echo "${G} Usage: ${W} $0 <options> ${RST}"
                echo
                echo "${G} The script will ask for the URL and name of the distro during installation as default"
                echo "${G} If you want to provide the URL and name as arguments, use the following options:"
                echo
                echo "${Y}     --url <url>          ${C}URL of the rootfs tarball${RST}" 
                echo "${Y}     --name <name>        ${C}name of the distro${RST}"
                exit 0
                ;;
            --url)
                [[ -z "$2" ]] && echo "${R}URL not provided after '${Y}--url${R}'${RST}" && exit 1
                [[ $2 == -* ]] && echo "${R}option '${Y}${2}${R}' cannot be used after '${Y}--url'${RST}" && exit 1
                url=$2
                shift 2
                ;;
            --name)
                [[ -z "$2" ]] && echo "${R}Name not provided after '${Y}--name${R}'${RST}" && exit 1
                [[ $2 == -* ]] && echo "${R}option '${Y}${2}${R}' cannot be used after '${Y}--name'${RST}" && exit 1
                name=$2
                shift 2
                ;;
            *) echo "${R}Unknown option '${Y}$1${R}'${RST}" && exit 1 ;;
        esac
    done
fi

# Check if required arguments are provided
if [[ $mode == "args" ]]; then
    if [[ -z $url ]]; then
        echo "${R}URL not provided with '${Y}--url${R}'${RST}"
        exit 1
    fi
    if [[ -z $name ]]; then
        echo "${R}Name not provided with '${Y}--name${R}'${RST}"
        exit 1
    fi
fi

# some functions
## ask() - prompt the user with a message and wait for a Y/N answer
## copied from udroid 
ask() {
    local msg=$*

    echo -ne "$msg\t[y/n]: "
    read -r choice

    case $choice in
        y|Y|yes) return 0;;
        n|N|No) return 1;;
        "") return 0;;
        *) return 1;;
    esac
}

#Warning
clear
echo ${R}"Warning!
This script is based on the functions of proot-distro
Errors may occur during installation."
sleep 3

#requirements
echo ${G}"Installing requirements"${RST}
pkg install wget proot-distro -y
sleep 1
clear

#Notice
echo ${C}"Your architecture is $ARCHITECTURE ."
case `dpkg --print-architecture` in
    aarch64)
        arch="arm64" ;;
    arm*)
        arch="armhf" ;;
    x86_64|amd64)
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
if [[ $mode == "args" ]]; then
    URL=$url
    ds_name=$name
    echo ${G}"Your URl is $URL${RST}"
else
    echo ${G}"Please put in your URL here for downloading rootfs: "${W}
    read URL        
    sleep 1
    echo ""
    echo ${G}"Please put in your distro name "
    echo ${G}"If you put in 'gentoo', your login script will be "
    echo ${G}" proot-distro login gentoo"
    echo ${Y}"After proot-distro v3.17.0, these names cannot be used as distro name"
    echo ${Y}" kali / parrot / nethunter / blackarch"${W}
    read ds_name 
    sleep 2
    echo  
fi

echo ${Y}"Your distro name is $ds_name "${RST}
sleep 2

if [[ ! -d "$PREFIX/var/lib/proot-distro" ]]; then
    mkdir -p $PREFIX/var/lib/proot-distro
    mkdir -p $PREFIX/var/lib/proot-distro/installed-rootfs
fi
rootfs_dir=$PD/$ds_name
if [[ -d "$rootfs_dir" ]]; then
    if ask "${G}Existing folder found, remove it ?${W}"; then
        echo ${Y}"Deleting existing directory...."${RST}
        chmod u+rwx -R $rootfs_dir
        rm -rf $rootfs_dir
        clear
        if [ -d "$rootfs_dir" ]; then
            echo ${R}"Cannot remove directory"; exit 1
        fi
    else
        echo ${R}"Sorry, but we cannot complete the installation"
        exit 1
    fi
fi
clear

#Downloading and Decompressing rootfs
mkdir -p $rootfs_dir
echo ${G}"Downloading rootfs"${RST}
wget -q --show-progress $URL -P $rootfs_dir/.cache/ || ( echo ${R}"Error in downloading rootfs,exiting..." ; exit 1 )
echo ${G}"Decompressing rootfs"
archive=$(echo $URL | awk -F / '{print $NF}')
sha256=$(sha256sum $rootfs_dir/.cache/$archive | awk '{ print $1}' )
proot --link2symlink  \
    tar --warning=no-unknown-keyword \
        --delay-directory-restore --preserve-permissions \
        -xpf $rootfs_dir/.cache/$archive -C $rootfs_dir/ --exclude='dev'||:
rm -rf $rootfs_dir/.cache

declare -i TARBALL_STRIP_OPT=0
while [[ ! -d "$rootfs_dir/etc" ]] ; do
    for dir in `ls $rootfs_dir`; do
        mv $rootfs_dir/$dir/* $rootfs_dir/
        chmod u+rwx -R $rootfs_dir/$dir
        rm -rf $rootfs_dir/$dir
    done
    TARBALL_STRIP_OPT=$TARBALL_STRIP_OPT+1
    [[ -d "$rootfs_dir/etc" ]] && break
    [[ $TARBALL_STRIP_OPT == 3 ]] && echo ${R}"Cannot find /etc in archive, exiting..." && exit 1
done

rm -rf $rootfs_dir/etc/hostname
rm -rf $rootfs_dir/etc/resolv.conf
touch $rootfs_dir/root/.hushlogin
echo "localhost" > $rootfs_dir/etc/hostname
echo "127.0.0.1 localhost " >> $rootfs_dir/etc/hosts
echo "nameserver 8.8.8.8 " >> $rootfs_dir/etc/resolv.conf
echo "touch .hushlogin" >> $rootfs_dir/root/.bashrc
cat <<- EOF >> $rootfs_dir/etc/environment
EXTERNAL_STORAGE=/sdcard
LANG=en_US.UTF-8
MOZ_FAKE_NO_SANDBOX=1
PATH=/usr/local/sbin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin:/usr/games:/usr/local/games:/data/data/com.termux/files/usr/bin
PULSE_SERVER=127.0.0.1
TERM=${TERM-xterm-256color}
TMPDIR=/tmp
EOF

#Adding distro in proot-distro list
if [[ ! -f "$PREFIX/etc/proot-distro/$ds_name.sh" ]]; then
echo "
# This is a default distribution plug-in.
# Do not modify this file as your changes will be overwritten on next update.
# If you want customize installation, please make a copy.

DISTRO_NAME='$ds_name'
DISTRO_COMMENT='Custom distro : $ds_name'
TARBALL_STRIP_OPT=$TARBALL_STRIP_OPT

TARBALL_URL['$ARCHITECTURE']='$URL'
TARBALL_SHA256['$ARCHITECTURE']='$sha256'
">> $SCRIPT/$ds_name.sh 
fi
sleep 2
clear

#Finish
sleep 2
echo ${G}"Installation Finish!"
echo ${G}"Now you can login to your distro by" 
echo ${Y}"proot-distro login $ds_name"
