# NRR Cloud Workstation — Claude Code Project Memory

## What This Project Is

We are building a plug-and-play GPU workstation system for Nairoeel Productions to use Blender on RunPod. Any team member should be able to spin up a GPU pod in any region, open a browser desktop, launch Blender, and have all their files already there — with changes syncing back automatically.

The system has three parts that must be built in order:
1. VPS storage partition (RackNerd VPS, already running Coolify)
2. Custom Docker image (published to Docker Hub)
3. RunPod template configured to use that image

---

## Architecture

```
Team member
  │
  ├─── uploads files via File Browser UI ──► /srv/studio/ on VPS (RackNerd)
  │                                               │
  │                                          SFTP (port 22, studio-sync user)
  │                                               │
  └─── opens RunPod pod ──────────────────► Custom Docker image pulls files on startup
                                            rclone syncs PROJECTS/ back every 5 min
                                            Blender ready on desktop
```

**Key decision: storage uses SFTP directly over existing SSH (port 22). No new Nginx config. Client portal is completely untouched.**

---

## The VPS (RackNerd)

See `docs/VPS_REFERENCE.md` for full server documentation.

Critical facts for this project:
- IP: `107.172.153.249`
- Port 22 is open (iptables already allows it)
- OS: Ubuntu 24.04 LTS
- Everything runs via Docker/Coolify
- Auth: Ed25519 key only, password auth disabled
- The sshd_config drop-in `/etc/ssh/sshd_config.d/50-cloud-init.conf` overrides the main config — any SSH changes must be applied to BOTH files
- **Do not touch**: coolify-proxy (Traefik), iptables rules, /data/coolify/, client portal Nginx config
- Default iptables policy is DROP — port 22 is already open, no new ports needed for this project
- Before editing sshd_config: always `cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak-YYYYMMDD` first

---

## VPS Storage Structure

```
/srv/studio/                        ← chroot root, owned by ROOT (OpenSSH requirement)
├── BLENDER_APPS/                   ← owned by studio-sync, Blender tarballs + extracted app
├── CONFIG_MASTER/
│   └── scripts/
│       └── addons/                 ← Blender addon folders
├── LIBRARY_GLOBAL/
│   ├── botaniq/
│   └── alpha_trees/
└── PROJECTS/
    └── Your_Project/
        ├── Project_v01.blend
        └── tex/
```

**Critical**: `/srv/studio/` itself must be owned by `root:root` with permissions `755`. This is an OpenSSH chroot requirement — if it is owned by `studio-sync`, the chroot will refuse to start.

---

## The `studio-sync` SSH User

- System user, no shell (`/usr/sbin/nologin`), home is `/srv/studio`
- Authenticates via Ed25519 keypair generated specifically for rclone (separate from the admin .ppk key)
- Chrooted to `/srv/studio` via sshd_config `Match User` block
- Can only SFTP, no shell access, no TCP forwarding
- The `Match User` block must be added at the **bottom** of `/etc/ssh/sshd_config` (Match blocks must come last)

---

## Docker Image

- Base: `madiator2011/kasm-runpod-desktop:mldesk`
- Desktop user inside the image: `kasm-user` (hyphen, not underscore)
- Published to: Docker Hub as `YOUR_DOCKERHUB_USERNAME/nrr-studio:1.0` (replace with real username)
- Built on Windows with Docker Desktop — no GPU needed at build time
- Files: `docker/Dockerfile` and `docker/fix-workspace-and-start.sh`

---

## Environment Variables (Set in RunPod Template)

| Variable | Description |
|---|---|
| `VPS_SSH_KEY_B64` | Base64-encoded OpenSSH private key for studio-sync user |

The VPS host IP is hardcoded in the startup script (`107.172.153.249`) since it never changes.

---

## Sync Logic

| Folder | Direction | Frequency |
|---|---|---|
| `BLENDER_APPS/` | VPS → Pod (pull only) | Once at startup |
| `CONFIG_MASTER/` | VPS → Pod (pull only) | Once at startup |
| `LIBRARY_GLOBAL/` | VPS → Pod (pull only) | Once at startup |
| `PROJECTS/` | VPS → Pod at start, Pod → VPS ongoing | Pull at startup, push every 5 min |

Libraries and Blender are treated as read-only on the pod side — the VPS is the source of truth for those. Only PROJECTS syncs back.

---

## Definition of Done

- [ ] `/srv/studio/` directory structure exists on VPS with correct ownership
- [ ] `studio-sync` user exists on VPS
- [ ] sshd_config `Match User` block in place, SSH restarted
- [ ] SFTP connection works: `sftp -i studio_sync_key -P 22 studio-sync@107.172.153.249`
- [ ] rclone keypair generated, public key in `/srv/studio/.ssh/authorized_keys`
- [ ] Docker image builds without errors
- [ ] Docker image pushed to Docker Hub
- [ ] RunPod template updated with new image name and `VPS_SSH_KEY_B64` env var
- [ ] Pod launched, `/workspace` is writable by kasm-user
- [ ] Blender launches from desktop shortcut
- [ ] File created in `/workspace/PROJECTS/` appears on VPS within 5 minutes

---

## What Not to Do

- Do not modify the Nginx config for the client streaming portal
- Do not run `docker system prune -a` on the VPS
- Do not change iptables rules (port 22 is already open)
- Do not use `chmod 777` anywhere
- Do not store actual private key values in any file in this repo — the key goes in RunPod's environment variable field only
- Do not add log files to the VPS Nginx config without also adding logrotate entries
