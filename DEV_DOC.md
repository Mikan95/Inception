# DEV_DOC.md - Developer Documentation

## Overview

This document provides technical details for developers who want to understand, modify, or extend the Inception project. It covers the complete development workflow, architecture decisions, and implementation details based on the actual codebase.

---

## Project Architecture

### Technology Stack

| Component | Technology | Version | Purpose |
|-----------|-----------|---------|---------|
| Base OS | Alpine Linux | 3.22 | Lightweight container base |
| Web Server | NGINX | Latest (Alpine) | Reverse proxy, SSL termination, static files |
| Application | WordPress | Latest | Content management system |
| PHP Runtime | PHP-FPM | 8.3 | FastCGI process manager for PHP |
| Database | MariaDB | 11.4.8+ | MySQL-compatible database |
| Orchestration | Docker Compose | 2.x | Multi-container management |

### Container Architecture

```
┌─────────────────────────────────────────────────────┐
│                   Host Machine                      │
│  ┌──────────────────────────────────────────────┐  │
│  │      Docker Network: docker-network          │  │
│  │  ┌─────────┐  ┌──────────┐  ┌───────────┐  │  │
│  │  │  NGINX  │  │WordPress │  │  MariaDB  │  │  │
│  │  │ :443    │→ │ :9000    │→ │  :3306    │  │  │
│  │  └────┬────┘  └────┬─────┘  └─────┬─────┘  │  │
│  │       │            │               │         │  │
│  │       ↓            ↓               ↓         │  │
│  │  wordpress-data ←──┴──────────────┘         │  │
│  │  mariadb-data                                │  │
│  └──────────────────────────────────────────────┘  │
│         ↓                     ↓                     │
│  /home/${LOGIN}/data/wordpress                      │
│  /home/${LOGIN}/data/mariadb                        │
└─────────────────────────────────────────────────────┘
```

### Data Flow

1. **Browser** sends HTTPS request to `https://${LOGIN}.42.fr:443`
2. **NGINX** receives request:
   - Terminates SSL/TLS
   - Serves static files (images, CSS, JS) directly
   - Forwards PHP requests to WordPress via FastCGI
3. **WordPress (PHP-FPM)** processes dynamic requests:
   - Executes PHP code
   - Queries MariaDB for data
   - Renders HTML response
4. **MariaDB** provides database services:
   - Stores posts, pages, users, settings
   - Handles queries from WordPress
   - Health check endpoint for container orchestration

---

## Environment Setup from Scratch

### Prerequisites

**System Requirements:**
- Linux distribution (Debian/Ubuntu recommended)
- Docker Engine 20.10+
- Docker Compose v2.0+
- Make utility
- 4GB+ RAM
- 20GB+ free disk space

**Installation (Debian/Ubuntu):**

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install prerequisites
sudo apt install -y ca-certificates curl gnupg make

# Add Docker GPG key
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | \
  sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add Docker repository
echo "deb [arch=$(dpkg --print-architecture) \
  signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io \
  docker-buildx-plugin docker-compose-plugin

# Add user to docker group
sudo usermod -aG docker $USER
# Log out and log back in for changes to take effect
```

---

### Initial Project Setup

**1. Clone the repository:**
```bash
git clone https://github.com/yourusername/Inception.git
cd Inception
```

**2. Configure domain name:**
```bash
sudo nano /etc/hosts
```
Add line:
```
127.0.0.1    your_login.42.fr
```

**3. Run automated setup:**
```bash
make setup
```

This creates:
- `srcs/.env` from `srcs/.env.example`
- `secrets/db_root_password.txt`
- `secrets/db_password.txt`
- `secrets/credentials.txt` (format: `username:password`)
- `secrets/second_user.txt`
- All secrets with chmod 600 permissions

**4. Edit environment variables:**
```bash
nano srcs/.env
```

Required variables:
```bash
LOGIN=your_42_login                    # Used for domain and data paths

MYSQL_DATABASE=database_name
MYSQL_USER=db_username                 # Cannot contain "admin"

WP_PAGE_TITLE=Site Title
WP_ADMIN_USER_ENV=admin_username       # Cannot contain "admin"
WP_ADMIN_EMAIL=admin@example.com
WP_USER=second_username
WP_USER_EMAIL=user@example.com

