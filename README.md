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
   station {WIRELESS_DEVICE connect {WIFI}
   exit

git clone https://github.com/varla-am/archittos-install.git
cd archittos-install
./install.sh
```
### How to use it:
