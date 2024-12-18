#!/bin/bash

# litd Installation Script for Ubuntu
# This script automates the installation and configuration of Lightning Terminal (litd)

set -e  # Exit immediately if a command exits with a non-zero status

# Variables
LITD_DIR="$HOME/litd"
LIT_CONF_DIR="$HOME/.lit"
LIT_CONF_FILE="$LIT_CONF_DIR/lit.conf"
GIT_REPO="https://github.com/lightninglabs/lightning-terminal.git"
GO_VERSION="1.21.0"
NODE_VERSION="18.x"  # Ensure an even-numbered, stable release
LITD_VERSION="v0.13.6-alpha"  # Version of litd to be installed

# Functions
function print_info {
    echo -e "[+] $1"
}

function print_success {
    echo -e "[+] $1"
}

function print_error {
    echo -e "[!] $1" >&2
}

function install_dependencies {
    print_info "Step 1: Updating package list and installing required dependencies..."
    sudo apt update && sudo apt install -y git wget curl build-essential
    print_success "Dependencies installed successfully."
}

function install_go {
    print_info "Step 2: Installing Go $GO_VERSION..."
    wget -q https://golang.org/dl/go$GO_VERSION.linux-amd64.tar.gz
    if [[ -f go$GO_VERSION.linux-amd64.tar.gz ]]; then
        sudo tar -C /usr/local -xzf go$GO_VERSION.linux-amd64.tar.gz
        rm go$GO_VERSION.linux-amd64.tar.gz
        export PATH=$PATH:/usr/local/go/bin
        echo "export PATH=\$PATH:/usr/local/go/bin" >> ~/.bashrc
        source ~/.bashrc
        print_success "Go $GO_VERSION installed successfully!"
        print_info "Current Go version: $(go version)"
    else
        print_error "Failed to download Go tarball. Exiting."
        exit 1
    fi
}

function install_nodejs {
    print_info "Step 3: Installing Node.js (stable release)..."
    sudo apt-get install -y curl
    curl -fsSL https://deb.nodesource.com/setup_$NODE_VERSION -o nodesource_setup.sh
    if sudo -E bash nodesource_setup.sh; then
        sudo apt-get install -y nodejs
        print_success "Node.js installed successfully."
        print_info "Current Node.js version: $(node -v)"
        print_info "Current npm version: $(npm -v)"
    else
        print_error "Failed to install Node.js. Exiting."
        exit 1
    fi
}

function configure_lit {
    print_info "Step 4: Configuring Lightning Terminal (litd)..."

    # Create the .lit directory
    if [[ ! -d $LIT_CONF_DIR ]]; then
        mkdir -p $LIT_CONF_DIR
        print_success "Created configuration directory at $LIT_CONF_DIR."
    else
        print_info "$LIT_CONF_DIR already exists."
    fi

    # Prompt user for configuration details
    read -p "Is your bitcoind backend running on mainnet or signet? [mainnet/signet]: " NETWORK
    if [[ $NETWORK != "mainnet" && $NETWORK != "signet" ]]; then
        print_error "Invalid network selection. Please choose either 'mainnet' or 'signet'."
        exit 1
    fi

    read -s -p "Enter the RPC password for your bitcoind backend: " RPC_PASSWORD
    echo

    read -s -p "Enter a UI password for litd: " UI_PASSWORD
    echo

    read -p "Enter a Lightning Node alias: " NODE_ALIAS

    # Generate config content
    CONFIG_CONTENT="# Litd Settings
enablerest=true
httpslisten=0.0.0.0:8443
uipassword=$UI_PASSWORD
network=$NETWORK
lnd-mode=integrated
pool-mode=disable
loop-mode=disable
autopilot.disable=true

# Bitcoin Configuration
lnd.bitcoin.active=1
lnd.bitcoin.node=bitcoind
lnd.bitcoind.rpchost=127.0.0.1
lnd.bitcoind.rpcuser=bitcoinrpc
lnd.bitcoind.rpcpass=$RPC_PASSWORD
lnd.bitcoind.zmqpubrawblock=tcp://127.0.0.1:28332
lnd.bitcoind.zmqpubrawtx=tcp://127.0.0.1:28333

# LND General Settings
lnd.debuglevel=debug
lnd.alias=$NODE_ALIAS
lnd.maxpendingchannels=3
lnd.accept-keysend=true
lnd.accept-amp=true
lnd.rpcmiddleware.enable=true
lnd.autopilot.active=0

# LND Protocol Settings
lnd.protocol.simple-taproot-chans=true
lnd.protocol.simple-taproot-overlay-chans=true
lnd.protocol.option-scid-alias=true
lnd.protocol.zero-conf=true
lnd.protocol.custom-message=17"

    # Adjust config for mainnet
    if [[ $NETWORK == "mainnet" ]]; then
        CONFIG_CONTENT=$(echo "$CONFIG_CONTENT" | sed "/pool-mode=disable/s/^/# /" | sed "/loop-mode=disable/s/^/# /" | sed "/autopilot.disable=true/s/^/# /")
    fi

    # Write config to file
    echo "$CONFIG_CONTENT" > $LIT_CONF_FILE

    print_success "Configuration file created at $LIT_CONF_FILE."
}

function clone_and_build_litd {
    print_info "Step 5: Cloning Lightning Terminal repository..."
    if git clone $GIT_REPO $LITD_DIR; then
        print_success "Repository cloned successfully."
        cd $LITD_DIR
        print_info "Checking out version $LITD_VERSION..."
        if git checkout tags/$LITD_VERSION; then
            print_success "Checked out version $LITD_VERSION."
            print_info "Building litd... This might take a few minutes."
            if make install && make go-install-cli; then
                print_success "litd successfully built and installed!"
            else
                print_error "Failed to build and install litd. Check for errors in the build process."
                exit 1
            fi
        else
            print_error "Failed to checkout version $LITD_VERSION. Ensure the tag exists."
            exit 1
        fi
    else
        print_error "Failed to clone repository. Check your internet connection and permissions."
        exit 1
    fi
}

function setup_systemd_service {
    print_info "Step 6: Setting up litd as a systemd service..."

    sudo bash -c "cat > /etc/systemd/system/litd.service" << EOF
[Unit]
Description=Lightning Terminal (litd)
After=network.target

[Service]
ExecStart=$LITD_DIR/litd --uipassword=<CHANGEME>
User=$USER
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

    print_info "Reloading systemd to apply the new service..."
    sudo systemctl daemon-reload
    sudo systemctl enable litd
    sudo systemctl start litd

    if systemctl is-active --quiet litd; then
        print_success "litd service started successfully and enabled at boot!"
    else
        print_error "litd service failed to start. Check logs with: sudo journalctl -u litd"
        exit 1
    fi
}

function verify_installation {
    print_info "Step 7: Verifying litd installation..."
    sleep 2
    if systemctl is-active --quiet litd; then
        print_success "litd is running and active!"
    else
        print_error "litd is not running. Check logs for details."
        exit 1
    fi
}

# Main Script Execution
print_info "Welcome to the Lightning Terminal (litd) installation script!"
print_info "We will guide you through installing all necessary components step-by-step.\n"

install_dependencies
install_go
install_nodejs
configure_lit
clone_and_build_litd
setup_systemd_service
verify_installation

print_success "\n[+] Lightning Terminal (litd) installation completed successfully!"
print_info "[+] You can check the service status with: sudo systemctl status litd"
print_info "[+] To view live logs, use: sudo journalctl -u litd -f"