SSL_CERT=/etc/nginx/ssl/nginx.crt
SSL_KEY=/etc/nginx/ssl/nginx.key
```

---

## Project Structure

```
Inception/
├── Makefile                      # Build and management commands
├── srcs/
│   ├── docker-compose.yml       # Multi-container orchestration
│   ├── .env                     # Environment variables (gitignored)
│   ├── .env.example            # Template for .env
│   └── requirements/
│       ├── mariadb/
│       │   ├── Dockerfile       # MariaDB container image
│       │   ├── .dockerignore
│       │   ├── conf/
│       │   │   └── my.cnf      # MariaDB server configuration
│       │   └── tools/
│       │       └── entrypoint.sh  # Database initialization + healthcheck
│       ├── wordpress/
│       │   ├── Dockerfile       # WordPress + PHP-FPM container
│       │   ├── .dockerignore
│       │   ├── conf/
│       │   │   └── www.conf    # PHP-FPM configuration
│       │   └── tools/
│       │       └── entrypoint.sh  # WordPress installation via WP-CLI
│       └── nginx/
│           ├── Dockerfile       # NGINX container image
│           ├── .dockerignore
│           ├── conf/
│           │   └── nginx.conf.template  # NGINX config with variables
│           └── tools/
│               └── entrypoint.sh  # SSL cert generation, config processing
├── secrets/                     # Secret files (gitignored)
│   ├── .gitkeep
│   ├── README.md
│   ├── db_root_password.txt
│   ├── db_password.txt
│   ├── credentials.txt          # Format: username:password
│   └── second_user.txt
└── .gitignore                   # Prevents committing secrets
```

---

## Building and Launching

### Makefile Targets

| Target | Purpose | Usage |
|--------|---------|-------|
| `setup` | Create secrets and directories | `make setup` |
| `all` | Build all Docker images (runs setup first) | `make all` |
| `up` | Start containers (use existing images) | `make up` |
| `down` | Stop and remove containers | `make down` |
| `downv` | Stop containers and remove volumes | `make downv` |
| `rebuild` | Force rebuild without cache | `make rebuild` |
| `clean` | Remove secrets and .env | `make clean` |
| `nuke` | Remove everything (images, volumes, data, secrets) | `make nuke` |
| `re` | Full clean + rebuild (clean → all) | `make re` |
| `ps` | Show running containers | `make ps` |
| `volumes` | List Docker volumes | `make volumes` |

### Build Process

**Complete build sequence:**
```bash
make nuke      # Clean slate (if needed)
make setup     # Configure secrets
make all       # Build images
make up        # Start containers
```

**Docker Compose commands executed internally:**
```bash
# make all:
docker compose -f srcs/docker-compose.yml build

# make up:
docker compose -f srcs/docker-compose.yml up -d --build --pull never mariadb

# make down:
docker compose -f srcs/docker-compose.yml down
```

---

## Container Management

### Manual Docker Commands

**Build specific service:**
```bash
docker compose -f srcs/docker-compose.yml build mariadb
docker compose -f srcs/docker-compose.yml build wordpress
docker compose -f srcs/docker-compose.yml build nginx
```

**Start specific service:**
```bash
docker compose -f srcs/docker-compose.yml up -d mariadb
docker compose -f srcs/docker-compose.yml up -d wordpress
docker compose -f srcs/docker-compose.yml up -d nginx
```

**View logs:**
```bash
docker compose -f srcs/docker-compose.yml logs -f mariadb
docker compose -f srcs/docker-compose.yml logs -f wordpress
docker compose -f srcs/docker-compose.yml logs -f nginx
```

**Execute commands in running containers:**
```bash
# MariaDB shell
docker exec -it mariadb sh
docker exec -it mariadb mariadb -u root -p

# WordPress shell
docker exec -it wordpress sh

# WordPress WP-CLI commands
docker exec -it wordpress wp --info --allow-root
docker exec -it wordpress wp user list --allow-root
docker exec -it wordpress wp plugin list --allow-root

# NGINX shell
docker exec -it nginx sh

# Test NGINX config
docker exec -it nginx nginx -t
```

**Inspect container details:**
```bash
docker inspect mariadb
docker inspect wordpress
docker inspect nginx
```

**Container resource usage:**
```bash
docker stats
```

---

## Volume Management

### Named Volumes with Bind Mounts

The project uses Docker named volumes with bind mount configuration to satisfy two requirements:
1. Subject requirement: "use Docker named volumes"
2. Subject requirement: "store data in /home/login/data"

```yaml
volumes:
  mariadb-data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/${LOGIN}/data/mariadb

  wp-data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/${LOGIN}/data/wordpress
