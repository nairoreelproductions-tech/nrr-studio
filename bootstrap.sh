#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# NRR Cloud Workstation — FINAL WRITABLE BOOTSTRAP
# Optimized for: Full Write Access, Blender 4.5.7, and Auto-Sync.
# ─────────────────────────────────────────────────────────────
set -euo pipefail

# ── CONFIGURATION ────────────────────────────────────────────
# We detect the GUI user (usually 'ubuntu') to ensure write access.
GUI_USER=$(logname 2>/dev/null || echo "ubuntu")
STUDIO_ROOT="/home/$GUI_USER/studio"
DESKTOP_DIR="/home/$GUI_USER/Desktop"
VPS_HOST="107.172.153.249"
VPS_USER="studio-sync"
LOG="$STUDIO_ROOT/bootstrap.log"

# ── INITIALIZATION ───────────────────────────────────────────
mkdir -p "$STUDIO_ROOT"
mkdir -p "$DESKTOP_DIR"
log() { echo "[nrr] $(date '+%H:%M:%S') $*" | tee -a "$LOG"; }

log "========================================"
log "NRR Studio bootstrap: WRITABLE MODE"
log "========================================"

# ── SECTION 1-2: Tools & Connectivity ────────────────────────
if ! command -v rclone &>/dev/null; then
    log "Installing rclone..."
    curl -fsSL https://rclone.org/install.sh | sudo bash
fi

# We keep the SSH keys in /root so the background Cron job can use them.
mkdir -p "/root/.ssh"
echo "${VPS_SSH_KEY_B64:-}" | base64 -d > "/root/.ssh/studio_sync_key" || { log "ERROR: Key missing"; exit 1; }
chmod 600 "/root/.ssh/studio_sync_key"

mkdir -p "/root/.config/rclone"
cat > "/root/.config/rclone/rclone.conf" << EOF
[vps]
type = sftp
host = $VPS_HOST
port = 22
user = $VPS_USER
key_file = /root/.ssh/studio_sync_key
EOF

# ── SECTION 3: Workspace Construction ────────────────────────
log "Building workspace in $STUDIO_ROOT..."
mkdir -p "$STUDIO_ROOT/BLENDER_APPS" \
         "$STUDIO_ROOT/PROJECTS" \
         "$STUDIO_ROOT/LIBRARY_GLOBAL" \
         "$STUDIO_ROOT/CONFIG_MASTER"

log "Syncing PROJECTS and BLENDER from VPS..."
rclone copy vps:/PROJECTS "$STUDIO_ROOT/PROJECTS" --transfers=8 --stats=10s
rclone copy vps:/BLENDER_APPS "$STUDIO_ROOT/BLENDER_APPS" --transfers=4

# ── SECTION 4: Blender 4.5.7 & Visible Shortcut ──────────────
log "Installing Blender 4.5.7 LTS..."
BLENDER_TAR=$(ls "$STUDIO_ROOT/BLENDER_APPS/blender-4.5.7"*.tar.xz 2>/dev/null | head -1 || true)

if [ -n "$BLENDER_TAR" ]; then
    if [ ! -d "$STUDIO_ROOT/BLENDER_APPS/blender-app" ]; then
        tar -xf "$BLENDER_TAR" -C "$STUDIO_ROOT/BLENDER_APPS/"
        EXTRACTED_DIR=$(ls -d "$STUDIO_ROOT/BLENDER_APPS/blender-4.5.7"*linux* 2>/dev/null | head -1)
        mv "$EXTRACTED_DIR" "$STUDIO_ROOT/BLENDER_APPS/blender-app"
    fi

    # Create Shortcut specifically for the GUI Desktop
    cat > "$DESKTOP_DIR/Blender-Studio.desktop" << EOF
[Desktop Entry]
Name=Blender 4.5.7 (Studio)
Exec=$STUDIO_ROOT/BLENDER_APPS/blender-app/blender %f
Icon=$STUDIO_ROOT/BLENDER_APPS/blender-app/blender.svg
Type=Application
Terminal=false
EOF
    chmod +x "$DESKTOP_DIR/Blender-Studio.desktop"
    log "Desktop shortcut created for $GUI_USER."
fi

# ── SECTION 5: THE "OWNERSHIP" FIX ───────────────────────────
log "FIXING PERMISSIONS: Transferring ownership to $GUI_USER..."
# This command tells Linux: "The root user no longer owns these files; the GUI user does."
chown -R "$GUI_USER:$GUI_USER" "$STUDIO_ROOT"
chown -R "$GUI_USER:$GUI_USER" "$DESKTOP_DIR"

# Ensure all folders are writable and searchable by the user
chmod -R 775 "$STUDIO_ROOT"
log "Permissions updated. Directory is now fully writable."

# ── SECTION 6: Background Sync (Updated Paths) ───────────────
# The cron job runs as root, so it can still access the user's studio folder to sync back.
CRON_CMD="rclone sync $STUDIO_ROOT/PROJECTS vps:/PROJECTS --transfers=4 2>>$LOG"
(crontab -l 2>/dev/null | grep -v "vps:/PROJECTS" ; echo "*/5 * * * * $CRON_CMD") | crontab -

log "========================================"
log "SUCCESS: Workspace is ready and writable!"
log "========================================"
