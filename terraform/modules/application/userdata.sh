#!/bin/bash
yum update -y
yum install -y httpd mysql

# Start and enable Apache
systemctl start httpd
systemctl enable httpd

# Get instance metadata
INSTANCE_ID=$(ec2-metadata --instance-id | cut -d ' ' -f 2)
AZ=$(ec2-metadata --availability-zone | cut -d ' ' -f 2)

# Create a simple test page
cat > /var/www/html/index.html <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>Application Server</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 50px;
            background-color: #f0f0f0;
        }
        .container {
            background-color: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
        }
        h1 { color: #333; }
        .info { color: #666; margin: 10px 0; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Application Server</h1>
        <div class="info"><strong>Instance ID:</strong> $INSTANCE_ID</div>
        <div class="info"><strong>Availability Zone:</strong> $AZ</div>
        <div class="info"><strong>Database Endpoint:</strong> ${db_endpoint}</div>
        <div class="info"><strong>Database Name:</strong> ${db_name}</div>
    </div>
</body>
</html>
EOF

# Create health check endpoint
echo "OK" > /var/www/html/health.html

# Database connection info
cat > /var/www/html/db-info.txt <<EOF
Database Endpoint: ${db_endpoint}
Database Name: ${db_name}
EOF

# Set proper permissions
chmod 644 /var/www/html/*
chown apache:apache /var/www/html/*