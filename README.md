# Sentinel OS

A self-provisioning Linux VM that bundles everything in the Sentinel toolkit:
the **Sentinel desktop app** (GUI: recon, scanner, threat intel, Gmail/GitHub,
the autonomous Assistant) and the **Nexus CLI** (`sentinel` / `sentinel nexus`),
on an Ubuntu 24.04 + XFCE desktop with common security tooling pre-installed.

## Build & run

```bash
./build.sh          # downloads the base image, builds sentinel-os.qcow2 + seed.iso
./launch.sh         # boots it in QEMU (KVM-accelerated) — a window opens
```

First boot self-provisions via cloud-init (installs the app + CLI from the public
releases) — give it a few minutes, then the XFCE desktop auto-logs-in as
**`sentinel`** (password `sentinel`), auto-launches the Sentinel app, and opens a
terminal on Nexus.

### Other launchers
- **GNOME Boxes / virt-manager:** open `sentinel-os.qcow2` directly.
- **VirtualBox:** `./export-vbox.sh` then start the "Sentinel OS" VM.

## What's inside
| Component | How it's installed |
|---|---|
| Sentinel desktop app | latest `.deb` from the `sentinel` GitHub release |
| Nexus CLI (`sentinel`) | `git clone` + `npm link` from `sentinel-cli` |
| Desktop | XFCE + LightDM autologin |
| Tools | nmap, whois, dnsutils, node, python3, jq, net-tools |

## Config
- RAM/CPUs: `SENTINEL_RAM=8192 SENTINEL_CPUS=4 ./launch.sh`
- Port-forwards (host→guest): `2222→22` (ssh), `8099→8099` (honeypot AI bridge), `8080→80`.
- Change the default password after first login (`passwd`).

## Rebuild from scratch
```bash
rm -f sentinel-os.qcow2 seed.iso   # keep base-noble.img to skip re-downloading
./build.sh
```
