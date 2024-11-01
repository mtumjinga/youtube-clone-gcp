# Stage-1 & specify a name 'builder'
FROM node:18.20.2-alpine AS builder

WORKDIR /app

COPY package.json .
RUN npm install
COPY . . 
RUN npm run build

# Stage-2
FROM nginx:1.25.2-alpine-slim

RUN rm /etc/nginx/conf.d/default.conf

# SSL-enabled nginx configuration
RUN echo ' \
server { \
    listen 80; \
    server_name markbosire.click; \
    location / { \
        return 301 https://$host$request_uri; \
    } \
} \
server { \
    listen 443 ssl; \
    server_name markbosire.click; \
    ssl_certificate /etc/letsencrypt/live/markbosire.click/fullchain.pem; \
    ssl_certificate_key /etc/letsencrypt/live/markbosire.click/privkey.pem; \
    ssl_protocols TLSv1.2 TLSv1.3; \
    ssl_ciphers HIGH:!aNULL:!MD5; \
    location / { \
        root /usr/share/nginx/html; \
        index index.html index.htm; \
        try_files $uri $uri/ /index.html; \
    } \
    location /api { \
        proxy_pass http://server:8800; \
        proxy_http_version 1.1; \
        proxy_set_header Upgrade $http_upgrade; \
        proxy_set_header Connection "upgrade"; \
        proxy_set_header Host $host; \
        proxy_cache_bypass $http_upgrade; \
    } \
}' > /etc/nginx/conf.d/default.conf

COPY --from=builder /app/build /usr/share/nginx/html
EXPOSE 80 443
CMD ["nginx", "-g", "daemon off;"]
