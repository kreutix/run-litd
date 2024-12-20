#!/bin/bash

# litd Installation Script for Ubuntu
# This script automates the installation and configuration of Lightning Terminal (litd)

set -e  # Exit immediately if a command exits with a non-zero status

# Variables
USER_HOME=$(eval echo ~${SUDO_USER:-$USER})
LIT_CONF_DIR="$HOME/.lit"
LIT_CONF_FILE="$LIT_CONF_DIR/lit.conf"
LND_DIR="$HOME/.lnd"
WALLET_PASSWORD_FILE="$LND_DIR/wallet_password"
GO_VERSION="1.21.0"
NODE_VERSION="22.x"  # Ensure an even-numbered, stable release
LITD_VERSION="v0.13.6-alpha"  # Version of litd to be installed
SERVICE_FILE="/etc/systemd/system/litd.service"

# Install Go
echo "[+] Checking if Go $GO_VERSION is installed..."
if command -v go &> /dev/null && [[ $(go version | awk '{print $3}' | cut -c3-) > 1.18 ]]; then
    echo "[+] Go $GO_VERSION is already installed. Skipping installation."
else
    echo "[+] Installing Go $GO_VERSION..."
    wget -q https://golang.org/dl/go$GO_VERSION.linux-amd64.tar.gz
    if [[ -f go$GO_VERSION.linux-amd64.tar.gz ]]; then
        sudo tar -C /usr/local -xzf go$GO_VERSION.linux-amd64.tar.gz
        rm go$GO_VERSION.linux-amd64.tar.gz
        echo "GOPATH=$HOME/go" >> ~/.profile
        echo "PATH=\"$HOME/bin:$HOME/go/bin:$HOME/.local/bin:/usr/local/go/bin:$PATH\"" >> ~/.profile
        source ~/.profile
        echo "[+] Go $GO_VERSION installed successfully!"
        echo "[+] Current Go version: $(go version)"
    else
        echo "[-] Failed to download Go tarball. Exiting."
        exit 1
    fi
fi

# Install Node.js
echo "[+] Checking if Node.js is installed..."
if command -v node &> /dev/null && [[ $(node -v | grep -oP '\d+' | head -1) -ge 18 ]]; then
    echo "[+] Node.js is already installed. Version: $(node -v)"
else
    echo "[+] Installing Node.js (stable release)..."
    sudo apt-get install -y curl
    curl -fsSL https://deb.nodesource.com/setup_$NODE_VERSION -o nodesource_setup.sh
    if sudo -E bash nodesource_setup.sh; then
        sudo apt-get install -y nodejs
        echo "[+] Node.js installed successfully."
        echo "[+] Current Node.js version: $(node -v)"
        echo "[+] Current npm version: $(npm -v)"
    else
        echo "[-] Failed to install Node.js. Exiting."
        exit 1
    fi
fi

# Clone and build litd
echo "[+] Checking if Lightning Terminal is already installed..."
if command -v litd &> /dev/null; then
    echo "[+] Lightning Terminal (litd) is already installed. Skipping build."
else
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

# Ensure ~/.lnd directory exists
echo "[+] Ensuring the ~/.lnd directory exists..."
if [[ ! -d $LND_DIR ]]; then
    mkdir -p $LND_DIR
    echo "[+] Created directory at $LND_DIR."
    # Ensure ~/.lnd directory is owned by the user
    echo "[+] Ensuring ownership of $LND_DIR..."
    sudo chown -R ${SUDO_USER:-$USER}:${SUDO_USER:-$USER} $LND_DIR
    echo "[+] Ownership set to ${SUDO_USER:-$USER} for $LND_DIR."
else
    echo "[!] Directory $LND_DIR already exists."
fi

# Generate wallet password
echo "[+] Checking if wallet password file exists and is not empty..."
if [[ -f $WALLET_PASSWORD_FILE && -s $WALLET_PASSWORD_FILE ]]; then
    echo "[+] Wallet password file already exists and is not empty. Skipping generation."
