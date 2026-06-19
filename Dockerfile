# Pi Agent — Dockerized local coding agent
# Restricted container with bash-only access for sandboxed operation

FROM node:22-slim

# Install only essential tools — bash, git, core unix utils
# Intentionally NO python, NO curl, NO web tools (matching author's security posture)
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    git \
    ca-certificates \
    jq \
    tree \
    ripgrep \
    && rm -rf /var/lib/apt/lists/*

# Install pi globally
RUN npm install -g @earendil-works/pi-coding-agent@0.79.6

# Create non-root user for safety
RUN useradd -m -s /bin/bash piuser

# Pi config and session dirs — create before switching user
RUN mkdir -p /home/piuser/.pi/agent/sessions && \
    chown -R piuser:piuser /home/piuser/.pi

USER piuser

# Working directory — workspace gets mounted here
WORKDIR /workspace

ENTRYPOINT ["pi"]
