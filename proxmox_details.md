# Homelab Services

## Infrastructure

### Proxmox Cluster - "homelab"
- **Nodes:** cluster01 (192.168.50.200), cluster02 (.201), cluster03 (.202)
- **Web UI:** https://192.168.50.200:8006 (any node)
- **Quorum:** 3 nodes, requires 2 for quorum
- **Storage:** local-lvm on each node (~141GB usable per node)
- **Ceph:** Installed (Squid 19.2.3-pve4) but not active - no spare disks for OSDs

---

## Containers

### CT 100 - Jellyfin (cluster01)
- **Type:** LXC (unprivileged, Debian 12)
- **IP:** 192.168.50.63 (DHCP)
- **Web UI:** http://192.168.50.63:8096
- **Resources:** 2 cores, 4GB RAM, 16GB disk
- **GPU:** Intel Quick Sync passed through (/dev/dri/card0, /dev/dri/renderD128)
- **Media mounts (bind from host):**
  - `/media/movies` -> USB drive Movies folder
  - `/media/tv` -> USB drive TV folder
  - `/media/startrek` -> USB drive star-trek folder
- **Notes:**
  - GPU permissions set via udev rule on host (`/etc/udev/rules.d/99-gpu-lxc.rules`)
  - Enable hardware transcoding in Dashboard > Playback > Transcoding > Intel QuickSync (QSV)

### CT 101 - arr-stack (cluster01)
- **Type:** LXC (unprivileged, Debian 12, nesting + keyctl enabled)
- **IP:** 192.168.50.58 (DHCP)
- **Resources:** 2 cores, 4GB RAM, 32GB disk
- **Docker:** Installed (Docker CE)
- **TUN device:** Passed through for VPN (/dev/net/tun)
- **Media mounts (bind from host):**
  - `/media/movies` -> USB drive Movies folder
  - `/media/tv` -> USB drive TV folder
  - `/media/startrek` -> USB drive star-trek folder
- **Docker Compose location:** `/opt/arr-stack/docker-compose.yml`

#### Docker Services (all routed through Gluetun VPN)

| Service | URL | Purpose |
|---------|-----|---------|
| **Gluetun** | (internal) | VPN gateway - ProtonVPN WireGuard, US servers (non-Secure Core) |
| **FlareSolverr** | (internal :8191) | Cloudflare bypass proxy for indexers |
| **Prowlarr** | http://192.168.50.58:9696 | Indexer manager - add torrent indexers here first |
| **Radarr** | http://192.168.50.58:7878 | Movie automation - root folder: `/movies` |
| **Sonarr** | http://192.168.50.58:8989 | TV automation - root folders: `/tv`, `/startrek` |
| **qBittorrent** | http://192.168.50.58:8080 | Torrent client (default user: `admin`) |

#### arr-stack Setup Order
1. **Prowlarr** - Add torrent indexers (1337x, etc.)
2. **Radarr** - Add as app in Prowlarr, set root folder to `/movies`, add qBittorrent as download client (host: `localhost`, port: `8080`)
3. **Sonarr** - Add as app in Prowlarr, set root folders to `/tv` and `/startrek`, add qBittorrent as download client (host: `localhost`, port: `8080`)
4. **qBittorrent** - Change default password on first login, set download path to `/downloads`

---

## USB Storage (cluster01)

- **Device:** `/dev/sda` - Crucial CT1000P310SSD2 (931.5GB)
- **Filesystem:** exFAT (`/dev/sda2`)
- **Mount point:** `/mnt/usb-media`
- **Contents:**
  - `Movies/` - Movie collection (~various 1080p/4K)
  - `TV/` - Foundation S01-S02, Shogun S01
  - `star-trek/` - DS9, Enterprise, Lower Decks, Picard, Prodigy, Strange New Worlds, TAS
  - `Assets/`
  - `Games/`
  - `Graphic Novels/`
- **Mount method:** FUSE exfat (`mount.exfat-fuse`) with `dmask=0000,fmask=0000` for container write access
- **Note:** USB drive is not auto-mounted on reboot. For persistence, add to a startup script:
  ```bash
  mount.exfat-fuse /dev/sda2 /mnt/usb-media -o rw,dmask=0000,fmask=0000
  ```

### CT 102 - Uptime Kuma (cluster01)
- **Type:** LXC (unprivileged, Debian 12, nesting + keyctl enabled)
- **IP:** 192.168.50.237 (DHCP)
- **Web UI:** http://192.168.50.237:3001
- **Resources:** 1 core, 1GB RAM, 8GB disk
- **Docker:** Installed (Docker CE)
- **Purpose:** Service monitoring dashboard for all homelab services

