FROM debian:buster

ENV DEBIAN_FRONTEND=noninteractive

# Install essential build tools and pi-gen dependencies
RUN apt-get update && \
    apt-get install -y \
        # Build essentials
        git vim nano curl wget \
        build-essential \
        # pi-gen requirements
        parted quilt coreutils qemu-user-static debootstrap zerofree \
        zip dosfstools bsdtar libcap2-bin rsync grep udev xz-utils \
        xxd file kmod bc binfmt-support \
        # Docker client for building images
        apt-transport-https ca-certificates gnupg lsb-release \
        # Development tools
        sudo bash-completion tree htop \
    && rm -rf /var/lib/apt/lists/*

# Install Docker CLI
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" \
    | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    apt-get install -y docker-ce-cli && \
    rm -rf /var/lib/apt/lists/*

# Create vscode user with sudo privileges
RUN useradd -m -s /bin/bash -u 1000 vscode && \
    echo "vscode ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Set up binfmt for ARM emulation
RUN update-binfmts --enable

WORKDIR /workspace

# Keep container running
CMD ["sleep", "infinity"]
