<h5 id="introduction">🚀 WordPress on AWS EC2 with OpenLiteSpeed - Automated Setup</h5>

<p><strong>Complete automated installation script for production-grade WordPress hosting on AWS EC2</strong></p>

<h5 id="step1">What This Script Does</h5>

<p>This bash script automates the complete installation and configuration of:</p>

<ul>
<li>✅ <strong>OpenLiteSpeed Web Server</strong> - High-performance web server</li>
<li>✅ <strong>PHP 8.3</strong> - Latest PHP version with all required extensions</li>
<li>✅ <strong>MariaDB Database</strong> - Secure database server</li>
<li>✅ <strong>WordPress CMS</strong> - Latest WordPress version</li>
<li>✅ <strong>SSL Certificates</strong> - Free Let's Encrypt SSL with auto-renewal</li>
<li>✅ <strong>Redis Cache</strong> - Object caching for performance</li>
<li>✅ <strong>2GB Swap File</strong> - Memory optimization</li>
<li>✅ <strong>UFW Firewall</strong> - Port security</li>
<li>✅ <strong>Fail2Ban</strong> - Brute-force protection</li>
<li>✅ <strong>Security Headers</strong> - HSTS, X-Frame-Options, CSP, etc.</li>
<li>✅ <strong>WebAdmin Security</strong> - Localhost-only access</li>
<li>✅ <strong>Automatic Security Updates</strong> - Unattended upgrades</li>
<li>✅ <strong>Automated Backups</strong> - Daily database and file backups</li>
<li>✅ <strong>Helper Scripts</strong> - Status checks and maintenance tools</li>
</ul>

<h5 id="step2">Prerequisites</h5>

<h5>1. AWS EC2 Instance</h5>

<ul>
<li><strong>Instance Type:</strong> t3.micro or larger (t3.micro = 6 months free tier)</li>
<li><strong>OS:</strong> Ubuntu 24.04 LTS</li>
<li><strong>Storage:</strong> At least 20 GB</li>
<li><strong>Region:</strong> Your preferred region (e.g., eu-west-2 London)</li>
</ul>

<h5>2. Security Group Configuration</h5>

<p>Allow the following ports:</p>

<ul>
<li><strong>SSH (22)</strong> - Your IP only</li>
<li><strong>HTTP (80)</strong> - 0.0.0.0/0</li>
<li><strong>HTTPS (443)</strong> - 0.0.0.0/0</li>
</ul>

<h5>3. Domain Name</h5>

<ul>
<li>Domain pointed to your EC2 Elastic IP</li>
<li>Both <code>example.com</code> and <code>www.example.com</code> A records configured</li>
</ul>

<h5>4. SSH Key Pair</h5>

<ul>
<li>Download your <code>.pem</code> key file from AWS</li>
</ul>

<h5 id="step3">Installation Instructions</h5>

<h5>Step 1: Launch EC2 Instance</h5>

<ol>
<li><strong>Go to AWS Console</strong> → EC2 → Launch Instance</li>
<li><strong>Name:</strong> wordpress-production</li>
<li><strong>AMI:</strong> Ubuntu Server 24.04 LTS</li>
<li><strong>Instance Type:</strong> t3.micro (free tier eligible)</li>
<li><strong>Key Pair:</strong> Create new or select existing</li>
<li><strong>Network:</strong>
<ul>
<li>Create security group with ports 22, 80, 443</li>
<li>Assign Elastic IP after launch</li>
</ul>
</li>
<li><strong>Storage:</strong> 20 GB gp3</li>
<li><strong>Launch Instance</strong></li>
</ol>

<h5>Step 2: Point Your Domain</h5>

<p>Add these DNS records at your domain registrar:</p>

A    @      YOUR_ELASTIC_IP
A    www    YOUR_ELASTIC_IP

<p><strong>Wait 5-10 minutes for DNS propagation</strong></p>

<h5>Step 3: Connect to Server</h5>

chmod 400 your-key.pem
ssh -i your-key.pem ubuntu@YOUR_ELASTIC_IP

<h5>Step 4: Upload and Run Script</h5>

<p><strong>Option A: Direct Download (if script is hosted)</strong></p>

wget https://your-server.com/wordpress-aws-openlitespeed-setup.sh
chmod +x wordpress-aws-openlitespeed-setup.sh
./wordpress-aws-openlitespeed-setup.sh

<p><strong>Option B: Copy and Paste</strong></p>

nano wordpress-aws-openlitespeed-setup.sh
# Paste the script content
# Save: Ctrl + X → Y → Enter

