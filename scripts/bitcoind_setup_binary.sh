#!/bin/bash

# Bitcoin Core Node Setup Script
# Tested on Ubuntu 24.04

set -e

# Configuration
USER_HOME=$(eval echo ~${SUDO_USER:-$USER})
BITCOIN_DIR="$USER_HOME/.bitcoin"
BITCOIN_CONF="$BITCOIN_DIR/bitcoin.conf"
RPC_AUTH=""
NETWORK=""
SERVICE_FILE="/etc/systemd/system/bitcoind.service"
BITCOIN_VERSION="27.2"  # Stick with the 27.x version
BITCOIN_TARBALL="bitcoin-${BITCOIN_VERSION}-x86_64-linux-gnu.tar.gz"
BITCOIN_URL="https://bitcoincore.org/bin/bitcoin-core-${BITCOIN_VERSION}/${BITCOIN_TARBALL}"
SHA256SUMS_URL="https://bitcoincore.org/bin/bitcoin-core-${BITCOIN_VERSION}/SHA256SUMS"
SHA256SUMS_ASC_URL="https://bitcoincore.org/bin/bitcoin-core-${BITCOIN_VERSION}/SHA256SUMS.asc"

# Check if user is root
echo "[+] Checking for root privileges..."
if [[ $EUID -ne 0 ]]; then
  echo "[-] This script must be run as root. Use sudo."
  exit 1
fi

# Update & Install dependencies
echo "[+] Updating system and installing dependencies..."
apt update && apt upgrade -y
apt install -y wget tar gnupg

# Download Bitcoin Core binary and related files
echo "[+] Downloading Bitcoin Core binary, checksums, and signatures..."
wget -q $BITCOIN_URL -O $BITCOIN_TARBALL
wget -q $SHA256SUMS_URL -O SHA256SUMS
wget -q $SHA256SUMS_ASC_URL -O SHA256SUMS.asc

if [[ ! -f $BITCOIN_TARBALL || ! -f SHA256SUMS || ! -f SHA256SUMS.asc ]]; then
    echo "[-] Failed to download necessary files. Exiting."
    exit 1
fi

# Verify SHA256 checksum
echo "[+] Verifying SHA256 checksum of the binary..."
sha256sum --ignore-missing --check SHA256SUMS
if [[ $? -ne 0 ]]; then
    echo "[-] SHA256 checksum verification failed. Exiting."
    exit 1
fi
echo "[+] SHA256 checksum verified successfully."


# Verify SHA256 checksum
echo "[+] Verifying SHA256 checksum of the binary..."
sha256sum --ignore-missing --check SHA256SUMS
if [[ $? -ne 0 ]]; then
    echo "[-] SHA256 checksum verification failed. Exiting."
    exit 1
fi
echo "[+] SHA256 checksum verified successfully."

# Import Bitcoin Core signing keys
echo "[+] Checking for 'guix.sigs' directory..."
if [[ -d "guix.sigs" ]]; then
    echo "[!] 'guix.sigs' directory already exists. Pulling the latest changes..."
    cd guix.sigs
    git pull --ff-only || { echo "[-] Failed to update 'guix.sigs'. Please resolve manually."; exit 1; }
    cd ..
else
    echo "[+] Cloning 'guix.sigs' repository..."
    git clone https://github.com/bitcoin-core/guix.sigs guix.sigs || { echo "[-] Failed to clone 'guix.sigs'. Exiting."; exit 1; }
fi

echo "[+] Importing Bitcoin Core signing keys..."
gpg --import guix.sigs/builder-keys/* || { echo "[-] Failed to import Bitcoin Core signing keys. Exiting."; exit 1; }

# Verify PGP signature of the SHA256SUMS file
echo "[+] Verifying PGP signature of the SHA256SUMS file..."
gpg --verify SHA256SUMS.asc SHA256SUMS
if [[ $? -ne 0 ]]; then
    echo "[-] PGP signature verification failed. Exiting."
    exit 1
fi
echo "[+] PGP signature verified successfully."

# Extract and install Bitcoin Core binary
echo "[+] Extracting Bitcoin Core binary..."
tar -xzf $BITCOIN_TARBALL
BITCOIN_EXTRACT_DIR="bitcoin-${BITCOIN_VERSION}"

if [[ -d "$BITCOIN_EXTRACT_DIR/bin" ]]; then
    sudo install -m 0755 -o root -g root -t /usr/local/bin $BITCOIN_EXTRACT_DIR/bin/*
    rm -rf $BITCOIN_TARBALL $BITCOIN_EXTRACT_DIR
    echo "[+] Bitcoin Core binaries installed successfully."
else
    echo "[-] Expected directory structure not found: $BITCOIN_EXTRACT_DIR/bin. Exiting."
    rm -rf $BITCOIN_TARBALL $BITCOIN_EXTRACT_DIR
    exit 1
fi

