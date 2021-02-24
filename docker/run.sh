#!/bin/bash

if [ ! -z "$DB_URL" ]; then


  # extract the protocol
  db_proto="`echo $DB_URL | grep '://' | sed -e's,^\(.*://\).*,\1,g'`"
  # remove the protocol
  db_url=`echo $DB_URL | sed -e s,$db_proto,,g`

  # extract the user and password (if any)
  db_userpass="`echo $db_url | grep @ | cut -d@ -f1`"
  db_pass=`echo $db_userpass | grep : | cut -d: -f2`
  if [ -n "$db_pass" ]; then
      db_user=`echo $db_userpass | grep : | cut -d: -f1`
  else
      db_user=$db_userpass
  fi

  # extract the host -- updated
  db_hostport=`echo $db_url | sed -e s,$db_userpass@,,g | cut -d/ -f1`
  db_port=`echo $db_hostport | grep : | cut -d: -f2`
  if [ -n "$db_port" ]; then
      db_host=`echo $db_hostport | grep : | cut -d: -f1`
      db_port=3306
  else
      db_host=$db_hostport
  fi

  # extract the path (if any)
  db_name="`echo $db_url | grep / | cut -d/ -f2-`"

  echo "db url: $db_url"
  echo "  proto: $db_proto"
  echo "  user: $db_user"
  echo "  pass: $db_pass"
  echo "  host: $db_host"
  echo "  port: $db_port"
  echo "  name: $db_name"

  if [ -z "$db_user" ] || [ -z "$db_pass" ] || [ -z "$db_name" ] || [ -z "$VBX_SALT" ]
  then
    >&2 echo "Ensure the following DB_URL is format: mysqli://<user>:<pass>@<db_host>:<port>/<db_name> and that environment variable VBX_SALT is defined"
    exit 1;
  fi


   cat >/var/www/site/OpenVBX/config/database.php <<EOL
<?php
   \$active_group = 'default';
   \$active_record = TRUE;
   \$db['default']['username'] = '$db_user';
   \$db['default']['password'] = '$db_pass';
   \$db['default']['hostname'] = '$db_host';
   \$db['default']['database'] = '$db_name';
   \$db['default']['dbdriver'] = 'mysqli';
   \$db['default']['dbprefix'] = '';
   \$db['default']['pconnect'] = FALSE;
   \$db['default']['db_debug'] = FALSE;
   \$db['default']['cache_on'] = FALSE;
   \$db['default']['cachedir'] = '';
   \$db['default']['char_set'] = 'utf8';
   \$db['default']['dbcollat'] = 'utf8_general_ci';
/* Generated from docker install */
EOL
  chown root:www-data /var/www/site/OpenVBX/config/database.php

   cat >/var/www/site/OpenVBX/config/openvbx.php <<EOL
<?php
\$config['salt'] = '$VBX_SALT';
/* Generated from docker install */
EOL
  chown root:www-data /var/www/site/OpenVBX/config/openvbx.php

  echo "Generated files:";
  echo "/var/www/site/OpenVBX/config/database.php"
  cat /var/www/site/OpenVBX/config/database.php
  echo ""
  echo "/var/www/site/OpenVBX/config/openvbx.php"
  cat /var/www/site/OpenVBX/config/openvbx.php
else

  echo "Commencing fresh startup"
fi


# If SMTP_URL is set then configure codeigniter
if [ ! -z "$SMTP_URL" ]; then

  # extract the protocol
  smtp_proto="`echo $SMTP_URL | grep '://' | sed -e's,^\(.*://\).*,\1,g'`"
  # remove the protocol
  smtp_url=`echo $SMTP_URL | sed -e s,$smtp_proto,,g`

  # extract the user and password (if any)
  smtp_userpass="`echo $smtp_url | grep @ | cut -d@ -f1`"
  smtp_pass=`echo $smtp_userpass | grep : | cut -d: -f2`
  if [ -n "$smtp_pass" ]; then
      smtp_user=`echo $smtp_userpass | grep : | cut -d: -f1`
  else
      smtp_user=$smtp_userpass
  fi

  # extract the host -- updated
  smtp_hostport=`echo $smtp_url | sed -e s,$smtp_userpass@,,g | cut -d/ -f1`
  smtp_port=`echo $smtp_hostport | grep : | cut -d: -f2`
  if [ -n "$smtp_port" ]; then
      smtp_host=`echo $smtp_hostport | grep : | cut -d: -f1`
  else
      smtp_host=$smtp_hostport
      smtp_port=25
  fi

  # extract the path (if any)
  smtp_path="`echo $smtp_url | grep / | cut -d/ -f2-`"

  echo "url: $smtp_url"
  echo "  proto: $smtp_proto"
  echo "  user: $smtp_user"
  echo "  pass: $smtp_pass"
  echo "  host: $smtp_host"
  echo "  port: $smtp_port"
  echo "  path: $smtp_path"

  sed -i "s/\$config\['protocol'] = 'mail';/\$config\['protocol'] = 'smtp';/" /var/www/site/OpenVBX/config/email.php
  sed -i "s/\$config\['smtp_host'] = '';/\$config\['smtp_host'] = '$smtp_host';/" /var/www/site/OpenVBX/config/email.php
  sed -i "s/\$config\['smtp_user'] = '';/\$config\['smtp_user'] = '$smtp_user';/" /var/www/site/OpenVBX/config/email.php
  sed -i "s/\$config\['smtp_pass'] = '';/\$config\['smtp_pass'] = '$smtp_pass';/" /var/www/site/OpenVBX/config/email.php
  sed -i "s/\$config\['smtp_port'] = '25';/\$config\['smtp_port'] = '$smtp_port';/" /var/www/site/OpenVBX/config/email.php

  cat /var/www/site/OpenVBX/config/email.php
fi




/usr/sbin/apache2ctl -D FOREGROUND
