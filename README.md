### Termux-Proot-Custom-Installer
 An easy script to install any distro by yourself in Termux.
 You need to find the URL of rootfs images by yourself.

### Some recommended sites
 - [proot-distro](https://github.com/termux/proot-distro)
 - [Udroid](https://github.com/RandomCoderOrg/ubuntu-on-android)
 - [Linux Containers](https://images.linuxcontainers.org)

### 1. Via proot-distro
Paste following command into Termux.
``` 
curl -s https://raw.githubusercontent.com/23xvx/Termux-Proot-Custom-Installer/main/wget-proot-distro.sh | sh
```
### 2. Via Custom Proot (Recommend)
Paste following command into Termux.
``` 
curl -s https://raw.githubusercontent.com/23xvx/Termux-Proot-Custom-Installer/main/wget-proot.sh | sh
```

### Changelog
- 03/06/2023 Adding option for already downloaded files.<br>
- 07/06/2023 Remove option (Error occurred).<br>
- 24/07/2023 Binding ***cap_last_cap*** in custom proot startup scipt.<br>
- 21/12/2023 Huge improvement on wget-proot.sh , making it more flexible and easy to configure.<br>
- 04/05/2024 Adding option to remove rootfs directory in `wget-proot.sh`
- 01/06/2024 Adding option to reinstall custom distro in `wget-proot-distro.sh`
- 21/11/2024 Do not download installation script directly using `curl`

