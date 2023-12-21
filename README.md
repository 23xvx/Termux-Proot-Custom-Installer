### Termux-Proot-Custom-Installer
 A automatic script to install any distro by yourself in Termux.
 You need to find the URL of rootfs images by yourself.
 Rootfs can be from [proot-distro](https://github.com/termux/proot-distro), [Udroid](https://github.com/RandomCoderOrg/ubuntu-on-android) or any other site.

### 1. Via proot-distro
Paste following command into Termux.
``` 
curl https://raw.githubusercontent.com/23xvx/Termux-Proot-Custom-Installer/main/wget-proot-distro.sh >> wget-proot-distro.sh
bash wget-proot-distro.sh
```
### 2. Via Custom Proot (Recommend)
Paste following command into Termux.
``` 
curl https://raw.githubusercontent.com/23xvx/Termux-Proot-Custom-Installer/main/wget-proot.sh >> wget-proot.sh
bash wget-proot.sh
```

### Changelog
03/06/2023 Adding option for already downloaded files.<br>
07/06/2023 Remove option (Error occurred).<br>
24/07/2023 Binding ***cap_last_cap*** in custom proot startup scipt.<br>
21/12/2023 Huge improvement on wget-proot.sh , making it more flexible and easy to configure.


