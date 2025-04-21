FROM ubuntu:24.04

# Avoid prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Create scripts directory and copy setup scripts
COPY scripts /home/ubuntu/setup
RUN chown -R ubuntu:ubuntu /home/ubuntu/setup && \
    chmod +x /home/ubuntu/setup/*.sh

# Install required packages
RUN apt-get update && \
    apt-get install -y curl wget git vim sudo && \
    ./scripts/bitcoind_setup.sh && \
    ./scripts/litd_setup.sh && \
    ./scripts/litd_setup2a.sh && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create ubuntu user with sudo rights
# RUN useradd -m -s /bin/bash ubuntu && \
RUN usermod -aG sudo ubuntu && \
    echo "ubuntu ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ubuntu && \
    chmod 0440 /etc/sudoers.d/ubuntu

# Set the user
USER ubuntu
WORKDIR /home/ubuntu

CMD ["/bin/bash"] 