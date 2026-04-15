# Initial Prompt for Claude Code

Copy and paste this entire message as your first message when you open the Claude Code session.

---

I am setting up a plug-and-play GPU workstation pipeline for my production studio (Nairoeel Productions) using RunPod for Blender work. Read CLAUDE.md first for the full project context, then read PLAN.md for the phased implementation steps.

Here is where we are right now and what I need you to help me execute:

**Already done (context only):**
- I have a RackNerd VPS running Ubuntu 24.04 with Coolify, Traefik, Nginx, and a File Browser. The VPS reference doc is in docs/VPS_REFERENCE.md.
- I have designed the architecture: files live on the VPS and are pulled into RunPod pods on startup via rclone over SFTP.
- The Docker image files are already written in docker/Dockerfile and docker/fix-workspace-and-start.sh.
- Port 22 is already open on the VPS iptables — no firewall changes needed.

**What I need you to do with me:**

Start with Phase 1 from PLAN.md. Walk me through each step interactively. For steps that require me to run commands on the VPS or on my Windows machine, show me exactly what to run and wait for me to confirm the output before moving to the next step. Do not skip ahead.

When we reach Phase 2 (Docker build), check the Dockerfile and startup script in the docker/ folder and flag anything that might fail on the base image `madiator2011/kasm-runpod-desktop:mldesk` before I build.

My Docker Hub username is: [FILL IN YOUR USERNAME]

Let's start with Step 1.1 from the plan — generating the rclone keypair on my Windows machine.
