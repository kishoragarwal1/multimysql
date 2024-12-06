#!/bin/bash

# Update package list
echo "Updating package list..."
sudo apt update

# Install MySQL server
echo "Installing MySQL server..."
sudo apt install -y mysql-server
# sudo apt install -y mysql-server=8.0.40-0ubuntu0.24.04.1

# Modify MySQL configuration to allow remote connections
echo "Modifying MySQL configuration to allow remote connections..."
sudo sed -i '/bind-address/s/^#*\s*bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf

# Start MySQL and create the admin user
echo "Creating MySQL admin user..."
sudo mysql -u root <<EOF
CREATE USER 'admin'@'%' IDENTIFIED BY 'root@@1234';
GRANT ALL PRIVILEGES ON *.* TO 'admin'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;

SELECT user, host FROM mysql.user WHERE user = 'admin';

ALTER USER 'admin'@'%' IDENTIFIED BY 'root@@1234';
GRANT CREATE ON *.* TO 'admin'@'%';
GRANT ALL PRIVILEGES ON *.* TO 'admin'@'%';
EOF

# Enable UFW firewall rules for SSH and MySQL
echo "Configuring firewall..."
sudo ufw allow 22
sudo ufw allow 3306

# Enable and reload UFW firewall
echo "Enabling UFW firewall..."
sudo ufw enable
sudo ufw reload

echo "Restarting mysql server"
sudo systemctl restart mysql

echo "Script completed successfully."
