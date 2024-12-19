#!/bin/bash

# Exit on error
set -e

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root."
  exit 1
fi

# Variables
NEW_USER="ubuntu"
SSH_DIR="/home/$NEW_USER/.ssh"
AUTHORIZED_KEYS="$SSH_DIR/authorized_keys"
TEAM_KEYS=(
    # Add your team's keys here
) 

# 1. Add a new user
if id "$NEW_USER" &>/dev/null; then
  echo "User $NEW_USER already exists."
else
  echo "Creating user $NEW_USER..."
  adduser --gecos "" $NEW_USER
  echo "$NEW_USER ALL=(ALL:ALL) ALL" >> /etc/sudoers
  echo "User $NEW_USER added and given sudo access."
fi

# 2. Set up SSH authorized keys
echo "Setting up .ssh/authorized_keys for $NEW_USER..."
mkdir -p $SSH_DIR
chmod 700 $SSH_DIR

# Add team keys
for KEY in "${TEAM_KEYS[@]}"; do
  echo "$KEY" >> $AUTHORIZED_KEYS
done

chmod 600 $AUTHORIZED_KEYS
chown -R $NEW_USER:$NEW_USER $SSH_DIR
echo "SSH keys added for $NEW_USER."

# 3. Disable root login and password authentication
echo "Disabling root login and password authentication..."
SSHD_CONFIG="/etc/ssh/sshd_config"

sed -i "s/^PermitRootLogin.*/PermitRootLogin no/" $SSHD_CONFIG
sed -i "s/^#PasswordAuthentication.*/PasswordAuthentication no/" $SSHD_CONFIG
sed -i "s/^PasswordAuthentication.*/PasswordAuthentication no/" $SSHD_CONFIG

# Restart SSH service
echo "Restarting SSH service..."
systemctl restart ssh

echo "Setup completed successfully."
