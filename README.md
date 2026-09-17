# Archittos Install
## This is unofficial install script for Arch Linux x86_64

### How to install it:
#### First when ArchISO started up run these commands:
```bash
iwctl
   device list
   # Find your wireless device and replace {WIRELESS_DEVICE} with it's name
   station {WIRELESS_DEVICE} scan
   station {WIRELESS_DEVICE} get-networks
   # Find your Wi-Fi network and replace {WIFI} with it's name
   station {WIRELESS_DEVICE} connect {WIFI}
   exit

git clone https://github.com/varla-am/archittos-install.git
cd archittos-install
./installscript.sh
```
### How to use it:
> [!CAUTION]
> **! THIS SCRIPT IS USED FOR CLEAN INSTALL WITHOUT DUAL BOOT !**
>
> **! THIS SCRIPT WILL DESTROY ALL DATA ON SPECIFIED DISK  !**
#### For dual boot built in `archinstall` script
#### This script has alias that was installed using installscript.sh
#### When running command you need to specify:
| Flag | Meaning | Example |
|------|---------|---------|
| `-ed` | Specifies EFI BOOT Disk | `-ed /dev/sda` |
| `-md` | Specifies Main disk  | `-md /dev/sda` |
| `-de` | Specifies Desktop environment | `-de` {`kde` \| `gnome` \| `xfce` \| `none`} |
| `-tz` | Specifies Timezone (`Region/City` under `/usr/share/zoneinfo`) | `-tz Europe/Sofia` |
| `--after-boot` | Specifies commands run **once** at first login, then self-deleted | `--after-boot 'sudo pacman -Syu'` |
| `-h`, `--help` | Show usage | `-h` |


#### If you will specify EFI BOOT disk and Main disk as one disk it will cut your disk into two partitions
### When script finished installing it will automatically reboot
