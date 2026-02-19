FROM library/nginx:1.29.5
RUN echo "Custom Nginx configuration for Cosign testing" > /usr/share/nginx/html/index.html
