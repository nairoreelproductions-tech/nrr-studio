# RackNerd VPS — Operations, Security & Recovery Reference

Brandon Maiywa | March 2026 | Private

---

## 1. Server Identity

| Detail | Value |
|---|---|
| Provider | RackNerd |
| Plan | Monthly KVM |
| RAM | 8 GB (3.5 GB usable after OS + services) |
| CPU | 6 cores |
| Disk | 220 GB SSD (~63 GB formatted) |
| Bandwidth | 5 TB/month |
| OS | Ubuntu 24.04 LTS |
| IP Address | 107.172.153.249 |
| Network | 1 Gbps port, dedicated IPv4 |
| Root Access | Yes |
| Management Panel | RackNerd client area (for VNC, reboots, reinstalls) |

---

## 2. What Is Running

The VPS runs everything through Docker, managed by Coolify. Traefik sits in front as the reverse proxy and handles TLS certificates. Do not restart or remove containers you did not create yourself.

### 2.1 Services and Domains

| Service | Access Point | Port(s) | Purpose |
|---|---|---|---|
| Coolify | coolify.nairoreelproductions.com | 8000 | Deployment dashboard for all services |
| Traefik v3.6.9 | (manages all routing) | 80, 443 | Reverse proxy, Let's Encrypt TLS |
| n8n | n8n.nairoreelproductions.com | 5678 | Workflow automation engine |
| PostgreSQL | localhost (proxied via nginx) | 5432 | n8n database |
| FileBrowser | sslip.io address (internal) | 80 (internal) | Serves /data/coolify/nairoreelmedia |
| Nginx | stream.nairoreelproductions.com | 80/443 | Streams client media from FileBrowser storage |
| Coolify Realtime (Soketi) | (internal) | 6001-6002 | Websockets for Coolify UI |
| Coolify Redis | (internal) | 6379 | Cache layer for Coolify |
| Coolify Sentinel | (internal) | — | Health monitoring |

### 2.2 All Docker Containers

These are the containers that should be running. If any go missing after a reboot, check the Coolify dashboard first.

| Container Name | What It Does |
|---|---|
| coolify | Coolify panel application |
| coolify-db | Coolify internal database |
| coolify-redis | Coolify cache |
| coolify-realtime | Coolify websocket server |
| coolify-proxy | Traefik reverse proxy |
| coolify-sentinel | Health monitoring agent |
| n8n-* | n8n workflow automation |
| postgresql-* | n8n database |
| filebrowser-* | File browser for media |
| vskkc0c8ggk4cos0wk0wc448 | Laravel application |
| vskkc0c8ggk4cos0wk0wc448-proxy | Laravel app proxy |
| as8s8ksgwo40sccgss8gk0cc-* | Additional service |

---

## 3. Network and Firewall

No UFW installed. Firewall rules run through iptables directly. The default policy is DROP, which means anything not explicitly allowed gets blocked.

### 3.1 Open Ports

