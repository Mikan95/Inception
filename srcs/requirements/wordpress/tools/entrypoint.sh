#!/bin/sh

# Immediate exit if a command fails
set -e


if [ ! wp core is-installed --alow-root 2>/dev/null ]; then
	echo ">>> Installing Wordpress..."

	wp core install

fi

#!/bin/sh
set -e

# ── Read All Relevant WP info form Secrets ───────────────────────────────────────────────────
DB_PASSWORD=$(cat /run/secrets/db_user_pw)

# Parse WordPress admin - Format in file: "username:password"
SECRET_WP_ADMIN_USER=$(cat /run/secrets/credentials | cut -d: -f1)
WP_ADMIN_PASS=$(cat /run/secrets/credentials | cut -d: -f2)

# WP_USER_PASS=$(cat /run/secrets/wp_user_pw)

# ── Wait for MariaDB to be ready ─────────────────────────────────────────────────────────────
echo ">>> Waiting for MariaDB..."
# nc = netcat // -z = just try to connect, don't write or read data
# tries to connect to mariadb:3306 until success/mariadb is ready,
# returns 0 on failed connection
# returns 1 on successful connection
while ! nc -z mariadb 3306; do
    sleep 1
done
echo ">>> MariaDB is ready!"


# ── Install WP if not installed ──────────────────────────────────────────────────────────────
# docker containers often run as root, so we use the --allow-root so WP-CLI runs as root too
if ! wp core is-installed --allow-root 2>/dev/null; then

    echo ">>> First run: Setting up WordPress..."

    # Download WordPress core (if not already downloaded)
    if [ ! -f wp-config.php ]; then
        wp core download --allow-root
    fi

	# ── Create wp-config.php ─────────────────────────────────────────────────────────────────
    # Connects Wordpress to Database
    wp config create \
        --dbname=${MYSQL_DATABASE} \
        --dbuser=${MYSQL_USER} \
        --dbpass=${DB_PASSWORD} \
        --dbhost=mariadb:3306 \
        --allow-root

	# ── Install WordPress ────────────────────────────────────────────────────────────────────
    # Creates admin user, sets up site, etc.
    wp core install \
        --url=https://${DOMAIN_NAME} \
        --title="${WP_TITLE}" \
        --admin_user=${WP_ADMIN_USER} \
        --admin_password=${WP_ADMIN_PASS} \
        --admin_email=${WP_ADMIN_EMAIL} \
        --skip-email \
        --allow-root

    # Create second user (subject requirement!)
    wp user create \
        ${WP_USER} \
        ${WP_USER_EMAIL} \
        --role=author \
        --user_pass=${WP_USER_PASS} \
        --allow-root

    echo ">>> WordPress installation complete!"

else
    echo ">>> WordPress already installed, skipping setup"
fi

# Start PHP-FPM (replaces this script with PHP-FPM as PID 1)
echo ">>> Starting PHP-FPM..."
exec "$@"