```

**Why this hybrid approach?**
- Named volumes provide Docker's management capabilities
- Bind mount behavior allows direct host filesystem access
- Data persists even if volumes are removed via Docker commands

### Volume Commands

**List volumes:**
```bash
docker volume ls
```

**Inspect volume:**
```bash
docker volume inspect srcs_mariadb-data
docker volume inspect srcs_wp-data
```

**Remove volumes:**
```bash
docker volume rm srcs_mariadb-data
docker volume rm srcs_wp-data
```

**Volume location on host:**
```bash
ls -la /home/${LOGIN}/data/mariadb
ls -la /home/${LOGIN}/data/wordpress
```

### Data Persistence

**What persists:**
- MariaDB database files
- WordPress core files
- Uploaded media
- Installed plugins
- Installed themes
- `wp-config.php` configuration

**Backup strategy:**
```bash
# Stop containers
make down

# Backup data directories
sudo tar -czf backup_$(date +%Y%m%d).tar.gz /home/${LOGIN}/data

# Database dump (more reliable for MariaDB)
docker compose -f srcs/docker-compose.yml up -d mariadb
docker exec mariadb mysqldump -u root -p --all-databases > backup.sql
```

---

## Network Configuration

### Docker Network

**Network definition:**
```yaml
networks:
  docker-network:
    driver: bridge
```

**Network driver: bridge**
- Default Docker network driver
- Containers communicate by service name
- Isolated from host network
- NGINX publishes port 443 to host

**Service name resolution:**
```
wordpress → connects to → mariadb:3306
nginx     → connects to → wordpress:9000
```

Docker's built-in DNS resolves service names to container IPs.

**Network inspection:**
```bash
docker network ls
docker network inspect srcs_docker-network
```

---

## Secrets Management

### Docker Compose Secrets

**Top-level secrets definition:**
```yaml
secrets:
  db_root_pw:
    file: ../secrets/db_root_password.txt
  db_user_pw:
    file: ../secrets/db_password.txt
  credentials:
    file: ../secrets/credentials.txt
  second_user:
    file: ../secrets/second_user.txt
```

**Service-level consumption:**
```yaml
services:
  mariadb:
    secrets:
      - db_root_pw
      - db_user_pw
    environment:
      - MYSQL_ROOT_PASSWORD_FILE=/run/secrets/db_root_pw
      - MYSQL_PASSWORD_FILE=/run/secrets/db_user_pw
```

**How it works:**
1. Docker reads files from `secrets/` directory
2. Mounts them inside container at `/run/secrets/<secret_name>`
3. Files are read-only
4. Scripts read secrets: `DB_PASSWORD=$(cat /run/secrets/db_user_pw)`

---

## Service-Specific Details

### MariaDB Container

**Dockerfile (Alpine 3.22):**
```dockerfile
FROM alpine:3.22
RUN apk add --no-cache mariadb mariadb-client
EXPOSE 3306
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["mariadbd", "--user=mysql"]
```

**Configuration file (`conf/my.cnf`):**
```ini
[mysqld]
user = mysql
datadir = /var/lib/mysql
bind-address = 0.0.0.0     # Allow cross-container connections
port = 3306
skip-name-resolve          # Performance optimization
innodb_buffer_pool_size=128M  # Small VM optimization
max_connections=50

[client]
socket = /run/mysqld/mysql.sock
```

**Entrypoint script logic:**
1. Set data directory permissions (`chown mysql:mysql`)
2. Read secrets from `/run/secrets/`
3. Check if database initialized (`/var/lib/mysql/mysql` exists)
4. If first run:
   - Run `mariadb-install-db` to create system tables
   - Create bootstrap SQL with:
     - Database creation
     - User creation with remote access
     - Root password setting
   - Execute bootstrap via `mariadbd --bootstrap`
5. Create health check config (`/etc/mysql/health.cnf`)
6. Start MariaDB as PID 1 via `exec "$@"`

**Health check:**
```yaml
healthcheck:
  test: ["CMD-SHELL", "mariadb-admin --defaults-extra-file=/etc/mysql/health.cnf ping --silent"]
  interval: 5s
  timeout: 3s
  retries: 5
  start_period: 10s
```

This allows WordPress to wait for MariaDB to be truly ready:
```yaml
wordpress:
  depends_on:
    mariadb:
      condition: service_healthy
