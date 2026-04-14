FROM madiator2011/kasm-runpod-desktop:mldesk

USER root

# Ensure curl and ssh tools are available, then install rclone
RUN apt-get update && apt-get install -y --no-install-recommends curl openssh-client \
    && rm -rf /var/lib/apt/lists/*
RUN curl https://rclone.org/install.sh | bash

# Copy and register the startup wrapper
COPY fix-workspace-and-start.sh /usr/local/bin/fix-workspace-and-start.sh
RUN chmod +x /usr/local/bin/fix-workspace-and-start.sh

ENTRYPOINT ["/usr/local/bin/fix-workspace-and-start.sh"]
