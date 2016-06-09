#!/bin/sh

#------------------------------------------------------------------------------
# Constants
#------------------------------------------------------------------------------
GHOST_ZIP_FILE=ghost-0.6.4.zip
USER=nicofrand

#------------------------------------------------------------------------------
# Script entry
#------------------------------------------------------------------------------

cd /

echo "Creating the default user"
#Will ask password ?
adduser "$USER"
adduser "$USER" sudo

#Install needed packages
echo "Installing all the packages needed"
apt-get update && apt-get upgrade --yes
apt-get install curl wget apache2 php5 php5-sqlite php5-tidy php5-imagick php5-curl php5-gd proftpd git unzip nodejs python-dev libffi-dev libyaml-dev libxml2-dev libxslt-dev --yes

#Get the install scripts
echo "Fetching the install scripts"
git clone https://github.com/nicofrand/vps.git tmp_vps

#Create the user directories
echo "Creating the directories needed"
mkdir www
mkdir www/up
mkdir www/cv
mkdir blog

chown -R $USER:$USER *

#Configure apache2
echo "Configuring apache and installing the VirtualHosts"
a2enmod proxy proxy_http rewrite
a2dissite 000-default.conf

cp /tmp_vps/vhosts/* /etc/apache2/sites-available/
a2ensite *
service apache2 restart

#Install wallabag
echo "Installing Wallabag"
wget http://wllbg.org/latest
unzip latest
mv wallabag-* wallabag
rm latest
chown -R www-data:www-data wallabag
cd wallabag
curl -s http://getcomposer.org/installer | php
php composer.phar install
echo "Please perform wallabag install then update wallabag assets and db directory (and set rights to www-data:www-data) and modify the salt key in inc/poche/config.inc.php once set."

#Install Ghost
echo "Installing Ghost"
cd blog
wget https://ghost.org/zip/$GHOST_ZIP_FILE
unzip $GHOST_ZIP_FILE
rm $GHOST_ZIP_FILE
npm install --production
chown -R $USER:$USER ../blog

#Create Ghost service
cd /etc/systemd/systemd
cp /tmp_vps/services/ghost.service .
sed -i -e "s/\/path\/to\/Ghost/\/home\/$USER\/blog/" ghost.service
sed -i -e "s/=http/=$USER/g" ghost.service
systemctl enable ghost.service
echo "Please update Ghost theme and database and restart ghost with 'service ghost stop && service ghost start'"

#Install cozy
echo "Installing cozy"
apt-get install ca-certificates apt-transport-https
wget -O - https://debian.cozycloud.cc/cozy.gpg.key 2>/dev/null | apt-key add -
echo 'deb [arch=amd64] https://debian.cozycloud.cc/debian jessie main' > /etc/apt/sources.list.d/cozy.list
apt-get update && apt-get install cozy --yes

#Firewall
echo "Installing firewall"
cp /tmp_vps/firewall /usr/bin/firewall
chmod +x /usr/bin/firewall
cp /tmp_vps/services/firewall.service .
#systemctl enable firewall.service

#Remove the temporary scripts
rm -rf /tmp_vps
