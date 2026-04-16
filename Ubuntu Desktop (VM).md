Ubuntu Desktop (VM)
► Create an Instance

What is this template?
This template gives you a full Ubuntu desktop environment with KDE Plasma running in a virtual machine. Access hardware-accelerated graphics and audio directly through your web browser, or connect via SSH, VNC, or streaming protocols. It comes with gaming, development, and creative software pre-installed.

Think: "Your own high-powered Linux desktop workstation in the cloud with GPU acceleration and remote access from anywhere."

Note: This is a full virtual machine with complete system access and a graphical desktop environment. Also consider the Linux Desktop Container template if your applications can run in a Docker container.

What can I do with this?
Full desktop environment with KDE Plasma accessible via web browser
Gaming platform with Steam and Proton for Windows game compatibility
3D creation and rendering with Blender and GPU acceleration
Development environment with browsers, Docker, and complete Linux toolchain
Game streaming with Sunshine/Moonlight for low-latency remote gaming
Windows application compatibility through Wine
Secure networking with Tailscale and Cloudflare tunnels
Multiple access methods - browser, VNC, SSH, streaming protocols
Who is this for?
This is perfect if you:

Need a full desktop environment with GPU acceleration in the cloud
Want to game remotely with high-performance streaming
Are doing 3D modeling, rendering, or creative work requiring GPU power
Need to run Windows applications through Wine compatibility
Want multiple ways to access your desktop (browser, mobile, VNC clients)
Are developing applications that require GUI testing or desktop environments
Need a powerful remote workstation accessible from any device
Quick Start Guide
Step 1: Launch Your Desktop
Click the Rent button when you've found an instance that works for you

Step 2: Choose Your Access Method
For browser desktop: Click the "Open" button to access the Instance Portal with desktop viewers
For SSH terminal: Connect via ssh -p mapped_port root@instance_ip
For VNC client: Connect to instance_ip:mapped_port using port 5900
💡 Multiple Options: The Instance Portal provides easy access to both Selkies WebRTC and NoVNC browser-based desktops, plus tunnel management for secure sharing.

💡 HTTPS Option: Want secure connections? Set ENABLE_HTTPS=true in the Environment Variables section of your Vast.ai account settings page. You'll need to install the Vast.ai certificate to avoid browser warnings. If you don't enable HTTPS, we'll try to redirect you to a temporary secure Cloudflare link (though availability is occasionally limited).

Step 3: Start Creating!
Full KDE Plasma desktop ready for immediate use
GPU acceleration available for gaming, rendering, and computing
Pre-installed software including Steam, Blender, browsers, and development tools
Key Features
Desktop Environment
KDE Plasma desktop with hardware-accelerated graphics and audio
Auto-login configuration for immediate access
Multiple display and resolution options
Full Linux desktop experience in your browser
Multiple Access Methods
Method	Best For	Port	What You Get
Instance Portal	Easy browser access	1111	Dashboard with desktop viewers and tunnel management
Selkies WebRTC	Low-latency browser desktop	6100	Hardware-accelerated browser desktop
Guacamole Client	Universal browser access	6200	Compatible browser-based desktop
VNC Client	Native desktop apps	5900	Connect with any VNC client application
SSH	Terminal access	22	Full command-line access
Moonlight Streaming	Gaming/low-latency	Tailscale	High-performance game streaming
Instance Portal Dashboard
Secure authentication with automatic login via "Open" button
Application management with easy access to all desktop viewers
Cloudflare tunnels for instant HTTPS sharing without port forwarding
Live log monitoring for all running services
Tunnel management for secure remote access
Gaming Platform
Steam with full gaming library access
Proton compatibility for Windows games on Linux
Sunshine streaming server for low-latency game streaming to mobile devices
Moonlight client support for streaming to phones, tablets, laptops
Hardware acceleration for optimal gaming performance
Creative Software
Blender for 3D modeling, animation, and rendering
GPU-accelerated rendering for fast viewport and final renders
Professional 3D creation suite ready for immediate use
Video editing and compositing capabilities
Development Environment
Docker Engine with GPU support for containerized development
Firefox and Chrome browsers for web development and testing
Complete Linux toolchain for any development needs
Wine compatibility for Windows development tools
Application Compatibility
Wine for running Windows applications on Linux
Comprehensive software compatibility - check WineHQ database
Legacy application support for older Windows software
Cross-platform development capabilities
Secure Networking
Tailscale Integration
Private networking without exposing additional ports
Peer-to-peer connections for secure team collaboration
Essential for Moonlight streaming setup
Setup: sudo tailscale up and follow prompts
Cloudflare Tunnels
Instant HTTPS access to any application
No port forwarding or firewall configuration needed
Temporary sharing links for collaboration
Managed through the Instance Portal dashboard
Port Configuration
SSH (22): Terminal access
Instance Portal (1111): Web dashboard and authentication
TURN Server (3478): WebRTC connectivity
VNC (5900): Desktop client connections
Selkies (6100): WebRTC browser desktop
Guacamole (6200): VNC browser desktop
Tailscale (741641): Private networking
Customization Tips
Desktop Configuration
# Install additional desktop software
apt update && apt install -y your-desktop-app


### **Development Environment**
```bash
# Docker with GPU support
docker run --gpus all your-development-image

# Install development tools
apt install -y build-essential git nodejs python3-pip
3D Rendering and Creative Work
# Blender available in applications menu
# GPU rendering automatically configured

# Install additional creative software
apt install -y gimp inkscape kdenlive
Network Configuration
# Set up Tailscale for private access
sudo tailscale up

# Access Instance Portal for tunnel management
# Click "Open" button or navigate to instance_ip:1111
Important Notes
Authentication
Desktop Username: user
Desktop Password: password
Instance Portal access: Automatic via "Open" button or manual with credentials
Username: vastai
Password: Your OPEN_BUTTON_TOKEN environment variable
VNC password: Same as OPEN_BUTTON_TOKEN unless VNC_PASSWORD is set
You will usually not need to use the OPEN_BUTTON_TOKEN to authenticate as this is passed automatically when you first access the instance. If you do need it then open a termionmal session and type:

echo $OPEN_BUTTON_TOKEN
Alternatively, from the instance logs button 'Extra Debug Logs' tab, appy a search filter for the text TOKEN

💡 Change the desktop password: You can use the passwd command to change the desktop password after the first login

TLS Certificate Setup
Avoid browser warnings: Install the Vast.ai certificate following our setup guide
Secure connections: All Instance Portal access uses TLS encryption
Gaming and Streaming
Moonlight streaming: Requires Tailscale network setup
Steam gaming: Enable Proton in Steam settings for Windows game compatibility
Performance optimization: GPU acceleration automatically configured
Software Installation
Pre-installed applications: Available in KDE applications menu
Additional software: Install via apt or application-specific installers
Wine applications: Install Windows software through Wine configuration
Pre-installed Software
Desktop and Utilities
KDE Plasma desktop environment
Firefox and Chrome web browsers
File managers and system utilities
Gaming and Entertainment
Steam gaming platform with Proton support
Sunshine streaming server for Moonlight
Audio and video playback capabilities
Development and Creative
Docker with GPU support
Blender 3D creation suite
Wine Windows compatibility layer
Git and essential development tools
Networking and Remote Access
Tailscale for private networking
Instance Portal with Cloudflare tunnel support
Multiple VNC and WebRTC servers
