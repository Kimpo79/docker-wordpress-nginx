#!/bin/bash
if [ ! -f /usr/share/nginx/www/wp-config.php ]; then
  #mysql has to be started this way as it doesn't work to call from /etc/init.d
  /usr/bin/mysqld_safe &
  sleep 10s
  # Here we generate random passwords (thank you pwgen!). The first two are for mysql users, the last batch for random keys in wp-config.php
  WORDPRESS_DB="wordpress"
  MYSQL_PASSWORD=`pwgen -c -n -1 12`
  WORDPRESS_PASSWORD=`pwgen -c -n -1 12`

  ADMIN_EMAIL="hello@test12321.com"
  ADMIN_USER_NAME="Admin"
  ADMIN_NICENAME="admin"
  ADMIN_DISPLAYNAME="Admin"
  ADMIN_PASSWORD="1234567"

  #This is so the passwords show up in logs.
  echo mysql root password: $MYSQL_PASSWORD
  echo wordpress password: $WORDPRESS_PASSWORD
  echo $MYSQL_PASSWORD > /mysql-root-pw.txt
  echo $WORDPRESS_PASSWORD > /wordpress-db-pw.txt

  sed -e "s/database_name_here/$WORDPRESS_DB/
  s/username_here/$WORDPRESS_DB/
  s/password_here/$WORDPRESS_PASSWORD/
  /'AUTH_KEY'/s/put your unique phrase here/`pwgen -c -n -1 65`/
  /'SECURE_AUTH_KEY'/s/put your unique phrase here/`pwgen -c -n -1 65`/
  /'LOGGED_IN_KEY'/s/put your unique phrase here/`pwgen -c -n -1 65`/
  /'NONCE_KEY'/s/put your unique phrase here/`pwgen -c -n -1 65`/
  /'AUTH_SALT'/s/put your unique phrase here/`pwgen -c -n -1 65`/
  /'SECURE_AUTH_SALT'/s/put your unique phrase here/`pwgen -c -n -1 65`/
  /'LOGGED_IN_SALT'/s/put your unique phrase here/`pwgen -c -n -1 65`/
  /'NONCE_SALT'/s/put your unique phrase here/`pwgen -c -n -1 65`/" /usr/share/nginx/www/wp-config-sample.php > /usr/share/nginx/www/wp-config.php

  # Download nginx helper plugin
  curl -O `curl -i -s https://wordpress.org/plugins/nginx-helper/ | egrep -o "https://downloads.wordpress.org/plugin/[^']+"`
  unzip -o nginx-helper.*.zip -d /usr/share/nginx/www/wp-content/plugins
  chown -R www-data:www-data /usr/share/nginx/www/wp-content/plugins/nginx-helper

  # Download Yoast SEO plugin
  curl -O `curl -i -s https://wordpress.org/plugins/wordpress-seo/ | egrep -o "https://downloads.wordpress.org/plugin/[^']+"`
  unzip -o wordpress-seo.*.zip -d /usr/share/nginx/www/wp-content/plugins
  chown -R www-data:www-data /usr/share/nginx/www/wp-content/plugins/wordpress-seo

  # Download Infinite WP plugin
  curl -O `curl -i -s https://wordpress.org/plugins/iwp-client/ | egrep -o "https://downloads.wordpress.org/plugin/[^']+"`
  unzip -o iwp-client.zip -d /usr/share/nginx/www/wp-content/plugins
  chown -R www-data:www-data /usr/share/nginx/www/wp-content/plugins/iwp-client

  # Download Related posts plugin
  curl -O `curl -i -s   https://wordpress.org/plugins/related-posts/ | egrep -o "https://downloads.wordpress.org/plugin/[^']+"`
  unzip -o related-posts.*.zip -d /usr/share/nginx/www/wp-content/plugins
  chown -R www-data:www-data /usr/share/nginx/www/wp-content/plugins/related-posts



  # Activate nginx plugin once logged in
  cat << ENDL >> /usr/share/nginx/www/wp-config.php
\$plugins = get_option( 'active_plugins' );
if ( count( \$plugins ) === 0 ) {
  require_once(ABSPATH .'/wp-admin/includes/plugin.php');
  \$pluginsToActivate = array( 
    'nginx-helper/nginx-helper.php',
    'wordpress-seo/wp-seo.php',
    'iwp-client/init.php',
    'related-posts/init.php');
  foreach ( \$pluginsToActivate as \$plugin ) {
    if ( !in_array( \$plugin, \$plugins ) ) {
      activate_plugin( '/usr/share/nginx/www/wp-content/plugins/' . \$plugin );
    }
  }
}
ENDL

  chown www-data:www-data /usr/share/nginx/www/wp-config.php

  mysqladmin -u root password $MYSQL_PASSWORD
  mysql -uroot -p$MYSQL_PASSWORD -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '$MYSQL_PASSWORD' WITH GRANT OPTION; FLUSH PRIVILEGES;"
  mysql -uroot -p$MYSQL_PASSWORD -e "CREATE DATABASE $WORDPRESS_DB; GRANT ALL PRIVILEGES ON wordpress.* TO 'wordpress'@'localhost' IDENTIFIED BY '$WORDPRESS_PASSWORD'; FLUSH PRIVILEGES;"
  
  # Let's create an initial Admin user
  
  mysql -uroot -p$MYSQL_PASSWORD -e "INSERT INTO $WORDPRESS_DB.wp_users ('ID', 'user_login', 'user_pass', 'user_nicename', 'user_email', 'user_status', 'display_name') VALUES ('666' ,'$ADMIN_USER_NAME', MD5('$ADMIN_PASSWORD'), '$ADMIN_NICENAME', '$ADMIN_EMAIL', '0', '$ADMIN_DISPLAYNAME');"
  mysql -uroot -p$MYSQL_PASSWORD -e "INSERT INTO $WORDPRESS_DB.wp_usermeta ('umeta_id', 'user_id', 'meta_key', 'meta_value') VALUES (NULL, '666', 'wp_capabilities', 'a:1:{s:13:\"administrator\";b:1;}');"
  mysql -uroot -p$MYSQL_PASSWORD -e "INSERT INTO $WORDPRESS_DB.wp_usermeta ('umeta_id', 'user_id', 'meta_key', 'meta_value') VALUES (NULL, '666', 'wp_user_level', '10');"
  
 # We need to create user and activate Wordpress here!
 
 WP_ADMIN_PATH="blabla" # http://www.example.com/wp-admin

 # We need to get 

  # IWP_ACTIVATIONKEY= mysql -uroot -p$MYSQL_PASSWORD -e "SELECT option_value FROM wp_options WHERE option_name = 'iwp_client_activate_key'"
  # echo $IWP_ACTIVATIONKEY
  # We need to echo out 
  killall mysqld
fi

# start all the services
/usr/local/bin/supervisord -n
