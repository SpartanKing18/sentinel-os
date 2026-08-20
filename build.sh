#!/usr/bin/env bash
# Build Sentinel OS: a self-provisioning Ubuntu VM that ships the Sentinel app
# + Nexus CLI. Produces sentinel-os.qcow2 (+ seed.iso) ready for launch.sh.
#
# Idempotent: re-run any time. Downloads the ~600 MB Ubuntu cloud image once.
set -euo pipefail
cd "$(dirname "$0")"

BASE_URL="https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
BASE_IMG="base-noble.img"
DISK="sentinel-os.qcow2"
SEED="seed.iso"
DISK_SIZE="20G"

need() { command -v "$1" >/dev/null 2>&1; }

echo "== Sentinel OS build =="

# 1) tools
for t in qemu-img xorriso curl openssl; do
  need "$t" || { echo "installing $t ..."; sudo apt-get update -qq && sudo apt-get install -y qemu-utils xorriso curl openssl; break; }
done

# 2) base cloud image (download once)
if [ ! -f "$BASE_IMG" ]; then
  echo "-- downloading Ubuntu 24.04 cloud image (~600 MB) ..."
  curl -fL "$BASE_URL" -o "$BASE_IMG.part"
  mv "$BASE_IMG.part" "$BASE_IMG"
fi

# 3) working disk (copy of base, resized)
if [ ! -f "$DISK" ]; then
  echo "-- creating $DISK ($DISK_SIZE) ..."
  qemu-img convert -O qcow2 "$BASE_IMG" "$DISK"
  qemu-img resize "$DISK" "$DISK_SIZE"
fi

# 4) cloud-init seed with a real password hash for user 'sentinel'
echo "-- building cloud-init seed ..."
HASH="$(openssl passwd -6 sentinel)"
mkdir -p .seed
cp cloud-init/meta-data .seed/meta-data
# substitute the password hash into user-data
sed "s#^    passwd: .*#    passwd: \"${HASH//#/\\#}\"#" cloud-init/user-data > .seed/user-data
xorriso -as mkisofs -quiet -output "$SEED" -volid CIDATA -joliet -rock .seed/user-data .seed/meta-data
rm -rf .seed

echo
echo "== done =="
echo "  disk:  $(pwd)/$DISK"
echo "  seed:  $(pwd)/$SEED"
echo "  next:  ./launch.sh          (QEMU + KVM, opens a window)"
echo "         ./export-vbox.sh     (make a VirtualBox VM)"
echo "  login: sentinel / sentinel  (first boot self-provisions — give it a few minutes)"
