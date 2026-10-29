# Erases the workstation's three NVMe drives and installs its NixOS
# configuration on them, encrypted, with Secure Boot keys of its own. Run it as
# root on the installer stick:
#
#   sudo install-workstation
#
# Nothing is changed until you type ERASE. The settings in capitals come from
# default.nix.

set -o errtrace

state=$(dirname "$LUKS_KEY") # in RAM
mnt=/mnt
volume_group=${LUKS_DEVICE#/dev/}
volume_group=${volume_group%%/*}

bold=$'\e[1m'
red=$'\e[1;31m'
green=$'\e[1;32m'
plain=$'\e[0m'

current="the checks"
step() {
  current=$1
  printf '\n%s== %s%s\n' "$bold" "$1" "$plain"
}
fail() {
  printf '\n%s%s%s\n' "$red" "$1" "$plain" >&2
  exit 1
}
on_error() {
  printf '\n%sinstall-workstation stopped during: %s.%s\n' "$red" "$current" "$plain" >&2
  printf 'The logs are in %s. Running install-workstation again starts over.\n' "$state" >&2
}
trap on_error ERR

efi_byte() {
  od -An -t u1 -j 4 -N 1 "/sys/firmware/efi/efivars/$1-8be4df61-93ca-11d2-aa0d-00e098032b8c" 2>/dev/null | tr -d ' '
}

# Whatever an earlier, interrupted run left mounted or open.
tear_down() {
  umount --recursive "$mnt" 2>/dev/null || true
  swapoff --all 2>/dev/null || true
  cryptsetup close "$LUKS_NAME" 2>/dev/null || true
  vgchange --activate n "$volume_group" >/dev/null 2>&1 || true
}

if [ "$(id -u)" -ne 0 ]; then
  fail "Run this as root: sudo install-workstation"
fi
mkdir -p "$state"
chmod 0700 "$state"

step "Checking the PC (nothing is changed yet)"

if [ ! -d /sys/firmware/efi/efivars ]; then
  fail "The installer didn't start in UEFI mode. In the BIOS, set BIOS UEFI/CSM Mode to UEFI."
fi
if [ "$(efi_byte SetupMode)" != 1 ]; then
  fail "Secure Boot isn't in Setup Mode. In the BIOS, choose Security › Secure Boot › Key Management › Reset To Setup Mode."
fi
if [ "$(cat /sys/class/tpm/tpm0/tpm_version_major 2>/dev/null)" != 2 ]; then
  fail "There's no TPM 2.0. In the BIOS, turn on Security › Trusted Computing › Security Device Support, with AMD fTPM."
fi
echo "  UEFI, Secure Boot in Setup Mode, TPM 2.0: fine."

for disk in $DISKS; do
  if [ ! -b "${disk#*=}" ]; then
    fail "Can't find the ${disk%%=*} drive, ${disk#*=}."
  fi
  printf '  %-8s %s\n' "${disk%%=*}:" "$(lsblk --nodeps --noheadings --output SIZE,MODEL,SERIAL "${disk#*=}")"
done

if [ "$(cat /sys/bus/pci/drivers/ccp/*/tsme_status 2>/dev/null)" = 1 ]; then
  echo "  TSME memory encryption: on."
else
  echo "  TSME memory encryption: off. It's optional, and in the BIOS."
fi

step "Ready"

cat <<EOF
This erases these drives completely, Windows and the old NixOS included:
$(for disk in $DISKS; do printf '  %s\n' "${disk#*=}"; done)

Then it installs the configuration this stick was built from, commit $REPO_REV.

EOF
read -r -p "Type ERASE to go ahead: " answer
if [ "$answer" != ERASE ]; then
  fail "Stopped. Nothing was changed."
fi

step "Erasing the drives"

tear_down
for disk in $DISKS; do
  name=${disk%%=*}
  dev=$(readlink -f "${disk#*=}")
  # The LBA format in use now, so the sector size stays 512 bytes.
  lbaf=$(nvme id-ns "$dev" --output-format=json | jq '.flbas % 16 + (.flbas / 32 | floor) % 4 * 16')
  echo "  $name ($dev)"
  if ! nvme format "$dev" --lbaf="$lbaf" --ses=1 --timeout=1800000 --force >"$state/erase-$name.log" 2>&1; then
    echo "    It refused a secure erase, so every block is discarded instead."
    blkdiscard --force "$dev"
  fi
done
udevadm settle

step "Partitioning and encrypting"

# A random key for the first key slot, only ever in RAM. It's removed again
# once the recovery key is in place.
(umask 0077 && head --bytes=32 /dev/urandom | od -An -v -t x1 | tr -d ' \n' >"$LUKS_KEY")
"$DISKO_FORMAT" >"$state/disko-format.log" 2>&1
echo "  Done; the details are in $state/disko-format.log."

step "Recovery key"

# systemd-cryptenroll prints just the key on stdout. Its other output, a QR
# code of the key included, stays out of the logs.
recovery_key=$(systemd-cryptenroll --unlock-key-file="$LUKS_KEY" --recovery-key "$LUKS_DEVICE" 2>"$state/cryptenroll.err") ||
  fail "systemd-cryptenroll failed: $(cat "$state/cryptenroll.err")"
show_recovery_key() {
  printf '\n    %s%s%s\n\n' "$bold" "$recovery_key" "$plain"
  qrencode --type=ANSIUTF8 "$recovery_key"
}
echo "This is the disk's recovery key:"
show_recovery_key
cat <<EOF
Write it down, or photograph the QR code, and keep it somewhere safe. You type
it once at the first start, and again whenever the TPM won't unlock the disk,
for example after a BIOS update.

EOF
read -r -p "Press Enter once you've saved it. " _
printf '\e[2J\e[H'
while :; do
  read -r -p "Type the recovery key from your copy, to check it: " typed
  if printf '%s' "$typed" | cryptsetup open --test-passphrase --key-file=- "$LUKS_DEVICE" 2>/dev/null; then
    break
  fi
  echo "That doesn't match. Here it is again:"
  show_recovery_key
done
echo "  Your copy is right."

# disko left the volume open, and it stays open to the end, so nothing needs
# the installer's key any more. Only the recovery key opens the volume now.
cryptsetup luksRemoveKey "$LUKS_DEVICE" "$LUKS_KEY"
rm "$LUKS_KEY"

step "Mounting"

"$DISKO_MOUNT" >"$state/disko-mount.log" 2>&1
findmnt --real --submounts --output TARGET,SOURCE "$mnt"

step "Creating Secure Boot keys"

sbctl create-keys >"$state/sbctl.log" 2>&1
install -d --mode=0700 "$mnt$PKI_BUNDLE"
cp --archive /var/lib/sbctl/. "$mnt$PKI_BUNDLE/"
echo "  Lanzaboote signs the boot files with them while installing."

step "Installing"

echo "  Copying about 20 GB from the stick. This takes a while; the details go to $state/nixos-install.log."
nixos-install --root "$mnt" --system "$SYSTEM" --no-root-passwd --no-channel-copy \
  --option substituters "" >"$state/nixos-install.log" 2>&1

install -d --mode=0700 "$mnt/var/log/install-workstation"
cp "$state/disko-format.log" "$state/disko-mount.log" "$state/nixos-install.log" "$mnt/var/log/install-workstation/"

step "Your password"

echo "  For $TARGET_USER. To keep the one you have now, type that."
until nixos-enter --root "$mnt" --silent -- /nix/var/nix/profiles/system/sw/bin/passwd "$TARGET_USER"; do
  echo "  Try again."
done
"$DISKO_UNMOUNT" >"$state/disko-unmount.log" 2>&1

step "Enrolling the Secure Boot keys"

# Last, because it ends Setup Mode: from here on, the firmware only starts what
# these keys signed, plus whatever Microsoft signed.
if ! sbctl enroll-keys --microsoft; then
  fail "The firmware didn't take the keys. They're still in /var/lib/sbctl; try: sbctl enroll-keys --microsoft"
fi

printf '\n%sThe workstation is installed.%s\n\n' "$green" "$plain"
cat <<EOF
Next:
 1. Restart and press F11 at the MSI logo, then pick this stick. The PC has to
    refuse it, because your new keys didn't sign it. If it starts anyway,
    Secure Boot isn't enforcing: turn the PC off and check the BIOS settings.
 2. Start NixOS from the T705 and type the recovery key when asked. The system
    then seals the disk key to the TPM, so it's only this once;
    systemctl status tpm-enroll shows how that went.
EOF
