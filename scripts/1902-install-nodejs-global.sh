#!/usr/bin/env bash
# 1902-install-nodejs-global.sh
# Install Node.js development tools in /root for global PM2 usage
# Ensures pm2 resurrect from /etc/rc.local works without sudo issues

set -euo pipefail

echo "=============================================="
echo " Installing Node.js Development Tools (Global/Root)"
echo "=============================================="

# Ensure we're running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root"
    echo "Usage: sudo ./1902-install-nodejs-global.sh"
    exit 1
fi

NVM_VERSION="v0.40.7"

# ------------------------------------------------
# 1. Remove old installations (clean slate)
# ------------------------------------------------

echo
echo "==> Cleaning up old installations..."

apt purge -y nodejs npm || true
apt autoremove -y || true

rm -rf /root/.npm /root/.node* /root/.pm2
rm -rf /root/.nvm
rm -rf /root/.local/share/pnpm
rm -rf /root/.yarn /root/.yarnrc /root/.config/yarn
rm -rf /root/.config/corepack


# ------------------------------------------------
# 2. Install NVM for root
# ------------------------------------------------

echo
echo "==> Installing NVM ${NVM_VERSION} for root..."

if [ -d "/root/.nvm" ]; then
    echo "    Existing NVM found, removing..."
    rm -rf /root/.nvm
fi

# Install NVM as root
curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash

# Load NVM into current shell
export NVM_DIR="/root/.nvm"

if [ -s "$NVM_DIR/nvm.sh" ]; then
    source "$NVM_DIR/nvm.sh"
else
    echo "ERROR: NVM installation failed."
    exit 1
fi

# Add NVM to root's profile for persistence
if ! grep -q "NVM_DIR" /root/.bashrc; then
    cat >> /root/.bashrc << 'EOF'

# NVM configuration
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
EOF
fi

if ! grep -q "NVM_DIR" /root/.profile; then
    cat >> /root/.profile << 'EOF'

# NVM configuration
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
EOF
fi

echo "    NVM version:"
nvm --version

# ------------------------------------------------
# 3. Install latest Node.js
# ------------------------------------------------

echo
echo "==> Installing latest Node.js..."

nvm install node

# Make latest Node the default
nvm alias default node
nvm use node

echo
echo "    Node.js:"
node --version

echo "    npm:"
npm --version

# ------------------------------------------------
# 4. Update npm to latest
# ------------------------------------------------

echo
echo "==> Installing latest npm..."

npm install --global npm@latest

echo
echo "    npm:"
npm --version

# ------------------------------------------------
# 5. Install Corepack
# ------------------------------------------------

echo
echo "==> Installing latest Corepack..."

npm install --global corepack@latest

echo
echo "    Corepack:"
corepack --version

# ------------------------------------------------
# 6. Enable Corepack
# ------------------------------------------------

echo
echo "==> Enabling Corepack..."

corepack enable

# ------------------------------------------------
# 7. Install Yarn via Corepack
# ------------------------------------------------

echo
echo "==> Installing latest stable Yarn through Corepack..."

corepack install --global yarn@stable

echo
echo "    Yarn:"
yarn --version

# ------------------------------------------------
# 8. Install pnpm via Corepack
# ------------------------------------------------

echo
echo "==> Installing latest pnpm through Corepack..."

corepack install --global pnpm@latest

echo
echo "    pnpm:"
pnpm --version

# ------------------------------------------------
# 9. Install PM2 globally
# ------------------------------------------------

echo
echo "==> Installing PM2 globally..."

npm install --global pm2@latest

echo
echo "    PM2:"
pm2 --version

# ------------------------------------------------
# 10. Configure PM2 for root
# ------------------------------------------------

echo
echo "==> Configuring PM2 for root usage..."

# Initialize PM2 for root user
pm2 update

# Set PM2 to start on boot (for root)
# pm2 startup systemd -u root --hp /root || true

echo
echo "    PM2 startup command (add to /etc/rc.local if needed):"
echo "    su - root -c 'pm2 resurrect'"

# ------------------------------------------------
# 11. Create symlink for global access (optional)
# ------------------------------------------------

echo
echo "==> Creating symlinks for global access..."

# Create symlinks in /usr/local/bin for global access
if [ -d "/usr/local/bin" ]; then
    ln -sf /root/.nvm/versions/node/$(nvm version default)/bin/node /usr/local/bin/node || true
    ln -sf /root/.nvm/versions/node/$(nvm version default)/bin/npm /usr/local/bin/npm || true
    ln -sf /root/.nvm/versions/node/$(nvm version default)/bin/npx /usr/local/bin/npx || true
    ln -sf /root/.nvm/versions/node/$(nvm version default)/bin/corepack /usr/local/bin/corepack || true
    ln -sf /root/.nvm/versions/node/$(nvm version default)/bin/yarn /usr/local/bin/yarn || true
    ln -sf /root/.nvm/versions/node/$(nvm version default)/bin/pnpm /usr/local/bin/pnpm || true
    ln -sf /root/.nvm/versions/node/$(nvm version default)/bin/pm2 /usr/local/bin/pm2 || true
    echo "    ✓ Symlinks created in /usr/local/bin"
fi

# ------------------------------------------------
# 12. Final verification
# ------------------------------------------------

echo
echo "=============================================="
echo " Installation complete"
echo "=============================================="

echo
echo "NVM:"
nvm --version

echo
echo "Node.js:"
node --version

echo
echo "npm:"
npm --version

echo
echo "Corepack:"
corepack --version

echo
echo "Yarn:"
yarn --version

echo
echo "pnpm:"
pnpm --version

echo
echo "PM2:"
pm2 --version

echo
echo "=============================================="
echo " Installation locations"
echo "=============================================="

echo "NVM: /root/.nvm"
echo "Node.js: $(which node)"
echo "npm: $(which npm)"
echo "Yarn: $(which yarn)"
echo "pnpm: $(which pnpm)"
echo "PM2: $(which pm2)"

tail -n5  ~/.bashrc ~/.profile

echo
echo "=============================================="
echo " PM2 Setup for /etc/rc.local"
echo "=============================================="

echo
echo "To enable PM2 resurrect on boot via /etc/rc.local:"
echo "1. Add this line to /etc/rc.local before 'exit 0':"
echo "   su - root -c 'pm2 resurrect'"
echo
echo "2. Make sure /etc/rc.local is executable:"
echo "   chmod +x /etc/rc.local"
echo
echo "3. Or use the systemd service (recommended):"
echo "   env PATH=\$PATH:/usr/local/bin pm2 startup systemd -u root --hp /root"
echo "   pm2 save"

echo
echo "=============================================="
echo " Done!"
echo "=============================================="
