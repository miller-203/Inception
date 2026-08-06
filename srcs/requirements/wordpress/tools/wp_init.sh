#!/bin/bash
set -e

mkdir -p /var/www/html
mkdir -p /var/www/html/wp-content/uploads

chown -R www-data:www-data /var/www/html

cd /var/www/html

echo "Waiting for MariaDB..."

until mysqladmin ping \
    -h"$MYSQL_HOST" \
    -u"$MYSQL_USER" \
    -p"$MYSQL_PASSWORD" \
    --silent
do
    sleep 1
done

if [ ! -f wp-config.php ]; then
    echo "Downloading WordPress..."

    wp core download --allow-root

    echo "Creating wp-config.php..."

    wp config create \
        --dbname="$MYSQL_DATABASE" \
        --dbuser="$MYSQL_USER" \
        --dbpass="$MYSQL_PASSWORD" \
        --dbhost="$MYSQL_HOST" \
        --allow-root

    echo "Installing WordPress..."

    wp core install \
        --url="$DOMAIN_NAME" \
        --title="$WP_TITLE" \
        --admin_user="$WP_ADMIN_USER" \
        --admin_password="$WP_ADMIN_PASSWORD" \
        --admin_email="$WP_ADMIN_EMAIL" \
        --skip-email \
        --allow-root

    echo "Creating WordPress user..."

    wp user create \
        "$WP_USER" \
        "$WP_USER_EMAIL" \
        --user_pass="$WP_USER_PASSWORD" \
        --role=author \
        --allow-root
fi

echo "Starting PHP-FPM..."

exec php-fpm7.4 -F