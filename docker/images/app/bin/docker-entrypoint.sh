#!/bin/sh
set -e

##
# Entrypoint script preferences
##
# Nextcloud release url
NEXTCLOUD_RELEASE_URL="${NEXTCLOUD_RELEASE_URL:-https://download.nextcloud.com/server/releases/latest.zip}"

# Required ENV
required_env_names="\
NEXTCLOUD_DB_TYPE
NEXTCLOUD_DOMAINS
NEXTCLOUD_MAIN_DOMAIN"

# Secrets ENV.
secret_env_names="\
NEXTCLOUD_DB_PASSWORD
NEXTCLOUD_SMTP_PASSWORD
NEXTCLOUD_CACHE_REDIS_USER
NEXTCLOUD_CACHE_REDIS_PASSWORD"

##
# Start container service
##
echo "[I] Initializing service..."

##
# Prepare service ENV
##
# Detect required ENV
if [ "$NEXTCLOUD_DB_TYPE" = "mysql" ] || [ "$NEXTCLOUD_DB_TYPE" = "pgsql" ]; then
    required_env_names="$required_env_names
NEXTCLOUD_DB_HOST
NEXTCLOUD_DB_NAME
NEXTCLOUD_DB_USER
NEXTCLOUD_DB_PASSWORD"
fi

if [ -n "$NEXTCLOUD_SMTP_MODE" ]; then
    required_env_names="$required_env_names
NEXTCLOUD_SMTP_HOST
NEXTCLOUD_SMTP_PORT"
    if [ "$NEXTCLOUD_SMTP_MODE" = "smtp" ]; then
        required_env_names="$required_env_names
NEXTCLOUD_SMTP_AUTH"
    fi
fi

if [ -n "$NEXTCLOUD_CACHE_MODE" ]; then
    case "$NEXTCLOUD_CACHE_MODE" in
        redis)
            required_env_names="$required_env_names
NEXTCLOUD_CACHE_REDIS_HOST
NEXTCLOUD_CACHE_REDIS_PORT"
            ;;
        memcached)
            required_env_names="$required_env_names
NEXTCLOUD_CACHE_MEMCACHED_HOST
NEXTCLOUD_CACHE_MEMCACHED_PORT"
            ;;
    esac
fi

# Parse secrets to ENV
for secret_env_name in $secret_env_names; do
  secret_file_var="${secret_env_name}_FILE"
  eval "secret_file_path=\$$secret_file_var"
  if [ -n "$secret_file_path" ]; then
    if [ -f "$secret_file_path" ]; then
      value=$(cat "$secret_file_path")
      export "$secret_env_name=$value"
      echo " >  Loaded '$secret_env_name' from '$secret_file_path'"
    else
      echo "[F] File '$secret_file_path' ('$secret_file_var') is not found!" >&2
    fi
  fi
done

# Check required ENV
for required_env_name in $required_env_names; do
    if [ -z "$(eval echo "\$$required_env_name")" ]; then
        echo "[F] ENV value '$required_env_name' is not set!" >&2
        exit 1
    fi
done

