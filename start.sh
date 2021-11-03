#!/bin/bash

echo "Starting cron"
crond
echo "Starting httpd"
httpd
echo "Starting daemons"
su - lpar2rrd -c "cd /home/lpar2rrd/lpar2rrd ; ./load.sh"

echo "Done!"
tail -f /dev/null
