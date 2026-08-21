# Sentinel OS

A unique, self-provisioning security workstation built **from scratch on a neutral Debian base** (not Kali) that bundles everything in the Sentinel
toolkit: the **Sentinel desktop app** (GUI: recon, scanner, threat intel,
Gmail/GitHub, the autonomous Assistant) and the **Nexus CLI**
(`sentinel` / `sentinel nexus`), with its own desktop, its own curated toolset (Debian + upstream — no Kali
packages), a local-AI autonomous layer, and the Sentinel app as the UI cockpit.

## What's inside
- **Base:** Debian 12 (generic cloud) + our own XFCE desktop
- **Sentinel app** (latest `.deb`) — auto-launches on login
- **Nexus CLI** (`sentinel` / `sentinel nexus`)
- **Our own curated toolset** (Debian repos + upstream, no Kali packages): nmap,
  masscan, nikto, whatweb, wafw00f, dnsrecon, dirb, wfuzz, gobuster, sqlmap, hydra,
  john, hashcat, aircrack-ng, wireshark, ettercap, radare2, binwalk, sleuthkit,
  impacket, seclists, searchsploit, **metasploit**, and upstream **nuclei /
  subfinder / httpx / ffuf / netexec**
- **Autonomous AI (Ollama)** — the desktop **Autopilot** and `sentinel nexus run`
  do recon + exploitation toward a goal, offline
- **Docker practice lab** (`sentinel lab up`)

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
