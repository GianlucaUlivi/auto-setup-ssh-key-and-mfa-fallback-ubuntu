#!/bin/bash

set -e

echo "=== SSH Public Key and Password+MFA Fallback Setup ==="
ehco "Please report any issue at https://github.com/GianlucaUlivi/auto-setup-ssh-key-and-mfa-fallback-ubuntu"

### 0. Setup
# Get the User
read -rp "Enter the username to configure SSH for: " INSTALL_USER

# Get the public key via editor
read -p "Press Enter to open the editor and insert your public key(s)."
tempfile=$(mktemp)
${EDITOR:-nano} "$tempfile"
PUBLIC_KEY=$(<"$tempfile")
rm "$tempfile"

# Constants
SSHD_CONFIG="/etc/ssh/sshd_config"
PAM_SSHD_CONFIG="/etc/pam.d/sshd"


### 1. Install necessary packages
echo "[*] Installing required packages..."
apt update
apt install -y -qq libpam-google-authenticator


### 2. Set up public key for user
echo "[*] Installing SSH public key for $INSTALL_USER..."

USER_HOME=$(eval echo "~$INSTALL_USER")
USER_SSH_DIR="$USER_HOME/.ssh"
AUTHORIZED_KEYS="$USER_SSH_DIR/authorized_keys"

mkdir -p "$USER_SSH_DIR"
echo "$PUBLIC_KEY" >> "$AUTHORIZED_KEYS"
cp "${USER_SSH_DIR}/authorized_keys" "${USER_SSH_DIR}/authorized_keys.bck"
chown -R "$INSTALL_USER:$INSTALL_USER" "$USER_SSH_DIR"
chmod 700 "$USER_SSH_DIR"
chmod 600 "$AUTHORIZED_KEYS"


### 3. Update sshd_config
echo "[*] Updating sshd_config..."
cp "$SSHD_CONFIG" "${SSHD_CONFIG}.bak"

sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/' "$SSHD_CONFIG"
sed -i 's/^#\?ChallengeResponseAuthentication.*/ChallengeResponseAuthentication yes/' "$SSHD_CONFIG"
sed -i 's/^#\?UsePAM.*/UsePAM yes/' "$SSHD_CONFIG"
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/' "$SSHD_CONFIG"

# Ensure pubkey is enabled
grep -q "^KbdInteractiveAuthentication" "$SSHD_CONFIG" \
    && sed -i "s|^KbdInteractiveAuthentication.*|KbdInteractiveAuthentication yes|" "$SSHD_CONFIG" \
    || echo "KbdInteractiveAuthentication yes" >> "$SSHD_CONFIG"

# Ensure keyboard-interactive is enabled
grep -q "^PubkeyAuthentication" "$SSHD_CONFIG" \
    && sed -i "s|^PubkeyAuthentication.*|PubkeyAuthentication yes|" "$SSHD_CONFIG" \
    || echo "PubkeyAuthentication yes" >> "$SSHD_CONFIG"

# Add or replace AuthenticationMethods
grep -q "^AuthenticationMethods" "$SSHD_CONFIG" \
    && sed -i "s|^AuthenticationMethods.*|AuthenticationMethods publickey keyboard-interactive|" "$SSHD_CONFIG" \
    || echo "AuthenticationMethods publickey keyboard-interactive" >> "$SSHD_CONFIG"




### 4. Configure PAM for SSH
echo "[*] Configuring PAM for SSH login..."
cp "$PAM_SSHD_CONFIG" "${PAM_SSHD_CONFIG}.bak"

# Ensure correct order: password first, then MFA
sed -i '/pam_google_authenticator.so/d' "$PAM_SSHD_CONFIG"
sed -i '1i@include common-auth\nauth required pam_google_authenticator.so' "$PAM_SSHD_CONFIG"


### 5. Restart SSH
echo "[*] Restarting SSH..."
systemctl restart ssh


### 6. Optional: Setup Google Authenticator for the user
echo "[*] Would you like to set up Google Authenticator for user: $INSTALL_USER? [y/N]"
read -r REPLY
if [[ "$REPLY" =~ ^[Yy]$ ]]; then
    echo "[*] Running google-authenticator for $INSTALL_USER..."
    sudo -u "$INSTALL_USER" google-authenticator
fi


### 7. End
echo "[✓] SSH with key and password+MFA fallback setup complete!"
echo "Please test the connection in a new session before closing this one."
echo "If you face any isse and wish to rollback the changes you can replace the newly created config files with their backup, the backup files have been created at the following locations:"
echo "- ${USER_SSH_DIR}/authorized_keys.bck"
echo "- ${SSHD_CONFIG}.bak"
echo "- ${PAM_SSHD_CONFIG}.bak"
echo "Bye Bye :)"
