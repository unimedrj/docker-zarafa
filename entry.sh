service ssh start
service slapd start
service mysql start
service amavis start
service clamav-daemon start
service spamassassin start
service postfix start
service apache2 start
service cron start

for z in /etc/init.d/zarafa-*; do $z start; done
