#!/bin/bash
# -----------------------------
# Backend Server User Data Script
# -----------------------------

# Run as root automatically in user data
yum update -y
yum install -y git mariadb105-server nodejs

# Clone backend repo
cd /root
git clone https://github.com/CloudTechDevOps/2nd10WeeksofCloudOps-main.git
cd 2nd10WeeksofCloudOps-main/backend

# Import test database into RDS
mysql -h three-tier-db.cno8qcoek90b.us-east-1.rds.amazonaws.com -u admin -pirumporaI < test.sql

# Create .env file
cat > .env <<EOF
APP_PORT=3000
DB_HOST=database.threetier.internal
DB_PORT=3306
DB_NAME=test
DB_USERNAME=admin
DB_PASSWORD=irumporaI
EOF

# Install dependencies
npm install
npm install mysql2 express cors dotenv pm2 -g

# Start backend with PM2
pm2 start index.js --name backend
pm2 save
pm2 startup systemd -u root --hp /root
