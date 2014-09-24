FROM leckerbeef/zarafabase:1.0
MAINTAINER Tobias Mandjik <webmaster@leckerbeef.de>

# noninteractive Installation (dont't touch this)
ENV DEBIAN_FRONTEND noninteractive

# Password Settings
ENV LB_ROOT_PASSWORD topSecret
ENV LB_LDAP_PASSWORD topSecret
ENV LB_MYSQL_PASSWORD topSecret

# Maildomain Settings
ENV LB_LDAP_DN dc=mydomain,dc=net
ENV LB_MAILDOMAIN mydomain.net

# Relayhost Settings
ENV LB_RELAYHOST smtp.relayhost.com
ENV LB_RELAYHOST_USERNAME FooMyAuthUser
ENV LB_RELAYHOST_PASSWORD BarAuthPassword

# Zarafa License (25 Digits)
# uncommented if you have a commercial license
# ENV LB_ZARAFA_LICENSE 12345123451234512345

# Install additional Software
RUN DEBIAN_FRONTEND=noninteractive apt-get -yqq install ssh fetchmail postfix amavisd-new clamav-daemon spamassassin razor pyzor slapd ldap-utils phpldapadmin supervisor

# Add configuration files
ADD 15-content_filter_mode /etc/amavis/conf.d/15-content_filter_mode
ADD 20-debian_defaults /etc/amavis/conf.d/20-debian_defaults
ADD ldap-aliases.cf /etc/postfix/ldap-aliases.cf
ADD ldap-users.cf /etc/postfix/ldap-users.cf
ADD main.cf /etc/postfix/main.cf
ADD master.cf /etc/postfix/master.cf
ADD ldap.ldif /usr/local/bin/ldap.ldif

# Add init-Script and run it
ADD init.sh /usr/local/bin/init.sh
RUN chmod 777 /usr/local/bin/init.sh
RUN /usr/local/bin/init.sh

# Autostart
ADD entry.sh /usr/local/bin/entry.sh
CMD ["/usr/local/bin/entry.sh"]

ENTRYPOINT ["/bin/bash"]
