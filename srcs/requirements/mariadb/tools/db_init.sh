#!/bin/bash

mkdir -p /var/lib/mysql
mkdir -p /var/run/mysql

chown -R mysql:mysql /var/lib/mysql
chown -R mysql:mysql /var/run/mysql

if [ ! -d /var/lib/mysql/mysql ]; then
    mysql_install_db --user=mysql --datadir=/var/lib/mysql

    mysqld_safe --datadir=/var/lib/mysql & skip--networking 

    until mysqladmin ping --silent; do
        sleep 1
    done 

    mysql -u root << EOF
    CREATE DATABASE IF NOY EXISTS  $MYSQL_DATABASE;
    CREATE USER IF NOT EXISTS '$MYSQL_USER'@'%' IDENTIFIED BY 'MYSQL_PASSWORD';
    GRANT ALL PRIVILEGES ON $MYSQL_DATABASE.* TO '$MYSQL_USER'@'%;
    ALTER LOGIN root@localhost IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';
    FLUSH PRIVILEGES;
    EOF


    fi


    exec mysqld --user=mysql