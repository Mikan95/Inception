FROM alpine:3.22

RUN apk update \
	&& apk add --no-cache mariadb mariadb-client

RUN mkdir -p /run/mysqld \
	&& chown -R mysql:mysql /run/mysqld

COPY conf/mydb.cnf /etc/my.cnf.d/mariadb-server.cnf

COPY --chmod=755 tools/init.sh /usr/local/bin/init.sh

#expose port
EXPOSE 3306

ENTRYPOINT [ "/usr/local/bin/init.sh" ]
