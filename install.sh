#!/bin/sh

#------------------------------------------------------------------------------
# Constants
#------------------------------------------------------------------------------
GHOST_ZIP_FILE=ghost-0.6.4.zip
USER=nicofrand

#------------------------------------------------------------------------------
# Script entry
#------------------------------------------------------------------------------

#Will ask password ?
adduser "$USER"
adduser "$USER" sudo

#Install needed packages
apt-get update && apt-get upgrade --yes
apt-get install curl wget apache2 php5 php5-sqlite php5-tidy php5-imagick php5-curl php5-gd proftpd git unzip nodejs --yes

#Create the user directories
mkdir www
mkdir www/up
mkdir www/cv
mkdir blog

chown -R $USER:$USER *

#Configure apache2
a2enmod proxy proxy_http rewrite
a2dissite 000-default.conf
service apache2 restart

#VirtualHosts
#wget them from nicofrand github repo
echo "Please install VirtualHosts and then reload apache2 service"

#Install wallabag
wget http://wllbg.org/latest
unzip latest
mv wallabag-* wb
rm latest
chown -R www-data:www-data wb
cd wb
curl -s http://getcomposer.org/installer | php
php composer.phar install
echo "Please perform wallabag install then update wallabag assets and db directory (and set rights to www-data:www-data) and modify the salt key in inc/poche/config.inc.php once set."

#Install Ghost
cd blog
wget https://ghost.org/zip/$GHOST_ZIP_FILE
unzip $GHOST_ZIP_FILE
rm $GHOST_ZIP_FILE
npm install --production
chown -R $USER:$USER ../blog

#Create Ghost service
cd /etc/systemd/systemd
wget https://raw.githubusercontent.com/TryGhost/Ghost-Config/master/systemd/ghost.service
sed -i -e "s/\/path\/to\/Ghost/\/home\/$USER\/blog/" ghost.service
sed -i -e "s/=http/=$USER/g" ghost.service
systemctl enable ghost.service
echo "Please update Ghost theme and database and restart ghost with 'service ghost stop && service ghost start'"

#Install cozy
apt-get install ca-certificates apt-transport-https
wget -O - https://debian.cozycloud.cc/cozy.gpg.key 2>/dev/null | apt-key add -
echo 'deb [arch=amd64] https://debian.cozycloud.cc/debian jessie main' > /etc/apt/sources.list.d/cozy.list
apt-get update && apt-get install cozy --yes

#Firewall
#wget github/nicofrand/firewall et firewall.service
echo "Please install firewall now and add it as a service"
