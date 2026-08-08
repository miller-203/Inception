#!/bin/bash
set -e

mkdir -p /var/lib/mysql
mkdir -p /var/run/mysqld

chown -R mysql:mysql /var/lib/mysql
chown -R mysql:mysql /var/run/mysqld

if [ ! -d /var/lib/mysql/mysql ]; then
    echo "Initializing MariaDB..."

    mysql_install_db \
        --user=mysql \
        --datadir=/var/lib/mysql

    echo "Starting temporary MariaDB..."

    mysqld_safe \
        --datadir=/var/lib/mysql \
        --skip-networking \
        --socket=/var/run/mysqld/mysqld.sock &

    until mysqladmin \
        --protocol=SOCKET \
        --socket=/var/run/mysqld/mysqld.sock \
        -u root \
        ping --silent
    do
        sleep 1
    done

    echo "Creating database and users..."

    mysql --protocol=SOCKET --socket=/var/run/mysqld/mysqld.sock -u root << EOF

        CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
        CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
        GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
        ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
        FLUSH PRIVILEGES;
EOF

    echo "Stopping temporary MariaDB..."

    mysqladmin --protocol=SOCKET \
        --socket=/var/run/mysqld/mysqld.sock \
        -u root \
        -p"${MYSQL_ROOT_PASSWORD}" \
        shutdown

    echo "MariaDB initialized."

else
    echo "MariaDB already initialized."
fi

echo "Starting MariaDB..."

exec mysqld --user=mysql