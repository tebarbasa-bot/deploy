#!/bin/bash
# =====================================================
# AiDuyen Full-Stack Auto Deployment Script (CentOS)
# Node.js + Nginx + HTTPS (Let's Encrypt)
# Author: 金泰来
# =====================================================

set -e

echo "🚀 Starting AiDuyen deployment setup..."

# --- Step 1: System Update ---
yum update -y

# --- Step 2: Install dependencies ---
yum install -y curl wget git unzip epel-release

# --- Step 3: Install Node.js (LTS) ---
curl -fsSL https://rpm.nodesource.com/setup_lts.x | bash -
yum install -y nodejs

# --- Step 4: Verify Node & NPM ---
node -v
npm -v

# --- Step 5: Install PM2 (for app process management) ---
npm install -g pm2

# --- Step 6: Install Nginx ---
yum install -y nginx
systemctl enable nginx
systemctl start nginx

# --- Step 7: Setup Project Folder ---
mkdir -p /var/www/aiduyen
cd /var/www/aiduyen

# --- Step 8: Clone from GitHub (placeholder for your project) ---
if [ ! -d ".git" ]; then
  git clone https://github.com/tebarbasa-bot/deploy.git .
fi

# --- Step 9: Create Example App (Express.js) ---
cat > app.js <<'EOF'
const express = require('express');
const app = express();
const PORT = 3000;

app.get('/', (req, res) => {
  res.send('<h1>✨ AiDuyen — Asian Romance Chat Community ✨</h1><p>Server is running successfully!</p>');
});

app.listen(PORT, () => console.log(`Server running on http://localhost:${PORT}`));
EOF

# --- Step 10: Run app with PM2 ---
pm2 start app.js --name aiduyen
pm2 save
pm2 startup systemd -u root --hp /root

# --- Step 11: Configure Nginx Reverse Proxy ---
cat > /etc/nginx/conf.d/aiduyen.conf <<EOF
server {
    listen 80;
    server_name aiduyen.com www.aiduyen.com;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

# --- Step 12: Restart Nginx ---
nginx -t && systemctl restart nginx

# --- Step 13: Setup HTTPS (Let's Encrypt) ---
if ! command -v certbot &> /dev/null; then
  yum install -y certbot python3-certbot-nginx
fi

echo "🔐 Applying Let's Encrypt SSL certificate..."
certbot --nginx -d aiduyen.com -d www.aiduyen.com --non-interactive --agree-tos -m admin@aiduyen.com || true

# --- Step 14: Final Check ---
echo "✅ Deployment complete!"
echo "🌐 Visit: https://aiduyen.com"
echo "🧠 PM2 Apps:"
pm2 list
