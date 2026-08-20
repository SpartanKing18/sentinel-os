#!/usr/bin/env bash
# Build Sentinel OS: a self-provisioning Kali Linux VM that ships the Sentinel
# app + Nexus CLI + a curated pentest toolset. Produces sentinel-os.qcow2
# (+ seed.iso) ready for launch.sh.
#
# Base: Kali "generic cloud" image (Debian-family, cloud-init w/ NoCloud) — same
# seed flow as before, but native Kali repos, kali-menu, and injection kernel.
# Idempotent: re-run any time; downloads the base image once.
set -euo pipefail
cd "$(dirname "$0")"

CLOUD_DIR="https://kali.download/cloud-images/current/"
BASE_TAR="kali-cloud.tar.xz"
BASE_IMG="base-kali.qcow2"
DISK="sentinel-os.qcow2"
SEED="seed.iso"
DISK_SIZE="30G"

need() { command -v "$1" >/dev/null 2>&1; }

echo "== Sentinel OS build (Kali base) =="

# 1) tools
for t in qemu-img xorriso curl openssl tar xz; do
  need "$t" || { echo "installing build deps ..."; sudo apt-get update -qq && sudo apt-get install -y qemu-utils xorriso curl openssl tar xz-utils; break; }
done

# 2) base Kali cloud image (download + unpack once)
if [ ! -f "$BASE_IMG" ]; then
  if [ ! -f "$BASE_TAR" ]; then
    echo "-- discovering current Kali generic cloud image ..."
    FNAME="$(curl -fsSL "$CLOUD_DIR" | grep -oE 'kali-linux-[0-9.]+-cloud-genericcloud-amd64\.tar\.xz' | head -1)"
    [ -n "$FNAME" ] || { echo "could not find the Kali genericcloud amd64 image at $CLOUD_DIR"; exit 1; }
    echo "-- downloading $FNAME ..."
    curl -fL "${CLOUD_DIR}${FNAME}" -o "$BASE_TAR.part"
    mv "$BASE_TAR.part" "$BASE_TAR"
  fi
  echo "-- unpacking disk image ..."
  tar -xf "$BASE_TAR"
  RAW="$(find . -maxdepth 2 -name 'disk.raw' 2>/dev/null | head -1)"
  [ -n "$RAW" ] || { echo "disk.raw not found in $BASE_TAR"; exit 1; }
  echo "-- converting raw -> qcow2 ..."
  qemu-img convert -f raw -O qcow2 "$RAW" "$BASE_IMG"
  rm -f "$RAW"; find . -maxdepth 1 -type d -name 'kali-linux-*cloud*' -exec rm -rf {} + 2>/dev/null || true
fi

# 3) working disk (copy of base, grown for the toolset)
if [ ! -f "$DISK" ]; then
  echo "-- creating $DISK ($DISK_SIZE) ..."
  qemu-img convert -O qcow2 "$BASE_IMG" "$DISK"
  qemu-img resize "$DISK" "$DISK_SIZE"
fi

# 4) cloud-init seed with a real password hash for user 'sentinel'
echo "-- building cloud-init seed ..."
HASH="$(openssl passwd -6 sentinel)"
rm -rf .seed && mkdir -p .seed
cp cloud-init/meta-data .seed/meta-data
sed "s#^    passwd: .*#    passwd: \"${HASH//#/\\#}\"#" cloud-init/user-data > .seed/user-data
( cd .seed && xorriso -as mkisofs -quiet -output "../$SEED" -volid CIDATA -joliet -rock user-data meta-data )
rm -rf .seed

echo
echo "== done =="
echo "  base:  $(pwd)/$BASE_IMG   (Kali cloud)"
echo "  disk:  $(pwd)/$DISK"
echo "  seed:  $(pwd)/$SEED"
echo "  next:  ./launch.sh          (QEMU + KVM, opens a window)"
echo "  login: sentinel / sentinel  (first boot installs the desktop + tools — allow ~10-15 min)"
