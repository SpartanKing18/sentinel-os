#!/usr/bin/env bash
# Convert the qcow2 to a VirtualBox VM so Sentinel OS runs in the VirtualBox GUI.
# Attaches the cloud-init seed as a DVD so first boot self-provisions.
set -euo pipefail
cd "$(dirname "$0")"

DISK="sentinel-os.qcow2"
SEED="seed.iso"
VDI="sentinel-os.vdi"
VM="Sentinel OS"

[ -f "$DISK" ] || { echo "no $DISK — run ./build.sh first"; exit 1; }
command -v VBoxManage >/dev/null || { echo "VirtualBox (VBoxManage) not found"; exit 1; }

[ -f "$VDI" ] || { echo "converting qcow2 -> VDI ..."; qemu-img convert -O vdi "$DISK" "$VDI"; }

if ! VBoxManage list vms | grep -q "\"$VM\""; then
  VBoxManage createvm --name "$VM" --ostype Debian_64 --register
  VBoxManage modifyvm "$VM" --memory 6144 --cpus 4 --vram 256 --graphicscontroller vmsvga --nic1 nat --nictype1 virtio --audio-driver none --usbohci on --mouse usbtablet --keyboard usb
  # virtio-scsi, NOT SATA: the Debian cloud initramfs is virtio-only, so a SATA/AHCI
  # controller leaves it unable to find the root disk ("Gave up waiting for root").
  VBoxManage storagectl "$VM" --name VIRTIO --add virtio-scsi
  VBoxManage storageattach "$VM" --storagectl VIRTIO --port 0 --device 0 --type hdd --medium "$(pwd)/$VDI"
  # cloud-init NoCloud seed (CIDATA) as a DVD so the VM provisions itself on first boot
  VBoxManage storagectl "$VM" --name IDE --add ide
  [ -f "$SEED" ] && VBoxManage storageattach "$VM" --storagectl IDE --port 0 --device 0 --type dvddrive --medium "$(pwd)/$SEED"
  # forward ssh + honeypot bridge to the host
  VBoxManage modifyvm "$VM" --natpf1 "ssh,tcp,,2222,,22"
  VBoxManage modifyvm "$VM" --natpf1 "bridge,tcp,,8099,,8099"
fi
echo "VirtualBox VM '$VM' is ready."
echo "Start it:  VBoxManage startvm \"$VM\" --type gui"
