#! /bin/bash
/home/ro1/.rbenv/shims/pumactl -F /var/www/erlog/lib/puma.rb stop  > /dev/null 2>&1
sleep 1
/home/ro1/.rbenv/shims/pumactl -F /var/www/erlog/lib/puma.rb start  > /dev/null 2>&1