| Port | Purpose |
|---|---|
| 22 | SSH (key-only, password disabled) |
| 80 | HTTP (Traefik redirects to 443) |
| 443 | HTTPS (Traefik with Let's Encrypt) |
| RELATED/ESTABLISHED | Return traffic for existing connections |

> Do not add or remove iptables rules unless you know what you are doing. If you lock yourself out of port 22, your only way back in is VNC through the RackNerd panel.

### 3.2 fail2ban

fail2ban is running with an active sshd jail. It watches for repeated failed login attempts and temporarily bans the source IP. With password auth now disabled, most brute-force attempts will fail before fail2ban even needs to act, but it is an extra layer worth keeping.

---

## 4. SSH Access

Password login is disabled. The only way to SSH into this server is with the Ed25519 key pair created in March 2026.

### 4.1 Current Configuration

| Setting | Value |
|---|---|
| Auth method | Ed25519 public/private key pair |
| Passphrase | Yes (set during key generation) |
| Key format | .ppk (PuTTY native) |
| PasswordAuthentication | no |
| KbdInteractiveAuthentication | no |
| PermitRootLogin | yes |
| SSH service name | ssh (not sshd, Ubuntu 24 convention) |
| Port | 22 |
| ClientAliveInterval | 60 seconds |
| ClientAliveCountMax | 120 |
| Config file | /etc/ssh/sshd_config |
| Config backup | /etc/ssh/sshd_config.bak |
| Drop-in override | /etc/ssh/sshd_config.d/50-cloud-init.conf (also set to no) |
| Authorized keys | /root/.ssh/authorized_keys |

> **Ubuntu 24.04 gotcha**: The file `/etc/ssh/sshd_config.d/50-cloud-init.conf` loads after sshd_config and overrides it. If you ever change password auth in the main config, check the drop-in file too or your change will have no effect. Both files must say `PasswordAuthentication no`.

### 4.2 How to Connect

Open PuTTY:

1. Session tab: Host Name = `107.172.153.249`, Port = `22`, Connection type = SSH
2. Connection > SSH > Auth > Credentials: browse to your .ppk file
3. Click Open. Enter `root` as the login username.
4. Enter your passphrase when prompted.

Save this as a PuTTY session (Session tab > type a name > Save) so you do not have to configure it every time.

### 4.3 Where the Key Lives

- **Private key (.ppk)**: On your Windows machine. Guard it. If you lose it and have no backup, you will need VNC to get back in.
- **Public key**: On the server at `/root/.ssh/authorized_keys`.

Keep a copy of the .ppk file on a USB drive or a second machine.

---

## 5. Emergency Access and Recovery

If you lose SSH access — lost key file, misconfigured firewall rule, botched sshd_config — VNC is your fallback. It bypasses SSH entirely.

### 5.1 VNC Access via RackNerd Panel

1. Log into the RackNerd client area.
2. Find your VPS in the service list and open the management page.
3. Click the VNC / Console button.
4. Log in as root with the root password set when you first provisioned the VPS (not the SSH passphrase — the original server password).
5. From here you can fix whatever broke.

### 5.2 Common Recovery Scenarios

**Lost the .ppk file:**
```bash
# VNC in, then re-enable password auth temporarily
sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
systemctl restart ssh
# SSH in with the root password, generate a new key, disable password auth again
```

**Locked out by iptables:**
```bash
# VNC in, then flush the rules and re-add the correct ones
iptables -F
iptables -P INPUT ACCEPT
# Then re-apply your rules for ports 22, 80, 443 and set policy back to DROP
```

**Broke sshd_config:**
```bash
# VNC in, restore the backup
cp /etc/ssh/sshd_config.bak /etc/ssh/sshd_config
systemctl restart ssh
```

**Server unresponsive (cannot even VNC):**
Use the RackNerd panel to force a hard reboot. If that does not help, open a support ticket with RackNerd.

---

## 6. Automated Maintenance (Already Running)

Configured in March 2026 during initial hardening. These need no attention unless something breaks.

| What Happens | How | Where to Check |
|---|---|---|
| Journal logs capped at 200 MB | systemd-journald | /etc/systemd/journald.conf |
| Journal logs older than 2 weeks deleted | systemd-journald | /etc/systemd/journald.conf |
| Docker container logs capped at 30 MB each | Docker daemon config | /etc/docker/daemon.json |
| Unused Docker images + volumes pruned | Cron job, every Sunday 3 AM | crontab -l |
| Security patches auto-applied | unattended-upgrades | Built into Ubuntu |

---

## 7. Manual Cleanup (Every 2-3 Months)

Do it when the server feels slow, or when you see any of these warning signs:
- Memory usage above 70% (`free -h`)
- Swap usage above 0% for an extended period
- Disk usage above 50% on /dev/vda2 (`df -h`)

### 7.1 Check Current State

```bash
free -h && df -h && docker system df && journalctl --disk-usage
```

What to look for: Memory above 70% or swap above 0% is a warning. Disk on /dev/vda2 approaching 60% needs attention.

### 7.2 Clean Docker Waste

```bash
docker image prune -f
docker volume prune -f
```

> `docker volume prune` only removes volumes with no container attached — safe to run. Do NOT run `docker system prune -a` or `docker image prune -a`. Those remove all unused images including ones Coolify needs for redeployments.

### 7.3 Clear APT Cache

```bash
apt-get clean
```

### 7.4 Reboot

```bash
reboot
```

Wait 30-60 seconds, then SSH back in. The reboot clears all swap, applies pending kernel updates, and gives all Docker containers a clean restart. No data is lost.

### 7.5 Verify After Reboot

```bash
free -h && df -h
```

Healthy state: Memory below 50%, swap at 0%, disk below 40%.

### 7.6 Copy-Paste Quick Reference

```bash
# Diagnose
free -h && df -h && docker system df && journalctl --disk-usage

# Clean
docker image prune -f && docker volume prune -f && apt-get clean

# Reboot
reboot

# Verify (after SSH back in)
free -h && df -h
```

---

## 8. SSH Configuration Reference

### 8.1 sshd_config Key Settings

Settings live in two places. The main file is `/etc/ssh/sshd_config`. The drop-in file `/etc/ssh/sshd_config.d/50-cloud-init.conf` loads after it and overrides anything it redefines. Both must agree.

| Directive | Value |
|---|---|
| PermitRootLogin | yes |
| PasswordAuthentication | no (set in BOTH main config AND 50-cloud-init.conf) |
| KbdInteractiveAuthentication | no |
| Port | 22 |
| ClientAliveInterval | 60 |
| ClientAliveCountMax | 120 |

### 8.2 Restarting SSH

```bash
systemctl restart ssh
```

Always keep a second PuTTY session open when you restart SSH. If the new config is broken, your existing session is still alive and you can revert.

### 8.3 Re-enabling Password Auth (Temporary)

You need to change it in both files:

```bash
sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config.d/50-cloud-init.conf
systemctl restart ssh

# Do what you need to do, then disable it again in BOTH files:
sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config.d/50-cloud-init.conf
systemctl restart ssh
```

---

## 9. Things Not to Touch

| Do Not | Why |
|---|---|
| Remove or restart coolify-proxy | This is Traefik. If it goes down, all your domains stop resolving and TLS breaks. |
| Run `docker system prune -a` | This removes images Coolify needs. Redeploying services after this is painful. |
| Modify iptables without a VNC fallback | One wrong rule and you lose SSH access. VNC is your only recovery path. |
| Edit /etc/ssh/sshd_config without a backup | A syntax error locks you out. Always cp the file first. |
| Delete anything in /data/coolify/ | This is where Coolify stores all deployment data, volumes, and configs. |
| Uninstall fail2ban | It is lightweight and catches automated scans even with key-only auth. |

---

## 10. Useful Commands Cheat Sheet

| What You Want | Command |
|---|---|
| See all running containers | `docker ps` |
| See all containers including stopped | `docker ps -a` |
| Check disk usage | `df -h` |
| Check memory and swap | `free -h` |
| Check Docker disk usage | `docker system df` |
| Check journal log size | `journalctl --disk-usage` |
| View logs for a container | `docker logs <container_name> --tail 100` |
| Follow live logs | `docker logs <container_name> -f` |
| Restart a container | `docker restart <container_name>` |
| Check SSH service status | `systemctl status ssh` |
| Check fail2ban status | `fail2ban-client status sshd` |
| View iptables rules | `iptables -L -n --line-numbers` |
| Check cron jobs | `crontab -l` |
| View sshd_config | `cat /etc/ssh/sshd_config` |
| Check who is logged in | `w` |
| Check uptime | `uptime` |
| Check last logins | `last -20` |

---

*Keep this file alongside your .ppk key file. Both are essential to server access.*