### CT 200 - Moltbot (cluster02)
- **Type:** LXC (unprivileged, Debian 12, nesting + keyctl enabled)
- **IP:** 192.168.50.96 (DHCP)
- **Gateway:** ws://192.168.50.96:18789
- **Dashboard:** http://192.168.50.96:18789/ (requires HTTPS or localhost for Control UI)
- **Resources:** 2 cores, 2GB RAM, 16GB disk
- **Docker:** Installed (Docker CE)
- **Config:** `/root/.openclaw/openclaw.json` (main config), `/root/.openclaw/config.json` (legacy)
- **Docker Compose:** `/opt/moltbot/docker-compose.yml` + `docker-compose.override.yml`
- **Gateway Token:** `aa9b1a98815c317bbb17592aef3780d37778232fe695a501702a09143e95e686`
- **AI Model:** `ollama/qwen3-coder-next` via Ollama on GPU server (`http://192.168.50.105:11434`)
- **Discord Bot:** Connected as `@Agent01` (bot ID: `1470319615312924732`)
- **Discord Policy:** `open` - responds in any channel when mentioned
- **Purpose:** AI assistant gateway with Discord integration, powered by GPU-accelerated Ollama LLM

### CT 201 - Ollama (cluster02) [LEGACY - superseded by GPU server]
- **Type:** LXC (unprivileged, Debian 12)
- **IP:** 192.168.50.65 (DHCP)
- **API:** http://192.168.50.65:11434
- **Resources:** 4 cores, 10GB RAM, 32GB disk
- **Models:**
  - `qwen2.5:3b` - Qwen 2.5 (3B params, tool-calling support)
  - `phi3:mini` - Phi-3 Mini (3.8B params, no tool support)
- **Service:** Ollama v0.15.6 (systemd, `OLLAMA_HOST=0.0.0.0`)
- **Purpose:** Former LLM inference server for Moltbot (CPU-only, i5-8600) - replaced by GPU server

### CT 300 - Terraform Dev (cluster03)
- **Type:** LXC (unprivileged, Debian 12)
- **IP:** 192.168.50.164 (DHCP)
- **Resources:** 2 cores, 2GB RAM, 16GB disk
- **Terraform:** v1.14.4 with Proxmox provider (bpg/proxmox v0.95.0)
- **Project location:** `/root/terraform-projects/homelab/`
- **Usage:**
  ```bash
  # SSH into container from cluster03
  pct exec 300 -- bash

  # Set credentials
  export PROXMOX_VE_USERNAME="root@pam"
  export PROXMOX_VE_PASSWORD="your-password"

  # Run terraform
  cd /root/terraform-projects/homelab
  terraform plan
  terraform apply
  ```

---

## Standalone Servers

### GPU Server (192.168.50.105)
- **SSH:** `ssh -p 2222 fragro@192.168.50.105`
- **OS:** Ubuntu 22.04.5 LTS
- **CPU/RAM:** 64GB RAM
- **GPUs:**
  - GPU 0: NVIDIA GeForce RTX 3090 Ti (24GB VRAM)
  - GPU 1: NVIDIA GeForce RTX 3090 (24GB VRAM)
- **NVIDIA Driver:** 550.163.01, CUDA 12.4
- **Docker:** 28.3.3 with NVIDIA Container Toolkit
- **Ollama:** Docker container (`~/llm-server/docker-compose.yml`), Ollama v0.15.6
  - **API:** http://192.168.50.105:11434
  - **Models:**
    - `qwen3-coder-next` - Qwen3 Coder Next (80B MoE, 3B active, Q4_K_M, 51GB) - **active**
    - `qwen3:32b` - Qwen3 32B dense (20GB)
  - **GPU Split:** Model distributed across both GPUs (~23.8GB each)
- **Purpose:** GPU-accelerated LLM inference server for Moltbot and other services

---

## Known Issues / TODOs
- **cluster03 RAM:** Shows 7.6GB instead of expected 32GB - needs investigation
- **cluster02/03 NIC:** `enp2s0` not detected, may use different interface name
- **cluster04:** Unreachable - standalone spare, not part of cluster
- **Ceph OSDs:** Cannot be configured - each node has only one NVMe (OS disk), no spare disks
- **USB drive persistence:** Not in fstab, will not auto-mount after reboot
- **DHCP reservations:** Not yet configured in router for container IPs
- **Clock skew:** Ceph warning about clock skew on cluster02/03 - Chrony should handle this