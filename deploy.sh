#!/bin/bash

# Exit on error
#set -e

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

# Define user names
ADMIN_USER="${random_name}_${random_surname}"
ADMIN_PASS="$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | head -c 12)"
SERVICE_USER="interview_service_user"

echo "Generated SSH credentials:"
echo "Username: $SSH_USER"
echo "Password: $SSH_PASS"
echo "Please save these credentials!"

# Update system packages
echo "Updating system packages..."
sudo apt-get update
# sudo apt-get upgrade -y

# Install required system packages
echo "Installing required system packages..."
sudo apt-get install -y python3 python3-pip python3-venv curl wget

# Create admin user (can't connect via SSH, has sudo rights)
echo "Creating admin user..."
sudo useradd -m -s /bin/bash "$ADMIN_USER"
echo "$ADMIN_USER:$ADMIN_PASS" | sudo chpasswd
sudo usermod -aG sudo "$ADMIN_USER"

# Create service user (can't connect via SSH, no sudo rights)
echo "Creating service user..."
sudo useradd -r -s /bin/false "$SERVICE_USER"
sudo mkdir -p /opt/app
sudo chown "$SERVICE_USER:$SERVICE_USER" /opt/app

# Clone repository
echo "Cloning repository..."
cd /opt/app
sudo -u "$SERVICE_USER" git clone http://demo:demo123@localhost:3000/demo/interview-service.git
sudo chown -R "$SERVICE_USER:$SERVICE_USER" /opt/app/interview-service

# Setup code-server for admin user
echo "Setting up code-server for $ADMIN_USER..."
sudo -u "$ADMIN_USER" bash -c "curl -fsSL https://code-server.dev/install.sh | sh"

# Create code-server config directory
sudo mkdir -p /home/"$ADMIN_USER"/.config/code-server
sudo chown -R "$ADMIN_USER:$ADMIN_USER" /home/"$ADMIN_USER"/.config

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
sudo tee /etc/systemd/system/code-server@.service > /dev/null <<EOF
[Unit]
Description=code-server
After=network.target

[Service]
Type=exec
ExecStart=/home/%i/.local/bin/code-server --config /home/%i/.config/code-server/config.yaml /opt/app/interview-service
Restart=always
User=%i
Environment=HOME=/home/%i

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and start services
echo "Starting services..."
sudo systemctl daemon-reload
sudo systemctl enable tech-interview-stand-backend
sudo systemctl enable tech-interview-stand-binance
sudo systemctl enable code-server@"$ADMIN_USER"
sudo systemctl start tech-interview-stand-backend
sudo systemctl start tech-interview-stand-binance
sudo systemctl start code-server@"$ADMIN_USER"
sudo systemctl restart nginx

echo "Deployment completed successfully!"

# Get server IP
SERVER_IP=$(hostname -I | awk '{print $1}')

echo ""
echo "=========================================="
echo "SSH Username: $ADMIN_USER"
echo "SSH Password: $ADMIN_PASS"
echo "Code-Server URL: http://$SERVER_IP:8080"
echo "Code-Server Password: $CODE_SERVER_PASSWORD"
echo "==========================================" 