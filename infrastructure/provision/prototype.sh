#!/bin/bash

export DEBIAN_FRONTEND=noninteractive
export CODE_SERVER_VERSION=3.4.1
release=code-server-${CODE_SERVER_VERSION}-linux-arm64

touch /tmp/hello-world

sudo -s
apt-get update
apt-get install -y nginx

#
mkdir /tmp/code-server
cd /tmp/code-server

# Download code-server
wget https://github.com/cdr/code-server/releases/download/v${CODE_SERVER_VERSION}/${release}.tar.gz
tar -xzvf ${release}.tar.gz
rm ${release}.tar.gz

# Install code-server
cp -r ${release} /usr/lib/code-server
rm -rf ${release}
ln -s /usr/lib/code-server/bin/code-server /usr/bin/code-server
mkdir /var/lib/code-server

# Configure systemctl
touch /lib/systemd/system/code-server.service
cat << EOF >> /lib/systemd/system/code-server.service
[Unit]
Description=code-server
After=nginx.service

[Service]
Type=simple
Environment=PASSWORD=TF_PASSWORD
ExecStart=/usr/bin/code-server --bind-addr 127.0.0.1:8080 --user-data-dir /var/lib/code-server --auth password
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl start code-server
systemctl status code-server
systemctl enable code-server

# Domain configuration
cat << EOF >> /etc/nginx/sites-available/code-server.conf
server {
    listen 80;
    listen [::]:80;

    server_name TF_DOMAIN_URL;

    location / {
      proxy_pass http://localhost:8080/;
      proxy_set_header Upgrade \$http_upgrade;
      proxy_set_header Connection upgrade;
      proxy_set_header Accept-Encoding gzip;
    }
}
EOF
ln -s /etc/nginx/sites-available/code-server.conf /etc/nginx/sites-enabled/code-server.conf
nginx -t &> /tmp/nginx
systemctl restart nginx

# Secure the domain
add-apt-repository ppa:certbot/certbot
apt install python-certbot-nginx

# ufw --force enable
# ufw default deny
# iptables -L
ufw app list
ufw allow 'Nginx HTTP'
ufw allow https
# ufw reload
ufw status