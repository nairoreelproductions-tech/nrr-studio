#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# NRR Cloud Workstation — INTERNAL USER BOOTSTRAP
# Run this inside the VNC/Moonlight terminal as 'user'
# ─────────────────────────────────────────────────────────────
set -euo pipefail

# ── CONFIGURATION ────────────────────────────────────────────
# Since we are running as 'user', we use the actual home path.
STUDIO_ROOT="$HOME/studio"
DESKTOP_DIR="$HOME/Desktop"
VPS_HOST="107.172.153.249"
VPS_USER="studio-sync"
LOG="$STUDIO_ROOT/bootstrap.log"

mkdir -p "$STUDIO_ROOT"
mkdir -p "$DESKTOP_DIR"

log() { echo "[nrr] $(date '+%H:%M:%S') $*" | tee -a "$LOG"; }

log "========================================"
log "Running Internal Setup as: $(whoami)"
log "========================================"

# ── SECTION 1: Install Tools (Needs sudo once) ───────────────
if ! command -v rclone &>/dev/null; then
    log "Installing rclone (System password may be required)..."
    sudo curl -fsSL https://rclone.org/install.sh | sudo bash
fi

# ── SECTION 2: SSH Keys (Stored in User Home) ────────────────
# We store keys in /home/user/.ssh so the user owns them.
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

if [ -z "${VPS_SSH_KEY_B64:-}" ]; then
    log "ERROR: Paste your VPS_SSH_KEY_B64 into the terminal before running, or edit this script."
    exit 1
fi

echo "$VPS_SSH_KEY_B64" | base64 -d > "$HOME/.ssh/studio_sync_key"
chmod 600 "$HOME/.ssh/studio_sync_key"
ssh-keyscan -p 22 "$VPS_HOST" >> "$HOME/.ssh/known_hosts" 2>/dev/null || true

# ── SECTION 3: Rclone Config (User-Specific) ─────────────────
mkdir -p "$HOME/.config/rclone"
cat > "$HOME/.config/rclone/rclone.conf" << EOF
[vps]
type = sftp
host = $VPS_HOST
port = 22
user = $VPS_USER
key_file = $HOME/.ssh/studio_sync_key
EOF

# ── SECTION 4: Data Pull (Absolute VPS Paths) ───────────────
log "Pulling data from VPS /srv/studio/..."
mkdir -p "$STUDIO_ROOT/PROJECTS" "$STUDIO_ROOT/BLENDER_APPS" "$STUDIO_ROOT/LIBRARY_GLOBAL" "$STUDIO_ROOT/CONFIG_MASTER"

# No more 'root' ownership—user creates these directly.
rclone copy vps:../../srv/studio/PROJECTS "$STUDIO_ROOT/PROJECTS" --transfers=8 --stats=10s
rclone copy vps:../../srv/studio/BLENDER_APPS "$STUDIO_ROOT/BLENDER_APPS" --transfers=4
rclone copy vps:../../srv/studio/LIBRARY_GLOBAL "$STUDIO_ROOT/LIBRARY_GLOBAL" --transfers=16
rclone copy vps:../../srv/studio/CONFIG_MASTER "$STUDIO_ROOT/CONFIG_MASTER" --transfers=4

# ── SECTION 5: Blender 4.5.7 Setup ──────────────────────────
log "Setting up Blender 4.5.7..."
BLENDER_TAR=$(ls "$STUDIO_ROOT/BLENDER_APPS/blender-4.5.7"*.tar.xz 2>/dev/null | head -1 || true)

if [ -n "$BLENDER_TAR" ]; then
    if [ ! -d "$STUDIO_ROOT/BLENDER_APPS/blender-app" ]; then
        tar -xf "$BLENDER_TAR" -C "$STUDIO_ROOT/BLENDER_APPS/"
        EXTRACTED_DIR=$(ls -d "$STUDIO_ROOT/BLENDER_APPS/blender-4.5.7"*linux* 2>/dev/null | head -1)
        mv "$EXTRACTED_DIR" "$STUDIO_ROOT/BLENDER_APPS/blender-app"
    fi

    # Create shortcut on the Desktop you are currently looking at
    cat > "$DESKTOP_DIR/Blender-Studio.desktop" << EOF
[Desktop Entry]
Name=Blender 4.5.7 (Studio)
Exec=$STUDIO_ROOT/BLENDER_APPS/blender-app/blender %f
Icon=$STUDIO_ROOT/BLENDER_APPS/blender-app/blender.svg
Type=Application
Terminal=false
EOF
    chmod +x "$DESKTOP_DIR/Blender-Studio.desktop"
fi

log "========================================"
log "BOOTSTRAP COMPLETE: You are the owner!"
log "========================================"
