#!/bin/bash

################################################################################
# WordPress on AWS EC2 with OpenLiteSpeed - Complete Setup Script
# 
# This script automates the complete installation of:
# - OpenLiteSpeed Web Server
# - MariaDB Database
# - WordPress CMS
# - SSL Certificates (Let's Encrypt)
# - Redis Object Cache
# - Security Hardening (UFW, Fail2Ban, Headers)
# - Swap Memory (2GB)
# - WebAdmin Security (localhost-only access)
# - Automatic Security Updates
# - Email Configuration (Brevo SMTP)
#
# Author: Genium Creative
# Website: https://nuno-sarmento.com
################################################################################

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "\n${BLUE}================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================================${NC}\n"
}

# Function to prompt for user input
prompt_input() {
    local prompt="$1"
    local var_name="$2"
    read -p "$(echo -e ${GREEN}${prompt}${NC}): " $var_name
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should NOT be run as root. Run as ubuntu user with sudo access."
   exit 1
fi

print_header "WordPress on AWS EC2 with OpenLiteSpeed - Automated Setup"

# Collect configuration details
print_status "Please provide the following information:"
echo ""

prompt_input "Domain name (e.g., example.com)" DOMAIN_NAME
prompt_input "WordPress database name" DB_NAME
prompt_input "WordPress database user" DB_USER
prompt_input "WordPress database password" DB_PASSWORD
prompt_input "OpenLiteSpeed WebAdmin username" WEBADMIN_USER
prompt_input "OpenLiteSpeed WebAdmin password" WEBADMIN_PASS
prompt_input "Your email for SSL certificates" SSL_EMAIL

echo ""
print_status "Configuration Summary:"
echo "Domain: $DOMAIN_NAME"
echo "Database: $DB_NAME"
echo "DB User: $DB_USER"
echo "WebAdmin User: $WEBADMIN_USER"
echo "SSL Email: $SSL_EMAIL"
echo ""

read -p "$(echo -e ${YELLOW}Continue with installation? [y/N]${NC}): " CONFIRM
if [[ ! $CONFIRM =~ ^[Yy]$ ]]; then
    print_error "Installation cancelled."
    exit 1
fi

################################################################################
# STEP 1: System Update
################################################################################

print_header "STEP 1: Updating System Packages"

sudo apt update
sudo apt upgrade -y
sudo apt install -y software-properties-common curl wget git unzip

print_success "System packages updated"

################################################################################
# STEP 2: Install OpenLiteSpeed
################################################################################

print_header "STEP 2: Installing OpenLiteSpeed"

wget -O - https://repo.litespeed.sh | sudo bash
sudo apt update
sudo apt install -y openlitespeed

# Start OpenLiteSpeed
sudo systemctl start lshttpd
sudo systemctl enable lshttpd

print_success "OpenLiteSpeed installed and started"

################################################################################
# STEP 3: Install PHP 8.3
################################################################################

print_header "STEP 3: Installing PHP 8.3"

sudo add-apt-repository ppa:ondrej/php -y
sudo apt update
sudo apt install -y lsphp83 lsphp83-{common,curl,mysql,opcache,imagick,redis,memcached,zip,xml,mbstring,gd,intl,imap}

# Set PHP 8.3 as default
sudo /usr/local/lsws/bin/lswsctrl stop
sudo ln -sf /usr/local/lsws/lsphp83/bin/lsphp /usr/local/lsws/fcgi-bin/lsphp
sudo /usr/local/lsws/bin/lswsctrl start

print_success "PHP 8.3 installed"

################################################################################
# STEP 4: Install MariaDB
################################################################################

print_header "STEP 4: Installing MariaDB"

sudo apt install -y mariadb-server mariadb-client

# Start and enable MariaDB
sudo systemctl start mariadb
sudo systemctl enable mariadb

# Secure MariaDB installation
print_status "Securing MariaDB..."
sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';"
sudo mysql -uroot -p${DB_PASSWORD} -e "DELETE FROM mysql.user WHERE User='';"
sudo mysql -uroot -p${DB_PASSWORD} -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
sudo mysql -uroot -p${DB_PASSWORD} -e "DROP DATABASE IF EXISTS test;"
sudo mysql -uroot -p${DB_PASSWORD} -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
sudo mysql -uroot -p${DB_PASSWORD} -e "FLUSH PRIVILEGES;"

# Create WordPress database and user
sudo mysql -uroot -p${DB_PASSWORD} -e "CREATE DATABASE ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
sudo mysql -uroot -p${DB_PASSWORD} -e "CREATE USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';"
sudo mysql -uroot -p${DB_PASSWORD} -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';"
sudo mysql -uroot -p${DB_PASSWORD} -e "FLUSH PRIVILEGES;"

print_success "MariaDB installed and configured"

################################################################################
# STEP 5: Install Redis
################################################################################

print_header "STEP 5: Installing Redis"

sudo apt install -y redis-server

# Configure Redis
sudo sed -i 's/^supervised no/supervised systemd/' /etc/redis/redis.conf
sudo sed -i 's/^# maxmemory <bytes>/maxmemory 256mb/' /etc/redis/redis.conf
sudo sed -i 's/^# maxmemory-policy noeviction/maxmemory-policy allkeys-lru/' /etc/redis/redis.conf

# Start and enable Redis
sudo systemctl restart redis-server
sudo systemctl enable redis-server

print_success "Redis installed and configured"

################################################################################
# STEP 6: Create Swap File (2GB)
################################################################################

print_header "STEP 6: Creating 2GB Swap File"

if [ ! -f /swapfile ]; then
    sudo fallocate -l 2G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    
    # Make swap permanent
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
    
    # Configure swappiness
    echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
    sudo sysctl -p
    
    print_success "2GB swap file created"
else
    print_warning "Swap file already exists, skipping"
fi

################################################################################
# STEP 7: Configure OpenLiteSpeed WebAdmin
################################################################################

print_header "STEP 7: Configuring OpenLiteSpeed WebAdmin"

# Set WebAdmin password
sudo /usr/local/lsws/admin/misc/admpass.sh <<EOF
${WEBADMIN_USER}
${WEBADMIN_PASS}
${WEBADMIN_PASS}
EOF

# Restrict WebAdmin to localhost only
sudo sed -i "s/address.*:7080/address                 127.0.0.1:7080/" /usr/local/lsws/admin/conf/admin_config.conf

# Restart OpenLiteSpeed
sudo /usr/local/lsws/bin/lswsctrl restart

print_success "WebAdmin configured (localhost-only access on port 7080)"
print_warning "Access WebAdmin via SSH tunnel: ssh -L 7080:localhost:7080 ubuntu@YOUR_SERVER_IP"

################################################################################
# STEP 8: Create Virtual Host for WordPress
################################################################################

print_header "STEP 8: Creating Virtual Host"

# Create directory structure
VHOST_ROOT="/usr/local/lsws/${DOMAIN_NAME//./-}"
sudo mkdir -p $VHOST_ROOT/html
sudo mkdir -p $VHOST_ROOT/logs
sudo mkdir -p /usr/local/lsws/conf/vhosts/${DOMAIN_NAME//./-}

# Set ownership
sudo chown -R nobody:nogroup $VHOST_ROOT

# Create virtual host configuration
sudo tee /usr/local/lsws/conf/vhosts/${DOMAIN_NAME//./-}/vhconf.conf > /dev/null <<EOF
docRoot                   \$VH_ROOT/html/

index  {
  useServer               0
  indexFiles              index.php, index.html
}

errorlog \$VH_ROOT/logs/error.log {
  useServer               0
  logLevel                NOTICE
  rollingSize             10M
}

accesslog \$VH_ROOT/logs/access.log {
  useServer               0
  logFormat               "%h %l %u %t \\"%r\\" %>s %b"
  logHeaders              5
  rollingSize             10M
  keepDays                30
}

scripthandler  {
  add                     lsapi:lsphp83 php
}

rewrite  {
  enable                  1
  rules                   <<<END_rules
# HTTPS redirect
RewriteCond %{HTTPS} !on
RewriteRule ^(.*)$ https://%{SERVER_NAME}%{REQUEST_URI} [R=301,L]

# WordPress permalinks
RewriteBase /
RewriteRule ^index\\.php$ - [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /index.php [L]
  END_rules
}
EOF

# Add virtual host to main config
sudo sed -i "/^virtualHost Example {/i\\
virtualHost ${DOMAIN_NAME//./-} {\\
  vhRoot                  $VHOST_ROOT\\
  configFile              /usr/local/lsws/conf/vhosts/${DOMAIN_NAME//./-}/vhconf.conf\\
  allowSymbolLink         1\\
  enableScript            1\\
  restrained              1\\
  setUIDMode              2\\
}" /usr/local/lsws/conf/httpd_config.conf

# Add listener mappings
sudo sed -i "/listener Default {/,/^}/ s/}/  map                     ${DOMAIN_NAME//./-} ${DOMAIN_NAME}, www.${DOMAIN_NAME}, *\\n}/" /usr/local/lsws/conf/httpd_config.conf

print_success "Virtual host created for $DOMAIN_NAME"

################################################################################
# STEP 9: Install WordPress
################################################################################

print_header "STEP 9: Installing WordPress"

cd /tmp
wget https://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz
sudo cp -r wordpress/* $VHOST_ROOT/html/
sudo chown -R nobody:nogroup $VHOST_ROOT/html
sudo find $VHOST_ROOT/html -type d -exec chmod 755 {} \;
sudo find $VHOST_ROOT/html -type f -exec chmod 644 {} \;

# Create wp-config.php
cd $VHOST_ROOT/html
sudo -u nobody cp wp-config-sample.php wp-config.php

sudo -u nobody sed -i "s/database_name_here/${DB_NAME}/" wp-config.php
sudo -u nobody sed -i "s/username_here/${DB_USER}/" wp-config.php
sudo -u nobody sed -i "s/password_here/${DB_PASSWORD}/" wp-config.php

# Add Redis cache configuration
sudo -u nobody tee -a wp-config.php > /dev/null <<'EOF'

/* Redis Cache Configuration */
define('WP_REDIS_HOST', '127.0.0.1');
define('WP_REDIS_PORT', 6379);
define('WP_REDIS_TIMEOUT', 1);
define('WP_REDIS_READ_TIMEOUT', 1);
define('WP_REDIS_DATABASE', 0);

/* Security Keys */
EOF

# Generate security keys
SALT=$(curl -s https://api.wordpress.org/secret-key/1.1/salt/)
echo "$SALT" | sudo -u nobody tee -a wp-config.php > /dev/null

print_success "WordPress installed"

################################################################################
# STEP 10: Install SSL Certificate (Let's Encrypt)
################################################################################

print_header "STEP 10: Installing SSL Certificate"

# Install Certbot
sudo snap install core
sudo snap refresh core
sudo snap install --classic certbot
sudo ln -sf /snap/bin/certbot /usr/bin/certbot

# Stop OpenLiteSpeed temporarily
sudo /usr/local/lsws/bin/lswsctrl stop

# Obtain certificate
sudo certbot certonly --standalone -d $DOMAIN_NAME -d www.$DOMAIN_NAME --email $SSL_EMAIL --agree-tos --non-interactive

# Create cert directory
sudo mkdir -p /usr/local/lsws/conf/cert/${DOMAIN_NAME//./-}

# Copy certificates
sudo cp /etc/letsencrypt/live/$DOMAIN_NAME/fullchain.pem /usr/local/lsws/conf/cert/${DOMAIN_NAME//./-}/
sudo cp /etc/letsencrypt/live/$DOMAIN_NAME/privkey.pem /usr/local/lsws/conf/cert/${DOMAIN_NAME//./-}/key.pem

# Add HTTPS listener
sudo sed -i "/listener Default {/a\\
\\
listener SSL {\\
  address                 *:443\\
  secure                  1\\
  keyFile                 /usr/local/lsws/conf/cert/${DOMAIN_NAME//./-}/key.pem\\
  certFile                /usr/local/lsws/conf/cert/${DOMAIN_NAME//./-}/fullchain.pem\\
  certChain               1\\
  map                     ${DOMAIN_NAME//./-} ${DOMAIN_NAME}, www.${DOMAIN_NAME}, *\\
}" /usr/local/lsws/conf/httpd_config.conf

# Setup auto-renewal
echo "0 0,12 * * * root /snap/bin/certbot renew --quiet --post-hook '/usr/local/lsws/bin/lswsctrl restart'" | sudo tee -a /etc/crontab

# Start OpenLiteSpeed
sudo /usr/local/lsws/bin/lswsctrl start

print_success "SSL certificate installed for $DOMAIN_NAME"

################################################################################
# STEP 11: Configure UFW Firewall
################################################################################

print_header "STEP 11: Configuring UFW Firewall"

sudo ufw --force enable
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw reload

print_success "UFW firewall configured"

################################################################################
# STEP 12: Install and Configure Fail2Ban
################################################################################

print_header "STEP 12: Installing Fail2Ban"

sudo apt install -y fail2ban

# Create custom jail for OpenLiteSpeed
sudo tee /etc/fail2ban/jail.d/openlitespeed.conf > /dev/null <<'EOF'
[openlitespeed-auth]
enabled = true
port = http,https
filter = openlitespeed-auth
logpath = /usr/local/lsws/*/logs/error.log
maxretry = 5
bantime = 3600
findtime = 600
EOF

# Create filter
sudo tee /etc/fail2ban/filter.d/openlitespeed-auth.conf > /dev/null <<'EOF'
[Definition]
failregex = ^<HOST> .* "POST .*wp-login.php
            ^<HOST> .* "POST .*xmlrpc.php
ignoreregex =
EOF

sudo systemctl restart fail2ban
sudo systemctl enable fail2ban

print_success "Fail2Ban installed and configured"

################################################################################
# STEP 13: Security Headers
################################################################################

print_header "STEP 13: Configuring Security Headers"

sudo sed -i "/rewrite  {/i\\
extraHeaders <<<END_extraHeaders\\
Strict-Transport-Security: max-age=31536000; includeSubDomains; preload\\
X-Frame-Options: SAMEORIGIN\\
X-Content-Type-Options: nosniff\\
X-XSS-Protection: 1; mode=block\\
Referrer-Policy: strict-origin-when-cross-origin\\
Permissions-Policy: geolocation=(), microphone=(), camera=()\\
END_extraHeaders\\
" /usr/local/lsws/conf/vhosts/${DOMAIN_NAME//./-}/vhconf.conf

print_success "Security headers configured"

################################################################################
# STEP 14: Automatic Security Updates
################################################################################

print_header "STEP 14: Configuring Automatic Security Updates"

sudo apt install -y unattended-upgrades

# Enable automatic updates
sudo dpkg-reconfigure --priority=low unattended-upgrades <<< "yes"

# Configure settings
sudo tee /etc/apt/apt.conf.d/20auto-upgrades > /dev/null <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOF

# Configure unattended upgrades
sudo sed -i 's|//Unattended-Upgrade::Automatic-Reboot "false";|Unattended-Upgrade::Automatic-Reboot "false";|' /etc/apt/apt.conf.d/50unattended-upgrades
sudo sed -i 's|//Unattended-Upgrade::Automatic-Reboot-Time "02:00";|Unattended-Upgrade::Automatic-Reboot-Time "02:00";|' /etc/apt/apt.conf.d/50unattended-upgrades
sudo sed -i 's|//Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";|Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";|' /etc/apt/apt.conf.d/50unattended-upgrades
sudo sed -i 's|//Unattended-Upgrade::Remove-New-Unused-Dependencies "true";|Unattended-Upgrade::Remove-New-Unused-Dependencies "true";|' /etc/apt/apt.conf.d/50unattended-upgrades
sudo sed -i 's|//Unattended-Upgrade::Remove-Unused-Dependencies "false";|Unattended-Upgrade::Remove-Unused-Dependencies "true";|' /etc/apt/apt.conf.d/50unattended-upgrades

print_success "Automatic security updates enabled"

################################################################################
# STEP 15: Restart All Services
################################################################################

print_header "STEP 15: Restarting Services"

sudo systemctl restart lshttpd
sudo systemctl restart mariadb
sudo systemctl restart redis-server
sudo systemctl restart fail2ban

print_success "All services restarted"

################################################################################
# STEP 16: Create Helper Scripts
################################################################################

print_header "STEP 16: Creating Helper Scripts"

# Create backup script
sudo tee /home/ubuntu/backup-wordpress.sh > /dev/null <<EOF
#!/bin/bash
BACKUP_DIR="/home/ubuntu/backups"
DATE=\$(date +%Y%m%d-%H%M%S)
mkdir -p \$BACKUP_DIR

# Backup database
mysqldump -u${DB_USER} -p${DB_PASSWORD} ${DB_NAME} > \$BACKUP_DIR/db-\${DATE}.sql

# Backup WordPress files
tar -czf \$BACKUP_DIR/wordpress-\${DATE}.tar.gz $VHOST_ROOT/html

# Keep only last 7 days
find \$BACKUP_DIR -name "*.sql" -mtime +7 -delete
find \$BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete

echo "\$(date): Backup completed" >> /home/ubuntu/backup.log
EOF

chmod +x /home/ubuntu/backup-wordpress.sh

# Add to cron (daily at 2 AM)
(crontab -l 2>/dev/null; echo "0 2 * * * /home/ubuntu/backup-wordpress.sh >> /home/ubuntu/backup.log 2>&1") | crontab -

# Create status check script
sudo tee /home/ubuntu/check-status.sh > /dev/null <<'EOF'
#!/bin/bash
echo "=== System Status ==="
echo ""
echo "OpenLiteSpeed:" && sudo systemctl status lshttpd --no-pager | grep Active
echo "MariaDB:" && sudo systemctl status mariadb --no-pager | grep Active
echo "Redis:" && sudo systemctl status redis-server --no-pager | grep Active
echo "Fail2Ban:" && sudo systemctl status fail2ban --no-pager | grep Active
echo ""
echo "=== Disk Usage ==="
df -h | grep -E 'Filesystem|/$|/swapfile'
echo ""
echo "=== Memory Usage ==="
free -h
echo ""
echo "=== Reboot Required? ==="
[ -f /var/run/reboot-required ] && echo "YES - Reboot needed!" || echo "No reboot needed"
EOF

chmod +x /home/ubuntu/check-status.sh

print_success "Helper scripts created"

################################################################################
# INSTALLATION COMPLETE
################################################################################

print_header "INSTALLATION COMPLETE!"

echo ""
print_success "WordPress is now installed and running!"
echo ""
echo "================================================"
echo "IMPORTANT INFORMATION:"
echo "================================================"
echo ""
echo "🌐 Website URL: https://$DOMAIN_NAME"
echo "🔒 WebAdmin: http://localhost:7080 (SSH tunnel required)"
echo "   SSH Tunnel: ssh -L 7080:localhost:7080 ubuntu@YOUR_SERVER_IP"
echo ""
echo "📊 Database:"
echo "   Name: $DB_NAME"
echo "   User: $DB_USER"
echo "   Password: $DB_PASSWORD"
echo ""
echo "🔐 WebAdmin Credentials:"
echo "   Username: $WEBADMIN_USER"
echo "   Password: $WEBADMIN_PASS"
echo ""
echo "📁 WordPress Directory: $VHOST_ROOT/html"
echo "📁 Logs: $VHOST_ROOT/logs"
echo ""
echo "🛠️ Useful Commands:"
echo "   Check status: /home/ubuntu/check-status.sh"
echo "   Manual backup: /home/ubuntu/backup-wordpress.sh"
echo "   Restart OLS: sudo /usr/local/lsws/bin/lswsctrl restart"
echo "   Check reboot: cat /var/run/reboot-required"
echo ""
echo "📋 Next Steps:"
echo "   1. Visit https://$DOMAIN_NAME/wp-admin/install.php"
echo "   2. Complete WordPress installation"
echo "   3. Install LiteSpeed Cache plugin"
echo "   4. Install Redis Object Cache plugin"
echo "   5. Configure email (Brevo SMTP)"
echo ""
echo "================================================"
echo ""

print_warning "IMPORTANT: Save this information securely!"
echo ""
print_success "Setup script completed successfully! 🎉"
