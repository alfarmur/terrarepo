#!/bin/bash
# =========================
# Backend Auto Setup Script
# =========================

# Update system packages
yum update -y

# Install Node.js (v18 LTS) and Git
curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
yum install -y nodejs git

# Install PM2 globally (for process management)
npm install -g pm2

# Navigate to home directory
cd /home/ec2-user

# Clone your backend repository (replace with your Git repo)
git clone https://github.com/CloudTechDevOps/2nd10WeeksofCloudOps-main.git 
cd 2nd10WeeksofCloudOps-main
# Go into backend folder
cd backend

# Install dependencies
npm install

# Create .env file (edit values as needed)
cat <<EOF > .env
DB_HOST=database-1.cmza4syuu81x.us-east-1.rds.amazonaws.com
DB_USER=admin
DB_PASSWORD=irumporaI
DB_NAME=test
PORT=3000
EOF

# Start the backend using PM2
pm2 start app.js --name backend

# Ensure PM2 restarts on reboot
pm2 startup systemd
pm2 save

# Enable port 3000
firewall-cmd --zone=public --add-port=3000/tcp --permanent
firewall-cmd --reload
