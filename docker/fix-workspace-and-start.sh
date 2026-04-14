#!/usr/bin/env bash
set -e

echo "[studio] ================================================"
echo "[studio] NRR Cloud Workstation startup"
echo "[studio] ================================================"

# ── 1. Fix /workspace permissions ────────────────────────────
echo "[studio] Fixing /workspace permissions..."
mkdir -p \
    /workspace/BLENDER_APPS \
    /workspace/CONFIG_MASTER/scripts/addons \
    /workspace/LIBRARY_GLOBAL \
    /workspace/PROJECTS

chown -R kasm-user:kasm-user /workspace || true
chmod -R 775 /workspace || true

# ── 2. Write SSH key from environment variable ────────────────
echo "[studio] Preparing SSH key for rclone..."

if [ -z "${VPS_SSH_KEY_B64}" ]; then
    echo "[studio] WARNING: VPS_SSH_KEY_B64 is not set. Skipping VPS sync."
    SKIP_SYNC=1
else
    echo "${VPS_SSH_KEY_B64}" | base64 -d > /run/studio_sync_key
    chmod 600 /run/studio_sync_key

    # Accept VPS host key automatically (first-connection workaround for non-interactive containers)
    mkdir -p /root/.ssh
    ssh-keyscan -p 22 107.172.153.249 >> /root/.ssh/known_hosts 2>/dev/null || true
    chmod 600 /root/.ssh/known_hosts

    SKIP_SYNC=0
fi

# ── 3. Write rclone config ────────────────────────────────────
if [ "${SKIP_SYNC}" = "0" ]; then
    echo "[studio] Writing rclone config..."
    mkdir -p /root/.config/rclone

    cat > /root/.config/rclone/rclone.conf << EOF
[vps]
type = sftp
host = 107.172.153.249
port = 22
user = studio-sync
key_file = /run/studio_sync_key
EOF

    # ── 4. Pull files from VPS ────────────────────────────────
    echo "[studio] Pulling BLENDER_APPS from VPS..."
    rclone copy vps:/BLENDER_APPS /workspace/BLENDER_APPS \
        --transfers=4 --stats=10s || echo "[studio] WARN: BLENDER_APPS sync had errors"

    echo "[studio] Pulling CONFIG_MASTER from VPS..."
    rclone copy vps:/CONFIG_MASTER /workspace/CONFIG_MASTER \
        --transfers=4 --stats=10s || echo "[studio] WARN: CONFIG_MASTER sync had errors"

    echo "[studio] Pulling LIBRARY_GLOBAL from VPS (this may take a while)..."
    rclone copy vps:/LIBRARY_GLOBAL /workspace/LIBRARY_GLOBAL \
        --transfers=8 --stats=10s || echo "[studio] WARN: LIBRARY_GLOBAL sync had errors"

    echo "[studio] Pulling PROJECTS from VPS..."
    rclone copy vps:/PROJECTS /workspace/PROJECTS \
        --transfers=4 --stats=10s || echo "[studio] WARN: PROJECTS sync had errors"
fi

# ── 5. Extract Blender if tarball present and not yet extracted ──
echo "[studio] Checking for Blender tarball..."
BLENDER_TAR=$(ls /workspace/BLENDER_APPS/blender-*.tar.xz 2>/dev/null | head -1)

if [ -n "$BLENDER_TAR" ] && [ ! -d /workspace/BLENDER_APPS/blender-app ]; then
    echo "[studio] Extracting Blender from ${BLENDER_TAR}..."
    tar -xf "$BLENDER_TAR" -C /workspace/BLENDER_APPS/
    BLENDER_DIR=$(ls -d /workspace/BLENDER_APPS/blender-*-linux-x64 2>/dev/null | head -1)
    if [ -n "$BLENDER_DIR" ]; then
        mv "$BLENDER_DIR" /workspace/BLENDER_APPS/blender-app
        echo "[studio] Blender extracted to /workspace/BLENDER_APPS/blender-app"
    fi
elif [ -d /workspace/BLENDER_APPS/blender-app ]; then
    echo "[studio] Blender already extracted."
else
    echo "[studio] No Blender tarball found in BLENDER_APPS/. Upload one to the VPS first."
fi

# Re-apply ownership after extraction
chown -R kasm-user:kasm-user /workspace/BLENDER_APPS || true

# ── 6. Create desktop shortcut ───────────────────────────────
echo "[studio] Setting up desktop shortcut..."
mkdir -p /home/kasm-user/Desktop

if [ -f /workspace/BLENDER_APPS/blender-app/blender ]; then
    ICON_PATH=/workspace/BLENDER_APPS/blender-app/blender.svg
    [ -f "$ICON_PATH" ] || ICON_PATH=blender  # fallback to system icon name

    cat > /home/kasm-user/Desktop/Blender.desktop << EOF2
[Desktop Entry]
Name=Blender
Exec=/workspace/BLENDER_APPS/blender-app/blender
Icon=${ICON_PATH}
Type=Application
Terminal=false
Categories=Graphics;3DGraphics;
EOF2
    chmod +x /home/kasm-user/Desktop/Blender.desktop
    chown kasm-user:kasm-user /home/kasm-user/Desktop/Blender.desktop
    echo "[studio] Desktop shortcut created."
else
    echo "[studio] Blender binary not found — shortcut not created."
fi

# ── 7. Start background project sync ─────────────────────────
if [ "${SKIP_SYNC}" = "0" ]; then
    echo "[studio] Starting background PROJECTS sync (every 5 minutes)..."
    (
        while true; do
            sleep 300
            rclone sync /workspace/PROJECTS vps:/PROJECTS \
                --transfers=4 2>/dev/null || true
        done
    ) &
    echo "[studio] Background sync PID: $!"
fi

echo "[studio] ================================================"
echo "[studio] Startup complete. Handing off to base image."
echo "[studio] ================================================"

# ── 8. Hand off to the base image's original startup ─────────
# If arguments were passed (e.g. CMD from base image), run them.
# Otherwise, start the kasm desktop default entrypoint.
if [ $# -gt 0 ]; then
    exec "$@"
else
    exec /dockerstartup/kasm_default_profile.sh /dockerstartup/vnc_startup.sh
fi
