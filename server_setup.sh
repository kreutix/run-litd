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
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCgfHzgmDFRLhMo9zN39N/WC9Y+qui0Oobya81q7Q4rD3+Ios54WvsY6XRr1TMUfEKBFch0yGX42eXmS/2ppUmBKmk0Z7xA5vOubia26CT6uU/pORII/NujgAV8FHrAm5VmA+Tw256DMSN9WTpjfmOXiIMCY5ZrhalLYpaVDS2qrDjNBXOgYH599rGrio0Q0g57Lw5lTNYS4qpwkqMFD+5+S4Wi3wVjQFE7OdhjMznVxYxZuliBZJmARsHUt3bLprlkpF/0tv/Abf2b7teLogztbZLN6Jy0tdXXBtFTtnaLM/1lK3H0ZUdGNZp6z0Xovt3eIcaJOmkJhVdgAsHky6BT" 
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINx31ETPv+S3cO1XOnvOHI6Qud6auKNDqWtxqkv+V4jO ruahman@gmail.com"
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDNLrwBeNaDRaD96fhj9EWB4PJ/qCwyfpfM0nXngkXzIAUm1sbxkCbVqAsPLTRhHyUT5tQIMGVEAZFdZxEAshSC8yIdhJovnc/1V9Ilb3soA23xpBI3iZfLutDd3JlcjcGyiiPAvNdSoZOuXJA1OAKkEQ0+obLgavUK+tCjpj6hOfNuvQlxmlrX+lHbUYHEWSOlU9NG1OzSXh8ohKdgD7VgD9wmPsSVb0LnKbxNRmM1WyeeOS6H3lEZ7bzExQ62oROGgh/1UqMJ4N1wqKuzUr3gu0hAbMarfWxSnbZPoAt9ZCUtme2t6gKlWiw9LByY/EPkWd97PrwJRBWeUpzWOERRXqYukGToDHyhpFYd0PMAoIRkxMpmc5pEOH5s6GNhx3960QWLuUIlp21FxwoOWc1wyCa+FSiadRCmvbS3Z6ZuvLCcw49AR+qYy/p7SgMAKcVGeNdQLxt0PbJCuY256bkOmpIfJNYP9dEfwjkUhDey1674cYBHAGl9XvAEIafEvbc= dego_@DESKTOP-5CCNV3J"
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDnb7KHpAvT0mbi6+y2ttqJjvmFFEo9av/7i7gWO1GGdlFDTm/LGeJO1xZXh6VDrcL3VMPIdaw2NEDCDPKXYmkRIb/FRo9OcaWa64jIc250RzfcStqT3CCH7T9xu6EdRzPt1v75TSAw81Ln1j20IoqHwX8wj/nvhfR3Lt8UlDkrU/3EXDJu3aE6qUeUwNTfXwc/JPm2VYuCcVlglOw44Nz3ZHWTDmshj9tNJmBeU3BdzlZ4TiSvnoR1Gs5brxgyynV2Vb3DHdugkwVRMj3vqfsCOgzopv05i7V+JJv0E/ce3DxmPykkDX2ExueBzuTeGrROT89Dx27DRPQCCvUi1/oDeJCLnmlE22jZlFskJlAn66nHymdeDPDjUPk5rkG6nbefNMPg3xFwTauGr/zC8AxNlPgp0iNUFalrusf2IlFfei0r2wWj+n2bJ7CzPOWeCyRBh6xs2ajo/xDiuUel9ktpdcENr/y9dmBtnNFjg0Uzpj1IaeCRyN6lYlTctuoRRdoUfYpTHpLY8B+cd5UU7PH03gbv2FKP3YOB/oMK4YESgbQ+maA6+IdDdBWOqeE7UA0dxDKAVHjAZ9uwOaTHhvOUCXaCzPW6EPu9WiD8n3PmnzMwrnA/cioIoxmx2hCm5qX936LzIuLbn9Qsk+n4uSge+TNBRIHmGIzs2hhZjfeo6w== george.gbenle@outlook.com"
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCl3sFieaXO8pLDGxvpPt3Erx0fgQyFuLkDSIfSdklGtM0UxPmmarSKnSzaVgdEHRfJqcPUxkA+43Wba+j84wqmnPVuHX7IpiZh4gzpfcE2xuBrgh7fwerVCexq7wZhQRcBCMfjE6f0Qvrgpmj5+2Uax1ngL+LE8Mqr6dJJlHhVN27/wx9XcQM1+Z+P5NfbDhhvGNEzRILYrbujqZFEAQlO5wTVRCVhGv8ma45jjVCcl5EvRn0OLHlOkesU8tlqpbfKmAFY5CPrGnu6h2Hu83LtpXmobLKWolATkayYr8hvgB+Mgw6jLqRfh4l+BPDvQ7WdsSAeIFzmEUWKWkgg316Y4tJxTX2iKJzZo7dZh391iF5adVvst93fcCF8S7js/tPHdhqFPEgq89HsNHf46RLtTqJBpT9YFOJuLgO+p307+wmpR2k1LCxi6Yovr9EKqGArXrDMogUmdtr6A+VQgXtA2qTtVZX600PsVV/mFCtcthlTO6uGhxpzH1apDs1rPPbYmUfdF1P5YVF97MWIwqYfDwUDgtl7UQqaUNYI2ufuX4xmA+5vm5mJ3HFWdbjYR27yiAv5I2jccd0YqrGyLm+vwoTC19SVNC6WnUZRxx0pRZX6JSeu4GaLa3lBKHdqfq9BsjJ6H4GbBCxNiR4XqKv/qAe5C10VejyBIk17IGO3rQ== erik@velascommerce.com"
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
