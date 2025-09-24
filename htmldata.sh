#!/bin/bash
exec > /var/log/user_data.log 2>&1
set -e
set -x

echo "🚀 Starting Nginx setup..."

# Update system
apt-get update -y

# Install Nginx
apt-get install -y nginx
systemctl enable nginx
systemctl start nginx

# Overwrite default Nginx config to serve index and proxy /submit to Node.js
cat <<'NGINX' | sudo tee /etc/nginx/sites-available/default > /dev/null
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    server_name _;

    root /usr/share/nginx/html;
    index index.html;

    location / {
        try_files /index.html =404;
    }

    location /submit {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
NGINX

# Validate and reload Nginx
sudo nginx -t && sudo systemctl reload nginx

# Deploy index page to Nginx root
cat << 'EOF' > /usr/share/nginx/html/index.html
<!DOCTYPE html>
<html>
<head>
    <title>Deployment Success</title>
</head>
<body style="font-family: Arial, sans-serif; text-align: center; margin-top: 50px;">
    <h1 style="color: green;">Hey! Your infrastructure is up and running /h1>
    <p>Auto Scaling Groups, Load Balancers, Target Groups, and Launch Templates were created successfully.</p>
</body>
</html>
EOF

echo "Nginx setup complete. Login page deployed and proxy configured."