##
# Prepare service software
##
# Download and install nextcloud
if [ ! -f "./index.php" ]; then
    echo "[W] Nextcloud sources not found! Installing..."
    wget --no-hsts --quiet -O ./pkg.zip "$NEXTCLOUD_RELEASE_URL"
    unzip -q ./pkg.zip
    mv ./nextcloud/* ./
    mv ./nextcloud/.[!.]* ./
    rm -rf ./nextcloud/
    rm ./pkg.zip
    echo "[I] Nextcloud sources installed!"
fi

# Preconfigure
# Clear auto-generated configs to allow reconfiguration on restart
rm -f ./config/*.config.php

# DB config
case "$NEXTCLOUD_DB_TYPE" in
    mysql|pgsql)
        cat > ./config/db.config.php <<PHP
<?php
\$CONFIG = [
    'dbtype'     => '${NEXTCLOUD_DB_TYPE}',
    'dbhost'     => '${NEXTCLOUD_DB_HOST}',
    'dbname'     => '${NEXTCLOUD_DB_NAME}',
    'dbuser'     => '${NEXTCLOUD_DB_USER}',
    'dbpassword' => '${NEXTCLOUD_DB_PASSWORD}',
];
PHP
        ;;
    sqlite3)
        cat > ./config/db.config.php <<PHP
<?php
\$CONFIG = [
    'dbtype' => 'sqlite3',
    'dbname' => '/home/files/nextcloud.db',
];
PHP
        ;;
esac
echo " >  Created 'db.config.php' (${NEXTCLOUD_DB_TYPE})"

# Storage config
cat > ./config/storage.config.php <<PHP
<?php
\$CONFIG = [
    'datadirectory' => '/home/files',
];
PHP
echo " >  Created 'storage.config.php'"

# Phone region config
if [ -n "$NEXTCLOUD_PHONE_REGION" ]; then
    cat > ./config/phone_region.config.php <<PHP
<?php
\$CONFIG = [
    'default_phone_region' => '${NEXTCLOUD_PHONE_REGION}',
];
PHP
    echo " >  Created 'phone_region.config.php' (${NEXTCLOUD_PHONE_REGION})"
fi

# Updater config
cat > ./config/updater.config.php <<PHP
<?php
\$CONFIG = [
    'upgrade.disable-web' => false,
];
PHP
echo " >  Created 'updater.config.php'"

# Mail config
if [ -n "$NEXTCLOUD_SMTP_MODE" ]; then
    if [ "$NEXTCLOUD_SMTP_MODE" = "smtp" ]; then
        smtp_auth_value="false"
        [ "$NEXTCLOUD_SMTP_AUTH" = "true" ] && smtp_auth_value="true"
        cat > ./config/mail.config.php <<PHP
<?php
\$CONFIG = [
    'mail_smtpmode'     => 'smtp',
    'mail_smtphost'     => '${NEXTCLOUD_SMTP_HOST}',
    'mail_smtpport'     => '${NEXTCLOUD_SMTP_PORT}',
    'mail_smtpsecure'   => '${NEXTCLOUD_SMTP_SECURE:-}',
    'mail_smtpauth'     => ${smtp_auth_value},
    'mail_smtpauthtype' => '${NEXTCLOUD_SMTP_AUTH_TYPE:-}',
    'mail_smtpname'     => '${NEXTCLOUD_SMTP_USER:-}',
    'mail_smtppassword' => '${NEXTCLOUD_SMTP_PASSWORD:-}',
    'mail_domain'       => '${NEXTCLOUD_SMTP_DOMAIN:-}',
    'mail_from_address' => '${NEXTCLOUD_SMTP_FROM:-}',
];
PHP
    else
        cat > ./config/mail.config.php <<PHP
<?php
\$CONFIG = [
    'mail_smtpmode' => 'sendmail',
    'mail_smtphost' => '${NEXTCLOUD_SMTP_HOST}',
    'mail_smtpport' => ${NEXTCLOUD_SMTP_PORT},
];
PHP
    fi
    echo " >  Created 'mail.config.php' (${NEXTCLOUD_SMTP_MODE})"
fi

# Cache config
redis_auth=""
[ -n "$NEXTCLOUD_CACHE_REDIS_USER" ]     && redis_auth="${redis_auth}
        'user'     => '${NEXTCLOUD_CACHE_REDIS_USER}',"
[ -n "$NEXTCLOUD_CACHE_REDIS_PASSWORD" ] && redis_auth="${redis_auth}
        'password' => '${NEXTCLOUD_CACHE_REDIS_PASSWORD}',"

case "${NEXTCLOUD_CACHE_MODE:-apcu}" in
    apcu)
        cat > ./config/cache.config.php <<PHP
<?php
\$CONFIG = [
    'memcache.local'       => '\OC\Memcache\APCu',
    'memcache.distributed' => '\OC\Memcache\APCu',
    'memcache.locking'     => '\OC\Memcache\APCu',
];
PHP
        ;;
    redis)
        cat > ./config/cache.config.php <<PHP
<?php
\$CONFIG = [
    'memcache.local'       => '\OC\Memcache\APCu',
    'memcache.distributed' => '\OC\Memcache\Redis',
    'memcache.locking'     => '\OC\Memcache\Redis',
    'redis' => [
        'host' => '${NEXTCLOUD_CACHE_REDIS_HOST}',
        'port' => ${NEXTCLOUD_CACHE_REDIS_PORT},${redis_auth}
    ],
];
PHP
        ;;
    memcached)
        cat > ./config/cache.config.php <<PHP
<?php
\$CONFIG = [
    'memcache.local'       => '\OC\Memcache\APCu',
    'memcache.distributed' => '\OC\Memcache\Memcached',
    'memcache.locking'     => '\OC\Memcache\Memcached',
    'memcached_servers' => [
        ['${NEXTCLOUD_CACHE_MEMCACHED_HOST}', ${NEXTCLOUD_CACHE_MEMCACHED_PORT}],
    ],
];
PHP
        ;;
esac
echo " >  Created 'cache.config.php' (${NEXTCLOUD_CACHE_MODE:-apcu})"

# Trusted domains config
trusted_domains_php=""
i=0
IFS=','
for domain in $NEXTCLOUD_DOMAINS; do
    domain=$(echo "$domain" | tr -d ' ')
    trusted_domains_php="${trusted_domains_php}        ${i} => '${domain}',
"
    i=$((i + 1))
done
IFS='
'
cat > ./config/trusted_domains.config.php <<PHP
<?php
\$CONFIG = [
    'trusted_domains' => [
${trusted_domains_php}    ],
];
PHP
echo " >  Created 'trusted_domains.config.php'"

# Domain config
cat > ./config/domain.config.php <<PHP
<?php
\$CONFIG = [
    'overwrite.cli.url'   => '${NEXTCLOUD_SCHEME:-http}://${NEXTCLOUD_MAIN_DOMAIN}',
    'overwriteprotocol'   => '${NEXTCLOUD_SCHEME:-http}',
];
PHP
echo " >  Created 'domain.config.php'"

# Proxy config
trusted_proxies_php=""
IFS=','
for proxy in ${NEXTCLOUD_TRUSTED_PROXIES:-10.0.0.0/8,172.16.0.0/12,192.168.0.0/16}; do
    proxy=$(echo "$proxy" | tr -d ' ')
    trusted_proxies_php="${trusted_proxies_php}        '${proxy}',
"
done
IFS='
'
cat > ./config/proxy.config.php <<PHP
<?php
\$CONFIG = [
    'trusted_proxies' => [
${trusted_proxies_php}    ],
    'forwarded_for_headers' => ['HTTP_X_FORWARDED_FOR'],
];
PHP
echo " >  Created 'proxy.config.php'"

# Clean sh history
echo "[I] Clean sh history..."
rm -f ./.ash_history

##
# Run service
##
echo "[I] Service initialization complete!"
echo "[I] Starting..."
exec "$@"
