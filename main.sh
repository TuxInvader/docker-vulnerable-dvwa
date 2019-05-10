#!/bin/bash

chown -R mysql:mysql /var/lib/mysql /var/run/mysqld

echo '[+] Starting mysql...'
service mysql start

echo '[+] Starting NGINX Unit'
service unit start

sleep 5

cat <<-EOF > /tmp/unit-php.json
{ 
  "applications": {
    "dvwa": {
      "type": "php",
      "processes": 20,
      "root": "/var/www/html/",
      "user": "www-data",
      "group": "www-data",

      "options": {
        "file": "/var/www/html/php.ini",
        "admin": {
            "memory_limit": "256M",
            "variables_order": "EGPCS",
            "expose_php": "0"
        },
        "user": {
            "display_errors": "0"
        }
      }
    }
  },
  "listeners": {
    "*:80": {
      "pass": "applications/dvwa"
    }
  },
  "access_log": "/var/log/unit_access.log"
}
EOF

curl -X PUT --data-binary @/tmp/unit-php.json --unix-socket \
       /var/run/control.unit.sock http://localhost/config/

while true
do
    tail -f /var/log/unit_access.log
    exit 0
done
