#!/bin/bash
# EC2 User Data Script — 3-Tier WordPress on AWS
# Bootstraps Apache, PHP, MySQL client, and mounts EFS on launch
# Replace <YOUR-EFS-DNS> with your actual EFS filesystem DNS name

exec > /var/log/manual-test.log 2>&1
set -x

# Update system
yum update -y

# Install Apache web server, mod_ssl, and related tools
sudo yum install -y httpd httpd-tools mod_ssl

# Enable and start Apache service
sudo systemctl enable httpd
sudo systemctl start httpd

# Install PHP and necessary extensions
sudo yum install -y php php-common php-pear php-cli \
  php-{cgi,curl,mbstring,gd,mysqlnd,gettext,json,xml,fpm,intl,zip}

# Install MySQL client (NOT server — database is managed by RDS)
sudo wget https://dev.mysql.com/get/mysql80-community-release-el9-1.noarch.rpm
sudo dnf install mysql80-community-release-el9-1.noarch.rpm -y
sudo rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2023
sudo dnf install mysql-community-client -y

# Create web root directory
sudo mkdir -p /var/www/html

# Mount EFS to /var/www/html
# Replace <YOUR-EFS-DNS> with your EFS filesystem DNS from the EFS console
echo "<YOUR-EFS-DNS>:/ /var/www/html nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport 0 0" | sudo tee -a /etc/fstab
sudo mount -a

# Set correct permissions for Apache
sudo usermod -a -G apache ec2-user
sudo chown -R ec2-user:apache /var/www
sudo chmod 2775 /var/www && find /var/www -type d -exec sudo chmod 2775 {} \;
sudo find /var/www -type f -exec sudo chmod 0664 {} \;
sudo chown apache:apache -R /var/www/html

# Restart Apache to apply all changes
sudo service httpd restart
