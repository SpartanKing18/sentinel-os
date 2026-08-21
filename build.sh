#!/usr/bin/env bash
# Build Sentinel OS: a unique, self-provisioning security workstation built on a
# neutral Debian 12 base (NOT Kali) — its own desktop, its own curated toolset,
# a local-AI autonomous layer, and the Sentinel app as the UI cockpit.
#
# The base is a plain Debian genericcloud qcow2 (cloud-init w/ NoCloud), so the
# whole identity — tools, desktop, branding — is ours, installed on first boot.
set -euo pipefail
cd "$(dirname "$0")"

CLOUD_DIR="https://cloud.debian.org/images/cloud/bookworm/latest/"
BASE_IMG="base-debian.qcow2"
DISK="sentinel-os.qcow2"
SEED="seed.iso"
DISK_SIZE="30G"

need() { command -v "$1" >/dev/null 2>&1; }
echo "== Sentinel OS build (Debian base, from scratch) =="

for t in qemu-img xorriso curl openssl; do
  need "$t" || { echo "installing build deps ..."; sudo apt-get update -qq && sudo apt-get install -y qemu-utils xorriso curl openssl; break; }
done

# 1) base Debian generic cloud image (a qcow2 directly — no unpack needed)
if [ ! -f "$BASE_IMG" ]; then
  FNAME="$(curl -fsSL "$CLOUD_DIR" | grep -oE 'debian-12-genericcloud-amd64(-[0-9.]+)?\.qcow2' | sort -u | head -1)"
  [ -n "$FNAME" ] || FNAME="debian-12-genericcloud-amd64.qcow2"
  echo "-- downloading $FNAME ..."
  curl -fL "${CLOUD_DIR}${FNAME}" -o "$BASE_IMG.part"
  mv "$BASE_IMG.part" "$BASE_IMG"
fi

# 2) working disk (copy of base, grown for the toolset)
if [ ! -f "$DISK" ]; then
  echo "-- creating $DISK ($DISK_SIZE) ..."
  qemu-img convert -O qcow2 "$BASE_IMG" "$DISK"
  qemu-img resize "$DISK" "$DISK_SIZE"
fi

# 3) cloud-init seed with a real password hash for user 'sentinel'
echo "-- building cloud-init seed ..."
HASH="$(openssl passwd -6 sentinel)"
rm -rf .seed && mkdir -p .seed
cp cloud-init/meta-data .seed/meta-data
sed "s#^    passwd: .*#    passwd: \"${HASH//#/\\#}\"#" cloud-init/user-data > .seed/user-data
( cd .seed && xorriso -as mkisofs -quiet -output "../$SEED" -volid CIDATA -joliet -rock user-data meta-data )
rm -rf .seed

echo
echo "== done =="
echo "  base:  $(pwd)/$BASE_IMG   (Debian 12 cloud)"
echo "  disk:  $(pwd)/$DISK"
echo "  seed:  $(pwd)/$SEED"
echo "  next:  ./launch.sh          (QEMU + KVM)   or   ./export-vbox.sh (VirtualBox)"
echo "  login: sentinel / sentinel  (first boot builds the desktop + tools — allow ~15-20 min)"
