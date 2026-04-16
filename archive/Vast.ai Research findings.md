## NRR Cloud Workstation — Architecture Evolution Report

---

### 1. Project Background & Initial Goal
The objective was to create a **plug-and-play cloud GPU workstation** system. Key requirements included:
* On-demand machine provisioning.
* Pre-configured Blender environment.
* Seamless file synchronization with a central VPS (Source of Truth).
* Low-latency remote access for interactive 3D work (lookdev).

---

### 2. Phase 1 — Analysis of the Container Approach (RunPod)
The initial implementation focused on Docker containers. While successful in engineering a complex stack, it revealed fundamental infrastructure mismatches.

| Feature | Outcome |
| :--- | :--- |
| **Graphics** | GPU-enabled Blender (Vulkan + VirtualGL) worked but was fragile. |
| **Streaming** | KasmVNC/WebRTC provided access but hit latency ceilings (200–400ms). |
| **Networking** | Limited UDP support and missing `/dev` access (tun/uinput) hindered optimized streaming. |

**Key Insight:** Containers are ideal for **batch compute (rendering)**, but persistent **Virtual Machines (VMs)** are superior for **real-time workstations**.

---

### 3. Phase 2 — Strategic Pivot to Vast.ai VMs
Shifting from Docker to the **Vast.ai Ubuntu VM template** solves the core limitations:
* **Full OS Access:** No kernel restrictions; direct access to hardware devices.
* **Native GPU Performance:** No need for VirtualGL; direct NVENC support for streaming.
* **Networking:** Full UDP support allowing for high-performance protocols like Sunshine/Moonlight.
* **Persistence:** Stable environment for workstation-specific configurations.

---

### 4. Technical Architecture: The Three-Layer Model
The system is divided into three distinct functional layers:

1.  **Lookdev Layer (Interactive):** User laptop connects via Moonlight/Sunshine or WebRTC to a Vast.ai VM.
2.  **Rendering Layer (Batch):** VPS triggers high-density render jobs on RunPod instances.
3.  **Storage Layer (Source of Truth):** A central VPS managing all project files, assets, and configurations.

---

### 5. Automation & Provisioning Strategy
To ensure machines are disposable but environments are reproducible, a **Modular Bootstrap System** is employed.

#### Script Distribution
* **Logic Layer (GitHub):** The bootstrap script and modules are hosted on a public or private GitHub repository for global accessibility and version control.
* **Data Layer (VPS):** Assets, projects, and Blender configurations reside on the VPS.
* **Secret Layer (Runtime Injection):** Sensitive data (SSH keys, IPs) is never stored in code; it is injected at runtime.

#### Runtime Secret Injection (The "Laptop-as-Control-Center" Model)
Instead of storing credentials on GitHub or in a disk image, secrets are passed via environment variables during the initial SSH session.

**Recommended Workflow:**
1.  **Local Storage:** Keep a `.env` file or local script on your laptop containing the VPS SSH key (base64) and server details.
2.  **Initialization:** SSH into the new VM and export the variables.
3.  **Execution:** Run the bootstrap via a one-line command:
    `curl -sL https://github.com/path/to/bootstrap.sh | bash`

---

### 6. The Sync Engine (rclone)
The file system uses a "State Hydration" model. Compute nodes are ephemeral; data is permanent.

* **Startup:** The VM "hydrates" by pulling the latest configs and project files from the VPS.
* **Ongoing:** A background sync process (cron or loop) pushes changes back to the VPS.
* **Structure:** Maintain mirrored paths (e.g., `/workspace/PROJECTS` on VM matches `/srv/studio/PROJECTS` on VPS).

---

### 7. Evaluation of Streaming Options
There is a trade-off between deployment speed and performance quality.

#### Option A: WebRTC (Vast.ai GLX Template)
* **Best for:** Rapid setup and light-to-medium lookdev.
* **Pros:** Zero setup; browser-based; ~50–100ms latency.
* **Cons:** Higher input lag; potential visual artifacts; less "native" feel.

#### Option B: Sunshine + Moonlight (Advanced VM)
* **Best for:** Professional animation, sculpting, and precision work.
* **Pros:** Near-local latency (20–60ms); production-grade stability.
* **Cons:** Higher initial setup complexity.

---

### 8. Key Findings & Best Practices
* **Fail Early:** Build the bootstrap script to stop immediately if the GPU is not detected.
* **Idempotency:** Scripts must be safe to run multiple times without creating duplicate installs.
* **Modular Design:** Separate the script into modules (GPU setup, Blender install, Sync config) for easier debugging.
* **Stateless Workstations:** Treat the VM as a disposable tool. If it breaks, kill it and run the script on a new one.