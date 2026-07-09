#!/usr/bin/env bash
#
# One-time: format a spare drive as the backup mirror, mount at /mnt/backup.
# DESTROYS ALL DATA on <device>. Refuses if the device already has a
# filesystem or partitions — wipe manually first if you really mean it.
#
# Usage: sudo ./setup-backup-drive.sh /dev/sdX
#
set -euo pipefail

DEV="${1:?usage: sudo setup-backup-drive.sh /dev/sdX}"
DEV_USER="${SUDO_USER:-marcus}"

[[ $EUID -eq 0 ]] || { echo "Run with sudo" >&2; exit 1; }
[[ -b "$DEV" ]] || { echo "$DEV is not a block device" >&2; exit 1; }

if mountpoint -q /mnt/backup; then
    echo "/mnt/backup already mounted — nothing to do."
    exit 0
fi

if blkid "$DEV" >/dev/null 2>&1 || [[ -n "$(lsblk -n -o NAME "$DEV" | tail -n +2)" ]]; then
    echo "REFUSING: $DEV has a filesystem or partitions. Wipe manually first." >&2
    exit 1
fi

mkfs.ext4 -L backup "$DEV"
mkdir -p /mnt/backup
grep -q '^LABEL=backup ' /etc/fstab \
    || echo 'LABEL=backup /mnt/backup ext4 defaults,nofail 0 2' >> /etc/fstab
systemctl daemon-reload
mount /mnt/backup
install -d -o "$DEV_USER" -g "$DEV_USER" /mnt/backup/srv-backups

echo "Done. backup.sh will now mirror /srv/data/backups here."
