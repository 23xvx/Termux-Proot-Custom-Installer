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

rootfs_dir="~/.local/share/cached-rootfs"
mkdir -p $rootfs_dir

#Downloading and Decompressing rootfs
mkdir -p $rootfs_dir
echo ${G}"Downloading rootfs"${RST}
wget -q --show-progress $URL -P $rootfs_dir/ || ( echo ${R}"Error in downloading rootfs,exiting..." ; exit 1 )

#Use proot-distro v5 script to automatically install and setup the distro
#Actually this script almost lost its justfication for existence lol
echo ${G}"Installing distro"${RST}
proot-distro install $rootfs_dir/$(basename $URL) --name $ds_name || ( echo ${R}"Error in installing distro,exiting..." ; exit 1 )

#Finish
sleep 2
echo ${G}"Installation Finish!"
echo ${G}"Now you can login to your distro by" 
echo ${Y}"proot-distro login $ds_name"
echo 
echo ${G}"If you want to reinstall the distro after removal, use"
echo ${Y}"proot-distro install $rootfs_dir/$(basename $URL) --name $ds_name"
