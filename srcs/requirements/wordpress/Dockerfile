FROM debian:bullseye

RUN apt-get update && \
    apt-get install -y \
        php-fpm \
        php-mysql \
        mariadb-client \
        curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp


COPY conf/wp.conf /etc/php/7.4/fpm/pool.d/wp.conf

COPY tools/wp_init.sh /usr/local/bin/wp_init.sh

RUN chmod +x /usr/local/bin/wp_init.sh

WORKDIR /var/www/html

CMD ["/usr/local/bin/wp_init.sh"]