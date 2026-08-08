FROM debian:bullseye

RUN apt-get update && \
    apt-get install -y mariadb-server && \
    rm -rf /var/lib/mysql/*

COPY tools/db_init.sh /usr/local/bin/db_init.sh
COPY conf/db.conf /etc/mysql/mariadb.conf.d/50-server.cnf

RUN chmod +x /usr/local/bin/db_init.sh

ENTRYPOINT ["/usr/local/bin/db_init.sh"]