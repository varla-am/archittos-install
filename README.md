# ArchittOS Install

Unattended Arch Linux installer for a fresh (V)machine. Point it at your disks,
pick a desktop, and it does the whole manual flow — partition → `pacstrap` →
`genfstab` → `arch-chroot` → GRUB → desktop → reboot — with no `archinstall`.

> ⚠️ **This ERASES the disks you give it.** Meant for a clean VM, not your daily machine.

## Files

| File | What it does |
|------|--------------|
| `installscript.sh` | Run once in the live ISO. Adds the `archittos` alias to `~/.bashrc`. |
| `archiitosinstallscript.sh` | The actual installer, launched by the alias. |

## Quick start (inside the Arch live ISO)

```bash
# 1. get the files onto the ISO (git, curl, or a mounted share), then:
cd achittosinstall
bash installscript.sh
source ~/.bashrc

# 2. install: single disk, KDE, Riga time, install Sober after first login
archittos -ed /dev/sda -md /dev/sda -de kde -tz Europe/Riga \
          --after-boot 'flatpak install -y flathub org.vinegarhq.Sober'
```

## Flags

| Flag | Meaning | Example |
|------|---------|---------|
| `-ed` | EFI disk (gets the 512M EFI partition) | `/dev/sda` |
| `-md` | Main disk (gets the root partition) | `/dev/sda` |
| `-de` | Desktop environment | `kde` \| `gnome` \| `xfce` \| `none` |
| `-tz` | Timezone (`Region/City` under `/usr/share/zoneinfo`) | `Europe/Riga` |
| `--after-boot` | Commands run **once** at first login, then self-deleted | `'sudo pacman -Syu'` |
| `-h`, `--help` | Show usage | |

`-ed` and `-md` may be the **same** disk — it is then split into EFI + root
automatically. Two separate disks are also supported. NVMe naming
(`nvme0n1p1`) is handled.

## Defaults (edit at the top of `archiitosinstallscript.sh`)

| Setting | Default |
|---------|---------|
| Hostname | `archittos` |
| Username | `varlaam` |
| Password (root + user) | `changeme` — **change after first boot!** |
| Locale | `en_US.UTF-8` |

## The `--after-boot` hook

The string you pass is written to `~/firstboot.sh` and wired into an
autostart `.desktop` entry. It runs **once** on the first graphical login,
then removes both itself and the autostart entry. It runs **as the user**
inside the desktop session — `sudo` inside it works because the user is
already in the `wheel` group (set up during install).

### Handy after-boot snippets

Enable multilib and install Steam (Steam is NOT in the base repos):

```bash
--after-boot 'sudo sed -i "/^#\[multilib\]/{s/^#//;n;s/^#//}" /etc/pacman.conf; sudo pacman -Sy --noconfirm; sudo pacman -S steam --noconfirm'
```

Set up Flathub + install Sober (Roblox):

```bash
--after-boot 'sudo pacman -S flatpak --noconfirm; flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo; flatpak install -y flathub org.vinegarhq.Sober'
```

## Not included (by design)

- swap partition / zram
- LUKS disk encryption
- `systemd-boot` (uses GRUB instead)
- multilib repo (enable it via `--after-boot`, see above)

## Errors

All failures print `ERR: <reason>` and exit non-zero. Common ones:

| Message | Fix |
|---------|-----|
| `ERR: Not runned as root` | run from the ISO as root |
| `ERR: Disk not specified` | pass `-ed` and `-md` |
| `ERR: Not a block device <x>` | check the disk path with `lsblk` |
| `ERR: None valid DE ...` | `-de` must be kde/gnome/xfce/none |
| `ERR: Invalid timezone ...` | use a real `Region/City` |
| `ERR: Aborted by user` | you didn't type `YES` at the wipe prompt |
