# Initialization and Setup for a new
# created Docker Container
#
# Author: Tobias Mandjik <webmaster@leckerbeef.de>
#

# (LDAP) DELETE OLD DATABASES
echo "[LDAP] DELETING OLD DATABASES"
rm -rf /var/lib/ldap/*

# (LDAP) SET VALUES FOR CONFIGURATION
echo "[LDAP] SETTING NEW CONFIGURATION VALUES"
echo "slapd slapd/password1 password ${LB_LDAP_PASSWORD}" | debconf-set-selections
echo "slapd slapd/password2 password ${LB_LDAP_PASSWORD}" | debconf-set-selections
#echo "slapd slapd/internal/adminpw password ${LB_LDAP_PASSWORD}" | debconf-set-selections
#echo "slapd slapd/internal/generated_adminpw passowrd ${LB_LDAP_PASSWORD}" | debconf-set-selections
echo "slapd slapd/allow_ldap_v2 boolean false" | debconf-set-selections
echo "slapd slapd/invalid_config boolean true" | debconf-set-selections
echo "slapd slapd/move_old_database boolean false" | debconf-set-selections
#echo "slapd slapd/upgrade_slapcat_failure error" | debconf-set-selections
echo "slapd slapd/backend select HDB" | debconf-set-selections
echo "slapd shared/organization string ${LB_LDAP_DN}" | debconf-set-selections
echo "slapd slapd/domain string ${LB_MAILDOMAIN}" | debconf-set-selections
echo "slapd slapd/no_configuration boolean false" | debconf-set-selections
echo "slapd slapd/dump_database_destdir string /var/backups/slapd-VERSION" | debconf-set-selections
echo "slapd slapd/purge_database boolean true" | debconf-set-selections

# (LDAP) RECONFIGURE SLAPD
echo "[LDAP] INVOKING RECONFIGURATION OF SLAPD"
dpkg-reconfigure -f noninteractive slapd
echo "[LDAP] Starting SLAPD"
/etc/init.d/slapd start

# (LDAP) INSERT ZARAFA SCHEME
echo "[LDAP] INSERTING ZARAFA SCHEME INTO LDAP"
zcat /usr/share/doc/zarafa/zarafa.ldif.gz | ldapadd -H ldapi:/// -Y EXTERNAL

# (LDAP) INSERT TEMPLATE USER
echo "[LDAP] CREATING FIRST ZARAFA USER"
ldif="/usr/local/bin/ldap.ldif"
sed -i 's/dc=REPLACE,dc=ME/'${LB_LDAP_DN}'/g' $ldif
ldapadd -x -D cn=admin,${LB_LDAP_DN} -w ${LB_LDAP_PASSWORD} -f $ldif

# (SSH) REGENERATE SSH-HOST-KEY
echo "[SSH] REGENERATING SSH HOST-KEY"
rm -v /etc/ssh/ssh_host_*
dpkg-reconfigure openssh-server

# (MYSQL) UPDATE ROOT-USER PASSWORD
echo "[MySQL] STARTING MySQL SERVER"
mysqld_safe &
echo "[MYSQL] SETTING NEW ROOT PASSWORD"
sleep 5s && mysqladmin -u root password ${LB_MYSQL_PASSWORD}

# (AMAVIS) SET DOMAIN NAME
echo "[AMAVIS] SETTING DOMAIN NAME"
sed -i 's/^\#$myhostname.*/\$myhostname = \"'${HOSTNAME}'.'${LB_MAILDOMAIN}'\";/g' /etc/amavis/conf.d/05-node_id

# (AMAVIS) ADD USER
echo "[AMAVIS] Adding user 'clamav' to group 'amavis'"
adduser clamav amavis

# (SPAMASSASSIN) Enable
echo "[SPAMASSASSIN] Enabling Spamassassin and daily Cronjob"

sed -i 's/^ENABLED=0/ENABLED=1/g' /etc/default/spamassassin
sed -i 's/^CRON=0/CRON=1/g' /etc/default/spamassassin

