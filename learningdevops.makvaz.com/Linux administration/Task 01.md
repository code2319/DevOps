### [Task 01.](https://learningdevops.makvaz.com/phase1-task1-linux-administration) Linux administration. Install packages, start services, troubleshoot if something not working. VM on Virtualbox.

### 1. Setup Ubuntu for VMware
  1. [Download Ubuntu Server 22.04 LTS](https://ubuntu.com/download/server)
  2. Leave everything as default when installing.
  3. Take snapshot.
  4. Connect to VM using [putty](https://www.chiark.greenend.org.uk/~sgtatham/putty/)
  5. Add another network adapter: `Network Adapter 2 (Host-Only)`
  6. Change server date:  
      1. Search for your timezone:  
          - `timedatectl list-timezones | grep Moscow`  
      2. Set your timezone:  
          - `sudo timedatectl set-timezone Europe/Moscow`  
      3. Enable `timesyncd`:  
          - `sudo timedatectl set-ntp-on`

### 2. [Install and setup web server nginx](https://nginx.org/en/linux_packages.html#Ubuntu)
	
### 3. Opening Your Web Page
  1. Add the following line to the `hosts` file:
      > `192.168.26.131  ubuntuserver2204`

### 4. create file index.html
  1. `sudo vim /usr/share/nginx/html/index.html`
  2. `sudo systemctl restart nginx.service`
  3. Reload page in browser.
	
### 5. Make sure that you opened only needed ports
  1. List of open ports: `netstat -ntlp`
      - If the `netstat` command is not available, install it with: `sudo apt-get install net-tools`

### 6. Know your software
  1. Make sure that you have installed stable and secure nginx version (no CVE found for this version): `nginx -v`
		
### 7. Create a Self-Signed SSL Certificate for Nginx in Ubuntu 22.04
  1. [Let's take this tutorial as a basis](https://www.digitalocean.com/community/tutorials/how-to-create-a-self-signed-ssl-certificate-for-nginx-in-ubuntu-18-04)
  2. Adjusting the Nginx Configuration to Use SSL:
      > `sudo cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.bak`
  
   - if the file does not exist, then it needs to be created, most likely you will also need to create directories: `sites-available`, `sites-enabled`
  3. Make sure to have symlinks from `/etc/nginx/sites-available/*` to `/etc/nginx/sites-enabled/`:
      > cd /etc/nginx/sites-enabled  
      > sudo ln -sf ../sites-available/default .
  
  4. In file `/etc/nginx/sites-available/your_domain.com`:
      > server_name $hostname;
  
  5. Don't forget to add `include	/etc/nginx/sites-enabled/*;` to `/etc/nginx/nginx.conf`
  6. Check if nginx listen 443 port: `sudo lsof -iTCP -sTCP:LISTEN -P`
  7. Configure `ufw`:
      - `sudo ufw allow 443/tcp`
      - `sudo ufw enable`
  8. Test nginx configuration: `sudo nginx -t`
  9. If there are no errors: `sudo systemctl restart nginx.service`
 
