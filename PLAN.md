# Implementation Plan — NRR Cloud Workstation

## Overview

Three phases, must be done in order. Each phase has a verification step before moving on.

---

## Phase 1 — VPS Storage Setup

**Goal**: Create the storage directory, a locked-down SFTP user, and verify the connection works.

**Do this via SSH into the VPS (PuTTY, root login, 107.172.153.249).**

### Step 1.1 — Generate the rclone keypair (on your Windows machine)

Open PowerShell:

```powershell
ssh-keygen -t ed25519 -f "$HOME\.ssh\studio_sync_key" -C "runpod-studio-sync" -N ""
```

This creates:
- `~/.ssh/studio_sync_key` — private key (OpenSSH format, needed by rclone)
- `~/.ssh/studio_sync_key.pub` — public key (goes on the VPS)

**Do not confuse this with your existing PuTTY .ppk key. These are separate.**

### Step 1.2 — Create the directory structure on the VPS

```bash
# The chroot root MUST be owned by root (OpenSSH hard requirement)
mkdir -p /srv/studio
chown root:root /srv/studio
chmod 755 /srv/studio

# Create all subdirectories
mkdir -p /srv/studio/BLENDER_APPS
mkdir -p /srv/studio/CONFIG_MASTER/scripts/addons
mkdir -p /srv/studio/LIBRARY_GLOBAL/botaniq
mkdir -p /srv/studio/LIBRARY_GLOBAL/alpha_trees
mkdir -p /srv/studio/PROJECTS

# Create the studio-sync user
useradd -r -s /usr/sbin/nologin -d /srv/studio studio-sync

# Give studio-sync ownership of the subdirs (not the root)
chown -R studio-sync:studio-sync \
    /srv/studio/BLENDER_APPS \
    /srv/studio/CONFIG_MASTER \
    /srv/studio/LIBRARY_GLOBAL \
    /srv/studio/PROJECTS

# Set permissions
chmod -R 755 /srv/studio/BLENDER_APPS \
             /srv/studio/CONFIG_MASTER \
             /srv/studio/LIBRARY_GLOBAL \
             /srv/studio/PROJECTS
```

### Step 1.3 — Add the public key for studio-sync

```bash
# The .ssh dir must be inside the chroot and owned by root too
mkdir -p /srv/studio/.ssh
chown root:root /srv/studio/.ssh
chmod 755 /srv/studio/.ssh

# Create authorized_keys
touch /srv/studio/.ssh/authorized_keys
chown root:root /srv/studio/.ssh/authorized_keys
chmod 644 /srv/studio/.ssh/authorized_keys

# Paste the contents of studio_sync_key.pub into this file
nano /srv/studio/.ssh/authorized_keys
```

> **Note on chroot and .ssh ownership**: In a chroot setup, OpenSSH requires that `.ssh` and `authorized_keys` be owned by root (not the user), otherwise the server refuses the key. This is different from a normal SSH setup.

### Step 1.4 — Add the Match User block to sshd_config

```bash
# Backup first (your own documented rule)
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak-$(date +%Y%m%d)

# Append the Match block to the bottom of the main config
cat >> /etc/ssh/sshd_config << 'EOF'

Match User studio-sync
    ChrootDirectory /srv/studio
    ForceCommand internal-sftp
    AllowTcpForwarding no
    X11Forwarding no
EOF
```

**Keep a second PuTTY session open before restarting SSH.**

```bash
systemctl restart ssh

# Verify the service came back up
systemctl status ssh
```

### Step 1.5 — Verify SFTP works

On your Windows machine, PowerShell:

```powershell
sftp -i "$HOME\.ssh\studio_sync_key" -P 22 studio-sync@107.172.153.249
```

Expected output: an `sftp>` prompt. Run `ls` — you should see your folders. Run `exit`.

If this works, Phase 1 is done. If it fails, check `journalctl -u ssh -n 50` on the VPS for the error.

### Step 1.6 — Add logrotate for Nginx (housekeeping, per your VPS doc)

```bash
cat > /etc/logrotate.d/nginx-studio << 'EOF'
/var/log/nginx/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    sharedscripts
    postrotate
        nginx -s reopen 2>/dev/null || true
    endscript
}
EOF
```

---

## Phase 2 — Docker Image

**Goal**: Build a custom Docker image that fixes /workspace permissions, pulls files from the VPS on startup via rclone, and puts Blender on the desktop.

**Do this on your Windows machine with Docker Desktop.**

### Step 2.1 — Prepare your Docker Hub account

Log into hub.docker.com and confirm your username. You'll use it as `YOUR_DOCKERHUB_USERNAME` throughout.

### Step 2.2 — Review the image files

The two files that make up the image are in the `docker/` folder:
- `docker/Dockerfile`
- `docker/fix-workspace-and-start.sh`

