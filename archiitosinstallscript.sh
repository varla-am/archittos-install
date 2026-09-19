#!/usr/bin/env bash
#
# archiitosinstallscript.sh — ArchittOS unattended installer
# Run from the Arch live ISO (as root). Usually launched via the `archittos` alias.
#
# Usage:
#   archittos -ed <efi-disk> -md <main-disk> -de <kde|gnome|xfce|none> \
#             [-tz <Region/City>] [--after-boot '<commands to run after first login>']
#
# Example (single disk, KDE, install Sober after first login):
#   archittos -ed /dev/sda -md /dev/sda -de kde \
#             --after-boot 'flatpak install -y flathub org.vinegarhq.Sober'
#
# WARNING: this ERASES the disks you point it at. Meant for a fresh VM.
#
set -euo pipefail

# ---------- defaults (edit to taste) ----------
EFI_DISK=""
MAIN_DISK=""
DE="none"
AFTER_BOOT=""
HOSTNAME="Archittos-ArchLinux"
USERNAME="archittos"
TIMEZONE=""
LOCALE="en_US.UTF-8"
DEFAULT_PASS="archittos" # root & user password; CHANGE after first boot

# ---------- parse args ----------
while [[ $# -gt 0 ]]; do
  case "$1" in
  -ed)
    EFI_DISK="$2"
    shift 2
    ;;
  -md)
    MAIN_DISK="$2"
    shift 2
    ;;
  -de)
    DE="$2"
    shift 2
    ;;
  -tz)
    TIMEZONE="$2"
    shift 2
    ;;
  --after-boot)
    AFTER_BOOT="$2"
    shift 2
    ;;
  -h | --help)
    grep '^#' "$0" | sed 's/^#\{1,2\} \{0,1\}//'
    exit 0
    ;;
  *)
    echo "ERR: Unknown option $1" >&2
    exit 1
    ;;
  esac
done

# ---------- validate ----------
[[ $EUID -ne 0 ]] && {
  echo "ERR: Not runned as root"
  exit 1
}
[[ -z "$EFI_DISK" || -z "$MAIN_DISK" ]] && {
  echo "ERR: Disk not specified"
  exit 1
}
for d in "$EFI_DISK" "$MAIN_DISK"; do
  [[ -b "$d" ]] || {
    echo "ERR: Not a block device $d"
    exit 1
  }
done
case "$DE" in kde | gnome | xfce | none) ;; *)
  echo "ERR: None valid DE was specified (kde/gnome/xfce/none)"
  exit 1
  ;;
esac
[[ -f "/usr/share/zoneinfo/$TIMEZONE" ]] || {
  echo "ERR: Invalid timezone $TIMEZONE (e.g. Europe/Riga)"
  exit 1
}

# partition-name helper (nvme0n1 -> nvme0n1p1, sda -> sda1)
partname() {
  local disk="$1" num="$2"
  if [[ "$disk" =~ (nvme|mmcblk|loop) ]]; then echo "${disk}p${num}"; else echo "${disk}${num}"; fi
}

echo "=========================================="
echo " ArchittOS installer"
echo "   EFI disk : $EFI_DISK"
echo "   Root disk: $MAIN_DISK"
echo "   Desktop  : $DE"
echo "   Timezone : $TIMEZONE"
echo "   Hostname : $HOSTNAME   User: $USERNAME"
[[ -n "$AFTER_BOOT" ]] && echo "   After-boot hook: set"
echo "=========================================="
echo "!! This ERASES the disk(s) above. Type YES to continue:"
read -r ans
[[ "$ans" == "YES" ]] || {
  echo "ERR: Aborted by user"
  exit 1
}

# ---------- clock ----------
timedatectl set-ntp true

# ---------- partition ----------
if [[ "$EFI_DISK" == "$MAIN_DISK" ]]; then
  sgdisk --zap-all "$MAIN_DISK"
  sgdisk -n1:0:+512M -t1:ef00 -c1:EFI "$MAIN_DISK"
  sgdisk -n2:0:0 -t2:8300 -c2:root "$MAIN_DISK"
  EFI_PART="$(partname "$MAIN_DISK" 1)"
  ROOT_PART="$(partname "$MAIN_DISK" 2)"
else
  sgdisk --zap-all "$EFI_DISK"
  sgdisk -n1:0:+512M -t1:ef00 -c1:EFI "$EFI_DISK"
  EFI_PART="$(partname "$EFI_DISK" 1)"
  sgdisk --zap-all "$MAIN_DISK"
  sgdisk -n1:0:0 -t1:8300 -c1:root "$MAIN_DISK"
  ROOT_PART="$(partname "$MAIN_DISK" 1)"
fi
partprobe "$EFI_DISK" "$MAIN_DISK" 2>/dev/null || true
sleep 2

# ---------- format ----------
mkfs.fat -F32 "$EFI_PART"
mkfs.ext4 -F "$ROOT_PART"

# ---------- mount ----------
mount "$ROOT_PART" /mnt
mount --mkdir "$EFI_PART" /mnt/boot

# ---------- base packages (+ desktop) ----------
PKGS=(base linux linux-firmware networkmanager grub efibootmgr sudo vim)
case "$DE" in
kde) PKGS+=(plasma-meta sddm konsole dolphin) ;;
gnome) PKGS+=(gnome gdm) ;;
xfce) PKGS+=(xfce4 xfce4-goodies lightdm lightdm-gtk-greeter) ;;
esac
pacstrap -K /mnt "${PKGS[@]}"

# ---------- fstab ----------
genfstab -U /mnt >>/mnt/etc/fstab

# ---------- configure inside chroot ----------
arch-chroot /mnt /bin/bash <<CHROOT
set -e
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc
sed -i 's/^#$LOCALE/$LOCALE/' /etc/locale.gen
locale-gen
echo 'LANG=$LOCALE' > /etc/locale.conf
echo '$HOSTNAME' > /etc/hostname
echo 'root:$DEFAULT_PASS' | chpasswd
useradd -m -G wheel $USERNAME
echo '$USERNAME:$DEFAULT_PASS' | chpasswd
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
systemctl enable NetworkManager
CHROOT

# enable the display manager for the chosen desktop
case "$DE" in
kde) arch-chroot /mnt systemctl enable sddm ;;
gnome) arch-chroot /mnt systemctl enable gdm ;;
xfce) arch-chroot /mnt systemctl enable lightdm ;;
esac

# ---------- after-boot hook (runs once at first login, then self-deletes) ----------
if [[ -n "$AFTER_BOOT" ]]; then
  HOME_DIR="/mnt/home/$USERNAME"
  install -d "$HOME_DIR/.config/autostart"
  cat >"$HOME_DIR/firstboot.sh" <<HOOK
#!/bin/bash
$AFTER_BOOT
rm -f ~/.config/autostart/archittos-firstboot.desktop ~/firstboot.sh
HOOK
  chmod +x "$HOME_DIR/firstboot.sh"
  cat >"$HOME_DIR/.config/autostart/archittos-firstboot.desktop" <<DESK
[Desktop Entry]
Type=Application
Name=ArchittOS First Boot
Exec=/home/$USERNAME/firstboot.sh
X-GNOME-Autostart-enabled=true
DESK
  arch-chroot /mnt chown -R "$USERNAME:$USERNAME" "/home/$USERNAME"
fi

# ---------- done ----------
echo
echo "=========================================="
echo " ArchittOS installed."
echo "   login: $USERNAME / $DEFAULT_PASS  (CHANGE THIS!)"
echo "   rebooting in 5s — remove the ISO"
echo "=========================================="
sleep 5
umount -R /mnt
reboot
