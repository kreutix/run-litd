#!/bin/bash

# litd Installation Script for Ubuntu
# This script automates the installation and configuration of Lightning Terminal (litd)

set -e  # Exit immediately if a command exits with a non-zero status

# Variables
USER_HOME=$(eval echo ~${SUDO_USER:-$USER})
LIT_CONF_DIR="$USER_HOME/.lit"
LIT_CONF_FILE="$LIT_CONF_DIR/lit.conf"
LND_DIR="$USER_HOME/.lnd"
WALLET_PASSWORD_FILE="$LND_DIR/wallet_password"
SERVICE_FILE="/etc/systemd/system/litd.service"

LITD_VERSION="v0.14.0-alpha"  # Version of litd to be installed
BINARY_URL="https://github.com/lightninglabs/lightning-terminal/releases/download/$LITD_VERSION/lightning-terminal-linux-amd64-$LITD_VERSION.tar.gz"
SIGNATURE_URL="https://github.com/lightninglabs/lightning-terminal/releases/download/$LITD_VERSION/manifest-guggero-$LITD_VERSION.sig"
MANIFEST_URL="https://github.com/lightninglabs/lightning-terminal/releases/download/$LITD_VERSION/manifest-$LITD_VERSION.txt"
KEY_ID="F4FC70F07310028424EFC20A8E4256593F177720"
KEY_SERVER="hkps://keyserver.ubuntu.com"
DOWNLOAD_DIR="/tmp/litd_release_verification"


# Install litd from binary
echo "[+] Checking if Lightning Terminal is already installed..."
if [[ -f "/usr/local/bin/litd" ]]; then
    echo "[+] Lightning Terminal (litd) is already installed. Skipping installation."
else
    echo "[+] litd not found in /usr/local/bin. Proceeding with installation."

    # Create download directory
    mkdir -p "$DOWNLOAD_DIR"
    cd "$DOWNLOAD_DIR" || { echo "Failed to navigate to download directory."; exit 1; }
    echo "The current working directory is: $PWD"

    # Import Oli's key
    echo "Importing Oli's key..."
    gpg --keyserver "$KEY_SERVER" --recv-keys "$KEY_ID" || { echo "Failed to import PGP key."; exit 1; }

    # Download litd binary
    echo "Downloading binary..."
    wget "$BINARY_URL" || { echo "Failed to download binary."; exit 1; }

    echo "Downloading signature..."
    wget "$SIGNATURE_URL" || { echo "Failed to download signature."; exit 1; }

    echo "Downloading manifest..."
    wget "$MANIFEST_URL" || { echo "Failed to download manifest."; exit 1; }

    # Verify the release signature
    echo "Verifying signature..."
    gpg --verify "$(basename "$SIGNATURE_URL")" "$(basename "$MANIFEST_URL")" 2>&1 | grep "$KEY_ID" > /dev/null
    if [ $? -eq 0 ]; then
        echo "Signature verification successful."
    else
        echo "Signature verification failed or does not match the expected key ID: $KEY_ID."
        exit 1
    fi

    #Check SHASUM
    echo "Checking shasum..."
    grep "$(sha256sum "$(basename "$BINARY_URL")" | awk '{print $1}')" "$(basename "$MANIFEST_URL")" > /dev/null
    if [ $? -eq 0 ]; then
        echo "SHA256 hash verification successful."
    else
        echo "SHA256 hash verification failed."
        exit 1
    fi

    echo "[+] Extracting litd binary..."
    tar -xvzf "$DOWNLOAD_DIR/lightning-terminal-linux-amd64-$LITD_VERSION.tar.gz" -C "$DOWNLOAD_DIR" --strip-components=1

    echo "[+] Moving binaries to /usr/local/bin..."
    sudo mv "$DOWNLOAD_DIR"/* /usr/local/bin/

    echo "[+] Cleaning up temporary files..."
    rm -rf "$DOWNLOAD_DIR"

    echo "[+] litd successfully installed!"

    # Change back to the ubuntu user's home directory
    cd "$USER_HOME" || { echo "Failed to return to the user's home directory: $USER_HOME"; exit 1; }
fi
