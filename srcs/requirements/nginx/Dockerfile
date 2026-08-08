FROM debian:bookworm

RUN apt-get update && apt-get install -y nginx openssl && apt-get clean

RUN mkdir -p /run/nginx
RUN mkdir -p /etc/ssl/certs
RUN openssl req -x509 -nodes  \
-keyout /etc/ssl/certs/nginx-selfsigned.key \
-out /etc/ssl/certs/nginx-selfsigned.crt \
-subj "/CN=yolaidi-.42.fr"

COPY conf/nginx.conf /etc/nginx/conf.d/conf.conf

ENTRYPOINT ["nginx", "-g", "daemon off;"]
