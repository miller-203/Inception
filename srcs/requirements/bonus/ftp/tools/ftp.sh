#!/bin/bash

FTP_PASSWORD=$(cat /run/secrets/ftp_password)

# Create required vsftpd directory
mkdir -p /var/run/vsftpd/empty

# Create FTP user with home directory pointing to WordPress volume

    useradd -m -d /var/www/html -s /bin/bash "$FTP_USER"
    echo "$FTP_USER":"${FTP_PASSWORD}" | chpasswd


usermod -aG www-data  "$FTP_USER"
chmod -R g+rwX /var/www/html
chmod  g+s /var/www/html

echo "Starting ftpd..."
exec vsftpd /etc/vsftpd.conf