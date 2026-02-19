FROM alpine:3.22

# Install PHP-FPM and all required extensions
RUN apk update && apk add --no-cache \
	php83 php83-fpm php83-mysqli php83-json php83-curl php83-dom \
	php83-exif php83-fileinfo php83-mbstring php83-openssl php83-xml \
	php83-zip php83-gd php83-phar curl tar wget \
	&& echo "memory_limit = 512M" > /etc/php83/conf.d/99-memory.ini



# Install WordPress CLI (Command line installer)
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
	&& chmod +x wp-cli.phar \
	&& mv wp-cli.phar /usr/local/bin/wp

# Create directory for PHP-FPM
RUN mkdir -p /var/www/html \
	&& chown -R nobody:nobody /var/www/html

# Set directory where WordPress files will live
WORKDIR /var/www/html

# Copy config file and entrypoint script
COPY conf/www.conf /etc/php83/php-fpm.d/www.conf
COPY --chmod=755 tools/entrypoint.sh /usr/local/bin/entrypoint.sh

# Expose port 9000 for cross container communication
EXPOSE 9000

# Run entrypoint script
ENTRYPOINT [ "/usr/local/bin/entrypoint.sh" ]

# Make container run in foreground (-F)
CMD [ "php-fpm83", "-F" ]