#!/bin/bash
# ─── userdata.sh ───────────────────────────────────────────────
# Grafana EC2 bootstrap — runs once on first boot
# Installs Docker, issues SSL cert, sets up renewal cron
# Actual stack deployment is handled by GitHub Actions

set -euo pipefail

DOMAIN="${domain_name}"
EMAIL="${admin_email}"

LOG=/var/log/grafana-bootstrap.log
exec >> "$LOG" 2>&1
echo "=== Bootstrap started at $(date) ==="

# ── 1. Install dependencies ───────────────────────────────────
dnf update -y
dnf install -y docker git python3-pip
pip3 install certbot

systemctl enable docker
systemctl start docker

# Install Docker Compose plugin — not in AL2023 default repos, download binary directly
mkdir -p /usr/local/lib/docker/cli-plugins
curl -SL https://github.com/docker/compose/releases/download/v2.35.1/docker-compose-linux-x86_64 \
  -o /usr/local/lib/docker/cli-plugins/docker-compose
chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

echo "Docker, Compose plugin, and certbot installed"

# ── 2. Create webroot for ACME challenge ──────────────────────
mkdir -p /var/www/certbot

# ── 3. Bootstrap nginx for ACME challenge ─────────────────────
# Inline minimal config — avoids dependency on repo being cloned
cat > /tmp/nginx-bootstrap.conf << 'NGINX'
events { worker_connections 1024; }
http {
  server {
    listen 80;
    location /.well-known/acme-challenge/ {
      root /var/www/certbot;
    }
    location / {
      return 200 "OK\n";
      add_header Content-Type text/plain;
    }
  }
}
NGINX

docker run -d \
  --name nginx-bootstrap \
  -p 80:80 \
  -v /var/www/certbot:/var/www/certbot \
  -v /tmp/nginx-bootstrap.conf:/etc/nginx/nginx.conf:ro \
  nginx:1.27-alpine

echo "Bootstrap nginx started, waiting for readiness..."
sleep 5

# ── 4. Issue SSL certificate ──────────────────────────────────
certbot certonly \
  --webroot \
  --webroot-path /var/www/certbot \
  --non-interactive \
  --agree-tos \
  --email "$EMAIL" \
  -d "$DOMAIN"

echo "SSL cert issued for $DOMAIN"

# ── 5. Stop bootstrap nginx ───────────────────────────────────
docker stop nginx-bootstrap && docker rm nginx-bootstrap

# ── 6. Auto-renewal cron (twice daily) ───────────────────────
mkdir -p /etc/cron.d
cat > /etc/cron.d/certbot-renew << 'CRON'
0 3,15 * * * root certbot renew --quiet --deploy-hook "cd /home/ec2-user/aws-grafana && docker compose exec -T nginx nginx -s reload" 2>&1 | logger -t certbot
CRON
chmod 644 /etc/cron.d/certbot-renew

# ── 7. Prepare app directory ──────────────────────────────────
mkdir -p /home/ec2-user/aws-grafana
chown ec2-user:ec2-user /home/ec2-user/aws-grafana

echo "=== Bootstrap complete at $(date) ==="
echo "Next: push to GitHub to trigger Actions deployment"
