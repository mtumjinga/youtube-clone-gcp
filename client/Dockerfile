# Stage-1 & specify a name 'builder'
FROM node:18.20.2-alpine AS builder

# Create a directory and go to the directory  
WORKDIR /app

# Copy the package.json file to my current directory to install the necessary dependence   
COPY package.json .

# Install the dependence
RUN npm install

# Copy other files to my current directory
COPY . .

# Build and optimize static file
RUN npm run build

# Stage-2
FROM nginx:1.25.2-alpine-slim

# Remove the default nginx configuration
RUN rm /etc/nginx/conf.d/default.conf

# Create a new nginx configuration
RUN echo ' \
server { \
    listen 80; \
    server_name localhost; \
    \
    location / { \
        root   /usr/share/nginx/html; \
        index  index.html index.htm; \
        try_files $uri $uri/ /index.html; \
    } \
    \
    location /api { \
        proxy_pass http://server:8800; \
        proxy_http_version 1.1; \
        proxy_set_header Upgrade $http_upgrade; \
        proxy_set_header Connection "upgrade"; \
        proxy_set_header Host $host; \
        proxy_cache_bypass $http_upgrade; \
    } \
}' > /etc/nginx/conf.d/default.conf

# Copy the static file to my Nginx folder to serve static contain
COPY --from=builder /app/build /usr/share/nginx/html

# Open the port to react
EXPOSE 80

# Run nginx in the foreground
CMD ["nginx", "-g", "daemon off;"]