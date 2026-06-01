FROM nginx:alpine
COPY dashboard/hvac-boc.html /usr/share/nginx/html/index.html
EXPOSE 80
