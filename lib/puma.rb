#!/usr/bin/env puma
application_path = '/var/www/erlog'
railsenv = 'production'
directory application_path
environment railsenv
daemonize true
pidfile "#{application_path}/tmp/pids/puma-#{railsenv}.pid"
state_path "#{application_path}/tmp/pids/puma-#{railsenv}.state"
stdout_redirect "#{application_path}/log/puma-#{railsenv}.stdout.log", "#{application_path}/log/puma-#{railsenv}.stderr.log"
bind "unix://#{application_path}/tmp/sockets/#{railsenv}.socket"
#activate_control_app "unix://#{application_path}/run/pumactl.sock"
bind 'tcp://0.0.0.0:9294'
