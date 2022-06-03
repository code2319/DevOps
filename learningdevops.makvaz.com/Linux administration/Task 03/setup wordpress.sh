#!/bin/bash
# Please do not remove this line. This command tells bash to stop executing on first error. 
set -e

# Your code goes below ...
echo 'This script should install and setup Wordpress'
echo ''

# some global vars
path="/var/www/wordpress"
wptheme="twentynineteen"
DBname="wordpress"
DBusername="wordpressuser"
DBpassword="password"
ip="$(ip -o -4 addr show eth1 | awk '{ split($4, ip_addr, "/"); print ip_addr[1] }')"
CYAN='\033[0;36m'
LG='\033[0;37m'
NC='\033[0m'

# wget can't resolve nginx.org when installing nginx...
if ! grep -Fwq "8.8.8.8" /etc/resolv.conf
then
	sed -i "/127/d" /etc/resolv.conf
	echo nameserver 8.8.8.8 | tee -a /etc/resolv.conf
fi

# installing nginx
if ! nginx -v &> /dev/null
then
	echo -e "${LG}installing nginx${NC}"
	apt-get update
	apt-get install -y curl gnupg2 ca-certificates lsb-release ubuntu-keyring
	wget https://nginx.org/keys/nginx_signing.key 
	cat nginx_signing.key | gpg --dearmor | sudo tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null
	echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/ubuntu `lsb_release -cs` nginx" | sudo tee /etc/apt/sources.list.d/nginx.list
	echo -e "Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900\n" | sudo tee /etc/apt/preferences.d/99nginx
	apt-get update
	apt-get install -y nginx-core
else
	echo -e "${CYAN}nginx already installed${NC}"
fi

# installing mysql
if ! mysql -V &> /dev/null
then
	echo -e "${LG}installing: mysql${NC}"
	apt-get install -y mysql-server
else
	echo -e "${CYAN}mysql already installed${NC}"
fi

# installing php
if ! php -v &> /dev/null
then
	echo -e "${LG}installing php${NC}"
	apt-get install -y php-fpm php-mysql php-curl php-gd php-intl php-mbstring php-soap php-xml php-xmlrpc php-zip
else
	echo -e "${CYAN}php already installed${NC}"
fi

# configuring nginx
if [ ! -f "/etc/nginx/sites-available/wordpress" ]
then
	echo -e "${LG}configuring nginx${NC}"
	rm /etc/nginx/sites-available/default
	rm /etc/nginx/sites-enabled/default
	echo -e 'server {\n\tlisten 80;\n\tserver_name wordpress;\n\troot /var/www/wordpress;\n\tindex index.html index htm index.php;\n\n\t location / {\n\t\ttry_files $uri $uri/ /index.php$is_args$args;\n\t}\n\n\tlocation ~ \.php {\n\t\tfastcgi_pass unix:/var/run/php/php7.4-fpm.sock;\n\t\tinclude /etc/nginx/fastcgi_params;\n\t\tfastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;\n\t\tfastcgi_param SCRIPT_NAME $fastcgi_script_name;\n\t}\n\n\tlocation ~ /\.ht {\n\t\tdeny all;\n\t}\n\n\tlocation = /favicon.ico {\n\t\tlog_not_found off;\n\t\taccess_log off;\n\t}\n\n\tlocation = /robots.txt {\n\t\tlog_not_found off;\n\t\taccess_log off;\n\t\tallow all;\n\t}\n\n\tlocation ~* \.(css|gif|ico|jpeg|jpg|js|png)$ {\n\t\texpires max;\n\t\tlog_not_found off;\n\t}\n}' > /etc/nginx/sites-available/wordpress
	ln -s /etc/nginx/sites-available/wordpress /etc/nginx/sites-enabled/
	
	if nginx -t
       	then 
		systemctl reload nginx; 
	fi
else
	echo -e "${CYAN}nginx already configured${NC}"
fi

# create db for wordpress
if ! mysqlshow "$DBname"
then
	echo -e "${LG}create database for wordpress${NC}"
	mysql -e "CREATE DATABASE $DBname DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;"
else
	echo -e "${CYAN}database exists${NC}"
fi

# create db user
check_db_user="$(mysql -sse "SELECT EXISTS(SELECT 1 FROM mysql.user WHERE user = '$DBusername')")"
if [ "$check_db_user" = 0 ]
then 
	echo -e "${LG}create db user${NC}"
	mysql -e "CREATE USER '$DBusername'@'localhost' IDENTIFIED BY '$DBpassword';"
	mysql -e "GRANT ALL ON wordpress.* TO '$DBusername'@'localhost';"
else
	echo -e "${CYAN}user exists${NC}"
fi       

# downloading wordpress
if [ ! -d $path ]
then
	echo -e "${LG}downloading wordpress${NC}"
	mkdir $path
	wget https://wordpress.org/latest.tar.gz
	tar -zxf latest.tar.gz
	cp ./wordpress/wp-config-sample.php ./wordpress/wp-config.php
	cp -a ./wordpress/. $path
	chown -R www-data:www-data $path
	echo ""
	echo -e "${LG}changing db params${NC}"
	sed -i "s/'database_name_here'/'$DBname'/g" $path/wp-config.php
	sed -i "s/'username_here'/'$DBusername'/g" $path/wp-config.php
	sed -i "s/'password_here'/'$DBpassword'/g" $path/wp-config.php
else
	echo -e "${CYAN}wordpress already downloaded and configured${NC}"
fi

# installing wp-cli
if [ -f "/usr/local/bin/wp" ]
then
	echo -e "${CYAN}wp-cli already installed${NC}"
else
	echo -e "${LG}downloading wp-cli${NC}"
	wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
	chmod +x wp-cli.phar
	mv wp-cli.phar /usr/local/bin/wp
fi

# installing wordpress
if ! wp core is-installed --url=$ip --path=$path --allow-root
then
	echo -e "${LG}installing wordpress${NC}"
	wp core install --url=$ip --title=wp_core_test --admin_user=admin --admin_email=admin@admin.admin --admin_password=\!2three456. --path=$path --skip-email --allow-root
else
	echo -e "${CYAN}wordpress already installed${NC}"
fi

# installing wordpress theme
if wp theme is-active $wptheme --url=$ip --path=$path --allow-root
then
	echo -e "${CYAN}theme $wptheme already installed${NC}"
else
	wp theme install $wptheme --path=$path --activate --allow-root
	if nginx -t
	then
		systemctl reload nginx
	fi
fi

# cleaning
if [ ! -z "$(ls)" ]; then
	rm -r *
fi
