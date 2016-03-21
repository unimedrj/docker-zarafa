
function do_init() {

    # run init-Script
    # ~~~~~~~~~~~~~~~

    /usr/local/bin/init.sh
    return 0

}

function do_start() {

    # Define Services to start
    # ~~~~~~~~~~~~~~~~~~~~~~~~

    services="rsyslog ssh slapd mysql amavis clamav-daemon spamassassin postfix apache2"
    for s in ${services}; do service ${s} start; done

    # Start Zarafa via /etc/init.d/
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    for z in /etc/init.d/zarafa-*; do ${z} start; done
    
    # Start cron
    # ~~~~~~~~~~
    
    /usr/sbin/cron

    # Open Shell
    # ~~~~~~~~~~

    /bin/bash

}

# Check if it's the first time
# the Container got started
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~

FIRSTRUN=$(cat /usr/local/bin/firstrun)
echo "FIRSTRUN? ${FIRSTRUN}"

case ${FIRSTRUN} in
    "yes")
            # It's the first time, so we have to
            # run the init-Script first
            # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

            do_init
            do_start
    ;;
    "no")
            # Otherwise start the Services and
            # open a Shell
            # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

            do_start
    ;;
esac
