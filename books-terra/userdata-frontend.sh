#!/bin/bash
sudo su -

yum update -y
yum install -y git httpd nodejs

cd /root
git clone https://github.com/CloudTechDevOps/2nd10WeeksofCloudOps-main.git
cd 2nd10WeeksofCloudOps-main/client

# Configure backend API
BACKEND_API="http://backend.851725454959.realhandsonlabs.net"
cat > src/pages/config.js <<EOF
export const API_BASE_URL = "${BACKEND_API}";
EOF

npm install
npm run build
cp -r build/* /var/www/html/
systemctl start httpd
systemctl enable httpd
