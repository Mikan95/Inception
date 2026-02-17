FROM alpine:3.22

RUN apk update \
	&& apk add --no-cache mariadb mariadb-client

RUN mkdir -p /var/lib/mysql /run/mysqld \
	&& chown -R mysql:mysql /var/lib/mysql /run/mysqld

COPY conf/my.cnf /etc/my.cnf

COPY --chmod=755 tools/entrypoint.sh /usr/local/bin/entrypoint.sh

#expose port
EXPOSE 3306


ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["mariadbd", "--user=mysql"]