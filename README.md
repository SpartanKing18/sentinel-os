# Sentinel OS

A self-provisioning security workstation — a Kali/BlackArch alternative that wraps a
neutral cloud base (Debian, Ubuntu, or Kali) in the **Sentinel** identity: a branded
XFCE desktop, a curated offensive/defensive toolset, a local-AI layer, and a built-in
honeypot. You pick the base OS at build time; everything else is installed on first
boot by cloud-init.

## Architecture

```
   Base cloud image  (Debian 12 · Ubuntu 24.04/22.04 · Kali)
          |
          |  build.sh   (chooses the base, builds a cloud-init NoCloud seed)
          v
   Sentinel OS disk  +  seed.iso
          |
          |  first boot -> cloud-init runs the provisioner
          v
   +----------------------------------------------------------+
   |  Desktop      XFCE · dark theme · Whisker menu · Chrome   |
   |  Toolkit      recon · web · passwords · wireless · forensics
   |  AI layer     Ollama + sentinel-ai -> recon / triage / engage / loot
   |  Defense      sentinel-lockout · sentinel-scope · sentinel-anon
   |  Honeypot     bundled deception service                   |
   +----------------------------------------------------------+
          |
          v
   Run it:  launch.sh (QEMU/KVM)   or   export-vbox.sh (VirtualBox)
```

The base image never carries the identity — `build.sh` stamps the chosen family into
the cloud-init seed, and the provisioner adapts per distro (kernel package, repos)
before installing the desktop, tools, and AI layer.

## Project Structure

```
sentinel-os/
├── build.sh              # OS picker + base-image fetch + cloud-init seed builder
├── launch.sh             # boot the VM under QEMU/KVM
├── export-vbox.sh        # import the disk into VirtualBox (virtio-scsi, auto-resize)
├── sentinel-os.conf      # remembered base-OS choice (the "setting")
├── cloud-init/
│   ├── user-data         # the provisioner: desktop, tools, AI, branding, hardening
│   └── meta-data         # NoCloud instance metadata
└── toolkit/              # everything installed into the OS
    ├── sentinel-ai       # shared AI engine (local Ollama + cloud), used by the tools
    ├── sentinel-scope    # engagement authorization guard (in-scope enforcement)
    ├── sentinel-recon    # AI-orchestrated recon -> prioritized findings
    ├── sentinel-loot     # AI findings register from raw scan output
    ├── sentinel-triage / sentinel-engage   # AI triage + report
    ├── sentinel-lockout  # emergency defensive lockdown
    ├── sentinel-anon / sentinel-stealth / sentinel-macspoof   # anonymity
    ├── sentinel-desktop-setup / gen-sentinel-menu             # first-login desktop
    └── assets            # wallpaper, icons, Chrome/desktop assets
```

## Choosing the base OS

```
./build.sh              # interactive picker
./build.sh ubuntu       # or name it
SENTINEL_BASE=debian ./build.sh
```

Debian and Ubuntu are fully wired; Kali is experimental. Windows/Fedora/Arch aren't
built by this pipeline (different provisioners) and the picker says so.

## Editions

Pick how much ships — every edition self-provisions on first boot:

| Edition | Disk | UI | What's included |
|---|---|---|---|
| **netinstall** | ~12 GB | none (terminal only) | Core CLI security stack + Nexus AI agent + local models. Boots to a console with tty1 autologin. Smallest & fastest. |
| **slim** | ~20 GB | XFCE desktop | Full branded desktop + Nexus + the CLI toolset, **minus** Metasploit, SecLists, Exploit-DB, Docker and the cockpit app. |
| **full** | ~30 GB | XFCE desktop | Everything: desktop, cockpit app, Metasploit, SecLists, Exploit-DB, Docker, autonomous AI recon, honeypot — 80+ tools. |

```
./build.sh debian netinstall     # base + edition (default edition is full)
./build.sh debian slim
./build.sh debian full
SENTINEL_BASE=debian SENTINEL_EDITION=slim ./build.sh
```

Editions build to separate files (`sentinel-os-<edition>.qcow2` / `seed-<edition>.iso`) so they don't clobber each other. Pass the edition to the launchers too: `./launch.sh slim`, `./export-vbox.sh netinstall`.

## Installation

```
git clone https://github.com/SpartanKing18/sentinel-os
cd sentinel-os
./build.sh debian full        # pick a base + edition; builds the disk + cloud-init seed
./launch.sh full              # QEMU/KVM   (or ./export-vbox.sh full for VirtualBox)
```

First boot self-provisions (netinstall ~5–8 min, full ~15–20 min). Login: `sentinel` / `sentinel`.

## Status

Active. Debian/Ubuntu bases fully supported; VirtualBox Guest Additions, Chrome,
the AI toolkit, and the defensive tools are provisioned on first boot.

## Security

Sentinel OS ships offensive tooling for **authorized** testing only. Use
`sentinel-scope` to declare in-scope targets — the AI tools refuse anything outside
it. Do not distribute images with live credentials baked in.

## License

See `LICENSE`.
