FROM debian:bullseye

RUN apt-get update && apt-get install -y mariadb-server 

COPY tools/db_init.sh /usr/local/bin/db_init.sh

RUN chmod +x /usr/local/bin/db_init.sh

ENTRYPOINT ["/usr/local/bin/db_init.sh"]