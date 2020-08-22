#!/bin/bash

export DEBIAN_FRONTEND=noninteractive
export CODE_SERVER_VERSION=3.4.1
export CODE_SERVER_WORKSPACE="/home/coder/workspace"
release=code-server-${CODE_SERVER_VERSION}-linux-amd64
touch /tmp/hello-world

sudo -s

# Install server components
apt-get update
apt-get install -y nginx

# Install tooling
apt-get install -y \
    curl \
    dumb-init \
    htop \
    locales \
    man \
    nano \
    git \
    procps \
    ssh \
    sudo \
    vim \
    lsb-release
sed -i "s/# en_US.UTF-8/en_US.UTF-8/" /etc/locale.gen
locale-gen

chsh -s /bin/bash
echo "LANG=en_US.UTF-8" >> /etc/environment

adduser --gecos '' --disabled-password coder
echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/nopasswd
mkdir -p "${CODE_SERVER_WORKSPACE}" /var/lib/code-server
chown coder:coder "${CODE_SERVER_WORKSPACE}" /var/lib/code-server

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

# Configure systemctl
touch /lib/systemd/system/code-server.service
cat << EOF >> /lib/systemd/system/code-server.service
[Unit]
Description=code-server
After=nginx.service

[Service]
Type=simple
Environment=PASSWORD="TF_PASSWORD"
ExecStart=/usr/bin/code-server ${CODE_SERVER_WORKSPACE} --bind-addr 127.0.0.1:8080 --user-data-dir /var/lib/code-server --auth password
Restart=always
User=coder

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
      proxy_pass http://127.0.0.1:8080/;
      proxy_set_header Upgrade \$http_upgrade;
      proxy_set_header Connection upgrade;
      proxy_set_header Accept-Encoding gzip;
      proxy_set_header X-Real-IP \$remote_addr;
      proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
      proxy_set_header Host \$host;
      proxy_set_header X-NginX-Proxy true;
      proxy_redirect http://127.0.0.1:8080/ https://\$server_name/;
    }
}
EOF
ln -s /etc/nginx/sites-available/code-server.conf /etc/nginx/sites-enabled/code-server.conf
unlink /etc/nginx/sites-enabled/default

nginx -t &> /tmp/nginx
systemctl restart nginx

# Secure the domain
add-apt-repository ppa:certbot/certbot -y
apt-get update
apt-get install -y python-certbot-nginx
certbot --nginx -d "TF_DOMAIN_URL" --non-interactive --agree-tos -m "TF_DOMAIN_WEBMASTER"

# Installing extensions to vscode
run_cs() {
  sudo su -c "code-server --user-data-dir /var/lib/code-server --extensions-dir /var/lib/code-server/extensions $@" coder
}

run_cs "--install-extension hashicorp.terraform"
run_cs "--install-extension vscode-icons-team.vscode-icons"
