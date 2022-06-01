#!/bin/bash
# Please do not remove this line. This command tells bash to stop executing on first error. 
set -e

# Your code goes below ...
echo 'This script should install and setup Wordpress'
echo ''

# some global vars
path='/var/www/wordpress'
DBname='wordpress'
DBusername='wordpressuser'
DBpassword='password'
ip="$(ip -o -4 addr show eth1 | awk '{ split($4, ip_addr, "/"); print ip_addr[1] }')"

# wget can't resolve nginx.org when installing nginx...
sed -i '/127/d' /etc/resolv.conf
echo nameserver 8.8.8.8 | tee -a /etc/resolv.conf

# installing nginx
echo 'installing nginx'
apt-get update
apt-get install -y curl gnupg2 ca-certificates lsb-release ubuntu-keyring
wget https://nginx.org/keys/nginx_signing.key 
cat nginx_signing.key | gpg --dearmor | sudo tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null
echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/ubuntu `lsb_release -cs` nginx" | sudo tee /etc/apt/sources.list.d/nginx.list
echo -e "Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900\n" | sudo tee /etc/apt/preferences.d/99nginx
apt-get update
apt-get install -y nginx-core
echo ''

# installing mysql, php and wordpress deps
echo 'installing mysql, php and wordpress deps'
apt-get install -y mysql-server php-fpm php-mysql php-curl php-gd php-intl php-mbstring php-soap php-xml php-xmlrpc php-zip
echo ''

# configuring nginx
echo 'configuring nginx'
mkdir $path
chown -R www-data:www-data /var/www/wordpress
rm /etc/nginx/sites-available/default
rm /etc/nginx/sites-enabled/default
echo -e 'server {\n\tlisten 80;\n\tserver_name wordpress;\n\troot /var/www/wordpress;\n\tindex index.html index htm index.php;\n\n\t location / {\n\t\ttry_files $uri $uri/ /index.php$is_args$args;\n\t}\n\n\tlocation ~ \.php {\n\t\tfastcgi_pass unix:/var/run/php/php7.4-fpm.sock;\n\t\tinclude /etc/nginx/fastcgi_params;\n\t\tfastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;\n\t\tfastcgi_param SCRIPT_NAME $fastcgi_script_name;\n\t}\n\n\tlocation ~ /\.ht {\n\t\tdeny all;\n\t}\n\n\tlocation = /favicon.ico {\n\t\tlog_not_found off;\n\t\taccess_log off;\n\t}\n\n\tlocation = /robots.txt {\n\t\tlog_not_found off;\n\t\taccess_log off;\n\t\tallow all;\n\t}\n\n\tlocation ~* \.(css|gif|ico|jpeg|jpg|js|png)$ {\n\t\texpires max;\n\t\tlog_not_found off;\n\t}\n}' > /etc/nginx/sites-available/wordpress
ln -s /etc/nginx/sites-available/wordpress /etc/nginx/sites-enabled/
if nginx -t; then systemctl reload nginx; else echo 'nginx test configuration file error'; fi
echo ''

# create db for wordpress
echo 'create db for wordpress'
mysql -e "CREATE DATABASE $DBname DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;"
mysql -e "CREATE USER '$DBusername'@'localhost' IDENTIFIED BY '$DBpassword';"
mysql -e "GRANT ALL ON wordpress.* TO '$DBusername'@'localhost';"
echo ''

# downloading wordpress
echo 'downloading wordpress'
wget https://wordpress.org/latest.tar.gz
tar -zxf latest.tar.gz
cp ./wordpress/wp-config-sample.php ./wordpress/wp-config.php
cp -a ./wordpress/. $path
chown -R www-data:www-data $path
echo ''

# configuring wp-config.php
echo 'configuring wp-config.php'
sed -i "s/'database_name_here'/'$DBname'/g" $path/wp-config.php
sed -i "s/'username_here'/'$DBusername'/g" $path/wp-config.php
sed -i "s/'password_here'/'$DBpassword'/g" $path/wp-config.php
###
#SALT=$(wget https://api.wordpress.org/secret-key/1.1/salt/)
#STRING='put your unique phrase here'
#printf '%s\n' "g/$STRING/d" a "$SALT" . w | ed -s $path/wp-config.php
#echo 'changing wordpress secrets'
#wget http://api.wordpress.org/secret-key/1.1/salt/
#mv index.html wp_keys.txt
#sed -i '/put your unique phrase here/d' $path/wp-config.php
#cat wp_keys.txt >> $path/wp-config.php
#echo 'define( '\''FS_METHOD'\'', '\''direct'\'' );' >> $path/wp-config.php
###
echo ''

# installing wordpress, changing theme
echo 'installing wordpress, changing theme'
wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
mv wp-cli.phar /usr/local/bin/wp
wp core install --url=$ip --title=wp_core_test --admin_user=admin --admin_email=admin@admin.admin --admin_password=\!2three456. --path=$path --skip-email --allow-root --debug
wp theme install twentynineteen --path=$path --activate --allow-root
systemctl reload nginx
echo ''

# cleaning
echo 'some cleaning'
rm -r *