chmod +x wordpress-aws-openlitespeed-setup.sh
./wordpress-aws-openlitespeed-setup.sh

<p><strong>Option C: SCP Upload from Local Machine</strong></p>

# On your local machine
scp -i your-key.pem wordpress-aws-openlitespeed-setup.sh ubuntu@YOUR_ELASTIC_IP:/home/ubuntu/

# Then SSH and run
ssh -i your-key.pem ubuntu@YOUR_ELASTIC_IP
chmod +x wordpress-aws-openlitespeed-setup.sh
./wordpress-aws-openlitespeed-setup.sh

<h5>Step 5: Follow Prompts</h5>

<p>The script will ask you for:</p>

Domain name: example.com
Database name: wordpress_db
Database user: wp_user
Database password: [strong-password]
WebAdmin username: admin
WebAdmin password: [strong-password]
SSL email: your-email@example.com

<p><strong>Installation takes 10-15 minutes</strong></p>

<h5 id="step4">Post-Installation Steps</h5>

<h5>1. Complete WordPress Installation</h5>

<p>Visit: <code>https://your-domain.com/wp-admin/install.php</code></p>

<p>Fill in:</p>

<ul>
<li>Site Title</li>
<li>Admin Username</li>
<li>Admin Password</li>
<li>Admin Email</li>
</ul>

<h5>2. Install Essential Plugins</h5>

<p><strong>Via WordPress Dashboard:</strong></p>

<p><strong>LiteSpeed Cache</strong></p>

<ol>
<li>Plugins → Add New → Search "LiteSpeed Cache"</li>
<li>Install and Activate</li>
<li>Go to LiteSpeed Cache settings</li>
<li>Enable Image Optimization</li>
<li>Enable CSS/JS Minification</li>
</ol>

<p><strong>Redis Object Cache</strong></p>

<ol>
<li>Plugins → Add New → Search "Redis Object Cache"</li>
<li>Install and Activate</li>
<li>Settings → Redis → Enable Object Cache</li>
</ol>

<p><strong>Wordfence Security</strong> (Optional but recommended)</p>

<ol>
<li>Plugins → Add New → Search "Wordfence"</li>
<li>Install and Activate</li>
</ol>

<h5>3. Configure Email (Brevo SMTP)</h5>

<ol>
<li><strong>Create Brevo Account:</strong> <a href="https://www.brevo.com" target="_blank">https://www.brevo.com</a> (300 emails/day free)</li>
<li><strong>Get SMTP Credentials:</strong>
<ul>
<li>Brevo Dashboard → SMTP & API</li>
<li>Copy your SMTP credentials</li>
</ul>
</li>
<li><strong>Install WP Mail SMTP Plugin</strong></li>
<li><strong>Configure Settings:</strong>
<ul>
<li>From Email: noreply@yourdomain.com</li>
<li>SMTP Host: smtp-relay.brevo.com</li>
<li>Port: 587</li>
<li>Encryption: TLS</li>
<li>Username: Your Brevo email</li>
<li>Password: Your SMTP key</li>
</ul>
</li>
</ol>

<h5>4. Access WebAdmin Panel (Localhost Only)</h5>

<p><strong>Create SSH Tunnel:</strong></p>

ssh -i your-key.pem -L 7080:localhost:7080 ubuntu@YOUR_ELASTIC_IP

<p><strong>Access in Browser:</strong></p>

http://localhost:7080

<p><strong>Credentials:</strong> (the ones you set during installation)</p>

<h5>5. Verify Everything Works</h5>

<p>Run the status check script:</p>

/home/ubuntu/check-status.sh

<p>You should see all services as "active (running)"</p>

<h5 id="step5">Performance Optimization</h5>

<h5>PageSpeed 100/100 Setup</h5>

<p><strong>LiteSpeed Cache Settings:</strong></p>

<ul>
<li>Cache → Cache ON</li>
<li>CSS Combine: ON</li>
<li>JS Combine: ON</li>
<li>Image Optimization: ON</li>
<li>Lazy Load: ON</li>
<li>WebP: ON</li>
</ul>

<p><strong>Redis Object Cache:</strong></p>

<ul>
<li>Already configured by script</li>
<li>Just activate in WordPress</li>
</ul>

<p><strong>Verify Performance:</strong></p>

<ul>
<li>Visit: <a href="https://pagespeed.web.dev/" target="_blank">https://pagespeed.web.dev/</a></li>
<li>Test your domain</li>
<li>Should achieve 90-100 scores</li>
</ul>

