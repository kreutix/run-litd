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

# Check if user is root
echo "[+] Checking for root privileges..."
if [[ $EUID -ne 0 ]]; then
  echo "[-] This script must be run as root. Use sudo."
  exit 1
fi

# Update & Install dependencies
echo "[+] Updating system and installing dependencies..."
apt update && apt upgrade -y
apt install -y git build-essential libtool autotools-dev automake pkg-config libssl-dev libevent-dev \
    bsdmainutils libboost-system-dev libboost-filesystem-dev libboost-chrono-dev \
    libboost-program-options-dev libboost-test-dev libboost-thread-dev libminiupnpc-dev libzmq3-dev python3

# Clone Bitcoin Core repository
echo "[+] Checking for Bitcoin Core repository..."
if [[ ! -d "$USER_HOME/bitcoin" ]]; then
    echo "[+] Cloning Bitcoin Core repository using v27.2 into $USER_HOME..."
    git clone -b v27.2 https://github.com/bitcoin/bitcoin.git "$USER_HOME/bitcoin"
    sudo chown -R ${SUDO_USER:-$USER}:${SUDO_USER:-$USER} "$USER_HOME/bitcoin"
else
    echo "[!] Bitcoin repository already exists. Skipping clone."
fi

# Navigate to the repository
cd "$USER_HOME/bitcoin/"

# Build Bitcoin Core from source
if [[ ! -f "/usr/local/bin/bitcoind" ]]; then
    echo "[+] Building Bitcoin Core. This may take a while..."
    ./autogen.sh
    ./configure CXXFLAGS="--param ggc-min-expand=1 --param ggc-min-heapsize=32768" --enable-cxx --with-zmq --without-gui \
        --disable-shared --with-pic --disable-tests --disable-bench --enable-upnp-default --disable-wallet
    echo "[+] This is the tedious part..."
    make -j "$(($(nproc)+1))"
    echo "[+] Almost done!"
    sudo make install
else
    echo "[!] bitcoind is already installed. Skipping build."
fi