# (POSTFIX) SET CONFIGURATION VALUES
echo "[POSTFIX] REPLACING CONFIGURATION VALUES"

echo ${HOSTNAME}.${LB_MAILNAME} > /etc/mailname

pf="/etc/postfix/main.cf"
pfs="/etc/postfix/saslpass"

sed -i 's/^virtual_mailbox_domains.*/virtual_mailbox_domains = '${LB_MAILDOMAIN}'/g' $pf
sed -i 's/^myhostname.*/myhostname = '${HOSTNAME}'/g' $pf
sed -i 's/^mydestination.*/mydestination = localhost, '${HOSTNAME}'/g' $pf
sed -i 's/^realyhost.*/relayhost = '${EBIS_RELAYHOST}'/g' $pf

echo "${LB_RELAYHOST} ${LB_RELAYHOST_USERNAME}:${LB_RELAYHOST_PASSWORD}" > $pfs
postmap $pfs

sed -i 's/^search_base.*/search_base = ou=Zarafa,'${LB_LDAP_DN}'/g' /etc/postfix/ldap-users.cf
sed -i 's/^search_base.*/search_base = ou=Zarafa,'${LB_LDAP_DN}'/g' /etc/postfix/ldap-aliases.cf

# (ZARAFA) REPLACING LDAP SETTINGS
echo "[ZARAFA] REPLACING LDAP SETTINGS"
mv /etc/zarafa/ldap.openldap.cfg /etc/zarafa/ldap.cfg
sed -i 's/^ldap_search_base.*/ldap_search_base = ou=Zarafa,'${LB_LDAP_DN}'/g' /etc/zarafa/ldap.cfg
sed -i 's/^user_plugin.*/user_plugin = ldap/g' /etc/zarafa/server.cfg

# (ZARAFA) REPLACING MYSQL PASSWORD
echo "[ZARAFA] REPLACING MYSQL PASSWORD"
sed -i 's/^mysql_password.*/mysql_password = '${LB_MYSQL_PASSWORD}'/g' /etc/zarafa/server.cfg

# (FETCHMAIL) Add fetchmailrc and Cronjob
echo "[FETCHMAIL] Adding fetchmailrc and cronjob"
touch /etc/fetchmailrc
chmod 0700 /etc/fetchmailrc && chown postfix /etc/fetchmailrc
cronline="*/5 * * * * su postfix -c '/usr/bin/fetchmail -f /etc/fetchmailrc'"
(crontab -u root -l; echo "${cronline}" ) | crontab -u root -

# (APACHE) Enable PhpLDAPadmin and Zarafa Webaccess/Webapp
mv /etc/apache2/sites-available/zarafa-webaccess /etc/apache2/sites-available/zarafa-webaccess.conf
mv /etc/apache2/sites-available/zarafa-webapp /etc/apache2/sites-available/zarafa-webapp.conf
cp /etc/phpldapadmin/apache.conf /etc/apache2/sites-available/phpldapadmin.conf

a2ensite zarafa-webaccess
a2ensite zarafa-webapp
a2ensite phpldapadmin

# (SYSTEM) SET ROOT PASSWORD
echo "[SYSTEM] SETTING NEW ROOT PASSWORD"
echo "root:${LB_ROOT_PASSWORD}" | chpasswd

# (Clamav) Refreshing Clamav database
echo "[Clamav] Refreshing Clamav database (be patient ...)"
#freshclam

# (SYSTEM) START SERVICES
#echo "[SYSTEM] STARTING SERVICES"
#STARTUP="ssh apache2 amavis spamassassin clamav-daemon postfix slapd"
#ZARAFA="/etc/init.d/zarafa-*"

#for daemon in $STARTUP; do echo "Starting $daemon"; /etc/init.d/$daemon restart; done
#for zarafa in $ZARAFA; do echo "Starting $zarafa"; $zarafa restart; done

# FINISHED
echo "SETUP FINISHED! Now run your new Zarafa Contrainer!"