<h5 id="step6">Security Features Included</h5>

<h5>What's Protected:</h5>

<ul>
<li>✅ <strong>UFW Firewall</strong> - Only ports 22, 80, 443 open</li>
<li>✅ <strong>Fail2Ban</strong> - Blocks brute-force attacks</li>
<li>✅ <strong>Security Headers</strong> - HSTS, X-Frame-Options, CSP</li>
<li>✅ <strong>WebAdmin</strong> - Localhost-only access</li>
<li>✅ <strong>SSL/TLS</strong> - A+ grade SSL configuration</li>
<li>✅ <strong>Auto Updates</strong> - Security patches applied automatically</li>
<li>✅ <strong>Database</strong> - Secure installation, strong passwords</li>
</ul>

<h5>Check Security Status:</h5>

# Check firewall
sudo ufw status

# Check Fail2Ban
sudo fail2ban-client status

# Check SSL grade
# Visit: https://www.ssllabs.com/ssltest/

<h5 id="step7">Maintenance & Monitoring</h5>

<h5>Daily Automated Backups</h5>

<p><strong>Backups run automatically at 2 AM daily</strong></p>

<p>Location: <code>/home/ubuntu/backups/</code></p>

<p>Manual backup:</p>

/home/ubuntu/backup-wordpress.sh

<h5>Check for Updates</h5>

# Check if reboot needed
cat /var/run/reboot-required

# See what needs reboot
cat /var/run/reboot-required.pkgs

# Manual reboot (when needed)
sudo reboot

<h5>View Logs</h5>

# WordPress errors
sudo tail -50 /usr/local/lsws/your-domain/logs/error.log

# Access logs
sudo tail -50 /usr/local/lsws/your-domain/logs/access.log

# Automatic updates
sudo tail -50 /var/log/unattended-upgrades/unattended-upgrades.log

# Fail2Ban
sudo tail -50 /var/log/fail2ban.log

<h5>Restart Services</h5>

# Restart OpenLiteSpeed
sudo /usr/local/lsws/bin/lswsctrl restart

# Restart MariaDB
sudo systemctl restart mariadb

# Restart Redis
sudo systemctl restart redis-server

# Restart all
sudo systemctl restart lshttpd mariadb redis-server

<h5 id="step8">Troubleshooting</h5>

<h5>Website Not Loading</h5>

# Check if services running
/home/ubuntu/check-status.sh

# Restart OpenLiteSpeed
sudo /usr/local/lsws/bin/lswsctrl restart

# Check error logs
sudo tail -100 /usr/local/lsws/your-domain/logs/error.log

<h5>SSL Certificate Issues</h5>

# Renew manually
sudo certbot renew --force-renewal

# Copy to OpenLiteSpeed
sudo cp /etc/letsencrypt/live/YOUR_DOMAIN/fullchain.pem /usr/local/lsws/conf/cert/your-domain/
sudo cp /etc/letsencrypt/live/YOUR_DOMAIN/privkey.pem /usr/local/lsws/conf/cert/your-domain/key.pem

# Restart
sudo /usr/local/lsws/bin/lswsctrl restart

<h5>Can't Access WebAdmin</h5>

# Check if listening on localhost
sudo ss -tlnp | grep 7080

# Should show: 127.0.0.1:7080

# Create SSH tunnel again
ssh -i your-key.pem -L 7080:localhost:7080 ubuntu@YOUR_ELASTIC_IP

# Access: http://localhost:7080

<h5>Out of Disk Space</h5>

# Check disk usage
df -h

# Clear old backups
rm -f /home/ubuntu/backups/db-*
rm -f /home/ubuntu/backups/wordpress-*

