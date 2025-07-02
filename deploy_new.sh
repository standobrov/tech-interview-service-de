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

# Install required system packages including Docker
log "📦 Installing required packages..."
apt-get install -y python3 python3-pip python3-venv curl wget git sqlite3 docker.io docker-compose

# Ensure Docker is running
log "🐳 Ensuring Docker is running..."
systemctl enable docker
systemctl start docker

# Wait for Docker to be fully ready
sleep 10

# Verify Docker is working
log "🔍 Verifying Docker installation..."
if ! docker info >/dev/null 2>&1; then
    log "❌ Docker is not running properly"
    systemctl status docker
    exit 1
fi

# Test Docker with hello-world
if ! docker run --rm hello-world >/dev/null 2>&1; then
    log "❌ Docker test failed"
    exit 1
fi

log "✅ Docker is working properly"

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

# Setup Gitea with Docker
log "🐳 Setting up Gitea..."
mkdir -p /opt/gitea
cd /opt/gitea

# Create Gitea docker-compose with SQLite (simpler setup)
cat > docker-compose.yml <<EOF
version: "3"

networks:
  gitea:
    external: false

services:
  server:
    image: gitea/gitea:1.21.4
    container_name: gitea
    environment:
      - USER_UID=1001
      - USER_GID=1001
      - GITEA__database__DB_TYPE=sqlite3
      - GITEA__database__PATH=/data/gitea/gitea.db
      - GITEA__server__DOMAIN=localhost
      - GITEA__server__SSH_DOMAIN=localhost
      - GITEA__server__ROOT_URL=http://localhost:3000/
      - GITEA__security__INSTALL_LOCK=true
      - GITEA__service__DISABLE_REGISTRATION=true
      - GITEA__service__REQUIRE_SIGNIN_VIEW=false
      - GITEA__security__SECRET_KEY=$(openssl rand -base64 32)
      - GITEA__security__INTERNAL_TOKEN=$(openssl rand -base64 32)
    restart: always
    networks:
      - gitea
    volumes:
      - ./gitea:/data
      - /etc/timezone:/etc/timezone:ro
      - /etc/localtime:/etc/localtime:ro
    ports:
      - "3000:3000"
      - "222:22"
    user: "1001:1001"
EOF

# Create gitea data directory with proper permissions
mkdir -p ./gitea
chown -R 1001:1001 ./gitea

# Start Gitea
log "🚀 Starting Gitea..."
docker-compose up -d

# Wait for Gitea to be ready
log "⏳ Waiting for Gitea to be ready..."
sleep 45

# Check if Gitea is responding
for i in {1..10}; do
    if curl -s http://localhost:3000 > /dev/null; then
        log "✅ Gitea is ready!"
        break
    fi
    log "⏳ Still waiting for Gitea... (attempt $i/10)"
    sleep 10
done

# Setup Gitea admin user
log "👤 Setting up Gitea admin user..."

# Create Gitea admin user using the proper method
docker exec -u git gitea gitea admin user create \
  --username "$ADMIN_USER" \
  --password "$ADMIN_PASS" \
  --email "$ADMIN_USER@interview.local" \
  --admin \
  --must-change-password=false || log "⚠️ User creation failed, might already exist"

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
        "name": "deployment-token"
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
        log "✅ Token created successfully"
        break
    fi
    log "⚠️ Token creation attempt $i failed, retrying..."
    sleep 5
done

# Fallback: generate a simple token for basic auth
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
if [ ! -z "$GITEA_TOKEN" ] && [ "$GITEA_TOKEN" != "$ADMIN_PASS" ]; then
    # Use token if available
    curl -s -X POST \
      "http://localhost:3000/api/v1/user/repos" \
      -H "Authorization: token $GITEA_TOKEN" \
      -H "Content-Type: application/json" \
      -d '{
        "name": "assignments",
        "description": "Technical interview assignments",
        "private": false,
        "auto_init": true
      }' || log "⚠️ Repository creation via token failed"
else
    # Use basic auth
    curl -s -X POST \
      "http://localhost:3000/api/v1/user/repos" \
      -u "$ADMIN_USER:$ADMIN_PASS" \
      -H "Content-Type: application/json" \
      -d '{
        "name": "assignments",
        "description": "Technical interview assignments",
        "private": false,
        "auto_init": true
      }' || log "⚠️ Repository creation via basic auth failed"
fi

# Wait a bit for repository to be ready
sleep 5

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

cd assignments
git init
git add .
git config user.email "$ADMIN_USER@interview.local"
git config user.name "$ADMIN_USER"
git commit -m "Initial assignments setup" || echo "Commit might have failed"

# Add remote and push
git remote add origin "http://$ADMIN_USER:$ADMIN_PASS@localhost:3000/$ADMIN_USER/assignments.git" || echo "Remote might already exist"
git push -u origin master || git push -u origin main || echo "Push might have failed"

# Clone assignments to admin user home directory
log "📥 Cloning assignments to admin user home..."
sudo -u "$ADMIN_USER" bash -c "
  cd /home/$ADMIN_USER
  git clone http://$ADMIN_USER:$ADMIN_PASS@localhost:3000/$ADMIN_USER/assignments.git
  git config --global user.email '$ADMIN_USER@interview.local'
  git config --global user.name '$ADMIN_USER'
"

# Setup code-server for admin user
log "💻 Setting up code-server for $ADMIN_USER..."
sudo -u "$ADMIN_USER" bash -c "curl -fsSL https://code-server.dev/install.sh | sh"

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

# Create systemd service for code-server
tee /etc/systemd/system/code-server@.service > /dev/null <<EOF
[Unit]
Description=code-server
After=network.target

[Service]
Type=exec
ExecStart=/home/%i/.local/bin/code-server --config /home/%i/.config/code-server/config.yaml /home/%i/assignments
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
