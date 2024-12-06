#!/bin/bash

# Check if the correct number of arguments are passed
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <mysql_instance_name> <port_number>"
    exit 1
fi

# Assign the parameters to variables
INSTANCE_NAME=$1
PORT=$2

# Check if the directory exists, and create it if not
if [ ! -d "/var/lib/$INSTANCE_NAME" ]; then
    sudo mkdir /var/lib/$INSTANCE_NAME
    sudo chown mysql:mysql /var/lib/$INSTANCE_NAME
else
    echo "Directory /var/lib/$INSTANCE_NAME already exists. Skipping creation."
fi

# Modify AppArmor configuration for MySQL instance and add permissions

echo "Modifying AppArmor configuration for MySQL instance and adding permissions"

# Create the permission lines
sudo sed -i '$!b; s/\(}\)/\
\/var\/lib\/'$INSTANCE_NAME'\/ r,\
\/var\/lib\/'$INSTANCE_NAME'\/\*\* rwk,\
\/var\/run\/mysqld\/'$INSTANCE_NAME'.sock rw,\
\/var\/run\/mysqld\/'$INSTANCE_NAME'.sock.lock rw,\
\/var\/run\/mysqld\/'$INSTANCE_NAME'.pid rw,\
\/run\/mysqld\/'$INSTANCE_NAME'.sock rw,\
\/run\/mysqld\/'$INSTANCE_NAME'.pid rw,\
\/run\/mysqld\/'$INSTANCE_NAME'.sock.lock rw,\
\1/' /etc/apparmor.d/usr.sbin.mysqld

# Reload AppArmor to apply changes
sudo apparmor_parser -r /etc/apparmor.d/usr.sbin.mysqld

# Initialize the MySQL instance with the given data directory and socket
sudo mysqld --initialize-insecure --user=mysql --datadir=/var/lib/$INSTANCE_NAME --socket=/var/run/mysqld/$INSTANCE_NAME.sock

# Copy the default MySQL configuration and name it dynamically
sudo cp /etc/mysql/my.cnf /etc/mysql/$INSTANCE_NAME.cnf

# Modify the copied MySQL config for the new instance
sudo bash -c "cat <<EOL > /etc/mysql/$INSTANCE_NAME.cnf
[mysqld]
datadir=/var/lib/$INSTANCE_NAME
socket=/var/run/mysqld/$INSTANCE_NAME.sock
port=$PORT
pid-file=/var/run/mysqld/$INSTANCE_NAME.pid
bind-address = 0.0.0.0
# Optional: Uncomment if you'd like error logging, change as necessary
# error-log=/var/log/mysql/$INSTANCE_NAME.err
EOL"

# Create a systemd service file for the new MySQL instance
sudo bash -c "cat <<EOL > /etc/systemd/system/$INSTANCE_NAME.service
[Unit]
Description=MySQL Community Server ($INSTANCE_NAME)
After=network.target

[Service]
User=mysql
Group=mysql
ExecStart=/usr/sbin/mysqld --defaults-file=/etc/mysql/$INSTANCE_NAME.cnf
LimitNOFILE=5000
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOL"

# Allow firewall access for SSH and MySQL instance port
sudo ufw allow 22
sudo ufw allow $PORT
sudo ufw enable
sudo ufw reload

# Start and enable the new MySQL instance service
sudo systemctl daemon-reload
sudo systemctl start $INSTANCE_NAME
sudo systemctl enable $INSTANCE_NAME
sudo systemctl status $INSTANCE_NAME

# Connect to MySQL and create the 'admin' user
mysql -u root -P $PORT -S /var/run/mysqld/$INSTANCE_NAME.sock <<EOF
CREATE USER 'admin'@'%' IDENTIFIED BY 'root@@1234';
GRANT ALL PRIVILEGES ON *.* TO 'admin'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF

sleep 5

sudo systemctl restart $INSTANCE_NAME

echo "MySQL instance $INSTANCE_NAME is running on port $PORT."
