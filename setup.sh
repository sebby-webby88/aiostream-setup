#!/bin/bash

echo "=== Checking Docker ==="

if ! command -v docker &> /dev/null; then
    echo "Docker not found. Installing..."
    sudo apt-get update
    sudo apt-get install -y docker.io docker-compose-plugin
fi

if ! groups | grep -q docker; then
    echo "Adding user to docker group..."
    sudo usermod -aG docker $USER
    echo "Added to docker group. Applying changes..."
    exec newgrp docker
fi

sudo service docker start 2>/dev/null || sudo systemctl start docker 2>/dev/null || true

echo "Docker is ready!"
echo ""

ENV_FILE=".env"
ENV_SAMPLE=".env_sample"

if [ -f "$ENV_FILE" ]; then
    read -p ".env already exists. Overwrite? (y/N): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo "Setup cancelled."
        exit 0
    fi
fi

if [ ! -f "$ENV_SAMPLE" ]; then
    echo "Error: $ENV_SAMPLE not found."
    exit 1
fi

cp "$ENV_SAMPLE" "$ENV_FILE"

sed -i 's/^EMAIL_ADDRES=/EMAIL_ADDRESS=/' "$ENV_FILE"

detect_timezone() {
    if command -v timedatectl &> /dev/null; then
        tz=$(timedatectl show --property=Timezone --value 2>/dev/null)
    fi
    if [ -z "$tz" ] && [ -f /etc/timezone ]; then
        tz=$(cat /etc/timezone 2>/dev/null)
    fi
    if [ -z "$tz" ]; then
        tz=$(date +%Z 2>/dev/null)
    fi
    echo "$tz"
}

tz=$(detect_timezone)
if [ -n "$tz" ]; then
    sed -i "s|^TIMEZONE=|TIMEZONE=$tz|" "$ENV_FILE"
    echo "Detected timezone: $tz"
fi

echo ""
echo "=== AIOStreams Setup ==="
echo ""

read -p "Enter email for Let's Encrypt (traefik): " email
if [ -n "$email" ]; then
    sed -i "s%^EMAIL_ADDRESS=%EMAIL_ADDRESS=$email%" "$ENV_FILE"
fi

read -p "Enter your domain (e.g., aiostreams.example.com): " domain
if [ -n "$domain" ]; then
    sed -i "s%^DOMAIN_NAME=%DOMAIN_NAME=$domain%" "$ENV_FILE"
fi

read -p "Enter addon password (optional, press Enter to skip): " password
if [ -n "$password" ]; then
    sed -i "s%^ADDON_PASSWORD=%ADDON_PASSWORD=$password%" "$ENV_FILE"
fi

echo "Generating SECRET_KEY..."
secret_key=$(openssl rand -hex 32)
sed -i "s|^SECRET_KEY=|SECRET_KEY=$secret_key|" "$ENV_FILE"

echo ""
echo "Setup complete!"
echo "Run './aiostream up' to start the containers."
