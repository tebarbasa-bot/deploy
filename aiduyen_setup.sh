#!/bin/bash
# ======================================================
# 🚀 AiDuyen Full Auto Deploy Script
# Author: 金泰来
# Domain: aiduyen.com
# Environment: Node.js + Express + PM2 + Nginx + SSL
# ======================================================

set -e

echo "🔧 Starting AiDuyen deployment setup..."

# === 1. Update & install dependencies ===
apt update -y
apt install -y curl git ufw nginx certbot python3-certbot-nginx

# === 2. Install Node.js LTS ===
curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
apt install -y nodejs
npm install -g pm2

# === 3. Setup project directory ===
mkdir -p /var/www/aiduyen
cd /var/www/aiduyen

# === 4. Create a simple Express app ===
cat <<'EOF' > app.js
const express = require('express');
const app = express();
app.get('/', (req, res) => {
  res.send('<h1>✨ Welcome to AiDuyen — Asian Romantic Voice Community ✨</h1><p>App Store / Google Play (Coming Soon)</p>');
});
app.listen(3000, () => console.log('✅ AiDuyen app is running on port 3000'));
EOF

npm init -y
npm install express

# === 5. Setup PM2 process ===
pm2 start app.js --name aiduyen
pm2 startup systemd -u root --hp /root
pm2 save

# === 6. Configure Nginx reverse proxy ===
cat <<'EOF' > /etc/nginx/sites-available/aiduyen
server {
    listen 80;
    server_name aiduyen.com www.aiduyen.com;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
EOF

ln -sf /etc/nginx/sites-available/aiduyen /etc/nginx/sites-enabled/
nginx -t && systemctl restart nginx

# === 7. Enable HTTPS ===
echo "🛡️  Setting up Let's Encrypt SSL for aiduyen.com ..."
certbot --nginx -d aiduyen.com -d www.aiduyen.com --non-interactive --agree-tos -m admin@aiduyen.com || echo "⚠️ SSL auto-setup skipped (manual DNS might be needed)"

echo "✅ Deployment completed!"
echo "🌍 Visit: http://aiduyen.com or https://aiduyen.com"
echo "🚀 Managed by PM2 (run: pm2 status)"