```

---

### WordPress Container

**Dockerfile (Alpine 3.22):**
```dockerfile
FROM alpine:3.22
RUN apk update && apk add --no-cache \
    php83 php83-fpm php83-mysqli php83-json php83-curl \
    php83-dom php83-exif php83-fileinfo php83-mbstring \
    php83-openssl php83-xml php83-zip php83-gd php83-phar \
    curl tar wget netcat-openbsd \
    && echo "memory_limit = 512M" > /etc/php83/conf.d/99-memory.ini
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp
EXPOSE 9000
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["php-fpm83", "-F"]
```

**Key additions:**
- `php83-phar`: Required for WP-CLI
- `netcat-openbsd`: For MariaDB connection checking
- Memory limit increase: WordPress often needs more than default 128M

**PHP-FPM configuration (`conf/www.conf`):**
```ini
[www]
user = nobody
group = nobody
listen = 9000              # TCP socket for NGINX connection
pm = dynamic
pm.max_children = 5
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3
```

**Entrypoint script logic:**
1. Read all secrets:
   - Database password from `/run/secrets/db_user_pw`
   - Second user password from `/run/secrets/second_user`
   - Parse admin credentials from `/run/secrets/credentials` (format: `user:pass`)
2. Wait for MariaDB using netcat: `while ! nc -z mariadb 3306; do sleep 1; done`
3. Check if WordPress installed via WP-CLI
4. If first run:
   - Download WordPress core if `wp-admin/` doesn't exist
   - Create `wp-config.php` with database connection if missing
   - Install WordPress (creates admin user, sets site URL)
   - Create second user with author role
5. Start PHP-FPM as PID 1

**WP-CLI commands used:**
```bash
wp core download --allow-root
wp core is-installed --allow-root
wp config create --dbname=... --dbuser=... --dbpass=... --dbhost=mariadb:3306
wp core install --url=... --title=... --admin_user=... --admin_password=...
wp user create USER EMAIL --role=author --user_pass=...
```

---

### NGINX Container

**Dockerfile (Alpine 3.22):**
```dockerfile
FROM alpine:3.22
RUN apk add --no-cache nginx openssl gettext
COPY conf/nginx.conf.template /etc/nginx/nginx.conf.template
EXPOSE 443
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
```

**SSL Certificate generation:**
```bash
openssl req -x509 -nodes \
    -days 365 \
    -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/nginx.key \
    -out /etc/nginx/ssl/nginx.crt \
    -subj "/C=CH/ST=Vaud/L=Ecublens/O=42Lausanne/OU=42Lausanne/CN=${DOMAIN_NAME}/UID=${DOMAIN_NAME}"
```

**Configuration template processing:**
```bash
envsubst '${DOMAIN_NAME} ${SSL_CERT} ${SSL_KEY}' \
    < /etc/nginx/nginx.conf.template \
    > /etc/nginx/nginx.conf
```

The `gettext` package provides `envsubst` for environment variable substitution.

**NGINX configuration (`conf/nginx.conf.template`):**
```nginx
user nginx;
worker_processes auto;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    # Log to stdout/stderr for Docker
    access_log /dev/stdout;
    error_log /dev/stderr warn;
    
    server {
        listen 443 ssl;
        listen [::]:443 ssl;
        server_name ${DOMAIN_NAME};
        
        # SSL Configuration
        ssl_certificate ${SSL_CERT};
        ssl_certificate_key ${SSL_KEY};
        ssl_protocols TLSv1.2 TLSv1.3;    # Subject requirement!
        
        # WordPress root
        root /var/www/html;
        index index.php index.html index.htm;
        
        # Main location
        location / {
            try_files $uri $uri/ /index.php?$args;
        }
        
        # PHP-FPM forwarding
        location ~ \.php$ {
            try_files $uri =404;
            fastcgi_index index.php;
            fastcgi_pass wordpress:9000;
            include fastcgi_params;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        }
        
        # Deny hidden files
        location ~ /\. {
            deny all;
        }
    }
}
```

**Key FastCGI parameters:**
- `fastcgi_pass wordpress:9000`: Forward to WordPress container
- `SCRIPT_FILENAME`: Full path to PHP file
- `fastcgi_params`: Standard CGI variables

---

## Debugging and Development

### Development Workflow

**Modify code → Rebuild → Test:**
```bash
nano srcs/requirements/mariadb/tools/entrypoint.sh
docker compose -f srcs/docker-compose.yml build mariadb
docker compose -f srcs/docker-compose.yml up -d mariadb
docker compose -f srcs/docker-compose.yml logs -f mariadb
```

### Common Debugging Commands

**Check inter-container connectivity:**
```bash
docker exec -it wordpress nc -zv mariadb 3306
docker exec -it nginx nc -zv wordpress 9000
```

**Database inspection:**
```bash
docker exec -it mariadb mariadb -u root -p
```
```sql
SHOW DATABASES;
USE your_database;
SHOW TABLES;
SELECT * FROM wp_users;
SELECT User, Host FROM mysql.user;
```

**WordPress debugging:**
```bash
docker exec -it wordpress wp option get siteurl --allow-root
docker exec -it wordpress wp user list --allow-root
docker exec -it wordpress wp plugin list --allow-root
```

**NGINX debugging:**
```bash
docker exec -it nginx nginx -t
docker exec -it nginx tail -f /dev/stdout
docker exec -it nginx tail -f /dev/stderr
```

---

## Design Decisions

### Virtual Machines vs Docker

| Aspect | VM | Docker |
|--------|-----|--------|
| Isolation | Full OS | Process-level |
| Size | GBs | MBs |
| Startup | Minutes | Seconds |
| Resource usage | High | Low |

**Decision:** Docker for portability, speed, and resource efficiency.

---

### Secrets vs Environment Variables

| Feature | Secrets | Env Vars |
|---------|---------|----------|
| Visibility | Filesystem only | `docker inspect` |
| Storage | Files | Metadata |
| Security | High | Medium |

**Decision:** Secrets for passwords, env vars for configuration.

---

### Docker Network vs Host Network

**Bridge network (our choice):**
- Service name resolution
- Container isolation
- Standard for multi-container apps

**Host network (forbidden by subject):**
- Shares host network stack
- Less isolation
- Higher performance (not needed here)

---

### Docker Volumes vs Bind Mounts

**Our hybrid approach:**
- Named volumes (Docker management)
- Bind mount behavior (host access)
- Satisfies both subject requirements

---

## Testing Checklist

### Pre-Evaluation

```bash
# 1. Clean build
make nuke
make all