# Clear old logs
sudo rm -f /usr/local/lsws/*/logs/*.log.*

# Clear package cache
sudo apt clean

<h5 id="step9">Scaling & Performance</h5>

<h5>Upgrade Instance Type</h5>

<p>When traffic grows:</p>

<ol>
<li><strong>Stop instance</strong> in AWS Console</li>
<li><strong>Change instance type</strong> to t3.small or larger</li>
<li><strong>Start instance</strong></li>
<li><strong>No data loss</strong> - everything persists</li>
</ol>

<h5>Add CloudFlare CDN (Free)</h5>

<ol>
<li><strong>Sign up:</strong> <a href="https://cloudflare.com" target="_blank">https://cloudflare.com</a></li>
<li><strong>Add your domain</strong></li>
<li><strong>Update nameservers</strong> at your registrar</li>
<li><strong>Enable CDN, SSL, and caching</strong></li>
</ol>

<h5>Database Optimization</h5>

# Optimize tables
sudo mysql -p
USE your_database_name;
OPTIMIZE TABLE wp_posts, wp_postmeta, wp_options;
EXIT;

<h5 id="step10">Cost Breakdown</h5>

<h5>Free Tier (First 12 Months)</h5>

<ul>
<li><strong>EC2 t3.micro:</strong> FREE (750 hours/month)</li>
<li><strong>20 GB Storage:</strong> FREE (30 GB included)</li>
<li><strong>Data Transfer:</strong> FREE (15 GB out/month)</li>
<li><strong>Elastic IP:</strong> FREE (when attached)</li>
<li><strong>Let's Encrypt SSL:</strong> FREE (always)</li>
<li><strong>Brevo Email:</strong> FREE (300/day)</li>
</ul>

<h5>After Free Tier</h5>

<ul>
<li><strong>EC2 t3.micro:</strong> ~$8-10/month</li>
<li><strong>Storage:</strong> ~$2/month (20 GB)</li>
<li><strong>Data Transfer:</strong> $0.09/GB</li>
<li><strong>Total:</strong> ~$10-15/month</li>
</ul>

<h5>Optimization Tips</h5>

<ul>
<li>Use CloudFlare (free CDN reduces data transfer)</li>
<li>Optimize images before upload</li>
<li>Enable caching (LiteSpeed Cache plugin)</li>
</ul>

<h5 id="step11">Support & Resources</h5>

<h5>Official Documentation</h5>

<ul>
<li><strong>OpenLiteSpeed:</strong> <a href="https://docs.litespeedtech.com/" target="_blank">https://docs.litespeedtech.com/</a></li>
<li><strong>WordPress:</strong> <a href="https://wordpress.org/support/" target="_blank">https://wordpress.org/support/</a></li>
<li><strong>Let's Encrypt:</strong> <a href="https://letsencrypt.org/docs/" target="_blank">https://letsencrypt.org/docs/</a></li>
</ul>

<h5>Useful Links</h5>

<ul>
<li><strong>Tutorial Website:</strong> <a href="https://nuno-sarmento.com" target="_blank">https://nuno-sarmento.com</a></li>
<li><strong>PageSpeed Test:</strong> <a href="https://pagespeed.web.dev/" target="_blank">https://pagespeed.web.dev/</a></li>
<li><strong>SSL Test:</strong> <a href="https://www.ssllabs.com/ssltest/" target="_blank">https://www.ssllabs.com/ssltest/</a></li>
<li><strong>Security Headers:</strong> <a href="https://securityheaders.com/" target="_blank">https://securityheaders.com/</a></li>
</ul>

<h5 id="step12">Script Details</h5>

<ul>
<li><strong>Version:</strong> 1.0</li>
<li><strong>Author:</strong> Genium Creative</li>
<li><strong>Website:</strong> <a href="https://nuno-sarmento.com" target="_blank">https://nuno-sarmento.com</a></li>
<li><strong>Lines of Code:</strong> 607</li>
<li><strong>Execution Time:</strong> ~10-15 minutes</li>
</ul>

<h5 id="step13">Installation Checklist</h5>

<p>After installation, verify:</p>

<ul>
<li>☐ Website loads at <code>https://your-domain.com</code></li>
<li>☐ WordPress admin accessible at <code>/wp-admin</code></li>
<li>☐ SSL certificate valid (green padlock)</li>
<li>☐ WebAdmin accessible via SSH tunnel</li>
<li>☐ All services running (<code>check-status.sh</code>)</li>
<li>☐ Backups configured (check <code>/home/ubuntu/backups/</code>)</li>
<li>☐ Email sending works (WP Mail SMTP test)</li>
<li>☐ PageSpeed score 90+ (after cache plugins)</li>
<li>☐ Security headers present (securityheaders.com)</li>
<li>☐ Automatic updates enabled</li>
</ul>

<h5 id="conclusion">You're All Set!</h5>

<p>Your WordPress site is now running on a production-grade infrastructure with:</p>

<ul>
<li>✅ Enterprise-level security</li>
<li>✅ Maximum performance optimization</li>
<li>✅ Automatic backups</li>
<li>✅ Auto-updating security patches</li>
<li>✅ Professional SSL encryption</li>
<li>✅ 100/100 PageSpeed capability</li>
</ul>

<p><strong>Enjoy your ultra-fast, secure WordPress site!</strong> 🚀</p>