else
    echo "[+] Generating wallet password..."
    openssl rand -hex 21 > $WALLET_PASSWORD_FILE
    if [[ -f $WALLET_PASSWORD_FILE ]]; then
        echo "[+] Wallet password generated and saved to $WALLET_PASSWORD_FILE."
        # Ensure wallet password file is owned by the user
        echo "[+] Ensuring ownership of $WALLET_PASSWORD_FILE..."
        sudo chown ${SUDO_USER:-$USER}:${SUDO_USER:-$USER} $WALLET_PASSWORD_FILE
        echo "[+] Ownership set to ${SUDO_USER:-$USER} for $WALLET_PASSWORD_FILE."
    else
        echo "[-] Failed to generate wallet password. Exiting."
        exit 1
    fi
fi

# Configure litd
echo "[+] Step 4: Configuring Lightning Terminal (litd)..."

# Check if configuration directory exists
if [[ ! -d $LIT_CONF_DIR ]]; then
    mkdir -p $LIT_CONF_DIR
    echo "[+] Created configuration directory at $LIT_CONF_DIR."
    # Ensure .lit directory is owned by the user
    echo "[+] Ensuring ownership of $LIT_CONF_DIR..."
    sudo chown -R ${SUDO_USER:-$USER}:${SUDO_USER:-$USER} $LIT_CONF_DIR
    echo "[+] Ownership set to ${SUDO_USER:-$USER} for $LIT_CONF_DIR."
else
    echo "[!] $LIT_CONF_DIR already exists."
fi

# Check if configuration file exists and is not empty
if [[ -f $LIT_CONF_FILE && -s $LIT_CONF_FILE ]]; then
    echo "[+] Configuration file already exists and is not empty. Skipping creation."
else
    echo "[+] Generating new configuration file..."

    read -p "Is your bitcoind backend running on mainnet or signet? [mainnet/signet]: " NETWORK
    NETWORK=$(echo "$NETWORK" | tr '[:upper:]' '[:lower:]')
    if [[ $NETWORK != "mainnet" && $NETWORK != "signet" ]]; then
        echo "[-] Invalid network selection. Please choose either 'mainnet' or 'signet'."
        exit 1
    fi

    read -s -p "Enter the RPC password for your bitcoind backend: " RPC_PASSWORD
    echo
    if [[ -z $RPC_PASSWORD ]]; then
        echo "[-] RPC password cannot be empty. Exiting."
        exit 1
    fi

    read -s -p "Enter a UI password for litd: " UI_PASSWORD
    echo
    if [[ -z $UI_PASSWORD ]]; then
        echo "[-] UI password cannot be empty. Exiting."
        exit 1
    fi

    read -p "Enter a Lightning Node alias: " NODE_ALIAS

    CONFIG_CONTENT="# Litd Settings
enablerest=true
httpslisten=0.0.0.0:8443
uipassword=$UI_PASSWORD
network=$NETWORK
lnd-mode=integrated
pool-mode=disable
loop-mode=disable
autopilot.disable=true

    if [[ $NETWORK == "mainnet" ]]; then
        CONFIG_CONTENT=$(echo "$CONFIG_CONTENT" | sed "/pool-mode=disable/s/^/# /" | sed "/loop-mode=disable/s/^/# /" | sed "/autopilot.disable=true/s/^/# /")
    fi

# Bitcoin Configuration
lnd.bitcoin.active=1
lnd.bitcoin.node=bitcoind
lnd.bitcoind.rpchost=127.0.0.1
lnd.bitcoind.rpcuser=bitcoinrpc
lnd.bitcoind.rpcpass=$RPC_PASSWORD
lnd.bitcoind.zmqpubrawblock=tcp://127.0.0.1:28332
lnd.bitcoind.zmqpubrawtx=tcp://127.0.0.1:28333

# LND General Settings
#lnd.wallet-unlock-password-file=/home/ubuntu/.lnd/wallet_password
#lnd.wallet-unlock-allow-create=true
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

    echo "$CONFIG_CONTENT" > $LIT_CONF_FILE
    echo "[+] Configuration file created at $LIT_CONF_FILE."

    # Ensure configuration file is owned by the user
    echo "[+] Ensuring ownership of $LIT_CONF_FILE..."
    sudo chown ${SUDO_USER:-$USER}:${SUDO_USER:-$USER} $LIT_CONF_FILE
    echo "[+] Ownership set to ${SUDO_USER:-$USER} for $LIT_CONF_FILE."
fi

# Start litd and initialize wallet creation
echo "[+] Starting litd to initialize LND wallet creation..."
$USER_HOME/lightning-terminal/litd &
LITD_PID=$!
sleep 120  # Allow litd to fully start

