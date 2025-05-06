#!/bin/bash

# Define project directory and user
PROJECT_DIR="/home/ec2-user/myproject"  # Replace with your project directory
USER="your-username"  # Replace with your system username

# Create Gunicorn systemd service file
echo "Creating Gunicorn service file..."

cat > /etc/systemd/system/gunicorn.service <<EOF
[Unit]
Description=gunicorn daemon
After=network.target

[Service]
User=$USER
Group=www-data
WorkingDirectory=$PROJECT_DIR
ExecStart=$PROJECT_DIR/venv/bin/gunicorn --workers 3 --bind unix:$PROJECT_DIR/myproject.sock myproject.wsgi:application

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd to recognize the new service
systemctl daemon-reload

# Create Nginx config file
echo "Creating Nginx config file..."

cat > /etc/nginx/sites-available/myproject <<EOF
server {
    listen 80;
    server_name localhost;

    location = /favicon.ico { access_log off; log_not_found off; }
    location /static/ {
        root $PROJECT_DIR;
    }

    location / {
        include proxy_params;
        proxy_pass http://unix:$PROJECT_DIR/myproject.sock;
    }
}
EOF

# Create a symbolic link to enable the site
ln -s /etc/nginx/sites-available/myproject /etc/nginx/sites-enabled/

# Test Nginx configuration and restart Nginx
nginx -t && systemctl restart nginx

# Enable and start Gunicorn service
systemctl enable gunicorn
systemctl start gunicorn

echo "Deployment setup completed successfully!"

