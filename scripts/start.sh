#!/bin/bash

# Start supervisord and services
exec /usr/bin/supervisord -n -c /etc/supervisord.conf
# exec nginx
# exec systemctl start php72-php-fpm
