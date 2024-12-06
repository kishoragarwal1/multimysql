# MySQL Setup Scripts

This repository contains scripts to install MySQL and set up individual MySQL instances. Below are the instructions to use these scripts.

---

## Install Git

```bash
sudo apt update
sudo apt install git
```
### Clone repository
```bash
git clone https://github.com/kishoragarwal1/ubuntu.git
```

## install_mysql.sh

This script installs MySQL on your system.

### Permission
To make the script executable, run the following command:

```bash
sudo chmod +x install_mysql.sh
```

## mysql_instance_setup.sh

This script sets up a new MySQL instance with a given instance name and port number.

### Permission
To make the script executable, run the following command:

```bash
sudo chmod +x mysql_instance_setup.sh
```

### Run the script

To set up a MySQL instance, run the script with the desired instance name and port number:

```bash
sudo ./mysql_instance_setup.sh instance_name port_number
```
