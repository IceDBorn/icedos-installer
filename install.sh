#!/usr/bin/env bash

set -e

LVM_NAME=os

PS3="Select disk: "
select DISK in $(lsblk -d -io NAME | tail -n +2 | grep -vE 'loop0|sr0')
do break ; done
DISK="/dev/${DISK}"

# printf "Enter /boot size: "
# BOOT_SIZE="$(bash -c 'read a; echo $a')"
bash input.sh "Enter /boot size: " "512" "^[0-9]+[MmGg]$"

# printf "Enter swap size: "
# read SWAP_SIZE
bash input.sh "Enter swap size: " "1" "^[0-9]+[MmGg]$"

# printf "Enter LUKS password: "
# read LUKS_PASSWORD_FIRST
# printf "Enter LUKS password: "
# read LUKS_PASSWORD_SECOND
bash compare.sh "encryption password"

# EXPECT_PATH="$(nix-shell --quiet -p expect --run "bash -c 'which expect'")"
bash nix-export.sh "expect"

umount -l /mnt || true

EXISTING_VG="$(vgdisplay -s | awk '{print $1}' | xargs)"
[ "$EXISTING_VG" != "" ] && vgremove --force "${EXISTING_VG}"

EXISTING_PV="$(pvdisplay -s | awk '{print $2}' | xargs)"
[ "$EXISTING_PV" != "" ] && pvremove --force "${EXISTING_PV}"

EXISTING_LUKS="$(lsblk --list | grep crypt | awk '{print $1}')"
[ "$EXISTING_LUKS" != "" ] && cryptsetup close "${EXISTING_LUKS}"

printf "g\nn\n\n\n+${BOOT_SIZE}\nt\n1\nn\n\n\n\nw\n" | fdisk -w always -W always "${DISK}"

BOOT_FS="$(fdisk -l "${DISK}" | tail -n2 | head -n1 | awk '{print $1}')"
ROOT_FS="$(fdisk -l "${DISK}" | tail -n1 | awk '{print $1}')"

echo "
    spawn cryptsetup -y -v luksFormat ${ROOT_FS}
    expect \"Are you sure?\"
    send -- \"YES\r\n\"
    expect \"Enter passphrase\"
    send -- \"${LUKS_PASSWORD}\r\n\"
    expect \"Verify passphrase\"
    send -- \"${LUKS_PASSWORD}\r\n\"
    expect \"Command successful.\"
" | $EXPECT_PATH

echo "
    spawn cryptsetup -v luksOpen ${ROOT_FS} ${LVM_NAME}
    expect \"Enter passphrase\"
    send -- \"${LUKS_PASSWORD}\r\n\"
    expect \"Command successful.\"
" | $EXPECT_PATH

pvcreate --yes -ff "/dev/mapper/${LVM_NAME}"
vgcreate --yes -ff "${LVM_NAME}_lvm" "/dev/mapper/${LVM_NAME}"

lvcreate --yes -n "swap" -L "${SWAP_SIZE}" "${LVM_NAME}_lvm"
lvcreate --yes -n "root" -l +100%FREE "${LVM_NAME}_lvm"

mkfs.vfat "${BOOT_FS}"
mkswap "/dev/mapper/${LVM_NAME}_lvm-swap"
mkfs.btrfs "/dev/mapper/${LVM_NAME}_lvm-root"

mount "/dev/mapper/${LVM_NAME}_lvm-root" /mnt
btrfs subvolume create /mnt/@root
btrfs subvolume create /mnt/@home

umount /mnt
mount -t btrfs -o subvol=@root "/dev/mapper/${LVM_NAME}_lvm-root" /mnt
mkdir -p /mnt/{home,boot}
mount -t btrfs -o subvol=@home "/dev/mapper/${LVM_NAME}_lvm-root" /mnt/home
mount "${BOOT_FS}" /mnt/boot
# TODO: Mount swap

nixos-generate-config --root /mnt

ROOT_UUID="$(env `blkid -o export "${ROOT_FS}"` bash -c 'echo $UUID')"
echo "{...}: {
    boot.initrd = {
        luks.devices.${LVM_NAME} = {
            device = \"/dev/disk/by-uuid/${ROOT_UUID}\";
            allowDiscards = true;
            preLVM = true;
        };
    };
}" > /mnt/etc/nixos/luks.nix

# Add option for normal or config install
nixos-install --flake .# --impure --root /mnt
