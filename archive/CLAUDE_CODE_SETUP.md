# Claude Code Setup in VS Code

## Step 1 — Install the Claude Code extension

1. Open VS Code
2. Press `Ctrl+Shift+X` to open the Extensions panel
3. Search for **Claude Code**
4. Install the extension published by Anthropic
5. You will be prompted to sign in with your Anthropic account (the same one you use for Claude.ai)

Alternatively, install from the terminal:
```
code --install-extension anthropic.claude-code
```

## Step 2 — Open this project folder

1. In VS Code: File > Open Folder
2. Select the `nrr-studio-runpod/` folder you downloaded
3. VS Code will show the project tree on the left

## Step 3 — Open the Claude Code panel

Press `Ctrl+Shift+P` → type **Claude Code** → select **Claude Code: Open**

Or click the Claude icon in the left sidebar if it appeared after installation.

## Step 4 — Verify Claude reads your CLAUDE.md

Claude Code automatically reads `CLAUDE.md` from your project root when you open a session. You should see it acknowledge the project context in its first response. If it does not, type:

```
Please read CLAUDE.md and summarise the project for me.
```

## Step 5 — Start the project

Open `INITIAL_PROMPT.md`, copy the prompt text (everything below the horizontal line), and paste it into the Claude Code chat panel.

Fill in your Docker Hub username in the prompt before sending.

---

## How Claude Code works in this project

Claude Code can:
- Read all files in the project folder (CLAUDE.md, PLAN.md, docker files, etc.)
- Help you write and edit files
- Run terminal commands on your machine if you confirm them
- Walk you through the plan step by step

Claude Code cannot:
- SSH into your VPS directly (you do that yourself in PuTTY)
- Push to Docker Hub on your behalf (you run docker commands yourself in PowerShell)
- Access RunPod (you do that in the browser)

The workflow is: Claude Code tells you exactly what to run, you run it, you paste the output back, Claude Code confirms and moves to the next step.

---

## Project file reference

```
nrr-studio-runpod/
├── CLAUDE.md                   ← Claude Code reads this automatically (project memory)
├── PLAN.md                     ← Full phased implementation plan
├── INITIAL_PROMPT.md           ← Copy-paste this to start your Claude Code session
├── CLAUDE_CODE_SETUP.md        ← This file
├── docker/
│   ├── Dockerfile              ← The custom image definition
│   └── fix-workspace-and-start.sh  ← Startup script baked into the image
└── docs/
    └── VPS_REFERENCE.md        ← Your server documentation (converted from PDF)
```

---

## Tips for working with Claude Code on this project

**Be specific about where you are in the plan.** If you come back to a session after a break, start with:
> "I am on Step 2.3 of the plan. Here is what happened in the last session: [paste any relevant output]"

**Paste terminal output.** When Claude Code asks you to run something and report back, paste the full output — not just "it worked". This lets it catch subtle issues.

**If something unexpected happens**, describe it and ask Claude Code to diagnose before trying fixes. The VPS has iptables and sshd_config in play — random fixes can lock you out.

**Keep PuTTY open in the background** whenever you are making SSH config changes on the VPS. Per your own VPS reference doc: always have a second session open when restarting SSH.
