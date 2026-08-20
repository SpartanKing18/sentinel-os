#!/usr/bin/env bash
# Launch Sentinel OS in QEMU. Uses KVM if available (fast), else TCG (slow).
# The seed.iso stays attached; cloud-init runs it once (instance-id is pinned),
# so re-launches don't re-provision.
set -euo pipefail
cd "$(dirname "$0")"

DISK="sentinel-os.qcow2"
SEED="seed.iso"
RAM="${SENTINEL_RAM:-4096}"
CPUS="${SENTINEL_CPUS:-2}"

[ -f "$DISK" ] || { echo "no $DISK — run ./build.sh first"; exit 1; }

ACCEL=(); [ -w /dev/kvm ] && ACCEL=(-enable-kvm -cpu host) || echo "note: /dev/kvm not writable — running without KVM (slower). Add yourself to the 'kvm' group to speed it up."

SEED_ARGS=(); [ -f "$SEED" ] && SEED_ARGS=(-drive file="$SEED",format=raw,if=virtio,readonly=on)

# Port-forward: 2222->22 (ssh), 8099->8099 (honeypot AI bridge), 8080->80.
exec qemu-system-x86_64 \
  "${ACCEL[@]}" \
  -m "$RAM" -smp "$CPUS" \
  -drive file="$DISK",format=qcow2,if=virtio \
  "${SEED_ARGS[@]}" \
  -device virtio-net,netdev=n0 \
  -netdev user,id=n0,hostfwd=tcp::2222-:22,hostfwd=tcp::8099-:8099,hostfwd=tcp::8080-:80 \
  -device virtio-vga-gl -display gtk,gl=on \
  -device virtio-tablet -device virtio-keyboard \
  -name "Sentinel OS"
