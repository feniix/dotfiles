#!/bin/bash
# User data script for ${project_name} in ${environment}

set -e

# Update system and install packages
yum update -y
yum install -y httpd curl git htop

# Start Apache
systemctl start httpd
systemctl enable httpd

# Create simple web page
cat > /var/www/html/index.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>${project_name} - ${environment}</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .info { background: #f4f4f4; padding: 20px; border-radius: 5px; }
    </style>
</head>
<body>
    <h1>Welcome to ${project_name}</h1>
    <div class="info">
        <p>Environment: ${environment}</p>
        <p>Started: $(date)</p>
        <p>Hostname: $(hostname)</p>
    </div>
</body>
</html>
EOF

# Create application directory
mkdir -p /opt/${project_name}
chown ec2-user:ec2-user /opt/${project_name}

# Simple configuration
cat > /opt/${project_name}/config.json << EOF
{
    "project": "${project_name}",
    "environment": "${environment}",
    "version": "1.0.0",
    "settings": {
        "port": 8080,
        "debug": true
    }
}
EOF

echo "Setup completed successfully!" > /var/log/userdata.log 