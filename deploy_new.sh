#!/bin/bash

# Exit on error and enable logging
set -e
set -o pipefail

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a /root/deployment.log
}

# Error handler
error_handler() {
    log "❌ ERROR: Deployment failed at line $1"
    log "❌ Exit code: $2"
    exit $2
}

trap 'error_handler $LINENO $?' ERR

log "🚀 Starting Tech Interview Service Deployment"

# Word lists for username generation
names=(
    "hungry" "sleepy" "angry" "sad" "happy" "excited" "bored" "tired" "sick"
)

surnames=(
    "naruto" "sasuke" "sakura" "kakashi" "jiraiya" "tsunade" "orochimaru" "itachi" "madara" "obito"
    "shikamaru" "choji" "ino" "neji" "rocklee" "gaara" "temari" "kankuro" "hinata"
    "minato" "deidara" "kisame" "pain"
)

# Generate random username from words
random_name=${names[$RANDOM % ${#names[@]}]}
random_surname=${surnames[$RANDOM % ${#surnames[@]}]}

# Define user names and passwords
ADMIN_USER="${random_name}_${random_surname}"
ADMIN_PASS="$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | head -c 12)"
SERVICE_USER="interview_service_user"

echo "=========================================="
log "🚀 Starting Tech Interview Service Deployment"
echo "=========================================="

# Generate SSH key pair for admin user
log "📝 Generating SSH key pair for $ADMIN_USER..."
SSH_KEY_PATH="/tmp/admin_key"
ssh-keygen -t rsa -b 4096 -f "$SSH_KEY_PATH" -N "" -C "$ADMIN_USER@interview-server"

# Store SSH keys
ADMIN_PRIVATE_KEY=$(cat "$SSH_KEY_PATH")
ADMIN_PUBLIC_KEY=$(cat "$SSH_KEY_PATH.pub")

# Update system packages
log "📦 Updating system packages..."
apt-get update -y

# Install required system packages
log "📦 Installing required packages..."
apt-get install -y python3 python3-pip python3-venv curl wget git sqlite3

# Install Python packages including pandas
log "🐍 Installing Python packages..."
# Use system packages where possible, pip with --break-system-packages for others
apt-get install -y python3-pandas python3-numpy python3-matplotlib python3-seaborn python3-jupyter-core python3-ipython || true
pip3 install --break-system-packages jupyter pandas numpy matplotlib seaborn 2>/dev/null || pip3 install jupyter pandas numpy matplotlib seaborn --user 2>/dev/null || log "⚠️ Pip packages installation failed"

# Create git user for Gitea
log "� Creating git user for Gitea..."
adduser --system --shell /bin/bash --gecos 'Git Version Control' --group --disabled-password --home /home/git git

# Download and install Gitea
log "� Downloading and installing Gitea..."
wget -O /usr/local/bin/gitea https://dl.gitea.io/gitea/1.21.4/gitea-1.21.4-linux-amd64
chmod +x /usr/local/bin/gitea

# Create Gitea directories
mkdir -p /var/lib/gitea/{custom,data,log}
chown -R git:git /var/lib/gitea/
chmod -R 750 /var/lib/gitea/
mkdir -p /etc/gitea
chown root:git /etc/gitea
chmod 770 /etc/gitea

# Create admin user with SSH access
log "👤 Creating admin user: $ADMIN_USER..."
useradd -m -s /bin/bash "$ADMIN_USER"
echo "$ADMIN_USER:$ADMIN_PASS" | chpasswd
usermod -aG sudo "$ADMIN_USER"

# Setup SSH for admin user
mkdir -p /home/"$ADMIN_USER"/.ssh
echo "$ADMIN_PUBLIC_KEY" > /home/"$ADMIN_USER"/.ssh/authorized_keys
chmod 700 /home/"$ADMIN_USER"/.ssh
chmod 600 /home/"$ADMIN_USER"/.ssh/authorized_keys
chown -R "$ADMIN_USER:$ADMIN_USER" /home/"$ADMIN_USER"/.ssh

# Create service user (no SSH access)
log "👤 Creating service user: $SERVICE_USER..."
useradd -r -s /bin/false "$SERVICE_USER"

# Setup Gitea systemd service
log "� Setting up Gitea systemd service..."
cat > /etc/systemd/system/gitea.service <<EOF
[Unit]
Description=Gitea (Git with a cup of tea)
After=syslog.target
After=network.target

[Service]
Type=simple
User=git
Group=git
WorkingDirectory=/var/lib/gitea/
RuntimeDirectory=gitea
ExecStart=/usr/local/bin/gitea web --config /etc/gitea/app.ini
Restart=always
Environment=USER=git HOME=/home/git GITEA_WORK_DIR=/var/lib/gitea

[Install]
WantedBy=multi-user.target
EOF

# Create initial Gitea configuration
log "⚙️ Creating Gitea configuration..."
cat > /etc/gitea/app.ini <<EOF
APP_NAME = Tech Interview Gitea
RUN_MODE = prod
RUN_USER = git

[repository]
ROOT = /home/git/gitea-repositories

[server]
DOMAIN = localhost
HTTP_PORT = 3000
ROOT_URL = http://localhost:3000/
DISABLE_SSH = false
SSH_PORT = 22
SSH_LISTEN_PORT = 2222
LFS_START_SERVER = true
OFFLINE_MODE = false

[database]
DB_TYPE = sqlite3
PATH = /var/lib/gitea/data/gitea.db

[session]
PROVIDER = file

[log]
MODE = file
LEVEL = info
ROOT_PATH = /var/lib/gitea/log

[security]
INSTALL_LOCK = true
SECRET_KEY = $(openssl rand -base64 32)

[service]
DISABLE_REGISTRATION = true
REQUIRE_SIGNIN_VIEW = false
REGISTER_EMAIL_CONFIRM = false
ENABLE_NOTIFY_MAIL = false
ALLOW_ONLY_EXTERNAL_REGISTRATION = false
ENABLE_CAPTCHA = false
DEFAULT_KEEP_EMAIL_PRIVATE = false
DEFAULT_ALLOW_CREATE_ORGANIZATION = true
ENABLE_PUSH_CREATE_USER = true
ENABLE_PUSH_CREATE_ORG = true

[picture]
DISABLE_GRAVATAR = false
ENABLE_FEDERATED_AVATAR = true

[openid]
ENABLE_OPENID_SIGNIN = true
ENABLE_OPENID_SIGNUP = true

[mailer]
ENABLED = false
EOF

# Set proper permissions
chown git:git /etc/gitea/app.ini
chmod 640 /etc/gitea/app.ini

# Create git repositories directory
mkdir -p /home/git/gitea-repositories
chown git:git /home/git/gitea-repositories

# Start Gitea service
log "🚀 Starting Gitea service..."
systemctl daemon-reload
systemctl enable gitea
systemctl start gitea

# Wait for Gitea to be ready
log "⏳ Waiting for Gitea to be ready..."
for i in {1..30}; do
    if curl -s http://localhost:3000 > /dev/null; then
        log "✅ Gitea is ready!"
        break
    fi
    log "⏳ Still waiting for Gitea... (attempt $i/30)"
    sleep 5
done

# Setup Gitea admin user
log "👤 Setting up Gitea admin user..."

# Create Gitea admin user using the binary
sudo -u git /usr/local/bin/gitea admin user create \
  --config /etc/gitea/app.ini \
  --username "$ADMIN_USER" \
  --password "$ADMIN_PASS" \
  --email "$ADMIN_USER@interview.local" \
  --admin || log "⚠️ User creation failed, might already exist"

# Get server IP
SERVER_IP=$(hostname -I | awk '{print $1}')

# Create access token for admin user using API
log "🔑 Creating Gitea access token..."
sleep 5

# Try to create token via API with better error handling
GITEA_TOKEN=""
for i in {1..3}; do
    GITEA_TOKEN=$(curl -s -X POST \
      "http://localhost:3000/api/v1/users/$ADMIN_USER/tokens" \
      -H "Content-Type: application/json" \
      -u "$ADMIN_USER:$ADMIN_PASS" \
      -d '{
        "name": "deployment-token",
        "scopes": ["write:repository", "write:user", "read:user"]
      }' | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    if 'sha1' in data:
        print(data['sha1'])
    else:
        print('')
except:
    print('')
" 2>/dev/null || echo "")
    
    if [ ! -z "$GITEA_TOKEN" ]; then
        log "✅ Token created successfully with scopes"
        break
    fi
    log "⚠️ Token creation attempt $i failed, retrying..."
    sleep 5
done

# Fallback: use basic auth
if [ -z "$GITEA_TOKEN" ]; then
    log "⚠️ Using password authentication instead of token"
    GITEA_TOKEN="$ADMIN_PASS"
fi

# Add SSH key to Gitea user
log "🔑 Adding SSH key to Gitea..."
if [ ! -z "$GITEA_TOKEN" ] && [ "$GITEA_TOKEN" != "$ADMIN_PASS" ]; then
    # Use token if available
    curl -s -X POST \
      "http://localhost:3000/api/v1/user/keys" \
      -H "Authorization: token $GITEA_TOKEN" \
      -H "Content-Type: application/json" \
      -d "{
        \"title\": \"Admin SSH Key\",
        \"key\": \"$ADMIN_PUBLIC_KEY\"
      }" || log "⚠️ SSH key addition via token failed"
else
    # Use basic auth
    curl -s -X POST \
      "http://localhost:3000/api/v1/user/keys" \
      -u "$ADMIN_USER:$ADMIN_PASS" \
      -H "Content-Type: application/json" \
      -d "{
        \"title\": \"Admin SSH Key\",
        \"key\": \"$ADMIN_PUBLIC_KEY\"
      }" || log "⚠️ SSH key addition via basic auth failed"
fi

# Create assignments repository
log "📁 Creating assignments repository..."
REPO_CREATED=false

# Try multiple methods to create repository
if [ ! -z "$GITEA_TOKEN" ] && [ "$GITEA_TOKEN" != "$ADMIN_PASS" ]; then
    # Method 1: Use token - create empty repository first
    RESPONSE=$(curl -s -X POST \
      "http://localhost:3000/api/v1/user/repos" \
      -H "Authorization: token $GITEA_TOKEN" \
      -H "Content-Type: application/json" \
      -d '{
        "name": "assignments",
        "description": "Technical interview assignments",
        "private": false,
        "auto_init": false
      }' 2>/dev/null || echo "")
    
    if echo "$RESPONSE" | grep -q '"name":"assignments"'; then
        log "✅ Empty repository created via token"
        REPO_CREATED=true
    fi
fi

if [ "$REPO_CREATED" = false ]; then
    # Method 2: Use basic auth - create empty repository
    RESPONSE=$(curl -s -X POST \
      "http://localhost:3000/api/v1/user/repos" \
      -u "$ADMIN_USER:$ADMIN_PASS" \
      -H "Content-Type: application/json" \
      -d '{
        "name": "assignments",
        "description": "Technical interview assignments",
        "private": false,
        "auto_init": false
      }' 2>/dev/null || echo "")
    
    if echo "$RESPONSE" | grep -q '"name":"assignments"'; then
        log "✅ Empty repository created via basic auth"
        REPO_CREATED=true
    fi
fi

if [ "$REPO_CREATED" = false ]; then
    log "⚠️ Repository creation failed, will try push-to-create method"
fi

# Wait a bit for repository to be ready
sleep 10

# Setup git in assignments folder and push to Gitea
log "📂 Setting up assignments repository..."
cd /root/tech-interview-service-de

# Make sure assignments directory exists and has content
if [ ! -d "assignments" ]; then
    log "⚠️ Creating assignments directory with task content..."
    mkdir -p assignments/task1 assignments/task2
    cp -r task1/* assignments/task1/ 2>/dev/null || echo "No task1 files to copy"
    cp -r task2/* assignments/task2/ 2>/dev/null || echo "No task2 files to copy"
fi

# Clone the existing repository from Gitea first (if it has content) or create locally
log "📥 Setting up repository with assignment files..."
rm -rf /tmp/gitea_assignments

# Since we created an empty repository, we'll set it up locally
log "📂 Setting up local repository..."
cd /root/tech-interview-service-de/assignments
git init
git add .
git config user.email "$ADMIN_USER@interview.local"
git config user.name "$ADMIN_USER"
git commit -m "Add technical interview assignments (task1 and task2)" || log "⚠️ Commit might have failed"

# Add remote and push
git remote add origin "http://$ADMIN_USER:$ADMIN_PASS@localhost:3000/$ADMIN_USER/assignments.git" 2>/dev/null || log "Remote might already exist"

# Push to main branch (Gitea default for new repos)
if git push -u origin master 2>/dev/null; then
    log "✅ Assignment files pushed to master branch"
elif git push -u origin main 2>/dev/null; then
    log "✅ Assignment files pushed to main branch"
else
    log "⚠️ Push failed, trying with force..."
    git push --set-upstream origin master --force 2>/dev/null || \
    git push --set-upstream origin main --force 2>/dev/null || \
    log "❌ All push attempts failed"
fi

# Clone assignments to admin user home directory
log "📥 Cloning assignments to admin user home..."

# Wait a bit more for repository to be available
sleep 5

# Try cloning, if it fails, create assignments folder manually
log "🔄 Attempting to clone repository..."
if sudo -u "$ADMIN_USER" bash -c "
  cd /home/$ADMIN_USER
  git clone http://$ADMIN_USER:$ADMIN_PASS@localhost:3000/$ADMIN_USER/assignments.git 2>/dev/null
"; then
    log "✅ Repository cloned successfully"
else
    log "⚠️ Repository clone failed, creating local assignments folder..."
    # Copy assignments folder to a temporary location accessible by admin user
    log "📋 Copying assignments from /root to temp location..."
    cp -r /root/tech-interview-service-de/assignments /tmp/assignments_temp
    chown -R "$ADMIN_USER:$ADMIN_USER" /tmp/assignments_temp
    
    log "📂 Setting up local assignments folder for user..."
    sudo -u "$ADMIN_USER" bash -c "
      cd /home/$ADMIN_USER
      cp -r /tmp/assignments_temp ./assignments
      cd assignments
      git init
      git remote add origin http://$ADMIN_USER:$ADMIN_PASS@localhost:3000/$ADMIN_USER/assignments.git
      git config user.email '$ADMIN_USER@interview.local'
      git config user.name '$ADMIN_USER'
    "
    
    # Clean up temp folder
    rm -rf /tmp/assignments_temp
    log "✅ Local assignments folder created successfully"
fi

# Set global git config for admin user
log "⚙️ Setting up git configuration for $ADMIN_USER..."
sudo -u "$ADMIN_USER" bash -c "
  cd /home/$ADMIN_USER
  git config --global user.email '$ADMIN_USER@interview.local'
  git config --global user.name '$ADMIN_USER'
"

# Setup Python virtual environment for admin user
log "🐍 Setting up Python virtual environment for $ADMIN_USER..."
sudo -u "$ADMIN_USER" bash -c "
  cd /home/$ADMIN_USER
  python3 -m venv venv
  source venv/bin/activate
  pip install pandas numpy matplotlib seaborn jupyter ipython
  echo 'source ~/venv/bin/activate' >> .bashrc
"

log "✅ Git configuration and Python environment completed"

# Setup code-server for admin user
log "💻 Setting up code-server for $ADMIN_USER..."

# Install code-server via package manager to avoid sudo issues
log "📦 Installing code-server from package..."

# Set temporary environment to avoid /root access issues
export HOME=/tmp
export USER=root

curl -fsSL https://code-server.dev/install.sh | sh -s -- --method=standalone --prefix=/usr/local

# Reset environment
export HOME=/root
unset USER

# Verify installation
if [ ! -f "/usr/local/bin/code-server" ]; then
    log "⚠️ Standalone installation failed, trying alternative method..."
    # Alternative: download binary directly
    ARCH=$(uname -m)
    if [ "$ARCH" = "x86_64" ]; then
        ARCH="amd64"
    fi
    
    CODE_SERVER_VERSION="4.101.2"
    wget -O /tmp/code-server.tar.gz "https://github.com/coder/code-server/releases/download/v${CODE_SERVER_VERSION}/code-server-${CODE_SERVER_VERSION}-linux-${ARCH}.tar.gz"
    
    cd /tmp
    tar -xzf code-server.tar.gz
    cp "code-server-${CODE_SERVER_VERSION}-linux-${ARCH}/bin/code-server" /usr/local/bin/
    chmod +x /usr/local/bin/code-server
    rm -rf /tmp/code-server*
fi

# Set ownership for admin user's code-server files
chown -R "$ADMIN_USER:$ADMIN_USER" /home/"$ADMIN_USER"

# Create code-server config directory
mkdir -p /home/"$ADMIN_USER"/.config/code-server
chown -R "$ADMIN_USER:$ADMIN_USER" /home/"$ADMIN_USER"/.config

# Generate code-server password
CODE_SERVER_PASSWORD="$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | head -c 12)"

# Create code-server config
sudo -u "$ADMIN_USER" tee /home/"$ADMIN_USER"/.config/code-server/config.yaml > /dev/null <<EOF
bind-addr: 0.0.0.0:8080
auth: password
password: $CODE_SERVER_PASSWORD
cert: false
EOF

# Setup code-server workspace settings with dark theme
log "🎨 Setting up code-server with dark theme and extensions..."
mkdir -p /home/"$ADMIN_USER"/.local/share/code-server/User
cat > /home/"$ADMIN_USER"/.local/share/code-server/User/settings.json <<EOF
{
    "workbench.colorTheme": "Default Dark+",
    "workbench.preferredDarkColorTheme": "Default Dark+",
    "workbench.preferredLightColorTheme": "Default Light+",
    "editor.theme": "Default Dark+",
    "window.autoDetectColorScheme": false,
    "workbench.startupEditor": "welcomePage",
    "files.autoSave": "afterDelay",
    "files.autoSaveDelay": 1000,
    "editor.fontSize": 14,
    "editor.tabSize": 4,
    "editor.insertSpaces": true,
    "python.defaultInterpreterPath": "/home/$ADMIN_USER/venv/bin/python",
    "csv-edit.readOption_hasHeader": "true",
    "csv-edit.writeOption_hasHeader": "true",
    "rainbow_csv.enable_auto_csv_lint": true,
    "rainbow_csv.enable_tooltip": true
}
EOF

# Set proper ownership for code-server config
chown -R "$ADMIN_USER:$ADMIN_USER" /home/"$ADMIN_USER"/.local

# Create systemd service for code-server
tee /etc/systemd/system/code-server@.service > /dev/null <<EOF
[Unit]
Description=code-server
After=network.target

[Service]
Type=exec
ExecStart=/usr/local/bin/code-server --config /home/%i/.config/code-server/config.yaml /home/%i/assignments
Restart=always
User=%i
Environment=HOME=/home/%i

[Install]
WantedBy=multi-user.target
EOF

# Start services
log "🚀 Starting services..."
systemctl daemon-reload
systemctl enable code-server@"$ADMIN_USER"
systemctl start code-server@"$ADMIN_USER"

# Wait for code-server to start and install extensions
log "📦 Installing code-server extensions..."
sleep 10

# Install extensions for the admin user
sudo -u "$ADMIN_USER" bash -c "
  # Install Rainbow CSV extension
  /usr/local/bin/code-server --install-extension mechatroner.rainbow-csv --user-data-dir /home/$ADMIN_USER/.local/share/code-server --config /home/$ADMIN_USER/.config/code-server/config.yaml
  
  # Install Python extension
  /usr/local/bin/code-server --install-extension ms-python.python --user-data-dir /home/$ADMIN_USER/.local/share/code-server --config /home/$ADMIN_USER/.config/code-server/config.yaml
  
  # Install Jupyter extension
  /usr/local/bin/code-server --install-extension ms-toolsai.jupyter --user-data-dir /home/$ADMIN_USER/.local/share/code-server --config /home/$ADMIN_USER/.config/code-server/config.yaml
  
  # Install CSV Edit extension for better CSV handling
  /usr/local/bin/code-server --install-extension janisdd.vscode-edit-csv --user-data-dir /home/$ADMIN_USER/.local/share/code-server --config /home/$ADMIN_USER/.config/code-server/config.yaml
" 2>/dev/null || log "⚠️ Some extensions might not have installed"

# Restart code-server to load extensions
log "🔄 Restarting code-server to load extensions..."
systemctl restart code-server@"$ADMIN_USER"
sleep 5

# Cleanup temp SSH keys
rm -f "$SSH_KEY_PATH" "$SSH_KEY_PATH.pub"

# Verify services are running
log "🔍 Verifying services status..."
sleep 5

# Check Gitea
if curl -s http://localhost:3000 > /dev/null; then
    log "✅ Gitea is running"
else
    log "⚠️ Gitea might not be fully ready yet"
fi

# Check Gitea systemd service
if systemctl is-active --quiet gitea; then
    log "✅ Gitea systemd service is active"
else
    log "⚠️ Gitea systemd service is not active"
fi

# Check Code-Server
if systemctl is-active --quiet code-server@"$ADMIN_USER"; then
    log "✅ Code-Server is running"
else
    log "⚠️ Code-Server is not running properly"
fi

echo ""
echo "=========================================="
log "🎉 DEPLOYMENT COMPLETED SUCCESSFULLY!"
echo "=========================================="
echo ""
echo "📊 Server Information:"
echo "Server IP: $SERVER_IP"
echo ""
echo "👤 SSH Access:"
echo "Username: $ADMIN_USER"
echo "Password: $ADMIN_PASS"
echo "SSH Command: ssh $ADMIN_USER@$SERVER_IP"
echo ""
echo "🐙 Gitea Access:"
echo "URL: http://$SERVER_IP:3000"
echo "Username: $ADMIN_USER"
echo "Password: $ADMIN_PASS"
echo "Token: $GITEA_TOKEN"
echo ""
echo "💻 Code-Server Access:"
echo "URL: http://$SERVER_IP:8080"
echo "Password: $CODE_SERVER_PASSWORD"
echo ""
echo "📁 Repository:"
echo "Assignments available in: /home/$ADMIN_USER/assignments"
echo ""
echo "🔑 SSH Private Key (save this!):"
echo "$ADMIN_PRIVATE_KEY"
echo ""
echo "=========================================="

# Save credentials to file
cat > /root/deployment-info.txt <<EOF
Tech Interview Service - Deployment Information
==============================================

Server IP: $SERVER_IP
SSH Username: $ADMIN_USER
SSH Password: $ADMIN_PASS

Gitea URL: http://$SERVER_IP:3000
Gitea Username: $ADMIN_USER
Gitea Password: $ADMIN_PASS
Gitea Token: $GITEA_TOKEN

Code-Server URL: http://$SERVER_IP:8080
Code-Server Password: $CODE_SERVER_PASSWORD

SSH Private Key:
$ADMIN_PRIVATE_KEY

Repository: /home/$ADMIN_USER/assignments
EOF

echo "💾 Deployment info saved to: /root/deployment-info.txt"
log "💾 All credentials saved to /root/deployment-info.txt"
log "✅ Deployment completed successfully!"
