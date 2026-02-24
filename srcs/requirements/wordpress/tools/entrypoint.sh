#!/bin/sh
set -eu

# ── Read All Relevant WP info from Secrets ───────────────────────────────────────────────────
DB_PASSWORD=$(cat ${MYSQL_PASSWORD_FILE})
WP_USER_PASS=$(cat ${WP_USER_PASSWORD_FILE})

# Parse WordPress admin - Format in file: "username:password"
WP_ADMIN_USER=$(cat ${WP_ADMIN_PASSWORD_FILE} | cut -d: -f1)
WP_ADMIN_PASS=$(cat ${WP_ADMIN_PASSWORD_FILE} | cut -d: -f2)

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
    if [ ! -d wp-admin ]; then
		echo ">>> Downloading Wordpress core.."
        wp core download --allow-root
    fi

	# ── Create wp-config.php ─────────────────────────────────────────────────────────────────
    # Connects Wordpress to Database
	if [ ! -f wp-config.php ]; then
    wp config create \
        --dbname=${MYSQL_DATABASE} \
        --dbuser=${MYSQL_USER} \
        --dbpass=${DB_PASSWORD} \
        --dbhost=mariadb:3306 \
        --allow-root
	fi

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