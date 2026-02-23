FROM alpine:3.22

#── install Nginx and dependencies ────────────────────────────────────────────
RUN apk update && apk add --no-cache openssl gettext nginx


#── Create directories for NGINX ──────────────────────────────────────────────
RUN mkdir -p /var/www/html && \
    chown -R nginx:nginx /var/www/html && \
    mkdir -p /etc/nginx/ssl

COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY --chmod=755 tools/entrypoint.sh /usr/local/bin/entrypoint.sh

#── expose port ───────────────────────────────────────────────────────────────
EXPOSE 443

#── Run entrypoint script ─────────────────────────────────────────────────────
#
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

#── Run nginx in foreground, to maintain PID 1 alive ──────────────────────────
# By default nginx forks and would cause confusion for docker when PID 1 exits
# by doing daemon off we avoid this problem/
# CMD ["nginx", "-g", "daemon off;"]

# FOR TESTING
CMD ["sleep", "infinity"]