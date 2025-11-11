#!/bin/bash
sudo yum update -y

# Install Apache HTTPD
sudo yum install -y httpd

# Enable and start Apache
sudo systemctl enable httpd
sudo systemctl start httpd

# Clean the default HTML directory
sudo rm -rf /var/www/html/*

# Copy built frontend files (assumed baked inside AMI at /root/frontend/dist)
sudo cp -r /root/frontend/dist/* /var/www/html/

# Restart Apache to apply changes
sudo systemctl restart httpd

echo "✅ Frontend deployed successfully and running on port 80"

