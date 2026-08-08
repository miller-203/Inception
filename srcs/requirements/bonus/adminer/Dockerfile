FROM debian:bookworm

RUN apt-get update && \
    apt-get install -y \
        curl \
        php \
        php-mysqli && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/www/html && \
    curl -fL https://www.adminer.org/latest.php \
    -o /var/www/html/index.php

EXPOSE 8080

ENTRYPOINT ["php", "-S", "0.0.0.0:8080", "-t", "/var/www/html"]