#!/usr/bin/env bash
# Convert the qcow2 to a VirtualBox VM so Sentinel OS runs in the VirtualBox GUI.
set -euo pipefail
cd "$(dirname "$0")"

DISK="sentinel-os.qcow2"
VDI="sentinel-os.vdi"
VM="Sentinel OS"

[ -f "$DISK" ] || { echo "no $DISK — run ./build.sh first"; exit 1; }
command -v VBoxManage >/dev/null || { echo "VirtualBox (VBoxManage) not found"; exit 1; }

[ -f "$VDI" ] || qemu-img convert -O vdi "$DISK" "$VDI"

VBoxManage list vms | grep -q "\"$VM\"" || {
  VBoxManage createvm --name "$VM" --ostype Ubuntu_64 --register
  VBoxManage modifyvm "$VM" --memory 4096 --cpus 2 --vram 128 --graphicscontroller vmsvga --nic1 nat
  VBoxManage storagectl "$VM" --name SATA --add sata --controller IntelAhci
  VBoxManage storageattach "$VM" --storagectl SATA --port 0 --device 0 --type hdd --medium "$(pwd)/$VDI"
  # forward ssh + honeypot bridge
  VBoxManage modifyvm "$VM" --natpf1 "ssh,tcp,,2222,,22"
  VBoxManage modifyvm "$VM" --natpf1 "bridge,tcp,,8099,,8099"
}
echo "VirtualBox VM '$VM' is ready — open VirtualBox and Start it, or: VBoxManage startvm \"$VM\""
