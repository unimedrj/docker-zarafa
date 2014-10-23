## Zarafa Collaboration Platform ##
This is an automated build from latest `leckerbeef/zarafabase`.

## Containing Software ##
  - `postfix` > Mail Transer Agent
  - `amavis`, `clamav`, `spamassassin` > used by Postfix for Spam- and Virusfiltering
  - `openldap` > Database to store Users- and Groups
  - `phpldapadmin` > LDAP Management-Frontend
  - `ssh` > for remote Access
  - `fetchmail` > Fetch Mails from your Provider

## Prepare Dockerfile ##
just change the ENV variables

For multiple containers with different variables use the `env.conf` and pass it to the `run` command:

`docker run -it --env-file=env.conf <imageID>`

## After Successful Setup, Build & Run ##
you should be able to...

  - view the userlist on console with `zarfa-admin -l` (you see a `templateuser`, password is `abcde`)
  - access `webapp`, `webaccess` and `phpldapadmin` from your browser and login with `templateuser` account
    - http://domain_or_ip/webapp
    - http://domain_or_ip/webaccess
    - http://domain_or_ip/phplapadmin
  - access `zarafa` via `Outlook` (be sure you have installed `zarafaclient`)
  - access with your mobile device and ActiveSync (Port 80)

## Good to Know ##
  - manage fetchmail settings via ldap, lookup howto [LECKERBEEFde/fetchmail-ldap][2]
  - SSL certificates location is `/etc/ssl/zarafa/`

## Developers Homepage ##

View the articel on the developers homepage:

[leckerbeef.de/posts/zarafa-docker-container][1]


  [1]: http://leckerbeef.de/zarafa-docker-container-nearly-full-featured/
  [2]: https://github.com/LECKERBEEFde/fetchmail-ldap
