FROM shaojielinux/openresty:alpine
COPY conf.d /usr/local/openresty/nginx/conf/conf.d
COPY nginx.conf /usr/local/openresty/nginx/conf/nginx.conf 
RUN mkdir -p  /apps/openresty && mkdir -p /data/logs/resty
#COPY html /usr/local/openresty/nginx/html
COPY openresty /apps/openresty
