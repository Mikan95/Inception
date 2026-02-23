#!/bin/sh
set -e

# SSL certificate paths
CERT_PATH="/etc/nginx/ssl/nginx.crt"
KEY_PATH="/etc/nginx/ssl/nginx.key"

#── Generate SSL Certificate ──────────────────────────────────────────────────
if [ ! -f "$CERT_PATH" ] || [ ! -f "$KEY_PATH" ]; then
    echo ">>> Generating SSL certificate..."

    openssl req -x509 -nodes \
        -days 365 \
        -newkey rsa:2048 \
        -keyout "$KEY_PATH" \
        -out "$CERT_PATH" \
        -subj "/C=CH/ST=Vaud/L=Ecublens/O=42Lausanne/OU=42Lausanne/CN=${DOMAIN_NAME}/UID=${DOMAIN_NAME}"

    echo ">>> SSL certificate generated!"
else
    echo ">>> SSL certificate already exists"
fi

#── Substitute Env Vars in Config File ────────────────────────────────────────
echo ">>> Configuring NGINX..."
envsubst '${DOMAIN_NAME} ${SSL_CERT} ${SSL_KEY}' \
    < /etc/nginx/nginx.conf.template \
    > /etc/nginx/nginx.conf

#── Test NGINX configuration ──────────────────────────────────────────────────
nginx -t

# Start NGINX
echo ">>> Starting NGINX..."
exec "$@"