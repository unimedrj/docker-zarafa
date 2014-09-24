service ssh start
services amavis start
service clamav-daemon start
service spamassassin start
service postfix start
service slapd start
service mysql start
service cron start

for z in /etc/init.d/zarafa-*; do $z start; done
