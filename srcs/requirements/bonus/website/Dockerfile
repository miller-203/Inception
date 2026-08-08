FROM debian:bookworm

RUN apt-get update && apt-get install -y nginx

RUN mkdir -p /run/nginx

COPY conf/website.conf /etc/nginx/conf.d/website.conf
COPY index.html /var/www/html/index.html

ENTRYPOINT ["nginx", "-g", "daemon off;"]
