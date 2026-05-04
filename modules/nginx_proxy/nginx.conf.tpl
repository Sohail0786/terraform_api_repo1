#!/bin/bash
set -euo pipefail

# Install Nginx on Amazon Linux 2023
dnf install -y nginx

# Write Nginx config
cat > /etc/nginx/conf.d/proxy.conf <<'NGINX'
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass          ${upstream_url};
        proxy_set_header    Host              $host;
        proxy_set_header    X-Real-IP         $remote_addr;
        proxy_set_header    X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header    X-Forwarded-Proto $scheme;
        proxy_read_timeout  60s;
        proxy_connect_timeout 5s;
    }

    location /health {
        return 200 "ok\n";
        add_header Content-Type text/plain;
    }
}
NGINX

# Enable and start
systemctl enable nginx
systemctl start nginx
