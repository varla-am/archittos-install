#!/usr/bin/env bash
#
# installscript.sh — registers the `archittos` alias in ~/.bashrc
# Run this once inside the Arch live ISO. Afterwards you launch the
# installer just by typing:  archittos -ed ... -md ... -de ...
#
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="$DIR/archiitosinstallscript.sh"

if [[ ! -f "$TARGET" ]]; then
    echo "error: $TARGET not found (keep both scripts in the same folder)" >&2
    exit 1
fi
chmod +x "$TARGET"

LINE="alias archittos='sudo $TARGET'"
touch ~/.bashrc
if grep -qxF "$LINE" ~/.bashrc; then
    echo "Alias 'archittos' already present in ~/.bashrc"
else
    printf '\n# ArchittOS installer\n%s\n' "$LINE" >> ~/.bashrc
    echo "Alias 'archittos' added to ~/.bashrc"
fi
echo "Now run:  source ~/.bashrc   (or reopen the shell)"
echo "Then:     archittos -ed /dev/sda -md /dev/sda -de kde"
