#!/bin/sh

# Immediate exit if a command fails
set -e


DATADIR="/var/lib/mysql"                # MariaDB data directory path
SOCKET="/run/mysqld/mysql.sock"        # Local socket path


# ── Read secrets ─────────────────────────────────────────────────────────────
DB_NAME="${MYSQL_DATABASE:-wordpress}"	# If not set, default to "wordpress"
DB_USER="${MYSQL_USER:-wp_user}"		# If not set, default to "wp_user"
DB_ROOT_PASSWORD=$(cat $MYSQL_ROOT_PASSWORD_FILE)
DB_PASSWORD=$(cat $MYSQL_PASSWORD_FILE)


# ── First-time initialization ────────────────────────────────────────────────
# /var/lib/mysql/mysql is the core system database directory
# It only exists AFTER MariaDB has been initialised
if [ ! -d "$DATADIR/mysql" ]; then
	echo ">>> First run: Initialising MariaDB..."

	# create system tables
	mariadb-install-db	--user=mysql \
						--datadir="$DATADIR" \
						--skip-test-db > /dev/null \
						--auth-root-authentication-method=normal >/dev/null

	# ── Create Helathcheck config with root credentials ──────────────────────
	# {
	# echo "[client]"
	# echo "user=root"
	# echo "password=${MYSQL_ROOT_PASSWORD}"
	# } > /etc/mysql/healthcheck.cnf
	# chmod 600 /etc/mysql/healthcheck.cnf

	# ── Create Bootstrap file for temp first time setup ──────────────────────
	BOOTSTRAP_SQL="/tmp/bootstrap.sql"
	{
		echo "FLUSH PRIVILEGES;"

		# Set root password (only if provided)
		if [ -n "$DB_ROOT_PASSWORD" ]; then
			echo "ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';"
		fi

		# Create app database and user (idempotent)
		echo "CREATE DATABASE IF NOT EXISTS ${DB_NAME};"
		if [ -n "$DB_PASSWORD" ]; then
			echo "CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';"
			echo "ALTER USER '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';"
		else
			# Fallback password only if none provided (dev convenience)
			echo "CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY 'password';"
			echo "ALTER USER '${DB_USER}'@'%' IDENTIFIED BY 'password';"
		fi
		echo "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'%';"
		echo "FLUSH PRIVILEGES;"

		# # ── Create dedicated user for healthcheck ──────────────────────
		echo "CREATE USER 'health'@'%' IDENTIFIED BY 'secretphrase';"
		echo "GRANT USAGE ON *.* TO 'health'@'%';"
	} > "$BOOTSTRAP_SQL"

	# Run bootstrap SQL with server in bootstrap mode (no auth)
	mariadbd --datadir="$DATADIR" --user=mysql --bootstrap < "$BOOTSTRAP_SQL"
	rm -f "$BOOTSTRAP_SQL"

	echo ">>> MariaDB setup complete!"
fi

# ── Hand off to the actual daemon (PID 1) ─────────────────────────────────────
# exec replaces this shell process with mysqld
# mysqld becomes PID 1, receiving Docker's signals directly

echo ">>> Starting MariaDB.."
exec "$@"

# $@ is sppeccial shell variable thaat  stores the arguments passed in the command line
# Or in this case the CMD of the Dockerfile