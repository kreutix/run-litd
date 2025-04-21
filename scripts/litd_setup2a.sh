#!/bin/bash

# litd Installation Script for Ubuntu
# This script automates the installation of Lightning Terminal (litd)

set -e  # Exit immediately if a command exits with a non-zero status

# Variables
USER_HOME=$(eval echo ~${SUDO_USER:-$USER})
LIT_CONF_DIR="$USER_HOME/.lit"
LIT_CONF_FILE="$LIT_CONF_DIR/lit.conf"
LND_DIR="$USER_HOME/.lnd"
WALLET_PASSWORD_FILE="$LND_DIR/wallet_password"
GO_VERSION="1.21.0"
NODE_VERSION="22.x"  # Ensure an even-numbered, stable release
LITD_VERSION="v0.14.0-alpha"  # Version of litd to be installed
SERVICE_FILE="/etc/systemd/system/litd.service"


# Clone and build litd
echo "[+] Checking if Lightning Terminal is already installed..."
if [[ -f "$USER_HOME/go/bin/litd" ]]; then
    echo "[+] Lightning Terminal (litd) is already installed. Skipping build."
else
    echo "[+] litd not found in $USER_HOME/go/bin. Proceeding with installation."

    echo "[+] Ensuring $USER_HOME/go directory exists and is owned by the current user..."
    if [[ -d "$USER_HOME/go" ]]; then
        echo "[+] Directory $USER_HOME/go already exists."
    else
        echo "[+] Creating $USER_HOME/go directory..."
        mkdir -p "$USER_HOME/go"
        echo "[+] Directory $USER_HOME/go created successfully."
    fi
    echo "[+] Ensuring proper ownership of $USER_HOME/go..."
    sudo chown -R ${SUDO_USER:-$USER}:${SUDO_USER:-$USER} "$USER_HOME/go"

    # Ensure required build tools are installed
    echo "[+] Checking for required build tools..."
    if ! command -v make &> /dev/null; then
        echo "[+] 'make' not found. Installing build-essential package..."
        sudo apt update
        sudo apt install build-essential -y
    else
        echo "[+] 'make' is already installed."
    fi

    echo "[+] Checking if Lightning Terminal repository already exists..."
    if [[ -d "$USER_HOME/lightning-terminal" ]]; then
        echo "[!] Repository already exists. Using existing directory."
        cd "$USER_HOME/lightning-terminal"
    else
        echo "[+] Cloning Lightning Terminal repository into $USER_HOME/lightning-terminal..."
        if git clone https://github.com/lightninglabs/lightning-terminal.git "$USER_HOME/lightning-terminal"; then
            echo "[+] Repository cloned successfully."
            cd "$USER_HOME/lightning-terminal"
            # Ensure Lightning Terminal directory ownership
            sudo chown -R ${SUDO_USER:-$USER}:${SUDO_USER:-$USER} "$USER_HOME/lightning-terminal"
        else
            echo "[-] Failed to clone repository. Check your internet connection and permissions."
            exit 1
        fi
    fi

    echo "[+] Checking out version $LITD_VERSION..."
    if git checkout tags/$LITD_VERSION; then
        echo "[+] Checked out version $LITD_VERSION."
        echo "[+] Building litd... This might take a few minutes."
        export GOPATH=$USER_HOME/go
        export PATH=$USER_HOME/go/bin:/usr/local/go/bin:$PATH
        if make install && make go-install-cli; then
            echo "[+] litd successfully built and installed!"
            # Ensure binary ownership
            sudo chown -R ${SUDO_USER:-$USER}:${SUDO_USER:-$USER} "$USER_HOME/go"
        else
            echo "[-] Failed to build and install litd. Check for errors in the build process."
            exit 1
        fi
    else
        echo "[-] Failed to checkout version $LITD_VERSION. Ensure the tag exists."
        exit 1
    fi
fi

