#!/bin/bash
set -eo pipefail

##
# Variables
##
export CODE_SERVER_VERSION=3.4.1

release=code-server-${CODE_SERVER_VERSION}-linux-arm64
##

# Install essential dependencies
apt update
apt upgrade -y
apt install -y nginx
sudo ufw app list
sudo ufw allow 'Nginx HTTP'
sudo ufw allow https
sudo ufw reload
sudo ufw status

##

mkdir ~/code-server
cd ~/code-server

# Download code-server
wget https://github.com/cdr/code-server/releases/download/v${CODE_SERVER_VERSION}/${release}.tar.gz
tar -xzvf ${release}.tar.gz
rm ${release}.tar.gz

# Install code-server
sudo cp -r ${release} /usr/lib/code-server
rm -rf ${release}
sudo ln -s /usr/lib/code-server/bin/code-server /usr/bin/code-server
sudo mkdir /var/lib/code-server

# Configure systemctl
cat << EOF >> /lib/systemd/system/code-server.service
[Unit]
Description=code-server
After=nginx.service

[Service]
Type=simple
Environment=PASSWORD=your_password
ExecStart=/usr/bin/code-server --bind-addr 127.0.0.1:8080 --user-data-dir /var/lib/code-server --auth password
Restart=always

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl start code-server
sudo systemctl status code-server
sudo systemctl enable code-server

# Domain configuration
cat << EOF >> /etc/nginx/sites-available/code-server.conf
server {
    listen 80;
    listen [::]:80;

    server_name codespaces.jrbeverly.dev;

    location / {
      proxy_pass http://localhost:8080/;
      proxy_set_header Upgrade $http_upgrade;
      proxy_set_header Connection upgrade;
      proxy_set_header Accept-Encoding gzip;
    }
}
EOF
sudo ln -s /etc/nginx/sites-available/code-server.conf /etc/nginx/sites-enabled/code-server.conf
sudo nginx -t
sudo systemctl restart nginx

# Secure the domain
sudo add-apt-repository ppa:certbot/certbot
sudo apt install python-certbot-nginx
#sudo certbot --nginx -d codespaces.jrbeverly.dev # Must supply non-interactive