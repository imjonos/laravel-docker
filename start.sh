#!/bin/bash

cd /var/www/localhost;

sudo chown -R www-data  /var/www/localhost/storage
sudo chgrp -R docker  /var/www/localhost/storage
sudo chmod -R 775  /var/www/localhost/storage
sudo chown -R www-data  /var/www/localhost/bootstrap
sudo chgrp -R docker  /var/www/localhost/bootstrap
sudo chmod -R 775  /var/www/localhost/bootstrap

composer update

if [ "$3" = 'standalone' ]; then
  echo ">>>>>> STANDALONE <<<<<<"
  sudo chown -R docker  /var/www/localhost/public
  sudo chgrp -R docker  /var/www/localhost/public
  sudo chmod -R 775  /var/www/localhost/public
  echo ">>>>>> php artisan storage:link <<<<<<"
  sudo php artisan storage:link
  sudo rm /var/www/localhost/.env
  sudo cp /var/www/localhost/production.env /var/www/localhost/.env
  sudo echo "APP_URL=$4" >> /var/www/localhost/.env
  sudo echo "DB_HOST=$5" >> /var/www/localhost/.env
  sudo echo "DB_PORT=$6" >> /var/www/localhost/.env
  sudo echo "DB_DATABASE=$7" >> /var/www/localhost/.env
  sudo echo "DB_USERNAME=$8" >> /var/www/localhost/.env
  sudo echo "DB_PASSWORD=$9" >> /var/www/localhost/.env
fi

echo ">>>>>> php artisan key:generate <<<<<<"
php artisan key:generate

echo ">>>>>> START Apache <<<<<<"
sudo service apache2 start

if [ "$3" = 'true' ]; then
  echo ">>>>>> START SUPERVISOR <<<<<<"
  sudo service supervisor start;
fi

if [ "$1" = 'true' ]; then
  echo ">>>>>> START SSH <<<<<<"
  sudo service ssh restart;
fi

echo ">>>>>> php artisan migrate <<<<<<"
php artisan migrate

if [ "$2" = 'true' ]; then
  echo ">>>>>> START CRON <<<<<<"
  sudo cron && tail -f /var/log/cron.log;
fi

set -e
echo ">>>>>> SET DOMAIN HOST <<<<<<"
HOST_DOMAIN="host.docker.internal"
if ! ping -q -c1 $HOST_DOMAIN > /dev/null 2>&1
then
 HOST_IP=$(ip route | awk 'NR==1 {print $3}')
 echo -e "$HOST_IP\t$HOST_DOMAIN" >> /etc/hosts
 echo "$HOST_IP\t$HOST_DOMAIN"
fi
echo ">>>>>> SET DOMAIN HOST DONE <<<<<<"
