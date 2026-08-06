FROM debian:bullseye

RUN apt-get update && apt-get install -y nginx

COPY tools/nginx.sh /usr/local/bin/nginx.sh

COPY conf/nginx.conf /etc/nginx/sites-available/default

RUN chmod +x /usr/local/bin/nginx.sh

ENTRYPOINT ["/usr/local/bin/nginx.sh"]
