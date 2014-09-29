
function do_init() {

    # run init-Script
    /usr/local/bin/init.sh
    return 0

}

function do_start() {

    # Start Services
    service ssh start
    service slapd start
    service mysql start
    service amavis start
    service clamav-daemon start
    service spamassassin start
    service postfix start
    service apache2 start
    service cron start

    # Start Zarafa via init-Scripts
    for z in /etc/init.d/zarafa-*; do $z start; done

    # Open bash
    /bin/bash

}

echo "FIRSTRUN? ${FIRSTRUN}"

case ${FIRSTRUN} in
    "yes")
            do_init
            do_start
    ;;
    "no")
            do_start
    ;;
esac