Read both before building. The startup script references `107.172.153.249` as the VPS host — this is already correct.

### Step 2.3 — Build the image

Open PowerShell, navigate to the project root:

```powershell
cd path\to\nrr-studio-runpod

docker login

docker build -t YOUR_DOCKERHUB_USERNAME/nrr-studio:1.0 ./docker
```

The first build will take a while (downloading the base image). Subsequent rebuilds are fast because Docker caches layers.

Watch the output for any errors. Common issues:
- `curl: command not found` during rclone install → the base image may not have curl; add `apt-get install -y curl` before the rclone install line in the Dockerfile
- Permission errors during COPY → make sure the .sh file line endings are Unix (LF), not Windows (CRLF)

### Step 2.4 — Fix line endings if needed (Windows gotcha)

Windows sometimes saves shell scripts with CRLF line endings, which bash on Linux rejects with a cryptic `bad interpreter` error. Before building, run:

```powershell
# In PowerShell, convert line endings
(Get-Content "docker\fix-workspace-and-start.sh" -Raw) -replace "`r`n", "`n" | Set-Content "docker\fix-workspace-and-start.sh" -NoNewline
```

### Step 2.5 — Push to Docker Hub

```powershell
docker push YOUR_DOCKERHUB_USERNAME/nrr-studio:1.0
```

Confirm the tag appears at `hub.docker.com/r/YOUR_DOCKERHUB_USERNAME/nrr-studio`.

---

## Phase 3 — RunPod Template

**Goal**: Update the RunPod template to use the new image and inject the VPS SSH key.

### Step 3.1 — Base64-encode the private key

In PowerShell:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("$HOME\.ssh\studio_sync_key")) | Set-Clipboard
```

This copies the base64 string to clipboard. It will be a very long single line — that is correct.

### Step 3.2 — Update the RunPod template

In the RunPod console, open template `NRR_Cloud_Workstation` (ID: zjy0roc90x) and set:

| Field | Value |
|---|---|
| Container image | `YOUR_DOCKERHUB_USERNAME/nrr-studio:1.0` |
| HTTP ports | `6901` |
| TCP ports | `22` |
| Volume mount | `/workspace` |
| Environment variable: `VPS_SSH_KEY_B64` | (paste the base64 string from clipboard) |

Save the template.

### Step 3.3 — Launch a test pod

Deploy a new pod from the template. Choose any GPU. Wait for the pod to reach Running state (usually 1-2 minutes).

### Step 3.4 — Verify end-to-end

Open the browser desktop (port 6901). Open a terminal inside the desktop:

```bash
# Check /workspace is writable
whoami
ls -ld /workspace
touch /workspace/_write_test && echo "WRITE OK" || echo "WRITE FAILED"

# Check files arrived from VPS
ls /workspace/BLENDER_APPS/
ls /workspace/PROJECTS/

# Check Blender launches
/workspace/BLENDER_APPS/blender-app/blender --version
```

Check that the desktop shortcut for Blender appears and double-clicking it opens Blender.

### Step 3.5 — Verify sync back

Create a test file inside the pod:

```bash
touch /workspace/PROJECTS/sync_test_$(date +%s).txt
```

Wait 5 minutes, then check on the VPS:

```bash
ls /srv/studio/PROJECTS/
```

The file should appear. If it does, the full loop is working.

---

## Phase 4 — Upload Content to VPS Storage

Once the system is verified working, populate the VPS with your actual content.

### Upload Blender

Download the Linux x64 tarball from blender.org. Upload it to `/srv/studio/BLENDER_APPS/`:

```powershell
scp -i "$HOME\.ssh\YOUR_ADMIN_KEY" blender-4.x.x-linux-x64.tar.xz root@107.172.153.249:/srv/studio/BLENDER_APPS/
```

(Use your admin key here, not the studio_sync key.)

### Upload asset libraries

Upload the `botaniq` and `alpha_trees` folders to `/srv/studio/LIBRARY_GLOBAL/`.

### Upload addons

Upload addon zip files or folders to `/srv/studio/CONFIG_MASTER/scripts/addons/`.

---

## Rollback Plan

If anything goes wrong:

**VPS sshd_config broke**: `cp /etc/ssh/sshd_config.bak-YYYYMMDD /etc/ssh/sshd_config && systemctl restart ssh` via VNC if needed (see docs/VPS_REFERENCE.md section 5).

**Docker image broken**: The RunPod template can be reverted to the original base image `madiator2011/kasm-runpod-desktop:mldesk` instantly in the template editor.

**rclone sync wiped files**: rclone is configured with `copy` (not `sync --delete`) for everything except PROJECTS. A bad PROJECTS sync could overwrite VPS files — always keep a manual backup of PROJECTS on your local machine before major work sessions.