if [[ -f $WALLET_PASSWORD_FILE && -s $WALLET_PASSWORD_FILE ]]; then
    echo "[+] Running lncli create to initialize wallet..."
    WALLET_OUTPUT=$(echo -e "$(cat $WALLET_PASSWORD_FILE)\n$(cat $WALLET_PASSWORD_FILE)\nn\n" | lncli create 2>&1)
    echo "$WALLET_OUTPUT" | while read -r line; do
        echo "$line"
        if [[ "$line" == *"Generating fresh cypher seed"* ]]; then
            echo "[+] IMPORTANT: Below is your wallet seed phrase. BACK IT UP SECURELY!"
        fi
    done

    read -p "Have you backed up the wallet seed securely? Type 'yes' to confirm: " SEED_CONFIRM
    if [[ "$SEED_CONFIRM" != "yes" ]]; then
        echo "[-] You must back up your wallet seed before continuing. Exiting."
        kill $LITD_PID
        exit 1
    fi
else
    echo "[-] Wallet password file is missing or empty. Exiting."
    kill $LITD_PID
    exit 1
fi

# Uncomment wallet unlock settings in the configuration file
echo "[+] Uncommenting wallet unlock settings in the configuration file..."
sed -i "s|^#lnd.wallet-unlock-password-file=/home/ubuntu/.lnd/wallet_password|lnd.wallet-unlock-password-file=$USER_HOME/.lnd/wallet_password|" $LIT_CONF_FILE
sed -i "s|^#lnd.wallet-unlock-allow-create=true|lnd.wallet-unlock-allow-create=true|" $LIT_CONF_FILE

echo "[+] Wallet unlock settings have been enabled in $LIT_CONF_FILE."        exit 1
    fi
else
    echo "[-] Wallet password file is missing or empty. Exiting."
    kill $LITD_PID
    exit 1
fi

sleep 30
kill $LITD_PID
echo "[+] Wallet creation completed successfully."


# Create systemd service file
if [[ ! -f "$SERVICE_FILE" ]]; then
    echo "[+] Creating systemd service file for litd..."
    cat <<EOF > $SERVICE_FILE
[Unit]
Description=Litd Terminal Daemon
Requires=bitcoind.service
After=bitcoind.service

[Service]
ExecStart=$USER_HOME/go/bin/litd litd

User=${SUDO_USER:-$USER}
Group=${SUDO_USER:-$USER}

Type=simple
Restart=always
RestartSec=120

[Install]
WantedBy=multi-user.target
EOF
else
    echo "[!] Systemd service file already exists. Skipping creation."
fi

# Enable, reload, and start systemd service
systemctl enable litd
systemctl daemon-reload
if ! systemctl is-active --quiet litd; then
    systemctl start litd
    echo "[+] litd service started."
else
    echo "[!] litd service is already running."
fi

cat <<EOF

[+] Lightning Terminal Daemon (litd) built, configured, and service enabled successfully!


             ________________________________________________
            /                                                \
           |    _________________________________________     |
           |   |                                         |    |
           |   |       ___(                        )     |    |
           |   |      (                          _)      |    |
           |   |     (_                       __))       |    |
           |   |       ((                _____)          |    |
           |   |         (_________)----'                |    |
           |   |              _/  /                      |    |
           |   |             /  _/                       |    |
           |   |           _/  /                         |    |
           |   |          / __/                          |    |
           |   |        _/ /                             |    |
           |   |       /__/                              |    |
           |   |      /'                                 |    |
           |   |_________________________________________|    |
           |                                                  |
            \_________________________________________________/
                   \___________________________________/
                ___________________________________________
             _-'    .-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.  --- `-_
          _-'.-.-. .---.-.-.-.-.-.-.-.-.-.-.-.-.-.-.--.  .-.-.`-_
       _-'.-.-.-. .---.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-`__`. .-.-.-.`-_
    _-'.-.-.-.-. .-----.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-----. .-.-.-.-.`-_
 _-'.-.-.-.-.-. .---.-. .-------------------------. .-.---. .---.-.-.-.`-_
:-------------------------------------------------------------------------:
`---._.-------------------------------------------------------------._.---'

[+] Your Litd node is now up and running!
EOF