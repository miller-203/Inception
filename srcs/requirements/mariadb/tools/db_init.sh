#!/bin/bash

mkdir -p /var/lib/mysql
mkdir -p /var/run/mysqld

chown -R mysql:mysql /var/lib/mysql
chown -R mysql:mysql /var/run/mysqld

rm -rf /var/lib/mysql/*

echo "Database already initialized"
ls -la /var/lib/mysql


if [ ! -d /var/lib/mysql/mysql ]; then
    mysql_install_db --user=mysql --datadir=/var/lib/mysql

    echo "Starting MariaDB server..."
    mysqld_safe --datadir=/var/lib/mysql --skip-networking & 

    until mysqladmin ping --silent; do
        sleep 1
    done 

mysql -u root << EOF
    CREATE DATABASE IF NOT EXISTS \`$MYSQL_DATABASE\`;
    CREATE USER IF NOT EXISTS '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';
    GRANT ALL PRIVILEGES ON \`$MYSQL_DATABASE\`.* TO '$MYSQL_USER'@'%';
    ALTER USER 'root'@'localhost' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';
    FLUSH PRIVILEGES;
EOF

    # mysqladmin -uroot -p"$MYSQL_ROOT_PASSWORD"  shutdown
    mysqladmin -u root -p"$MYSQL_ROOT_PASSWORD" shutdown

    fi


    echo "Starting MariaDB server..."
    exec mysqld --user=mysql