# 2. Start services
make up
docker ps  # All containers "Up"

# 3. Check MariaDB
docker exec -it mariadb mariadb -u root -p
SHOW DATABASES;

# 4. Check WordPress
curl -k https://your-domain.42.fr

# 5. Verify SSL/TLS
openssl s_client -connect your-domain.42.fr:443 -tls1_2  # Should work
openssl s_client -connect your-domain.42.fr:443 -tls1_1  # Should fail

# 6. Verify data persistence
make down
make up
# Data should remain

# 7. Verify admin username validation
echo "admin:pass" > secrets/credentials.txt
make all  # Should fail or warn
```

---

## Resources

### Docker
- **Official Documentation**: https://docs.docker.com/
- **Dockerfile Best Practices**: https://docs.docker.com/develop/dev-best-practices/
- **Docker Compose**: https://docs.docker.com/compose/

### NGINX
- **Official Documentation**: https://nginx.org/en/docs/
- **Alpine Requirements**: https://wiki.alpinelinux.org/wiki/Nginx
- **envsubst usage**: https://www.gnu.org/software/gettext/manual/html_node/envsubst-Invocation.html
- **FastCGI Parameters**: https://www.nginx.com/resources/wiki/start/topics/examples/phpfcgi/

### WordPress & PHP
- **WordPress Documentation**: https://wordpress.org/documentation/
- **WP-CLI Installation**: https://wp-cli.org/#installing
- **PHP-FPM Config**: https://www.php.net/manual/en/install.fpm.configuration.php
- **PHP Memory Exhausted**: https://kinsta.com/knowledgebase/wordpress-memory-limit/

### SSL/TLS
- **OpenSSL Self-Signed Certificates**: https://www.openssl.org/docs/man1.1.1/man1/req.html

### Video Tutorials
- **TechnoTim - Build Your Own Dockerfile**: https://www.youtube.com/watch?v=SnSH8Ht3MIc

---

## Subject Requirements Met

- ✅ Alpine Linux (version 3.22)
- ✅ Custom Dockerfiles (no pre-built images)
- ✅ Three containers: NGINX, WordPress, MariaDB
- ✅ TLSv1.2/1.3 only on NGINX
- ✅ Docker named volumes with /home/login/data binding
- ✅ Docker bridge network
- ✅ Docker secrets for credentials
- ✅ Environment variables in .env
- ✅ Restart policy (unless-stopped)
- ✅ NGINX port 443 only
- ✅ Two WordPress users
- ✅ No "admin" in admin username
- ✅ No passwords in Dockerfiles
- ✅ Domain: ${LOGIN}.42.fr
- ✅ Health checks for MariaDB

---

## Command Reference

```bash
# Setup & Build
make setup              # Initial configuration
make all                # Build images
make up                 # Start containers
make down               # Stop containers
make downv              # Stop + remove volumes
make nuke               # Complete reset

# Development
make rebuild            # Force rebuild
docker compose -f srcs/docker-compose.yml logs -f
docker compose -f srcs/docker-compose.yml ps

# Container Access
docker exec -it mariadb sh
docker exec -it wordpress sh
docker exec -it nginx sh

# Debugging
docker ps
docker logs mariadb
docker inspect wordpress
docker stats
```
