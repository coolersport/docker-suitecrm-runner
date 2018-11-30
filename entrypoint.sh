#!/bin/bash
#set -e

if [[ "$@" = *bash* ]]; then
  exec "$@"
  exit 0
fi

# install if html folder is empty
www=/var/www/html
if [[ -z `find "$www" -mindepth 1 -print -quit 2>/dev/null` ]]; then
  VERSION=7.10.10
  echo Installing SuiteCRM $VERSION
  cd $www
  chown www-data:www-data $www
  gosu www-data curl -sSL https://github.com/salesagility/SuiteCRM/archive/v${VERSION}.tar.gz -o $www/v${VERSION}.tar.gz
  gosu www-data tar xvfz $www/v${VERSION}.tar.gz --strip 1 -C $www
  rm -rf v${VERSION}.tar.gz
  gosu www-data composer install --no-dev
fi

if [[ -f "$www/cron.php" ]]; then
  (crontab -l -u www-data 2>/dev/null; echo "*    *    *    *    *     cd $www; php -f cron.php &>/dev/null") | crontab -u www-data -
fi

exec "$@"
